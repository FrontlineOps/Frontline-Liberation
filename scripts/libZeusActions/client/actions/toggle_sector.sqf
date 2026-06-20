private _statement = {
	params ["_position", "_objects", "_groups", "_waypoints", "_markers", "_hoveredEntity", "_args"];
	_marker = [sectors_allSectors, _position] call BIS_fnc_nearestPosition;
	[(format ["~~~AdminAction~~~ - Toggle Sector (User: %1)", name player])] remoteExec ["diag_log", 2];
	[_marker] remoteExec ["toggle_sector_remote", 2];
};


private _action = ["ToggleSector", "Flip Sector Control", ["", [1,1,1,1]], _statement, { true }] call zen_context_menu_fnc_createAction;
[_action, ["KarmaLibRoot"], 0] call zen_context_menu_fnc_addAction;