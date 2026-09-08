/* Mission bootstrap after root configuration. Server owns skills and state.
   Interface clients/JIP register only a read-only Zeus action. No HC bootstrap,
   persistent unit metadata, per-unit threads or synchronization loop. */
if (isRemoteExecuted) exitWith {};
if (hasInterface && {isNil "KPLIB_aiSkills_zenReady"}
    && {!isNil "zen_context_menu_fnc_createAction"}) then {
    KPLIB_aiSkills_zenReady = true;
    private _action = ["frontlineAISkills", "Inspect Frontline AI Skills", "", {
        [_this select 0] remoteExecCall ["KPLIB_fnc_aiSkillsInspect", 2];
    }, {true}] call zen_context_menu_fnc_createAction;
    [_action, [], 0] call zen_context_menu_fnc_addAction;
};
if (!isServer || {localNamespace getVariable ["KPLIB_aiSkills_initialized", false]}) exitWith {};
localNamespace setVariable ["KPLIB_aiSkills_initialized", true];
KPLIB_aiSkills_names = ["general", "aimingAccuracy", "aimingShake", "aimingSpeed", "spotDistance", "spotTime", "courage", "reloadSpeed", "commanding"];
localNamespace setVariable ["KPLIB_aiSkills_registry", createHashMap];
localNamespace setVariable ["KPLIB_aiSkills_queue", []];
localNamespace setVariable ["KPLIB_aiSkills_blocked", ""];

private _profiles = createHashMap;
private _valid = true;
if ([KPLIB_aiSkills_profiles, KPLIB_aiSkills_sideProfiles, KPLIB_aiSkills_factionProfiles, KPLIB_aiSkills_sides]
    findIf {!(_x isEqualType [])} >= 0) then {_valid = false};
if (!_valid) exitWith {
    localNamespace setVariable ["KPLIB_aiSkills_blocked", "Invalid AI skill configuration: profiles, mappings and sides must be arrays."];
    [localNamespace getVariable "KPLIB_aiSkills_blocked", "AI SKILLS"] call KPLIB_fnc_log;
};
{
    if (!(_x isEqualType []) || {count _x != 2}) then {
        _valid = false;
        continue;
    };
    _x params ["_name", "_values"];
    if (!(_name isEqualType "") || {!(_values isEqualType [])} || {count _values != 9}
        || {_values findIf {!(_x isEqualType 0) || {!finite _x} || {_x < -1} || {_x > 1} || {_x < 0 && {_x != -1}}} >= 0}) then {
        _valid = false;
        continue;
    };
    _profiles set [toUpper _name, +_values];
} forEach KPLIB_aiSkills_profiles;
{
    if (!(_x isEqualType []) || {count _x != 9}
        || {_x findIf {!(_x isEqualType 0) || {!finite _x} || {_x < 0} || {_x > 1}} >= 0}) then {_valid = false};
} forEach [KPLIB_aiSkills_terrainFloor, KPLIB_aiSkills_suppressionFloor];
{
    if (!(_x isEqualType []) || {count _x != 2} || {!((_x select 1) isEqualType "")}
        || {!(toUpper (_x select 1) in _profiles)}) then {_valid = false};
} forEach (KPLIB_aiSkills_sideProfiles + KPLIB_aiSkills_factionProfiles);
if (_valid && {KPLIB_aiSkills_sides findIf {!(_x isEqualType WEST)} >= 0
    || {KPLIB_aiSkills_sideProfiles findIf {!((_x param [0, ""]) isEqualType WEST)} >= 0}
    || {KPLIB_aiSkills_factionProfiles findIf {!((_x param [0, WEST]) isEqualType "")} >= 0}}) then {_valid = false};
{
    _x params ["_value", "_minimum", "_maximum"];
    if (!(_value isEqualType 0) || {!finite _value} || {_value < _minimum} || {_value > _maximum}) then {_valid = false};
} forEach [
    [KPLIB_aiSkills_variation, 0, 1],
    [KPLIB_aiSkills_tickInterval, 0.05, 60],
    [KPLIB_aiSkills_batchSize, 1, 128],
    [KPLIB_aiSkills_updateInterval, 0.25, 600],
    [KPLIB_aiSkills_terrainSamplesPerTick, 0, 8],
    [KPLIB_aiSkills_terrainInterval, 1, 3600],
    [KPLIB_aiSkills_terrainRadius, 1, 100],
    [KPLIB_aiSkills_terrainSaturation, 1, 1000],
    [KPLIB_aiSkills_suppressionImpact, 0, 1],
    [KPLIB_aiSkills_suppressionHold, 0, 600],
    [KPLIB_aiSkills_suppressionRecovery, 0.1, 600],
    [KPLIB_aiSkills_nightFloor, 0, 1],
    [KPLIB_aiSkills_rainFloor, 0, 1],
    [KPLIB_aiSkills_fogFloor, 0, 1],
    [KPLIB_aiSkills_boostMaximum, 1, 1.5],
    [KPLIB_aiSkills_boostShots, 1, 100],
    [KPLIB_aiSkills_boostShotInterval, 0.25, 60],
    [KPLIB_aiSkills_boostMinDistance, 0, 5000],
    [KPLIB_aiSkills_boostTargetMovement, 0, 500],
    [KPLIB_aiSkills_boostExpiry, 0.25, 600]
];
if ([KPLIB_aiSkills_enabled, KPLIB_aiSkills_suppressionEnabled, KPLIB_aiSkills_weatherEnabled,
    KPLIB_aiSkills_boostEnabled, KPLIB_aiSkills_debug] findIf {!(_x isEqualType true)} >= 0) then {_valid = false};
