/* Mission effects and opt-in diagnostics on each projectile/unit owner. */
if (isRemoteExecuted || {localNamespace getVariable ["KPLIB_munitionsInitialized", false]}) exitWith {};
localNamespace setVariable ["KPLIB_munitionsInitialized", true];
[] call KPLIB_fnc_munitionsSettings;
[] call KPLIB_fnc_munitionsFragInit;
localNamespace setVariable ["KPLIB_munitionsPFH", -1];
localNamespace setVariable ["KPLIB_munitionsSession", -1];
localNamespace setVariable ["KPLIB_munitionsUntil", -1];
localNamespace setVariable ["KPLIB_munitionsShots", []];
localNamespace setVariable ["KPLIB_munitionsActiveTraces", []];
localNamespace setVariable ["KPLIB_munitionsLivePathCache", []];
localNamespace setVariable ["KPLIB_munitionsEvents", []];
localNamespace setVariable ["KPLIB_munitionsDropped", 0];
[] call KPLIB_fnc_blastInit;
localNamespace setVariable ["KPLIB_munitionsTargets", []];

addMissionEventHandler ["ProjectileCreated", {
    _this call KPLIB_fnc_munitionsSpall;
    if (CBA_missionTime >= (localNamespace getVariable ["KPLIB_munitionsUntil", -1])) exitWith {};
    _this call KPLIB_fnc_munitionsTrack;
    // Some engine creation paths report the origin before the position is assigned.
    [KPLIB_fnc_munitionsTrack, _this] call CBA_fnc_execNextFrame;
}];
{
    _x params ["_class", "_event"];
    [_class, _event, {
        [_this param [6, objNull]] call KPLIB_fnc_munitionsSpall;
        if (CBA_missionTime >= (localNamespace getVariable ["KPLIB_munitionsUntil", -1])) exitWith {};
        params ["_source", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile"];
        [_projectile] call KPLIB_fnc_munitionsTrack;
        [_projectile, "FIRED", getPosASL _source, [_weapon, _muzzle, _mode, _magazine, typeOf _source, vectorMagnitude velocity _projectile]] call KPLIB_fnc_munitionsEvent;
    }] call CBA_fnc_addClassEventHandler;
} forEach [["CAManBase", "FiredMan"], ["LandVehicle", "Fired"], ["Air", "Fired"], ["Ship", "Fired"], ["StaticWeapon", "Fired"]];

["ace_medical_woundReceived", {
    params ["_unit", "_damages", "_shooter", "_ammo"];
    if (!local _unit) exitWith {};
    [objNull, "ACE WOUND INPUT (before handler credits)", getPosASL _unit, [typeOf _unit, _ammo, _damages, typeOf _shooter], _unit] call KPLIB_fnc_munitionsEvent;
}] call CBA_fnc_addEventHandler;

// Diagnostics use independent bounded callbacks; the simulation stays separate.
[KPLIB_fnc_munitionsLog, 0.25] call CBA_fnc_addPerFrameHandler;
if (isServer) then {
    localNamespace setVariable ["KPLIB_munitionsLivePFH", [KPLIB_fnc_munitionsLiveTick, 0.25] call CBA_fnc_addPerFrameHandler];
};
if (!hasInterface || {isNil "zen_context_menu_fnc_createAction"}) exitWith {};
private _action = ["FrontlineMunitionsVisual", "Munitions visual debug: ON / OFF", "", {
    private _action = ["DEBUG_ON", "DEBUG_OFF"] select (uiNamespace getVariable ["KPLIB_munitionsDebug", false]);
    [_action] remoteExecCall ["KPLIB_fnc_munitionsRequest", 2];
}, {!isNull getAssignedCuratorLogic player}] call zen_context_menu_fnc_createAction;
[_action, [], 0] call zen_context_menu_fnc_addAction;
[KPLIB_fnc_munitionsDebugTick, 0.1] call CBA_fnc_addPerFrameHandler;
addMissionEventHandler ["Draw3D", {[] call KPLIB_fnc_munitionsDraw}];
