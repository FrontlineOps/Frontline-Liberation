/* Fast path only for a leased, aimed turret; no inventory/target scans. */
if (isRemoteExecuted || {isNil "_KPLIB_combatFireContext"} || {isNil "_KPLIB_vehicleCombatOwnerContext"}) exitWith {};
params ["_state"];
private _unit = _state get "unit";
private _reason = [_unit] call KPLIB_fnc_vehicleCombatEligible;
if (_reason != "") exitWith {[_state, _reason] call KPLIB_fnc_vehicleCombatRelease};
if (_state get "lease" == "" || {vehicle _unit != _state get "vehicle"}
    || {group _unit != _state get "group"} || {(assignedVehicleRole _unit select 1) isNotEqualTo (_state get "path")}) exitWith {
    [_state, "Firing assignment changed"] call KPLIB_fnc_vehicleCombatRelease;
};
private _v = _state get "vehicle";
private _p = _state get "profile";
private _target = _state get "target";
private _distance = _v distance _target;
if (_distance < _p get "minimum" || {_distance > _p get "range"}) exitWith {
    [_state, "Target outside round envelope"] call KPLIB_fnc_vehicleCombatRelease;
};
private _ws = weaponState [_v, _state get "path", _p get "weapon", _p get "muzzle"];
if (count _ws < 7 || {_ws select 3 != _p get "magazine"} || {_ws select 4 <= 0}
    || {_ws select 5 > 0} || {_ws select 6 > 0}) exitWith {};
if (_v aimedAtTarget [_target, _p get "muzzle"] < 0.75) exitWith {};
_reason = [_unit, _target, _p] call KPLIB_fnc_vehicleCombatSafe;
if (_reason != "") exitWith {[_state, _reason] call KPLIB_fnc_vehicleCombatRelease};
_state set ["attemptAt", CBA_missionTime];
[_unit, _p, _state get "fire", _distance, _p get "kind" == "ATGM"] call KPLIB_fnc_combatFireStep;
if ((_state get "fire") getOrDefault ["unsupported", false]) then {
    [_state, "No controllable single-round firing mode"] call KPLIB_fnc_vehicleCombatRelease;
};
