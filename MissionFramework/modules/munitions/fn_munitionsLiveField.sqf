/* Progressive replacement is per impact. Other recent impacts remain visible. */
if (!hasInterface || {!isRemoteExecuted} || {remoteExecutedOwner != 2}
    || {isNull getAssignedCuratorLogic player} || {!(uiNamespace getVariable ["KPLIB_munitionsDebug", false])}) exitWith {};
params [["_session", -1, [0]], ["_fields", [], [[]]]];
if (_session != (uiNamespace getVariable ["KPLIB_munitionsDebugSession", -2])
    || {count _fields != 1} || {!([_fields] call KPLIB_fnc_gasPayload)}) exitWith {};
private _field = _fields select 0;
private _fieldsUI = uiNamespace getVariable ["KPLIB_munitionsLiveFields", []];
private _index = _fieldsUI findIf {((_x select 0) select 0) == (_field select 0)};
private _at = diag_tickTime;
if (_index >= 0) then {
    _at = (_fieldsUI select _index) select 1;
    _fieldsUI deleteAt _index;
};
_fieldsUI pushBack [_field, _at, diag_tickTime];
if (count _fieldsUI > 8) then {_fieldsUI deleteAt 0};
uiNamespace setVariable ["KPLIB_munitionsLiveFields", _fieldsUI];
