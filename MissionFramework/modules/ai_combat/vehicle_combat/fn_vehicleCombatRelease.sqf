if (isRemoteExecuted || {isNil "_KPLIB_vehicleCombatOwnerContext"}) exitWith {};
params ["_state", "_reason"];
_state set ["reason", _reason];
(localNamespace getVariable "KPLIB_combatFire_queue") deleteAt (netId (_state get "unit"));
_state set ["fire", createHashMap];
private _nonce = _state getOrDefault ["lease", _state getOrDefault ["pending", ""]];
if (_nonce == "") then {_nonce = _state getOrDefault ["pending", ""]};
if (_nonce != "") then {
    private _args = ["RELEASE", _state get "unit", _nonce, [], localNamespace getVariable ["KPLIB_vehicleCombat_peerToken", ""]];
    if (isServer) then {
        private _KPLIB_vehicleCombatServerContext = true;
        _args call KPLIB_fnc_vehicleCombatRequest;
    } else {_args remoteExecCall ["KPLIB_fnc_vehicleCombatRequest", 2]};
};
_state set ["lease", ""];
_state set ["pending", ""];
_state set ["next", CBA_missionTime + 3];
