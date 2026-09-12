/*
    File: fn_initUavCrew.sqf
    Author: KP Liberation Dev Team - https://github.com/KillahPotatoes
    Date: 2019-11-25
    Last Update: 2019-12-04
    License: MIT License - http://www.opensource.org/licenses/MIT
    Description:
        Creates native engine crew for player-controlled drones.
        Keeps the configured crew classes and assigns them to the player side.
    Parameter(s):
        _veh - Drone to initialize [OBJECT, defaults to objNull]
    Returns:
        Function reached the end [BOOL]
*/

params [
    ["_veh", objNull, [objNull]]
];

if (!isServer || {isRemoteExecuted} || {isNull _veh} || {!unitIsUAV _veh}) exitWith {false};

//Create regular config crew
private _grp = createVehicleCrew _veh;

// Keep native UAV/crew types and occupied seats when changing allegiance.
if ((side _grp) != GRLIB_side_friendly) then {
    private _nativeGroup = _grp;
    _grp = createGroup [GRLIB_side_friendly, true];
    (units _nativeGroup) joinSilent _grp;
    deleteGroup _nativeGroup;
};

 //Set the crew to safe behaviour
_grp setBehaviour "SAFE";

true;
