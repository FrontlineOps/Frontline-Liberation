/* Local application only. Server commits and authenticated server snapshots
   are the only callers. Content/catalog generation remains in normal init. */
// HC-originated RPCs can report isRemoteExecuted=false. Require the private
// scope of an authorized local caller as well; network arguments cannot set it.
if (isRemoteExecuted || {isNil "_KPLIB_settingsApplyContext"}) exitWith {false};
params ["_revision", "_values"];
if (_revision <= (localNamespace getVariable ["KPLIB_settingsRevision", -1])) exitWith {false};
private _rows = localNamespace getVariable "KPLIB_settingsCatalog";
private _old = localNamespace getVariable ["KPLIB_settingsValues", []];
private _changed = [];
{
    private _value = _values select _forEachIndex;
    if (_old isEqualTo [] || {_value isNotEqualTo (_old select _forEachIndex)}) then {_changed pushBack (_x select 0)};
    missionNamespace setVariable [_x select 0, _value];
} forEach _rows;
[] call KPLIB_fnc_settingsDerive;
localNamespace setVariable ["KPLIB_settingsValues", +_values];
localNamespace setVariable ["KPLIB_settingsRevision", _revision];
localNamespace setVariable ["KPLIB_settingsReady", true];

// Invalidate only setting-dependent metadata. Existing jobs keep their own
// profiles; future decisions rebuild lazily. No world scan or worker restart.
if (_changed findIf {_x in ["KPLIB_aiCombat_rangeMultiplier", "KPLIB_aiCombat_rifleRange",
    "KPLIB_aiCombat_launcherRange", "KPLIB_aiCombat_grenadeRange",
    "KPLIB_aiCombat_minRifleRange", "KPLIB_aiCombat_blastMargin"]} >= 0) then {
    localNamespace setVariable ["KPLIB_aiCombat_profiles", createHashMap];
};
if (_changed findIf {_x in ["KPLIB_munitions_fragment_cap", "KPLIB_munitions_fragment_multiplier"]} >= 0) then {
    localNamespace setVariable ["KPLIB_munitionsFragProfiles", createHashMap];
};
if ("KPLIB_munitions_thermal_labels" in _changed) then {
    localNamespace setVariable ["KPLIB_blastProfiles", createHashMap];
};
if (isServer) then {
    if (_changed findIf {_x in ["GRLIB_time_factor", "GRLIB_shorter_nights"]} >= 0) then {
        private _multiplier = GRLIB_time_factor * ([1, 4] select (GRLIB_shorter_nights && {daytime >= 20 || daytime < 4}));
        setTimeMultiplier _multiplier;
        diag_log format ["[FL SETTINGS] Clock: base %1x, faster nights %2, active %3x", GRLIB_time_factor, GRLIB_shorter_nights, _multiplier];
    };
    if ("KP_liberation_fog_param" in _changed && {!KP_liberation_fog_param}) then {5 setFog [0, 0, 0]};
};
if (hasInterface && {!isNull player}) then {
    if ("GRLIB_fatigue" in _changed) then {player enableStamina GRLIB_fatigue};
    if ("KPLIB_sway" in _changed) then {player setCustomAimCoef ([0.1, 1] select KPLIB_sway)};
};
true
