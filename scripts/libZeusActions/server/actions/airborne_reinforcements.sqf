airborne_reinforcements_remote = {
	params ["_objective"];
	[markerPos _objective, 3, 6, true, markerText _objective] call send_paratroopers;
};