/* A sound produces a fuzzy position, never reveal/knowsAbout or a target object.
   Suppressed supersonic fly-bys still trigger the engine Suppressed event. */
params ["_state"];
if (!isServer || {isRemoteExecuted} || {!KPLIB_aiCombat_hearing}) exitWith {};
private _unit = _state get "unit";
private _heard = _state get "heard";
private _last = if (_heard isEqualTo []) then {-1000} else {_heard select 1};
private _best = [];
private _strength = 0;
{
    _x params ["_origin", "_side", "_radius", "_time", "_suppressed"];
    if (_time <= _last || {CBA_missionTime - _time > KPLIB_aiCombat_soundMemory}
        || {(side group _unit) getFriend _side >= 0.6}) then {continue};
    private _range = (eyePos _unit) vectorDistance _origin;
    if (_range > _radius) then {continue};
    private _score = 1 - _range / (1 max _radius);
    if (_score > _strength) then {
        _best = _x;
        _strength = _score
    };
} forEach (localNamespace getVariable "KPLIB_aiCombat_sounds");
if (_best isEqualTo []) exitWith {};
_best params ["_origin", "_side", "_radius", "_time", "_suppressed"];
// One obstruction test for the strongest fresh event. Walls/terrain attenuate.
if (lineIntersects [eyePos _unit, _origin, _unit, objNull]) then {_radius = _radius * 0.45};
private _range = (eyePos _unit) vectorDistance _origin;
if (_range > _radius) exitWith {};
private _error = 15 max (_range * (if (_suppressed) then {0.2} else {0.1}));
private _angle = random 360;
private _offset = 0.4 * _error + random (0.6 * _error);
private _estimate = _origin vectorAdd [sin _angle * _offset, cos _angle * _offset, 0];
_state set ["heard", [_estimate, _time, _suppressed, round _error, round _range]];
if (isNull (_state get "target") && {behaviour _unit != "COMBAT"}) then {
    _unit doWatch (ASLToAGL _estimate);
    _state set ["soundWatchUntil", CBA_missionTime + 5];
};
