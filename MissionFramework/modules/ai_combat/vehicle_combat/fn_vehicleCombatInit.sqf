if (isRemoteExecuted) exitWith {};
if (hasInterface && {isNil "KPLIB_vehicleCombat_zenReady"} && {!isNil "zen_context_menu_fnc_createAction"}) then {
    KPLIB_vehicleCombat_zenReady = true;
    private _action = ["frontlineVehicleCombat", "Inspect Frontline Vehicle Combat", "", {
        [_this select 0] remoteExecCall ["KPLIB_fnc_vehicleCombatInspect", 2];
    }, {true}] call zen_context_menu_fnc_createAction;
    [_action, [], 0] call zen_context_menu_fnc_addAction;
};
if (hasInterface && {!isServer}) exitWith {};
if (localNamespace getVariable ["KPLIB_vehicleCombat_initialized", false]) exitWith {};
localNamespace setVariable ["KPLIB_vehicleCombat_initialized", true];
[] call KPLIB_fnc_combatFireInit;
{
    localNamespace setVariable [_x, createHashMap];
} forEach ["KPLIB_vehicleCombat_registry", "KPLIB_vehicleCombat_states", "KPLIB_vehicleCombat_leases", "KPLIB_vehicleCombat_peers", "KPLIB_vehicleCombat_restores", "KPLIB_vehicleCombat_profiles", "KPLIB_vehicleCombat_muzzles"];
localNamespace setVariable ["KPLIB_vehicleCombat_queue", []];
["LandVehicle", "init", {
    [{_this call KPLIB_fnc_vehicleCombatRegister}, [_this select 0], 1] call CBA_fnc_waitAndExecute;
}, true, [], true] call CBA_fnc_addClassEventHandler;
["CAManBase", "Local", {
    if (_this select 1) then {
        private _KPLIB_vehicleCombatOwnerContext = true;
        [_this select 0] call KPLIB_fnc_vehicleCombatRestoreLocal;
    };
}] call CBA_fnc_addClassEventHandler;
["LandVehicle", "Fired", {
    params ["_v", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_gunner"];
    if (isRemoteExecuted || {isNull _gunner} || {!local _gunner}) exitWith {};
    private _s = (localNamespace getVariable "KPLIB_vehicleCombat_states") getOrDefault [netId _gunner, createHashMap];
    if (count _s == 0 || {_s get "lease" == ""}) exitWith {};
    // A scripted trigger pull does not carry the native AI's missile lock.
    // Designate this already-validated target on this shot only; the existing
    // native/Frontline guidance owner retains all subsequent flight control.
    private _p = _s get "profile";
    if (_p get "magazine" != _magazine || {_p get "muzzle" != _muzzle}
        || {CBA_missionTime - (_s getOrDefault ["attemptAt", -100]) >= 0.3}) exitWith {};
    if (_p get "kind" == "ATGM" && {_p get "magazine" == _magazine}
        && {local _projectile} && {CBA_missionTime - (_s getOrDefault ["attemptAt", -100]) < 0.3}
        && {isNull missileTarget _projectile}) then {
        _projectile setMissileTarget (_s get "target");
    };
    [_s getOrDefault ["fire", createHashMap], _mode] call KPLIB_fnc_combatFireFired;
    _s set ["shots", 1 + (_s get "shots")];
    _s set ["lastShot", [CBA_missionTime, _ammo, _magazine, round (_v distance (_s get "target"))]];
    if (KPLIB_vehicleCombat_debug) then {
        diag_log format ["[FL VEHICLE COMBAT] %1 turret %2: %3 -> %4 at %5 m | actual shot %6", typeOf _v, _s get "path", _magazine, typeOf (_s get "target"), round (_v distance (_s get "target")), _s get "shots"];
    };
}] call CBA_fnc_addClassEventHandler;
localNamespace setVariable ["KPLIB_vehicleCombat_handler", [{
    private _KPLIB_vehicleCombatOwnerContext = true;
    [] call KPLIB_fnc_vehicleCombatTick;
}, 0.25] call CBA_fnc_addPerFrameHandler];
diag_log format ["[FL VEHICLE COMBAT] Owner %1 initialized; gun/MG caps %2/%3 m, range factor %4", clientOwner, KPLIB_vehicleCombat_gunRange, KPLIB_vehicleCombat_mgRange, KPLIB_vehicleCombat_rangeMultiplier];
