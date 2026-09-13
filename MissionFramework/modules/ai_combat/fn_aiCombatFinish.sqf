params ["_state", "_reason"];
if (!isServer || {isRemoteExecuted}) exitWith {};
private _job = _state get "job";
if (count _job == 0) exitWith {};
private _unit = _state get "unit";
(localNamespace getVariable "KPLIB_combatFire_queue") deleteAt (netId _unit);
terminate (_job get "solver");
private _profile = _job get "profile";
private _kind = _profile get "kind";
if (!isNull _unit) then {
    private _restore = [_unit, [_job get "autoTarget", _job get "fsm", _job get "fireWeapon"], _job get "originalWeapon",
        if (_kind == "RPG") then {_job get "stance"} else {""}];
    if (local _unit) then {_restore call KPLIB_fnc_aiCombatRestore} else {
        _restore remoteExecCall ["KPLIB_fnc_aiCombatRestore", owner _unit];
    };
};
if (!(_job get "fired") && {_job get "attempts" > 0} && {_kind in ["RPG", "GL", "FLARE"]}) then {
    _state set ["cancelled", [_profile get "ammo", CBA_missionTime + 2]];
};
_state set ["next", CBA_missionTime + (if (_kind == "RIFLE" && {_job get "fired"}) then {0.25} else {if (_kind == "RIFLE") then {4} else {8}})];
if (_kind == "RIFLE") then {
    _state set ["next", (_state get "next") max ((_job get "fire") getOrDefault ["next", 0])];
};
_state set ["reason", _reason];
private _recent = _state get "recent";
_recent pushBack [CBA_missionTime, _kind, _reason];
if (count _recent > 4) then {_recent deleteAt 0};
if (KPLIB_aiCombat_debug) then {
    [format ["%1 %2: %3", typeOf _unit, _kind, _reason], "AI COMBAT"] call KPLIB_fnc_log;
};
_state set ["job", createHashMap];
