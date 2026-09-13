/* Bounded, solicited telemetry; never trust it for world or campaign state. */
if (!isServer || {!isRemoteExecuted}) exitWith {};
params [["_nonce", -1, [0]], ["_text", "", [""]], ["_lines", [], [[]]], ["_meta", [], [[]]]];
private _pending = localNamespace getVariable ["KPLIB_munitionsPending", []];
if (count _pending != 5) exitWith {};
_pending params ["_expected", "_recipient", "_expires", "_owners", "_caller"];
private _sender = remoteExecutedOwner;
if (_nonce != _expected || {CBA_missionTime > _expires} || {!(_sender in _owners)}) exitWith {};
if (isNull _caller || {owner _caller != _recipient} || {isNull getAssignedCuratorLogic _caller}) exitWith {};
if (count _text > 48000 || {!([_lines, _meta] call KPLIB_fnc_munitionsPayload)}) exitWith {};
_owners deleteAt (_owners find _sender);
[_nonce, format ["--- OWNER %1 (reported observations) ---%2%3", _sender, toString [13, 10], _text], _lines, _meta, _sender] remoteExecCall ["KPLIB_fnc_munitionsDisplay", _recipient];
