/* Identical selection for local rendering and remote owner snapshots. A burst
   disappears together, including any unusually long-lived member. */
params [["_now", CBA_missionTime, [0]]];
private _ids = ((localNamespace getVariable ["KPLIB_munitionsBursts", []]) select {
    (_x select 3) > _now
}) apply {_x select 0};
(localNamespace getVariable ["KPLIB_munitionsShots", []]) select {
    private _burst = _x getOrDefault ["historyBurst", -1];
    if (_burst >= 0) then {
        _burst in _ids
    } else {
        !(_x get "ended") || {_now - (_x getOrDefault ["endedAt", 0]) < 20}
    }
}
