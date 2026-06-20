params["_group", "_position", ["_radius", 50]];
//_group addWaypoint [_position, _radius] setWaypointScript "\x\cba\addons\ai\fnc_waypointGarrison.sqf []";
//[_group, _position] execVM "\x\cba\addons\ai\fnc_waypointGarrison.sqf";
[_group, _position, _radius, 1, false, 0.8] call CBA_fnc_taskDefend;