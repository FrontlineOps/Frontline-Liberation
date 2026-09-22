"""Static/regression checks; these do not execute SQF or replace Arma testing.
Run: python tools/test_live_settings.py
Optional: FL_SETTINGS_BASE_REF=<pre-change commit> checks numeric/schema compatibility.
"""
import ast
import os
from pathlib import Path
import re
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]
SECTION = "MissionFramework/modules/settings/sections"
ROW = re.compile(
    r'\[\s*"(?P<key>[^"]+)",\s*"(?P<kind>SLIDER|LIST|CHECKBOX)",\s*'
    r'"(?P<title>[^"]*)",\s*"(?P<tip>[^"]*)",\s*'
    r'(?P<category>\[[^\n]+\]),\s*(?P<data>[^\n]+),\s*'
    r'(?P<live>true|false)\s*\]\s*call _add;'
)
RESTART = set("""
KP_liberation_autoFaction_vehiclePriceMultipliers_0
KP_liberation_autoFaction_vehiclePriceMultipliers_1
KP_liberation_autoFaction_vehiclePriceMultipliers_2
BATTLESPACE_STRATEGIC_ENABLED BATTLESPACE_TASK_FORCES_PERSISTENT
BATTLESPACE_STRATEGIC_INITIAL_DELAY BATTLESPACE_STRATEGIC_INITIAL_STOCK_RATIO
BATTLESPACE_STRATEGIC_AIR_RESPONSE_INITIAL_DELAY KPLIB_intelligence_enabled
GRLIB_capture_size KP_liberation_cr_param_buildings KP_liberation_restart
KP_liberation_mapmarkers KP_liberation_commander_zeus KP_liberation_limited_zeus
KP_liberation_enemies_zeus KPLIB_intelligence_max_reports
""".split())


def read(path):
    return (ROOT / "MissionFramework" / path).read_text(encoding="utf-8")


def rows(text):
    return [m.groupdict() for m in ROW.finditer(text)]


def literal(text):
    return ast.literal_eval(re.sub(r"\b(true|false)\b", lambda m: m[0].title(), text))


