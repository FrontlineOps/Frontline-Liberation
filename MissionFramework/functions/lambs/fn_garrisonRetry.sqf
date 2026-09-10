/* A bounded retry uses the server's original job; callers cannot submit a
 * position, weapon, unit list or fresh retry budget. No persistent resources.
 */
if (!isServer) exitWith {false};
params [["_unit", objNull, [objNull]], ["_token", [], [[]]]];
if (isNull _unit || {isPlayer _unit} || {captive _unit} || {!(_unit call KPLIB_fnc_isAlive)}) exitWith {false};
if (isRemoteExecuted && {
    remoteExecutedOwner != owner _unit
    || {allPlayers findIf {_x isKindOf "HeadlessClient_F" && {owner _x == remoteExecutedOwner}} < 0}
}) exitWith {false};
if (isRemoteExecuted) exitWith {
    [{_this call KPLIB_fnc_garrisonRetry}, _this] call CBA_fnc_execNextFrame;
    true
};
if (canSuspend) exitWith {[KPLIB_fnc_garrisonRetry, _this] call CBA_fnc_directCall};
private _jobs = localNamespace getVariable ["KPLIB_garrisonJobs", createHashMap];
private _job = _jobs getOrDefault [netId _unit, []];
if (_job isEqualTo []) exitWith {false};
_job params ["_jobToken", "_group", "_center", "_radius", "_area", "_height", "_attempt", "_excluded", "_oldSlot", "_issued"];
if (_token isNotEqualTo _jobToken || {_token isNotEqualTo (_unit getVariable ["KPLIB_garrisonToken", []])}
    || {group _unit != _group} || {!isNull objectParent _unit}
    || {_attempt >= 2} || {CBA_missionTime - _issued < 15}) exitWith {false};
if (_oldSlot isNotEqualTo []) then {_excluded pushBackUnique (_oldSlot select [0, 2])};
private _slot = (([[_unit], _center, _radius, _area, _height, _token, _excluded, _attempt == 1] call KPLIB_fnc_garrisonSelect) select 0) select 1;
_attempt = _attempt + 1;
_job set [6, _attempt];
_job set [7, _excluded];
_job set [8, _slot];
_job set [9, CBA_missionTime];
_jobs set [netId _unit, _job];
private _args = [_unit, _token, _slot, false, _attempt];
if (local _unit) then {_args call KPLIB_fnc_garrisonMove} else {_args remoteExecCall ["KPLIB_fnc_garrisonMove", _unit]};
true
