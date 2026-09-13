/* Arma retains owner-local AI flags when an operator leaves and later returns.
   Restore only this owner's saved, server-authorized override; no network input. */
if (isRemoteExecuted || {isNil "_KPLIB_vehicleCombatOwnerContext"}) exitWith {};
params ["_unit"];
if (isNull _unit || {!local _unit}) exitWith {};
private _saved = localNamespace getVariable "KPLIB_vehicleCombat_restores";
private _key = netId _unit;
private _entry = _saved getOrDefault [_key, []];
if (_entry isEqualTo []) exitWith {};
private _state = (localNamespace getVariable "KPLIB_vehicleCombat_states") getOrDefault [_key, createHashMap];
if (count _state > 0 && {_state getOrDefault ["lease", ""] != ""}) exitWith {};
{
    if ((_entry select 2) select _forEachIndex) then {_unit enableAI _x};
} forEach ["AUTOTARGET", "FSM", "FIREWEAPON"];
_saved deleteAt _key;
