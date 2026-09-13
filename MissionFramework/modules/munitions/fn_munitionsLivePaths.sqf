/* Live observer records have owner/session IDs and point revisions. Reuse the
   full packet while those inputs are unchanged, including all omission counts.
   Recent selection happens before this call, so history expiry still applies. */
params ["_shots"];
private _key = [
    localNamespace getVariable ["KPLIB_munitionsSession", -1],
    +(localNamespace getVariable ["KPLIB_munitionsCaptureMetrics", [0,0,0,0,0]]),
    _shots apply {[
        _x get "id", _x getOrDefault ["pointVersion", -1], count (_x get "points"),
        _x get "kind", _x get "ammo", _x get "ended",
        _x getOrDefault ["historyBurst", -1], _x getOrDefault ["pointOmissions", 0]
    ]}
];
private _cache = localNamespace getVariable ["KPLIB_munitionsLivePathCache", []];
if (_cache isNotEqualTo [] && {(_cache select 0) isEqualTo _key}) exitWith {_cache select 1};
private _paths = [_shots, [], 4096] call KPLIB_fnc_munitionsPaths;
localNamespace setVariable ["KPLIB_munitionsLivePathCache", [_key, _paths]];
_paths