if (!_valid || {!("MISSION" in _profiles)}) exitWith {
    localNamespace setVariable ["KPLIB_aiSkills_blocked", "Invalid AI skill configuration; module stopped before changing units. Check profiles, mappings, floors and numeric bounds in fn_aiSkillsInit.sqf."];
    [localNamespace getVariable "KPLIB_aiSkills_blocked", "AI SKILLS"] call KPLIB_fnc_log;
};
localNamespace setVariable ["KPLIB_aiSkills_profiles", _profiles];
localNamespace setVariable ["KPLIB_aiSkills_wasEnabled", KPLIB_aiSkills_enabled];

// One delayed registration per new unit lets createManagedUnit and scripted
// loadouts finish their temporary civilian-group initialization first.
["CAManBase", "init", {
    if (isServer && {!isRemoteExecuted}) then {
        [{_this call KPLIB_fnc_aiSkillsRegister}, [_this select 0], 1] call CBA_fnc_waitAndExecute;
    };
}, true, [], true] call CBA_fnc_addClassEventHandler;
["CAManBase", "Local", {
    if (isServer && {!isRemoteExecuted} && {_this select 1}) then {
        [{_this call KPLIB_fnc_aiSkillsRegister}, [_this select 0], 1] call CBA_fnc_waitAndExecute;
    };
}] call CBA_fnc_addClassEventHandler;
["CAManBase", "Suppressed", {_this call KPLIB_fnc_aiSkillsThreat}] call CBA_fnc_addClassEventHandler;
["CAManBase", "FiredMan", {_this call KPLIB_fnc_aiSkillsFired}] call CBA_fnc_addClassEventHandler;
private _handler = [{[] call KPLIB_fnc_aiSkillsTick}, 0.05 max KPLIB_aiSkills_tickInterval] call CBA_fnc_addPerFrameHandler;
localNamespace setVariable ["KPLIB_aiSkills_handler", _handler];
[format ["Dynamic AI skills initialized (infantry and vehicle crews): profiles %1; batch %2 every %3s; suppression/terrain/weather/aim practice; tactical orders unchanged", keys _profiles, KPLIB_aiSkills_batchSize, KPLIB_aiSkills_tickInterval], "AI SKILLS"] call KPLIB_fnc_log;
