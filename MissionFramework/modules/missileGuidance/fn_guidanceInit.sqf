/* All machines register local flight hooks; server owns strategic SAM state.
   No projectile simulation is restored through JIP or campaign persistence. */
if (isRemoteExecuted || {localNamespace getVariable ["KPLIB_guidanceInitialized", false]}) exitWith {};
localNamespace setVariable ["KPLIB_guidanceInitialized", true];
{
    localNamespace setVariable [_x, createHashMap];
} forEach ["KPLIB_guidanceActive", "KPLIB_guidanceConfig", "KPLIB_guidanceSpatial", "KPLIB_guidanceMetrics"];
localNamespace setVariable ["KPLIB_guidanceCountermeasures", []];
localNamespace setVariable ["KPLIB_guidancePFH", -1];
localNamespace setVariable ["KPLIB_guidanceSequence", 0];

// Observe ACE's existing worker; this event never starts or replaces ACE code.
// Its first tick also releases any Frontline worker if an addon starts ACE late.
["ace_missileguidance_guidanceTick", {
    if (isRemoteExecuted) exitWith {};
    private _fired = _this param [0, [], [[]]];
    private _projectile = _fired param [6, objNull, [objNull]];
    if (isNull _projectile || {!local _projectile}
        || {_projectile getVariable ["KPLIB_guidanceAce", false]}) exitWith {};
    _projectile setVariable ["KPLIB_guidanceAce", true];
    if (_projectile getVariable ["KPLIB_guidanceOwner", ""] == "CUSTOM") then {
        [_projectile getVariable ["KPLIB_guidanceId", -1], "ACE guidance active", "ACE"] call KPLIB_fnc_guidanceRetire;
    };
    _projectile setVariable ["KPLIB_guidanceOwner", "ACE"];
    _projectile setVariable ["KPLIB_guidanceReason", "ACE guidance worker observed"];
}] call CBA_fnc_addEventHandler;

// Existing event name retained for local callers. Actual projectile identity is authoritative.
IADS_HandleFiredEvent = {
    params ["_unit", "_weapon", "", "", "", "", "_projectile", ["_vehicle", objNull]];
    [_projectile, _unit, _vehicle, _weapon] call KPLIB_fnc_guidanceRegister;
};
IADS_SAMOverride = IADS_HandleFiredEvent;
["CAManBase", "FiredMan", {_this call IADS_HandleFiredEvent}] call CBA_fnc_addClassEventHandler;
{
    [_x, "Fired", {
        params ["_vehicle", "_weapon", "", "", "", "", "_projectile", ["_gunner", objNull]];
        [_projectile, _gunner, _vehicle, _weapon] call KPLIB_fnc_guidanceRegister;
    }] call CBA_fnc_addClassEventHandler;
} forEach ["LandVehicle", "Air", "Ship", "StaticWeapon"];
[missionNamespace, "ProjectileCreated", {
    params ["_projectile"];
    [_projectile] call KPLIB_fnc_guidanceRegister;
}] call CBA_fnc_addBISEventHandler;

[] call compileFinal preprocessFileLineNumbers "modules\missileGuidance\fire-control\index.sqf";
// EWR compatibility uses actual ammo simulation, never obsolete surrogate classnames.
IADS_IsOrdinance = {
    params ["_class"];
    toLower getText (configFile >> "CfgAmmo" >> _class >> "simulation") in ["shotmissile", "shotrocket", "shotshell", "shotbomb"]
};
IADS_IsArtilleryOrdinance = {
    params ["_class"];
    toLower getText (configFile >> "CfgAmmo" >> _class >> "simulation") in ["shotrocket", "shotshell"]
};
// Warm only the selected faction's actual ammo. Novel classes are resolved on first use.
[
    {
        {
            {
                private _capability = [_x] call KPLIB_fnc_getVehicleAirDefense;
                {[_x] call KPLIB_fnc_guidanceResolve} forEach (_capability get "missileAmmo");
            } forEach (_y getOrDefault ["aa", []]);
        } forEach (missionNamespace getVariable ["KPLIB_autoFactionCatalogs", createHashMap]);
    }, [], 0.1
] call CBA_fnc_waitAndExecute;
["Automatic ammunition classification and local guidance hooks initialized", "GUIDANCE"] call KPLIB_fnc_log;
