/* Reservations include queued work and live native objects. Never reclaim a
   live owner's grant by timeout: a late message must not duplicate capacity. */
params [["_op", "", [""]], ["_serial", -1, [0]], ["_count", 0, [0]], ["_auth", "", [""]]];
if (!isServer) exitWith {};
private _localCall = !isRemoteExecuted && {!isNil "_KPLIB_munitionsBudgetContext"};
private _peers = localNamespace getVariable ["KPLIB_munitionsBudgetPeers", createHashMap];
if (_op == "DROP" && {_localCall}) exitWith {
    private _peer = _peers getOrDefault [_serial, []];
    if (_peer isEqualTo [] || {_serial == 2}) exitWith {};
    private _used = localNamespace getVariable ["KPLIB_munitionsBudgetUsed", 0];
    {_used = _used - ((_y select 0) - (_y select 1))} forEach (_peer select 2);
    localNamespace setVariable ["KPLIB_munitionsBudgetUsed", _used max 0];
    _peers deleteAt _serial;
};
if (!(_op in ["REQUEST", "RELEASE"]) || {!finite _serial} || {_serial < 1} || {_serial != floor _serial}
    || {!finite _count} || {_count < 0} || {_count > 512} || {_count != floor _count}) exitWith {};
private _sender = -1;
if (_localCall) then {_sender = 2} else {
    private _remote = remoteExecutedOwner;
    if (_auth != "" && {count _auth <= 128}) then {
        {
            if (_x > 2 && {_y select 0 == _auth} && {_remote <= 0 || {_remote == _x}}) exitWith {_sender = _x};
        } forEach _peers;
    };
};
private _peer = _peers getOrDefault [_sender, []];
if (_peer isEqualTo []) exitWith {};
private _grants = _peer select 2;
private _used = localNamespace getVariable ["KPLIB_munitionsBudgetUsed", 0];
if (_op == "RELEASE") exitWith {
    private _grant = _grants getOrDefault [_serial, []];
    if (_grant isEqualTo [] || {_count <= _grant select 1} || {_count > _grant select 0}) exitWith {};
    localNamespace setVariable ["KPLIB_munitionsBudgetUsed", _used - (_count - (_grant select 1))];
    _grant set [1, _count];
    if (_count == _grant select 0) then {_grants deleteAt _serial};
};
if (_serial <= _peer select 1) exitWith {};
_peer set [1, _serial];
private _cap = floor ((missionNamespace getVariable ["KPLIB_munitions_global_cap", 2048]) max 0 min 8192);
private _admitted = _count min ((_cap - _used) max 0);
if (_admitted > 0) then {
    _grants set [_serial, [_admitted, 0]];
    localNamespace setVariable ["KPLIB_munitionsBudgetUsed", _used + _admitted];
};
private _reply = ["GRANT", _serial, _admitted];
if (_sender == 2) then {
    private _KPLIB_munitionsBudgetContext = true;
    _reply call KPLIB_fnc_munitionsBudgetReceive;
} else {_reply remoteExecCall ["KPLIB_fnc_munitionsBudgetReceive", _sender]};
