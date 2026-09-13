if (isRemoteExecuted || {isGamePaused} || {accTime <= 0}) exitWith {};
private _started = diag_tickTime;
private _now = CBA_missionTime;
private _active = localNamespace getVariable ["KPLIB_guidanceActive", createHashMap];
{
    private _record = _active get _x;
    private _missile = _record get "missile";
    if (isNull _missile || {!alive _missile}) then {
        [_x, "projectile ended"] call KPLIB_fnc_guidanceRetire;
        continue;
    };
    if (!local _missile) then {
        [_x, "locality lost"] call KPLIB_fnc_guidanceRetire;
        continue;
    };
    private _profile = _record get "profile";

    if (!isNull missileTarget _missile) then {
        [_x, "Native seeker resumed", "NATIVE"] call KPLIB_fnc_guidanceRetire;
        continue;
    };
    private _age = _now - (_record get "created");
    if (_age > (_profile get "life")) then {
        [_x, "configured lifetime elapsed"] call KPLIB_fnc_guidanceRetire;
        continue;
    };
    if (_now >= (_record get "nextSeeker")) then {[_record, _now] call KPLIB_fnc_guidanceSeeker};
    private _lost = _now - (_record get "lastSeen");
    if (_lost > (_profile get "reacquire") && {_age > (_profile get "reacquire")}) then {
        [_x, "acquisition window elapsed; ballistic flight"] call KPLIB_fnc_guidanceRetire;
        continue;
    };
    private _dt = (_now - (_record get "lastTick")) max 0;
    _record set ["lastTick", _now];
    if (_dt <= 0 || {_lost > (_profile get "memory")}) then {continue};
    private _position = getPosASL _missile;
    private _aim = (_record get "position") vectorAdd ((_record get "velocity") vectorMultiply (_lost max 0));
    private _phase = "TERMINAL";
    if (_age < (_profile get "delay") + (_profile get "burn")) then {_phase = "BOOST"};
    if (_age < 0.25) then {_phase = "LAUNCH"};
    if ((_profile get "family") == "ARH" && {!(_record get "pitbull")}) then {_phase = "MIDCOURSE"};
    if (_phase != (_record get "phase")) then {
        _record set ["phase", _phase];
        _record set ["phaseAt", _now];
    };
    private _loft = _profile get "loft";
    if (_loft > 0 && {_phase in ["BOOST", "MIDCOURSE"]}) then {
        _aim = _aim vectorAdd [0,0,((_position distance2D _aim) * sin _loft) min 1000];
    };
    private _command = [_position, velocity _missile, _aim, _record get "velocity", _record get "acceleration"] call KPLIB_fnc_guidanceNavigation;
    _command = _command vectorAdd [0,0,9.80665 * (_profile get "gravity")];
    // Cap one frame's steering after a stall; do not run an unbounded catch-up loop.
    [_record, _command, _dt min (missionNamespace getVariable ["KPLIB_guidance_max_step", 0.05])] call KPLIB_fnc_guidanceSteer;
    if ([_record, _now] call KPLIB_fnc_guidanceFuze) then {[_x, "proximity fuze"] call KPLIB_fnc_guidanceRetire};
} forEach keys _active;
if (_now >= (localNamespace getVariable ["KPLIB_guidancePruneAt", 0])) then {
    private _spatial = localNamespace getVariable ["KPLIB_guidanceSpatial", createHashMap];
    {if ((_spatial get _x) select 0 < _now) then {_spatial deleteAt _x}} forEach keys _spatial;
    localNamespace setVariable ["KPLIB_guidancePruneAt", _now + 1];
};
private _metrics = localNamespace getVariable "KPLIB_guidanceMetrics";
private _elapsed = (diag_tickTime - _started) * 1000;
_metrics set ["ticks", (_metrics getOrDefault ["ticks", 0]) + 1];
_metrics set ["totalMs", (_metrics getOrDefault ["totalMs", 0]) + _elapsed];
_metrics set ["maxMs", (_metrics getOrDefault ["maxMs", 0]) max _elapsed];
