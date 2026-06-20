combat_air_patrol_remote = {
	params ["_objective"];
	[[markerPos _objective] call KPLIB_fnc_getNearestBluforObjective, true, 2] spawn spawn_air;
};