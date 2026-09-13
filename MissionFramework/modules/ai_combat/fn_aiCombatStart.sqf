params ["_state", "_profile", "_target", ["_flarePosition", []]];
if (!isServer || {isRemoteExecuted}) exitWith {false};
private _unit = _state get "unit";
if ([_unit] call KPLIB_fnc_aiCombatEligible != "" || {!(_unit checkAIFeature "FIREWEAPON")}) exitWith {false};
private _active = localNamespace getVariable "KPLIB_aiCombat_active";
if (count _active >= KPLIB_aiCombat_maxActive || {count (_state get "job") > 0}) exitWith {false};
private _kind = _profile get "kind";
private _position = if (_kind == "FLARE") then {_flarePosition} else {aimPos _target};
if (_kind in ["RPG", "GL"]) then {_position = (getPosASL _target) vectorAdd [0, 0, 0.15]};
// Aim rockets at the lower body; grenades at the ground beside the target.
if (_kind == "RPG") then {_position = (getPosASL _target) vectorAdd ((aimPos _target vectorDiff getPosASL _target) vectorMultiply 0.5)};
if ([_unit, _position, _profile, _target] call KPLIB_fnc_aiCombatSafe != "") exitWith {false};
private _weapon = _profile get "weapon";
private _muzzle = _profile get "muzzle";
private _job = createHashMapFromArray [
    ["profile", _profile], ["target", _target], ["position", +_position],
    ["originalWeapon", (weaponState _unit) select [0, 3]],
    ["autoTarget", _unit checkAIFeature "AUTOTARGET"],
    ["fsm", _unit checkAIFeature "FSM"],
    ["fireWeapon", _unit checkAIFeature "FIREWEAPON"],
    ["stance", unitPos _unit],
    ["group", group _unit],
    ["started", CBA_missionTime], ["deadline", CBA_missionTime + 25],
    ["fired", false], ["attempts", 0], ["nextFire", 0], ["fire", createHashMap],
    ["solution", []], ["solver", scriptNull], ["solved", false]
];
_state set ["job", _job];
_active pushBack _state;
_unit disableAI "AUTOTARGET";
_unit disableAI "FSM";
_unit disableAI "FIREWEAPON";
_unit doTarget objNull;
_unit doFire objNull;
if (_kind == "RPG") then {_unit setUnitPos "MIDDLE"};
private _loaded = _unit weaponState _muzzle;
if ((_loaded param [3, ""]) != (_profile get "magazine") || {(_loaded param [4, 0]) < 1}) then {
    _unit reload [_muzzle, _profile get "magazine"];
};
if (_muzzle != _weapon) then {_unit selectWeapon [_weapon, _weapon, (getArray (configFile >> "CfgWeapons" >> _weapon >> "modes")) select 0]};
if (_kind in ["RPG", "GL"]) then {
    _job set ["solver", [_unit, _job] spawn {
        params ["_unit", "_job"];
        _job set ["solution", [eyePos _unit, _job get "position", _job get "profile"] call KPLIB_fnc_aiCombatSolution];
        _job set ["solved", true];
    }];
};
if (_kind != "FLARE") then {
    _unit doTarget _target;
    _unit doWatch _target;
} else {
    _unit doWatch (ASLToAGL _position);
};
private _groups = localNamespace getVariable "KPLIB_aiCombat_groups";
private _groupKey = str group _unit;
private _groupState = _groups getOrDefault [_groupKey, [group _unit, -1000, -1000]];
if (_kind == "FLARE") then {
    _groupState set [2, CBA_missionTime];
} else {
    if (_kind in ["RPG", "GL"]) then {_groupState set [1, CBA_missionTime]};
};
_groups set [_groupKey, _groupState];
_state set ["reason", "Aiming " + _kind];
true
