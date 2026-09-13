if (isRemoteExecuted || {isNil "_KPLIB_vehicleCombatOwnerContext"}) exitWith {};
private _start = diag_tickTime;
private _now = CBA_missionTime;
if (isServer) then {
    if (_now >= localNamespace getVariable ["KPLIB_vehicleCombat_peerScanAt", -1]) then {
        localNamespace setVariable ["KPLIB_vehicleCombat_peerScanAt", _now + 1];
        private _peers = localNamespace getVariable "KPLIB_vehicleCombat_peers";
        private _headless = allPlayers select {_x isKindOf "HeadlessClient_F"};
        {if (!((_y select 0) in _headless) || {owner (_y select 0) != _x}) then {_peers deleteAt _x}} forEach _peers;
        {
            private _owner = owner _x;
            if (_owner <= 2 || {_owner in _peers}) then {continue};
            private _token = format ["%1:%2:%3:%4:%5", _owner, diag_tickTime, random 1e9, random 1e9, random 1e9];
            _peers set [_owner, [_x, _token]];
            [_token] remoteExecCall ["KPLIB_fnc_vehicleCombatPeer", _owner];
        } forEach _headless;
    };
    private _ledger = localNamespace getVariable "KPLIB_vehicleCombat_leases";
    {
        _y params ["_unit", "_nonce", "_owner", "_flags", "_heartbeat", "_vehicle", "_path"];
        if (isNull _unit || {owner _unit != _owner} || {_now - _heartbeat > 12}
            || {[_unit, false] call KPLIB_fnc_vehicleCombatEligible != ""} || {vehicle _unit != _vehicle}
            || {_vehicle turretOwner _path != _owner}) then {
            if (!isNull _unit) then {
                private _KPLIB_vehicleCombatServerContext = true;
                private _args = ["STOP", _unit, _nonce, _flags];
                if (local _unit) then {_args call KPLIB_fnc_vehicleCombatLease} else {_args remoteExecCall ["KPLIB_fnc_vehicleCombatLease", _unit]};
            };
            _ledger deleteAt _x;
        };
    } forEach _ledger;
};
private _states = localNamespace getVariable "KPLIB_vehicleCombat_states";
private _restores = localNamespace getVariable "KPLIB_vehicleCombat_restores";
private _restoreKeys = keys _restores;
private _rc = localNamespace getVariable ["KPLIB_vehicleCombat_restoreCursor", 0];
for "_i" from 1 to (2 min count _restoreKeys) do {
    _rc = _rc mod count _restoreKeys;
    private _key = _restoreKeys select _rc;
    _rc = _rc + 1;
    private _unit = (_restores get _key) select 0;
    if (isNull _unit || {!alive _unit}) then {_restores deleteAt _key} else {
        if (local _unit) then {[_unit] call KPLIB_fnc_vehicleCombatRestoreLocal};
    };
};
localNamespace setVariable ["KPLIB_vehicleCombat_restoreCursor", _rc];
private _registry = localNamespace getVariable "KPLIB_vehicleCombat_registry";
private _queue = localNamespace getVariable "KPLIB_vehicleCombat_queue";
private _cursor = localNamespace getVariable ["KPLIB_vehicleCombat_cursor", 0];
for "_i" from 1 to (4 min count _queue) do {
    _cursor = _cursor mod count _queue;
    private _key = _queue select _cursor;
    private _entry = _registry get _key;
    _entry params ["_v", "_next"];
    if (isNull _v || {!alive _v}) then {
        _registry deleteAt _key;
        _queue deleteAt _cursor;
        continue;
    };
    _cursor = _cursor + 1;
    if (_now < _next || {!KPLIB_vehicleCombat_enabled}) then {continue};
    _entry set [1, _now + 3];
    {
        private _unit = _v turretUnit _x;
        if (count _states >= 128) exitWith {};
        if (isNull _unit || {!local _unit} || {netId _unit in _states} || {[_unit] call KPLIB_fnc_vehicleCombatEligible != ""}) then {continue};
        _states set [netId _unit, createHashMapFromArray [
            ["unit", _unit], ["vehicle", _v], ["path", _x], ["group", group _unit], ["next", 0],
            ["target", objNull], ["lease", ""], ["pending", ""], ["requested", 0], ["heartbeat", 0],
            ["profile", createHashMap], ["profiles", []], ["shots", 0], ["lastShot", []],
            ["loadAt", -100], ["aimSince", _now], ["reason", "Assessing known targets"]
        ]];
    } forEach ((allTurrets _v) select [0, 4]);
};
localNamespace setVariable ["KPLIB_vehicleCombat_cursor", _cursor];
private _keys = keys _states;
// Service active aim/reload tasks first. Idle registries cannot delay a shot or
// restoration by a full sweep when many parked vehicles are present.
private _active = _keys select {
    private _s = _states get _x;
    _s get "lease" != "" || {_s get "pending" != ""}
};
private _work = [];
private _ac = localNamespace getVariable ["KPLIB_vehicleCombat_activeCursor", 0];
for "_i" from 1 to (8 min count _active) do {
    _ac = _ac mod count _active;
    _work pushBack (_active select _ac);
    _ac = _ac + 1;
};
localNamespace setVariable ["KPLIB_vehicleCombat_activeCursor", _ac];
private _sc = localNamespace getVariable ["KPLIB_vehicleCombat_stateCursor", 0];
for "_i" from 1 to (2 min count _keys) do {
    _sc = _sc mod count _keys;
    _work pushBackUnique (_keys select _sc);
    _sc = _sc + 1;
};
{
    private _key = _x;
    private _state = _states get _key;
    private _unit = _state get "unit";
    if (isNull _unit || {!alive _unit} || {!local _unit} || {vehicle _unit != _state get "vehicle"}
        || {group _unit != _state get "group"} || {((assignedVehicleRole _unit) param [1, []]) isNotEqualTo (_state get "path")}) then {
        [_state, "Crew removed or locality lost"] call KPLIB_fnc_vehicleCombatRelease;
        _states deleteAt _key;
        continue;
    };
    if (_state get "lease" == "" && {_state get "pending" == ""} && {_now < _state get "next"}) then {continue};
    [_state] call KPLIB_fnc_vehicleCombatUpdate;
} forEach _work;
localNamespace setVariable ["KPLIB_vehicleCombat_stateCursor", _sc];
localNamespace setVariable ["KPLIB_vehicleCombat_lastTickMs", (diag_tickTime - _start) * 1000];
