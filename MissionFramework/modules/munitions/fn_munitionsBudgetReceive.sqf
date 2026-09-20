/* Only the server may authorize local creation. Grants never carry positions,
   ammo, or damage commands; those stay in the owner's bounded pending jobs. */
params [["_op", "", [""]], ["_serial", -1, [0]], ["_count", 0, [0]], ["_token", "", [""]]];
if (!(isServer && {!isRemoteExecuted} && {!isNil "_KPLIB_munitionsBudgetContext"})
    && {!(isRemoteExecuted && {remoteExecutedOwner == 2})}) exitWith {};
if (_op == "PEER") exitWith {
    if (_token != "" && {count _token <= 128}) then {localNamespace setVariable ["KPLIB_munitionsBudgetToken", _token]};
};
if (_op != "GRANT" || {!finite _serial} || {_serial < 1} || {_serial != floor _serial}
    || {!finite _count} || {_count < 0} || {_count > 512} || {_count != floor _count}) exitWith {};
private _receipts = localNamespace getVariable ["KPLIB_munitionsBudgetReceipts", createHashMap];
if (_serial in _receipts) exitWith {};
private _pending = localNamespace getVariable ["KPLIB_munitionsBudgetPending", createHashMap];
private _job = _pending getOrDefault [_serial, []];
_pending deleteAt _serial;
// Cumulative returns make duplicate and late grants harmless after retirement.
private _expired = _job isEqualTo [] || {CBA_missionTime - (_job select 8) > 0.75};
if (_count > 0) then {
    _receipts set [_serial, [_count, [0, _count] select _expired, 0]];
    localNamespace setVariable ["KPLIB_munitionsBudgetReceipts", _receipts];
};
if (_job isEqualTo []) exitWith {};
private _metrics = localNamespace getVariable ["KPLIB_munitionsParticleMetrics", [0,0,0,0]];
_metrics set [2, (_metrics select 2) + count (_job select 2) - ([ _count, 0] select _expired)];
localNamespace setVariable ["KPLIB_munitionsParticleMetrics", _metrics];
if (_expired || {_count == 0}) exitWith {};
_job set [2, (_job select 2) select [0, _count]];
private _queue = localNamespace getVariable ["KPLIB_munitionsParticleQueue", []];
_queue pushBack _job;
localNamespace setVariable ["KPLIB_munitionsParticleQueue", _queue];
