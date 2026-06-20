private _statement = {
	params ["_position", "_objects", "_groups", "_waypoints", "_markers", "_hoveredEntity", "_args"];
	_marker = [sectors_allSectors, _position] call BIS_fnc_nearestPosition;
	[_marker] remoteExec ["airborne_battlegroup_remote", 2];
};


private _action = ["ParatroopBattlegroup", "Send Airborne", ["", [1,1,1,1]], _statement, { true }] call zen_context_menu_fnc_createAction;
[_action, ["KarmaLibRoot", "Battlegroups"], 0] call zen_context_menu_fnc_addAction;