/* Batched cumulative returns, bounded pending expiry, and per-connection
   capabilities follow the existing vehicle-combat owner authentication model. */
if (isRemoteExecuted) exitWith {};
private _now = CBA_missionTime;
if (isServer && {_now >= localNamespace getVariable ["KPLIB_munitionsBudgetScanAt", -1]}) then {
    localNamespace setVariable ["KPLIB_munitionsBudgetScanAt", _now + 1];
    private _peers = localNamespace getVariable ["KPLIB_munitionsBudgetPeers", createHashMap];
    {
        private _owner = owner _x;
        if (_owner <= 2 || {_owner in _peers}) then {continue};
        private _token = format ["%1:%2:%3:%4:%5", _owner, diag_tickTime, random 1e9, random 1e9, random 1e9];
        _peers set [_owner, [_token, 0, createHashMap]];
        ["PEER", 0, 0, _token] remoteExecCall ["KPLIB_fnc_munitionsBudgetReceive", _owner];
    } forEach allPlayers;
    localNamespace setVariable ["KPLIB_munitionsBudgetPeers", _peers];
};
private _pending = localNamespace getVariable ["KPLIB_munitionsBudgetPending", createHashMap];
private _metrics = localNamespace getVariable ["KPLIB_munitionsParticleMetrics", [0,0,0,0]];
{
    if (_now - (_y select 8) > 0.75) then {
        _metrics set [2, (_metrics select 2) + count (_y select 2)];
        _pending deleteAt _x;
    };
} forEach _pending;
localNamespace setVariable ["KPLIB_munitionsParticleMetrics", _metrics];
// Script-deleted native ammo does not reliably emit Deleted. Inspect only our
// capped references, not world entities; compact in place in one linear pass.
private _live = localNamespace getVariable ["KPLIB_munitionsBudgetLive", []];
private _kept = 0;
{
    if (isNull (_x select 0)) then {
        [_x select 1, 1] call KPLIB_fnc_munitionsBudgetReturn;
    } else {
        _live set [_kept, _x];
        _kept = _kept + 1;
    };
} forEach _live;
_live resize _kept;
private _receipts = localNamespace getVariable ["KPLIB_munitionsBudgetReceipts", createHashMap];
{
    _y params ["_total", "_freed", "_sent"];
    if (_freed > _sent) then {
        private _args = ["RELEASE", _x, _freed, localNamespace getVariable ["KPLIB_munitionsBudgetToken", ""]];
        if (isServer) then {
            private _KPLIB_munitionsBudgetContext = true;
            _args call KPLIB_fnc_munitionsBudgetServer;
        } else {_args remoteExecCall ["KPLIB_fnc_munitionsBudgetServer", 2]};
        _y set [2, _freed];
    };
    if (_freed == _total) then {_receipts deleteAt _x};
} forEach _receipts;
