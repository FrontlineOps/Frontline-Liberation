if (isRemoteExecuted || {isNil "_KPLIB_combatFireContext"}) exitWith {};
private _start = diag_tickTime;
private _queue = localNamespace getVariable "KPLIB_combatFire_queue";
private _now = CBA_missionTime;
// Existing limits bound this to 24 vehicle + 32 infantry operators per owner.
{
    _y params ["_vehicle", "_state", "_fire", "_expires"];
    if (_now > _expires) then {_queue deleteAt _x; continue};
    if (_now < _fire getOrDefault ["next", 0]) then {continue};
    if (_vehicle) then {
        private _KPLIB_vehicleCombatOwnerContext = true;
        [_state] call KPLIB_fnc_vehicleCombatFire;
    } else {
        [_state] call KPLIB_fnc_aiCombatFire;
    };
} forEach _queue;
localNamespace setVariable ["KPLIB_combatFire_lastTickMs", (diag_tickTime - _start) * 1000];
