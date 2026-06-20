
private _statement = {
	params ["_position", "_objects", "_groups", "_waypoints", "_markers", "_hoveredEntity", "_args"];
	_marker = [sectors_allSectors, _position] call BIS_fnc_nearestPosition;
	[DIRECTED_BATTLEGROUP_SPAWN, _marker, DIRECTED_BATTLEGROUP_IS_MECHANIZED] remoteExec ["directed_battlegroup_remote", 2];
};


private _action = ["DirectedBattlegroupSend", "Send Directed Battlegroup", ["", [1,1,1,1]], _statement, { !isNil "DIRECTED_BATTLEGROUP_SPAWN" }, [], {}, {

	params ["_action", "_parameters"];

	_action set [1, format ["Send Directed Battlegroup from %1", markerText DIRECTED_BATTLEGROUP_SPAWN]];

}] call zen_context_menu_fnc_createAction;
[_action, ["KarmaLibRoot", "DirectedBattlegroups"], 0] call zen_context_menu_fnc_addAction;