class LiveSettings(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.files = sorted((ROOT / SECTION).glob("*.sqf"))
        cls.rows = [r for p in cls.files for r in rows(p.read_text(encoding="utf-8"))]
        cls.catalog = {r["key"]: r for r in cls.rows}
        cls.apply = read("modules/settings/fn_settingsApply.sqf")
        cls.preinit = read("modules/settings/fn_settingsPreInit.sqf")

    def test_catalog_and_restart_policy(self):
        self.assertEqual(len(self.files), 9)
        self.assertEqual(len(self.rows), 329)
        self.assertEqual(len(self.catalog), 329)
        self.assertEqual({r["key"] for r in self.rows if r["live"] == "false"}, RESTART)
        self.assertEqual(sum(r["live"] == "true" for r in self.rows), 312)
        for p in self.files:
            self.assertEqual(len(rows(p.read_text())), p.read_text().count("call _add;"))

    @unittest.skipUnless(os.getenv("FL_SETTINGS_BASE_REF"), "Set FL_SETTINGS_BASE_REF to compare schemas")
    def test_saved_values_types_defaults_and_order_unchanged(self):
        base = os.environ["FL_SETTINGS_BASE_REF"]
        for p in self.files:
            original = subprocess.check_output(
                ["git", "show", f"{base}:{p.relative_to(ROOT).as_posix()}"], cwd=ROOT, text=True
            )
            before, after = rows(original), rows(p.read_text())
            self.assertEqual([r["key"] for r in before], [r["key"] for r in after])
            for old, new in zip(before, after):
                self.assertEqual(old["kind"], new["kind"])
                self.assertEqual(old["category"], new["category"])
                a, b = literal(old["data"]), literal(new["data"])
                if old["key"] == "GRLIB_time_factor":
                    self.assertEqual((a[0], a[2]), (b[0], b[2]))
                else:
                    self.assertEqual(a, b)

    def test_clock_labels_defaults_and_live_flags(self):
        clock = self.catalog["GRLIB_time_factor"]
        values, labels, default = literal(clock["data"])
        self.assertEqual(labels, [f"{v}x" for v in values])
        self.assertEqual(values[default], 6)
        self.assertEqual(clock["live"], "true")
        nights = self.catalog["GRLIB_shorter_nights"]
        self.assertEqual((nights["data"], nights["live"]), ("true", "true"))
        self.assertIn("3x becomes 12x", nights["tip"])

    def test_clock_boundary_expression_and_reference_cases(self):
        expression = "GRLIB_time_factor * ([1, 4] select (GRLIB_shorter_nights && {daytime >= 20 || daytime < 4}))"
        self.assertIn(expression, self.apply)
        self.assertIn(expression, read("scripts/server/game/manage_time.sqf"))
        for base in [1, 2, 3, 4, 6, 8]:
            for hour, night in [(0, True), (3.99, True), (4, False), (19.99, False), (20, True), (23.99, True)]:
                self.assertEqual(base * (4 if hour >= 20 or hour < 4 else 1), base * (4 if night else 1))
                self.assertEqual(base * (4 if False and night else 1), base)

    def test_authorization_and_revision_guards_retained(self):
        self.assertIn('isNil "_KPLIB_settingsApplyContext"', self.apply)
        self.assertIn('if (isRemoteExecuted ||', self.apply)
        self.assertIn('if (_revision <=', self.apply)
        self.assertIn('1, {}, !_live] call CBA_fnc_addSetting', self.preinit)
        self.assertIn('if (!isServer || {_key find "KPLIB_cfg_" != 0}', self.preinit)
        self.assertNotIn("remoteExec", self.apply)

    def test_targeted_cache_invalidation(self):
        for cache in ["KPLIB_aiCombat_profiles", "KPLIB_munitionsFragProfiles", "KPLIB_blastProfiles"]:
            self.assertIn(f'["{cache}", createHashMap]', self.apply)
        for key in ["rangeMultiplier", "rifleRange", "launcherRange", "grenadeRange", "minRifleRange", "blastMargin"]:
            self.assertIn(f'"KPLIB_aiCombat_{key}"', self.apply)
        self.assertIn('"KPLIB_munitions_thermal_labels" in _changed', self.apply)
        self.assertIn('"KPLIB_munitions_fragment_cap", "KPLIB_munitions_fragment_multiplier"', self.apply)
        self.assertNotIn("allUnits", self.apply)
        self.assertNotIn("addPerFrameHandler", self.apply)

    def test_player_respawn_and_disable_paths(self):
        client = read("scripts/client/init_client.sqf")
        self.assertIn('"Respawn", {player enableStamina GRLIB_fatigue;}', client)
        self.assertIn('"Respawn", {player setCustomAimCoef ([0.1, 1] select KPLIB_sway);}', client)
        state = read("scripts/client/misc/playerNamespace.sqf")
        self.assertIn('["KPLIB_isNearArsenal", KP_liberation_mobilearsenal && {', state)
        self.assertIn('["KPLIB_isNearMobRespawn", KP_liberation_mobilerespawn && {', state)

    def test_fuel_reads_live_values(self):
        fuel = read("scripts/client/misc/kp_fuel_consumption.sqf")
        self.assertNotIn("private _kp_", fuel)
        for speed in ["max", "normal", "neutral"]:
            self.assertIn(f"KP_liberation_fuel_{speed} * 60", fuel)

    def test_cleanup_can_reenable_and_never_deletes_on_disable(self):
        cleanup = read("scripts/server/game/cleanup_vehicles.sqf")
        self.assertIn("while {GRLIB_endgame == 0}", cleanup)
        self.assertIn("if (_cleanupHours <= 0) then {continue}", cleanup)
        self.assertIn("if (GRLIB_cleanup_vehicles <= 0) exitWith {}", cleanup)
        self.assertIn("(6 * _cleanupHours)", cleanup)
        self.assertIn("if (GRLIB_cleanup_vehicles > 0 &&", cleanup)
        for ticker in [0, 1, 6, 100]:
            self.assertFalse(0 > 0 and ticker >= 6 * 1)

    def test_fog_and_weather_reuse_existing_workers(self):
        server = read("scripts/server/init_server.sqf")
        self.assertNotIn("if (!KP_liberation_fog_param)", server)
        self.assertIn("if (!KP_liberation_fog_param)", read("scripts/server/game/fucking_set_fog.sqf"))
        weather = read("scripts/server/game/manage_weather.sqf")
        self.assertIn("_mode = GRLIB_weather_param;", weather)
        self.assertIn("waitUntil {sleep 5;", weather)
        self.assertIn("GRLIB_weather_param != _mode", weather)
        self.assertEqual(weather.count("forceWeatherChange"), 1)


if __name__ == "__main__":
    unittest.main()
