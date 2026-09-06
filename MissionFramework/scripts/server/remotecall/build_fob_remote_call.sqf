if (!isServer || {canSuspend}) exitWith {};
params [["_container", objNull, [objNull]], ["_position", [], [[]]], ["_direction", 0, [0]], ["_level", true, [false]]];
private _caller = ["BUILD"] call KPLIB_fnc_permissionRequest;
if (isNull _caller || {isNull _container} || {!alive _container}) exitWith {};
if !(typeOf _container in [FOB_box_typename, FOB_truck_typename]) exitWith {};
if (_caller distance _container > 10 || {!isNull attachedTo _container} || {({alive _x} count crew _container) > 0}) exitWith {};
if !([_caller, _position, _direction, FOB_typename] call KPLIB_fnc_validBuildPosition) exitWith {};
private _centre = getPos _caller;
if (surfaceIsWater _centre || {surfaceIsWater _position} || {_caller distance2D startbase <= 1000}
    || {count GRLIB_all_fobs >= GRLIB_maximum_fobs}
    || {(GRLIB_all_fobs findIf {_centre distance2D _x < 1000}) != -1}
    || {(sectors_allSectors findIf {_centre distance2D getMarkerPos _x < 300}) != -1}) exitWith {
    ["FOB deployment cancelled: this location is unavailable. Your container is unchanged."] remoteExecCall ["hint", owner _caller];
};
private _building = createVehicle [FOB_typename, _position, [], 0, "CAN_COLLIDE"];
if (isNull _building) exitWith {};
_building setDir _direction;
_building setPos _position;
_building setVectorUp (if (_level) then {[0, 0, 1]} else {surfaceNormal position _building});
deleteVehicle _container;
GRLIB_all_fobs pushBack _centre;
publicVariable "GRLIB_all_fobs";
[_building] call KPLIB_fnc_addObjectInit;
stats_fobs_built = stats_fobs_built + 1;
please_recalculate = true;
[] spawn KPLIB_fnc_doSave;
[_centre, 0] remoteExec ["remote_call_fob"];
["FOB deployment committed", "BUILD"] call KPLIB_fnc_log;
