/* A sound produces a fuzzy position, never reveal/knowsAbout or a target object.
   Suppressed supersonic fly-bys still trigger the engine Suppressed event. */
params ["_state"];
if (!isServer || {isRemoteExecuted} || {!KPLIB_aiCombat_hearing}) exitWith {};
private _unit = _state get "unit";
if ([_unit, true] call KPLIB_fnc_aiCombatEligible != "") exitWith {};
if (CBA_missionTime < (_state getOrDefault ["nextHear", 0])) exitWith {};
_state set ["nextHear", CBA_missionTime + 1];
private _heard = _state get "heard";
private _last = if (_heard isEqualTo []) then {-1000} else {_heard select 1};
private _best = [];
private _strength = 0;
private _eye = eyePos _unit;
{
    _x params ["_origin", "_side", "_radius", "_time", "_suppressed"];
    if (_time <= _last || {CBA_missionTime - _time > KPLIB_aiCombat_soundMemory}
        || {(side group _unit) getFriend _side >= 0.6}) then {continue};
    private _range = _eye vectorDistance _origin;
    if (_range >= _radius) then {continue};
    // A blocked loud report must not mask an audible alternative. Only test
    // candidates that could beat the best obstruction-adjusted score so far.
    private _score = 1 - _range / (1 max _radius);
    if (_score <= _strength) then {continue};
    if (lineIntersects [_eye, _origin, _unit, objNull] || {terrainIntersectASL [_eye, _origin]}) then {_radius = _radius * 0.45};
    _score = 1 - _range / (1 max _radius);
    if (_score > _strength) then {
        _best = _x;
        _strength = _score;
    };
} forEach (localNamespace getVariable "KPLIB_aiCombat_sounds");
if (_best isEqualTo []) exitWith {};
_best params ["_origin", "_side", "_radius", "_time", "_suppressed"];
private _range = _eye vectorDistance _origin;
private _error = 15 max (_range * (if (_suppressed) then {0.2} else {0.1}));
private _angle = random 360;
private _offset = 0.4 * _error + random (0.6 * _error);
private _estimate = _origin vectorAdd [sin _angle * _offset, cos _angle * _offset, 0];
_state set ["heard", [_estimate, _time, _suppressed, round _error, round _range]];
if (count (_state get "job") == 0 && {isNull getAttackTarget _unit}
    && {isNull (_state get "target")} && {_unit checkAIFeature "WEAPONAIM"}
    && {!(_unit getVariable ["KPLIB_lambs_forceMove", false])}) then {
    _unit doWatch (ASLToAGL _estimate);
    _state set ["soundWatchUntil", CBA_missionTime + 5];
};
