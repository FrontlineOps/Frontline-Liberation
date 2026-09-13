/* Sensor observations are sampled here. Flight never reads hidden target movement. */
if (isRemoteExecuted) exitWith {};
params ["_record", "_now"];
private _missile = _record get "missile";
private _profile = _record get "profile";
private _family = _profile get "family";
private _position = getPosASL _missile;
private _head = vectorDir _missile;
private _target = _record get "target";
private _original = _record get "originalTarget";
private _range = _profile get "range";
private _firstSample = isNil {_record get "lastSeeker"};
private _dt = (_now - (_record getOrDefault ["lastSeeker", _now - 0.1])) max 0.001;
_record set ["lastSeeker", _now];
private _interval = missionNamespace getVariable ["KPLIB_guidance_seeker_interval", 0.1];
private _stagger = if (_firstSample) then {((_record get "id") mod 10) * 0.1} else {0};
_record set ["nextSeeker", _now + _interval * (1 + _stagger)];
private _supported = false;
private _needSupport = _family in ["SARH", "RADIO"];
if (_family == "ARH" && {!(_record get "pitbull")}) then {
    private _estimate = (_record get "position") vectorAdd ((_record get "velocity") vectorMultiply ((_now - (_record get "lastSeen")) max 0 min 2));
    if (isNull _original || {_position distance _estimate <= (_profile get "pitbull")}) then {
        _record set ["pitbull", true];
    } else {
        _needSupport = true;
    };
};
if (_needSupport) then {_supported = [_record, _original] call KPLIB_fnc_guidanceSupport};
private _candidates = [];
if (_family == "LASER") then {
    if (!isNull _target && {_target isKindOf "LaserTarget"}) then {_candidates pushBack _target};
    {
        if (!isNull _x) then {
            private _spot = laserTarget _x;
            if (!isNull _spot) then {_candidates pushBackUnique _spot};
        };
    } forEach [_record get "shooter", _record get "carrier"];
} else {
    if (_needSupport) then {
        if (_supported) then {_candidates = [_original]};
    } else {
        if (_now >= (_record get "nextSearch")) then {
            _candidates = [_record] call KPLIB_fnc_guidanceCandidates;
            _record set ["nextSearch", _now + (missionNamespace getVariable ["KPLIB_guidance_search_interval", 0.5]) * (1 + _stagger)];
        } else {
            if (!isNull _target) then {_candidates = [_target]};
        };
    };
};
private _best = objNull;
private _bestScore = -1;
private _bestPos = [];
private _seekerDir = _record get "seekerDirection";
private _maxSlew = (_profile get "seekerRate") * _dt;
private _considered = (_record get "cmConsidered") select {!isNull (_x select 0)};
private _lost = _now - (_record get "lastSeen");
{
    private _candidate = _x;
    if (isNull _candidate || {!alive _candidate}) then {continue};
    private _cm = _candidate getVariable ["KPLIB_guidanceCM", false];
    if (!_cm && {_family != "LASER"} && {_profile get "airOnly"} && {!(_candidate isKindOf "Air")}) then {continue};
    private _candidatePos = if (_cm || {_family == "LASER"}) then {getPosASL _candidate} else {aimPos _candidate};
    private _offset = _candidatePos vectorDiff _position;
    private _distance = vectorMagnitude _offset;
    if (_distance > _range || {_distance < 0.01}) then {continue};
    private _maintaining = _candidate == _target || {_candidate == _original};
    if (!_maintaining && {!_needSupport} && {_distance < (_profile get "minRange")}) then {continue};
    private _direction = vectorNormalized _offset;
    private _cone = if (_maintaining || {_cm}) then {_profile get "gimbal"} else {_profile get "acquireCone"};
    if (!_needSupport && {_head vectorDotProduct _direction < cos _cone}) then {continue};
    private _maxSpeed = _profile get "maxTargetSpeed";
    if (!_cm && {_maxSpeed > 0} && {vectorMagnitude velocity _candidate > _maxSpeed}) then {continue};
    private _angle = acos (-1 max (1 min (_seekerDir vectorDotProduct _direction)));
    if (!_needSupport && {_record get "locked"} && {_angle > _maxSlew + 8}) then {continue};
    if (!([_position, _candidatePos, _missile, _candidate] call KPLIB_fnc_guidanceVisible)) then {continue};
    private _score = 1 / (1 + _distance / 1000);
    if (_candidate == _target) then {_score = _score * 1.5};
    if (_candidate == _original) then {_score = _score * 1.2};
    if (_family == "IR" && {!_cm}) then {
        // Engine heat/aspect are bounded game approximations, never hidden target history.
        private _rear = ((vectorDir _candidate) vectorDotProduct _direction) max 0;
        _score = _score * (([0.4, 1] select isEngineOn _candidate) + 0.4 * _rear);
    };
    if (_family in ["ARH", "SARH"] && {!_cm} && {!_needSupport}) then {
        // Clutter rejection depends on radial motion in a look-down geometry.
        private _radial = abs ((velocity _candidate) vectorDotProduct _direction);
        private _lookDown = (_position select 2) > (_candidatePos select 2) + 20;
        if (_lookDown && {_radial < (_profile get "radarMinimum")}
            && {getPosATL _candidate select 2 < (_profile get "radarNoise")}) then {continue};
    };
    if (_cm) then {
        private _tested = _considered findIf {(_x select 0) == _candidate};
        private _accepted = false;
        if (_tested >= 0) then {
            _accepted = (_considered select _tested) select 1;
        } else {
            private _closeToTrack = _candidatePos distance (_record get "position") < 250;
            private _radialDifference = abs (((velocity _candidate) vectorDiff (_record get "velocity")) vectorDotProduct _direction);
            private _plausible = _closeToTrack && {_family == "IR" || {_radialDifference < 40}};
            _accepted = _plausible && {random 1 > (_profile get "cmResistance")};
            _considered pushBack [_candidate, _accepted];
        };
        if (!_accepted) then {continue};
        _score = _score * 3;
    };
    if (_score > _bestScore) then {
        _best = _candidate;
        _bestScore = _score;
        _bestPos = _candidatePos;
    };
} forEach _candidates;
if (count _considered > 64) then {_considered deleteRange [0, count _considered - 64]};
_record set ["cmConsidered", _considered];
private _wasLocked = _record get "locked";
_record set ["locked", !isNull _best];
if (isNull _best) exitWith {
    _record set ["previousRelative", []];
    _record set ["quality", (1 - _lost / ((_profile get "memory") max 0.01)) max 0];
};
if (_best != _target) then {_record set ["previousRelative", []]};
private _velocity = velocity _best;
private _acceleration = [0,0,0];
if (_wasLocked && {_best == _target}) then {
    private _raw = (_velocity vectorDiff (_record get "velocity")) vectorMultiply (1 / _dt);
    private _magnitude = vectorMagnitude _raw;
    if (_magnitude > 100) then {_raw = _raw vectorMultiply (100 / _magnitude)};
    _acceleration = ((_record get "acceleration") vectorMultiply 0.7) vectorAdd (_raw vectorMultiply 0.3);
};
_record set ["target", _best];
_record set ["position", _bestPos];
_record set ["velocity", _velocity];
_record set ["acceleration", _acceleration];
_record set ["lastSeen", _now];
_record set ["quality", 1];
_record set ["seekerDirection", _position vectorFromTo _bestPos];
if (_best != (_record get "warnTarget") && {_family in ["ARH", "SARH", "RADIO"]}) then {
    [_record, _best] call KPLIB_fnc_guidanceNotify;
    _record set ["warnTarget", _best];
};
