
DIRECTED_BATTLEGROUP_IS_MECHANIZED = false;
private _statement = {
	params ["_position", "_objects", "_groups", "_waypoints", "_markers", "_hoveredEntity", "_args"];
	DIRECTED_BATTLEGROUP_IS_MECHANIZED = !DIRECTED_BATTLEGROUP_IS_MECHANIZED;
	DIRECTED_BATTLEGROUP_ACTUAL_SPAWN = [[2000, 1500] select DIRECTED_BATTLEGROUP_IS_MECHANIZED, [8000, 8000] select DIRECTED_BATTLEGROUP_IS_MECHANIZED, true, markerPos _marker, false, true] call KPLIB_fnc_getOpforSpawnPoint;
};


private _action = ["DirectedBattlegroupToggleType", "Toggle Mechanized", ["", [1,1,1,1]], _statement, { true }, [], {}, {

	params ["_action", "_parameters"];

	private _str = "MECHANIZED";

	if(DIRECTED_BATTLEGROUP_IS_MECHANIZED) then {
		_str = "MOTORIZED";
	};

	_action set [1, format ["Change Directed Battlegroup type to %1", _str]];
	
}] call zen_context_menu_fnc_createAction;
[_action, ["KarmaLibRoot", "DirectedBattlegroups"], 0] call zen_context_menu_fnc_addAction;