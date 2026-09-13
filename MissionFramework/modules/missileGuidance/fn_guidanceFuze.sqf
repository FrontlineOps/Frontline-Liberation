/* Detonate the original projectile at its actual position; never force target damage. */
if (isRemoteExecuted) exitWith {false};
params ["_record", "_now"];
private _missile = _record get "missile";
private _profile = _record get "profile";
private _radius = _profile get "fuzeRadius";
if (_radius <= 0 || {!local _missile} || {!(_record get "locked")}) exitWith {false};
private _target = _record get "target";
if (isNull _target || {!alive _target} || {!(_target isKindOf "Air")}) exitWith {false};
private _position = getPosASL _missile;
if (_now - (_record get "created") < (_profile get "armingTime")
    || {_position distance (_record get "launchPos") < (_profile get "armingDistance")}) exitWith {false};
private _relative = (aimPos _target) vectorDiff _position;
private _previous = _record get "previousRelative";
_record set ["previousRelative", _relative];
// Sampled closest-approach evidence prevents a fuze from missing a fast crossing.
private _closest = vectorMagnitude _relative;
if (_previous isNotEqualTo []) then {
    private _segment = _relative vectorDiff _previous;
    private _fraction = 0 max (1 min (-(_previous vectorDotProduct _segment) / ((vectorMagnitudeSqr _segment) max 0.0001)));
    _closest = vectorMagnitude (_previous vectorAdd (_segment vectorMultiply _fraction));
};
// A late low-FPS sample never relocates the explosion to the old intercept point.
if (_closest > _radius || {vectorMagnitude _relative > _radius * 1.5}) exitWith {false};
if (!([_position, aimPos _target, _missile, _target] call KPLIB_fnc_guidanceVisible)) exitWith {false};
triggerAmmo _missile;
true
