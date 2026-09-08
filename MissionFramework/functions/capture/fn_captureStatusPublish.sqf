/* One replaceable JIP snapshot; no growing event queue or client-authored state. */
if (!isServer || {isRemoteExecuted}) exitWith {};
private _entries = localNamespace getVariable ["KPLIB_captureStatusEntries", createHashMap];
private _keys = keys _entries;
_keys sort true;
private _rows = [];
{
    private _entry = _entries get _x;
    private _expires = _entry select 6;
    if (_expires >= 0 && {CBA_missionTime >= _expires}) then {
        _entries deleteAt _x;
    } else {
        private _row = _entry select [0, 5];
        // A failed/suspended worker must not masquerade as a frozen countdown.
        if (_expires < 0 && {CBA_missionTime - (_entry select 5) > 10}) then {
            _row set [3, "UPDATING"];
        };
        _rows pushBack _row;
    };
} forEach _keys;
localNamespace setVariable ["KPLIB_captureStatusEntries", _entries];
private _previous = localNamespace getVariable ["KPLIB_captureStatusPublished", [-1]];
if (_rows isEqualTo _previous && {_rows isEqualTo [] || {CBA_missionTime < (localNamespace getVariable ["KPLIB_captureStatusHeartbeat", 0])}}) exitWith {};
private _revision = 1 + (localNamespace getVariable ["KPLIB_captureStatusRevision", 0]);
localNamespace setVariable ["KPLIB_captureStatusRevision", _revision];
localNamespace setVariable ["KPLIB_captureStatusPublished", _rows];
localNamespace setVariable ["KPLIB_captureStatusHeartbeat", CBA_missionTime + 5];
[localNamespace getVariable "KPLIB_captureStatusSession", _revision, _rows] remoteExecCall ["KPLIB_fnc_captureStatusReceive", 0, "KPLIB_captureStatus"];
