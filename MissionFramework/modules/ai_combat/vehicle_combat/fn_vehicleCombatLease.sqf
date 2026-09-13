/* Receive only authenticated server grants/restores, including on a new owner. */
params [["_op", "", [""]], ["_unit", objNull, [objNull]], ["_nonce", "", [""]], ["_flags", [], [[]]]];
private _serverCall = isServer && {!isRemoteExecuted} && {!isNil "_KPLIB_vehicleCombatServerContext"};
if (!_serverCall && {remoteExecutedOwner != 2}) exitWith {};
if (isNull _unit || {!local _unit} || {!(_unit isKindOf "CAManBase")}
    || {count _flags != 3} || {_flags findIf {!(_x isEqualType true)} >= 0}) exitWith {};
private _states = localNamespace getVariable ["KPLIB_vehicleCombat_states", createHashMap];
private _state = _states getOrDefault [netId _unit, createHashMap];
if (_op == "STOP") exitWith {
    if (count _state > 0 && {_state getOrDefault ["lease", ""] != ""} && {_state get "lease" != _nonce}) exitWith {};
    (localNamespace getVariable ["KPLIB_combatFire_queue", createHashMap]) deleteAt (netId _unit);
    _state set ["fire", createHashMap];
    {
        if (_flags select _forEachIndex) then {_unit enableAI _x};
    } forEach ["AUTOTARGET", "FSM", "FIREWEAPON"];
    (localNamespace getVariable ["KPLIB_vehicleCombat_restores", createHashMap]) deleteAt (netId _unit);
    if (count _state > 0) then {
        _state set ["lease", ""];
        _state set ["pending", ""];
        _state set ["next", CBA_missionTime + 2];
    };
    if (!isPlayer _unit && {isNull remoteControlled _unit}) then {
        _unit doTarget objNull;
        _unit doWatch objNull;
        _unit doFire objNull;
    };
};
if (_op != "START" || {hasInterface && {!isServer}} || {count _state == 0}
    || {_state getOrDefault ["pending", ""] != _nonce} || {[_unit] call KPLIB_fnc_vehicleCombatEligible != ""}) exitWith {};
private _current = ["AUTOTARGET", "FSM", "FIREWEAPON"] apply {_unit checkAIFeature _x};
if (_current isNotEqualTo _flags) exitWith {};
_state set ["lease", _nonce];
_state set ["pending", ""];
_state set ["heartbeat", CBA_missionTime];
_state set ["started", CBA_missionTime];
(localNamespace getVariable "KPLIB_vehicleCombat_restores") set [netId _unit, [_unit, _nonce, +_flags]];
{_unit disableAI _x} forEach ["AUTOTARGET", "FSM", "FIREWEAPON"];
_unit doFire objNull;
_unit doTarget (_state get "target");
_unit doWatch (_state get "target");
_state set ["reason", "Aiming"];
