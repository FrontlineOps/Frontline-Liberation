/* Fast rifle/MG path. Explosive and illumination jobs keep their launch path. */
if (!isServer || {isRemoteExecuted} || {isNil "_KPLIB_combatFireContext"}) exitWith {};
params ["_state"];
private _job = _state get "job";
if (count _job == 0) exitWith {};
private _unit = _state get "unit";
private _reason = [_unit] call KPLIB_fnc_aiCombatEligible;
if (_reason != "") exitWith {[_state, _reason] call KPLIB_fnc_aiCombatFinish};
private _p = _job get "profile";
private _target = _job get "target";
if (_p get "kind" != "RIFLE" || {group _unit != _job get "group"}
    || {CBA_missionTime > _job get "deadline"}) exitWith {[_state, "Firing action ended"] call KPLIB_fnc_aiCombatFinish};
private _distance = _unit distance _target;
if (_distance < _p get "minimum" || {_distance > _p get "range"}
    || {vectorMagnitude velocity _unit > 3} || {!([_unit, _target] call KPLIB_fnc_aiCombatVisible)}) exitWith {
    [_state, "Firing solution changed"] call KPLIB_fnc_aiCombatFinish;
};
private _ws = _unit weaponState (_p get "muzzle");
if (count _ws < 7 || {_ws select 3 != _p get "magazine"} || {_ws select 4 <= 0}
    || {_ws select 5 > 0} || {_ws select 6 > 0}) exitWith {};
private _aim = vectorNormalized (aimPos _target vectorDiff eyePos _unit);
private _direction = _unit weaponDirection currentWeapon _unit;
if (_aim vectorDotProduct _direction < 0.985
    || {(vectorNormalized [_aim select 0, _aim select 1, 0]) vectorDotProduct (vectorNormalized [_direction select 0, _direction select 1, 0]) < 0.999}) exitWith {};
_reason = [_unit, aimPos _target, _p, _target] call KPLIB_fnc_aiCombatSafe;
if (_reason != "") exitWith {[_state, _reason] call KPLIB_fnc_aiCombatFinish};
[_unit, _p, _job get "fire", _distance] call KPLIB_fnc_combatFireStep;
if ((_job get "fire") getOrDefault ["unsupported", false]) then {
    [_state, "No controllable single-round firing mode"] call KPLIB_fnc_aiCombatFinish;
};
