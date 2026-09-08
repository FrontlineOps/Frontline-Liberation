/* Read-only server endpoint. The requester must own a living active curator.
   No caller-supplied owner ID, profile, skill or arbitrary code is accepted. */
params [["_position", [], [[]]]];
if (!isServer || {!isRemoteExecuted}) exitWith {};
private _owner = remoteExecutedOwner;
private _curator = allCurators findIf {
    private _operator = getAssignedCuratorUnit _x;
    !isNull _operator && {isPlayer _operator} && {alive _operator} && {owner _operator == _owner}
};
if (_curator < 0 || {count _position != 3}
    || {_position findIf {!(_x isEqualType 0) || {!finite _x}} >= 0}) exitWith {};
if (CBA_missionTime < (localNamespace getVariable ["KPLIB_aiSkills_nextInspect", -1])) exitWith {};
localNamespace setVariable ["KPLIB_aiSkills_nextInspect", CBA_missionTime + 0.5];
private _blocked = localNamespace getVariable ["KPLIB_aiSkills_blocked", "Module not initialized"];
if (_blocked != "") exitWith {[["FRONTLINE AI", _blocked]] remoteExecCall ["KPLIB_fnc_aiSkillsReceive", _owner]};
private _units = [_position, 50, 50, 0, false, 50] nearEntities [["CAManBase"], false, true, true];
private _unit = objNull;
private _distance = 50;
{
    private _range = _x distance _position;
    if (alive _x && {local _x} && {!isPlayer _x} && {_range <= _distance}) then {
        _unit = _x;
        _distance = _range;
    };
} forEach _units;
private _state = (localNamespace getVariable "KPLIB_aiSkills_registry") getOrDefault [netId _unit, createHashMap];
private _lines = ["FRONTLINE AI  /  SKILL INSPECTOR"];
if (count _state == 0) then {
    _lines pushBack "No registered server-owned AI within 50 m of the cursor.";
} else {
    (_state get "factors") params ["_terrain", "_suppression", "_weather", "_boost"];
    _lines append [
        getText (configOf _unit >> "displayName"),
        format ["Profile: %1 | %2", _state get "profile", ["Original skills / excluded", "Dynamic AI skills"] select (_state get "active")],
        format ["Foliage %1%% | Suppression %2%%", round (_terrain * 100), round (_suppression * 100)],
        format ["Spotting weather x%1 | Aiming practice x%2", _weather toFixed 2, _boost toFixed 2],
        "", "SKILL: ORIGINAL / BASE / CURRENT / EFFECTIVE"
    ];
    private _original = _state get "original";
    private _base = _state get "base";
    {
        _lines pushBack format ["%1: %2 / %3 / %4 / %5", _x,
            (_original select _forEachIndex) toFixed 2, (_base select _forEachIndex) toFixed 2,
            (_unit skill _x) toFixed 2, (_unit skillFinal _x) toFixed 2];
    } forEach KPLIB_aiSkills_names;
    _lines append ["", "Effective values include server difficulty and addon skill curves.", "Select again to refresh. Tactical orders remain with Battlespace."];
};
[_lines] remoteExecCall ["KPLIB_fnc_aiSkillsReceive", _owner];
