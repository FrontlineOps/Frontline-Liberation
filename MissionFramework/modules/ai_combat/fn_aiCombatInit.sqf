/* Server runtime; interface/JIP installs only shot evidence and read-only ZEN.
   No headless-client controller, global knowledge broadcast or per-unit thread. */
if (isRemoteExecuted) exitWith {};
if (hasInterface && {isNil "KPLIB_aiCombat_zenReady"}
    && {!isNil "zen_context_menu_fnc_createAction"}) then {
    KPLIB_aiCombat_zenReady = true;
    private _action = ["frontlineAICombat", "Inspect Frontline AI Combat", "", {
        [_this select 0] remoteExecCall ["KPLIB_fnc_aiCombatInspect", 2];
    }, {true}] call zen_context_menu_fnc_createAction;
    [_action, [], 0] call zen_context_menu_fnc_addAction;
};
if (localNamespace getVariable ["KPLIB_aiCombat_initialized", false]) exitWith {};
localNamespace setVariable ["KPLIB_aiCombat_initialized", true];
// Only the shooter's owner forwards the native event; the server validates it.
["CAManBase", "FiredMan", {_this call KPLIB_fnc_aiCombatFired}] call CBA_fnc_addClassEventHandler;
if (!isServer) exitWith {};
private _valid = KPLIB_aiCombat_sides isEqualType [];
if (_valid) then {_valid = KPLIB_aiCombat_sides findIf {!(_x isEqualType EAST) || {_x == civilian}} < 0};
{
    _x params ["_value", "_low", "_high"];
    if (!(_value isEqualType 0) || {!finite _value} || {_value < _low} || {_value > _high}) then {_valid = false};
} forEach [
    [KPLIB_aiCombat_rangeMultiplier, 1, 4], [KPLIB_aiCombat_rifleRange, 100, 2000],
    [KPLIB_aiCombat_launcherRange, 50, 1500], [KPLIB_aiCombat_grenadeRange, 50, 800],
    [KPLIB_aiCombat_minRifleRange, 50, 2000], [KPLIB_aiCombat_explosiveCooldown, 5, 600],
    [KPLIB_aiCombat_groupExplosiveCooldown, 2, 120], [KPLIB_aiCombat_blastMargin, 5, 100],
    [KPLIB_aiCombat_backblastRange, 10, 100], [KPLIB_aiCombat_flareCooldown, 30, 600],
    [KPLIB_aiCombat_flareRadius, 100, 600], [KPLIB_aiCombat_hearingRange, 100, 3000],
    [KPLIB_aiCombat_suppressedRange, 10, 500], [KPLIB_aiCombat_soundMemory, 5, 60],
    [KPLIB_aiCombat_batchSize, 1, 16], [KPLIB_aiCombat_maxActive, 1, 32]
];
if ([KPLIB_aiCombat_enabled, KPLIB_aiCombat_flares, KPLIB_aiCombat_hearing, KPLIB_aiCombat_debug]
    findIf {!(_x isEqualType true)} >= 0) then {_valid = false};
if (!_valid) exitWith {
    localNamespace setVariable ["KPLIB_aiCombat_blocked", "Invalid root configuration"];
    ["Infantry combat stopped: invalid configuration", "AI COMBAT"] call KPLIB_fnc_log;
};
localNamespace setVariable ["KPLIB_aiCombat_blocked", ""];
{localNamespace setVariable [_x, createHashMap]} forEach [
    "KPLIB_aiCombat_registry", "KPLIB_aiCombat_profiles", "KPLIB_aiCombat_muzzles", "KPLIB_aiCombat_groups"
];
{localNamespace setVariable [_x, []]} forEach ["KPLIB_aiCombat_queue", "KPLIB_aiCombat_active", "KPLIB_aiCombat_sounds", "KPLIB_aiCombat_flaresActive"];
["CAManBase", "init", {
    [{_this call KPLIB_fnc_aiCombatRegister}, [_this select 0], 1] call CBA_fnc_waitAndExecute;
}, true, [], true] call CBA_fnc_addClassEventHandler;
["CAManBase", "Local", {
    if (_this select 1) then {
        [{_this call KPLIB_fnc_aiCombatRegister}, [_this select 0], 1] call CBA_fnc_waitAndExecute;
    };
}] call CBA_fnc_addClassEventHandler;
// A near miss reports danger at the listener; it grants no shooter identity.
["CAManBase", "Suppressed", {
    params ["_unit"];
    if (!isRemoteExecuted && {local _unit}) then {
        private _state = (localNamespace getVariable "KPLIB_aiCombat_registry") getOrDefault [netId _unit, createHashMap];
        if (count _state > 0) then {_state set ["nearMiss", CBA_missionTime]};
    };
}] call CBA_fnc_addClassEventHandler;
localNamespace setVariable ["KPLIB_aiCombat_handler", [{[] call KPLIB_fnc_aiCombatTick}, 0.25] call CBA_fnc_addPerFrameHandler];
[format ["Infantry combat initialized: rifle/RPG/GL caps %1/%2/%3 m; carried flares and sound cues", KPLIB_aiCombat_rifleRange, KPLIB_aiCombat_launcherRange, KPLIB_aiCombat_grenadeRange], "AI COMBAT"] call KPLIB_fnc_log;
