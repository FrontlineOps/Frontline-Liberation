if (!isServer || {isRemoteExecuted}) exitWith {};
private _start = diag_tickTime;
private _now = CBA_missionTime;
private _pending = localNamespace getVariable "KPLIB_blastPending";
if (_pending isNotEqualTo []) then {
    private _burst = _pending deleteAt 0;
    _burst call KPLIB_fnc_blastStart;
};
private _shots = localNamespace getVariable "KPLIB_blastShots";
{
    private _shot = _shots get _x;
    private _projectile = _shot select 0;
    if (_now > (_shot select 6) || {isNull _projectile && {_now - (_shot select 4) > 0.5}}) then {
        _shots deleteAt _x;
    } else {
        if (!isNull _projectile) then {
            _shot set [3, getPosASL _projectile];
            _shot set [4, _now];
            _shot set [5, vectorMagnitude velocity _projectile];
        };
    };
} forEach keys _shots;
private _jobs = localNamespace getVariable "KPLIB_blastJobs";
private _cursor = localNamespace getVariable ["KPLIB_blastJobCursor", 0];
for "_i" from 1 to KPLIB_munitions_blast_cells_per_tick do {
    if (_jobs isEqualTo [] || {diag_tickTime - _start > 0.003}) exitWith {};
    // Release completed work and deliver primary exposure before costly grids.
    private _urgent = _jobs findIf {(_x get "phase") in ["DONE", "GAS_PRIMARY"]};
    if (_urgent >= 0) then {
        _cursor = _urgent;
    } else {
        // Complete the oldest native field first. Splitting every work unit
        // across eight geometries could make all eight expire before sampling.
        private _native = _jobs findIf {(_x getOrDefault ["backend", "LEGACY"]) == "GAS"};
        if (_native >= 0) then {_cursor = _native};
    };
    _cursor = _cursor mod count _jobs;
    private _job = _jobs select _cursor;
    if (!(missionNamespace getVariable ["KPLIB_munitions_blast_enabled", true]) || {_now - (_job get "at") > 8}) then {
        _job set ["phase", "DONE"];
        _job set ["truncated", true];
        _job set ["gasReason", "Stopped: disabled or eight-second work deadline reached"];
    };
    if (_job get "phase" == "DONE") then {
        [_job] call KPLIB_fnc_gasBlastFinish;
        private _history = localNamespace getVariable "KPLIB_blastHistory";
        _history pushBack _job;
        if (count _history > 8) then {_history deleteAt 0};
        _jobs deleteAt _cursor;
    } else {
        [_job] call KPLIB_fnc_blastStep;
        _cursor = _cursor + 1;
    };
};
localNamespace setVariable ["KPLIB_blastJobCursor", _cursor];
private _metrics = localNamespace getVariable "KPLIB_blastMetrics";
_metrics set ["maxTickMs", (_metrics get "maxTickMs") max (1000 * (diag_tickTime - _start))];
