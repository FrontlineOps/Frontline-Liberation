/* Server lease ledger. Only server AI and connected headless owners may request
   control; ordinary player clients cannot select actors, flags or ammunition. */
params [["_op", "", [""]], ["_unit", objNull, [objNull]], ["_nonce", "", [""]], ["_flags", [], [[]]], ["_auth", "", [""]]];
if (!isServer || {isNull _unit} || {_nonce == ""} || {count _nonce > 80}) exitWith {};
private _sender = remoteExecutedOwner;
private _serverCall = !isNil "_KPLIB_vehicleCombatServerContext" && {!isRemoteExecuted};
if (_serverCall) then {_sender = 2} else {
    // Arma can drop remote caller metadata on HC -> server calls. Require the
    // private per-connection capability as well as current unit/turret ownership.
    private _matched = -1;
    if (_auth != "" && {count _auth <= 128}) then {
        {
            if (_y select 1 == _auth && {owner (_y select 0) == _x}
                && {(_y select 0) in allPlayers} && {_sender <= 0 || {_sender == _x}}) exitWith {_matched = _x};
        } forEach (localNamespace getVariable ["KPLIB_vehicleCombat_peers", createHashMap]);
    };
    _sender = _matched;
};
if (_sender < 2) exitWith {};
private _ledger = localNamespace getVariable ["KPLIB_vehicleCombat_leases", createHashMap];
private _key = netId _unit;
private _lease = _ledger getOrDefault [_key, []];
if (_op in ["RELEASE", "KEEP"]) exitWith {
    if (_lease isEqualTo [] || {_lease select 1 != _nonce} || {_lease select 2 != _sender}) exitWith {};
    if (_op == "KEEP" && {owner _unit == _sender}) then {
        _lease set [4, CBA_missionTime];
    } else {
        private _KPLIB_vehicleCombatServerContext = true;
        private _args = ["STOP", _unit, _nonce, _lease select 3];
        if (local _unit) then {_args call KPLIB_fnc_vehicleCombatLease} else {_args remoteExecCall ["KPLIB_fnc_vehicleCombatLease", _unit]};
        _ledger deleteAt _key;
    };
};
if (_op != "REQUEST" || {owner _unit != _sender} || {_lease isNotEqualTo []}
    || {count _ledger >= 64} || {count _flags != 3} || {_flags findIf {!(_x isEqualType true)} >= 0}
    || {!(_flags select 2)}
    || {[_unit, false] call KPLIB_fnc_vehicleCombatEligible != ""}) exitWith {};
private _vehicle = vehicle _unit;
private _path = (assignedVehicleRole _unit) select 1;
if (_vehicle turretOwner _path != _sender) exitWith {};
if ({_x select 2 == _sender} count (values _ledger) >= KPLIB_vehicleCombat_maxActive) exitWith {};
_ledger set [_key, [_unit, _nonce, _sender, +_flags, CBA_missionTime, _vehicle, _path]];
private _KPLIB_vehicleCombatServerContext = true;
private _args = ["START", _unit, _nonce, _flags];
if (local _unit) then {_args call KPLIB_fnc_vehicleCombatLease} else {_args remoteExecCall ["KPLIB_fnc_vehicleCombatLease", _unit]};
