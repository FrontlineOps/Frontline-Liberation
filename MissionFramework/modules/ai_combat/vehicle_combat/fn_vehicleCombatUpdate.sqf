if (isRemoteExecuted || {isNil "_KPLIB_vehicleCombatOwnerContext"}) exitWith {};
params ["_state"];
private _now = CBA_missionTime;
private _unit = _state get "unit";
private _reason = [_unit] call KPLIB_fnc_vehicleCombatEligible;
if (_reason != "" || {vehicle _unit != _state get "vehicle"}
    || {group _unit != _state get "group"} || {(assignedVehicleRole _unit param [1, []]) isNotEqualTo (_state get "path")}) exitWith {
    [_state, if (_reason == "") then {"Crew assignment changed"} else {_reason}] call KPLIB_fnc_vehicleCombatRelease;
};
private _v = _state get "vehicle";
private _path = _state get "path";
if (_state get "lease" == "" && {_state get "pending" != ""}) exitWith {
    if (_now - (_state get "requested") > 3) then {[_state, "Control grant unavailable"] call KPLIB_fnc_vehicleCombatRelease};
};
if (_now >= _state get "next") then {
    _state set ["next", _now + 3];
    private _profiles = [_v, _path] call KPLIB_fnc_vehicleCombatWeapons;
    _state set ["profiles", _profiles];
    private _target = _state get "target";
    if (!([_unit, _target] call KPLIB_fnc_vehicleCombatVisible)
        || {count ([_v, _target, _profiles] call KPLIB_fnc_vehicleCombatChoose) == 0}) then {
        _target = objNull;
        // Native target memory only. Perceived side can be stale after an owner
        // transfer; Visible verifies current hostility, knowledge and geometry.
        // Do not age out an enemy merely because it has been known for a while.
        private _known = _unit targets [false, KPLIB_vehicleCombat_gunRange, []];
        private _cursor = _state getOrDefault ["candidateCursor", 0];
        for "_i" from 1 to (4 min count _known) do {
            _cursor = _cursor mod count _known;
            private _candidate = vehicle (_known select _cursor);
            _cursor = _cursor + 1;
            if ([_unit, _candidate] call KPLIB_fnc_vehicleCombatVisible
                && {count ([_v, _candidate, _profiles] call KPLIB_fnc_vehicleCombatChoose) > 0}) exitWith {_target = _candidate};
        };
        _state set ["candidateCursor", _cursor];
    };
    if (isNull _target) exitWith {[_state, "No known visible target with a usable round"] call KPLIB_fnc_vehicleCombatRelease};
    private _chosen = [_v, _target, _profiles, (weaponState [_v, _path]) param [3, ""]] call KPLIB_fnc_vehicleCombatChoose;
    if (count _chosen == 0) exitWith {[_state, "No suitable carried ammunition in range"] call KPLIB_fnc_vehicleCombatRelease};
    private _changed = _target != _state get "target" || {(_state getOrDefault ["profile", createHashMap]) getOrDefault ["magazine", ""] != _chosen get "magazine"};
    if (_changed) then {
        _state set ["loadAt", -100];
        _state set ["aimSince", _now];
        _state set ["fire", createHashMap];
        (localNamespace getVariable "KPLIB_combatFire_queue") deleteAt (netId _unit);
    };
    _state set ["target", _target];
    _state set ["profile", _chosen];
    if (_state get "lease" == "") then {
        private _states = localNamespace getVariable "KPLIB_vehicleCombat_states";
        if ({_x get "lease" != "" || {_x get "pending" != ""}} count (values _states) >= KPLIB_vehicleCombat_maxActive) exitWith {_state set ["reason", "Active turret budget full"]};
        private _safe = [_unit, _target, _chosen] call KPLIB_fnc_vehicleCombatSafe;
        if (_safe != "") exitWith {_state set ["reason", _safe]};
        private _serial = 1 + (localNamespace getVariable ["KPLIB_vehicleCombat_serial", 0]);
        localNamespace setVariable ["KPLIB_vehicleCombat_serial", _serial];
        private _nonce = format ["%1:%2", clientOwner, _serial];
        _state set ["pending", _nonce];
        _state set ["requested", _now];
        private _flags = ["AUTOTARGET", "FSM", "FIREWEAPON"] apply {_unit checkAIFeature _x};
        // Respect an explicit firing disable from another mission system.
        if (!(_flags select 2)) exitWith {
            _state set ["pending", ""];
            _state set ["reason", "Firing disabled by another controller"];
        };
        private _args = ["REQUEST", _unit, _nonce, _flags, localNamespace getVariable ["KPLIB_vehicleCombat_peerToken", ""]];
        if (isServer) then {
            private _KPLIB_vehicleCombatServerContext = true;
            _args call KPLIB_fnc_vehicleCombatRequest;
        } else {_args remoteExecCall ["KPLIB_fnc_vehicleCombatRequest", 2]};
    } else {
        if (_changed) then {
            _unit doTarget _target;
            _unit doWatch _target;
        };
    };
};
if (_state get "lease" == "") exitWith {};
private _target = _state get "target";
private _p = _state get "profile";
if (_now - (_state get "heartbeat") >= 4) then {
    _state set ["heartbeat", _now];
    private _args = ["KEEP", _unit, _state get "lease", [], localNamespace getVariable ["KPLIB_vehicleCombat_peerToken", ""]];
    if (isServer) then {
        private _KPLIB_vehicleCombatServerContext = true;
        _args call KPLIB_fnc_vehicleCombatRequest;
    } else {_args remoteExecCall ["KPLIB_fnc_vehicleCombatRequest", 2]};
};
private _distance = _v distance _target;
if (isNull _target || {_distance < _p get "minimum"} || {_distance > _p get "range"}) exitWith {[_state, "Target outside round envelope"] call KPLIB_fnc_vehicleCombatRelease};
private _safe = [_unit, _target, _p] call KPLIB_fnc_vehicleCombatSafe;
if (_safe != "") exitWith {[_state, _safe] call KPLIB_fnc_vehicleCombatRelease};
// Keep an established burst scheduled during native cycling/reloads. The fast
// path still checks current weapon state and safety before every trigger.
private _fireQueue = localNamespace getVariable "KPLIB_combatFire_queue";
private _fireKey = netId _unit;
if (_fireKey in _fireQueue) then {(_fireQueue get _fireKey) set [3, _now + 1.25]};
private _weapon = _p get "weapon";
private _muzzle = _p get "muzzle";
private _mode = _p get "mode";
private _ws = weaponState [_v, _path, _weapon, _muzzle];
if (count _ws < 7) exitWith {[_state, "Muzzle state unavailable"] call KPLIB_fnc_vehicleCombatRelease};
private _phase = (_ws select 5) max (_ws select 6);
if (abs (_phase - (_state getOrDefault ["reloadPhase", -1])) > 0.001) then {
    _state set ["reloadPhase", _phase];
    _state set ["reloadProgress", _now];
};
private _lastProgress = ((_state get "lastShot") param [0, -100]) max (_state get "started") max (_state getOrDefault ["reloadProgress", 0]);
if (_now - _lastProgress > 25) exitWith {[_state, "No firing solution; returning to native assessment"] call KPLIB_fnc_vehicleCombatRelease};
if ((_ws select 5) > 0 || {_ws select 6 > 0}) exitWith {_state set ["reason", "Normal weapon reload"]};
if (_ws select 3 != _p get "magazine" || {_ws select 4 <= 0}) exitWith {
    if (_now - (_state get "loadAt") > 12) then {
        _v loadMagazine [_path, _weapon, _p get "magazine"];
        _state set ["loadAt", _now];
    };
    _state set ["reason", "Loading " + (_p get "magazine")];
};
private _selected = weaponState [_v, _path];
if (_selected select 0 != _weapon || {_selected select 1 != _muzzle}) then {
    _unit selectWeapon [_weapon, _muzzle, _mode];
    _state set ["aimSince", _now];
};
private _aim = _v aimedAtTarget [_target, _muzzle];
_state set ["alignment", _aim];
_state set ["reason", format ["Aiming %1 / %2 at %3 m", _p get "kind", _p get "magazine", round _distance]];
if (_aim < 0.75 || {_now - (_state get "aimSince") < 1.5}) exitWith {};
private _fire = _state getOrDefault ["fire", createHashMap];
_state set ["fire", _fire];
(localNamespace getVariable "KPLIB_combatFire_queue") set [netId _unit, [true, _state, _fire, _now + 1.25]];
