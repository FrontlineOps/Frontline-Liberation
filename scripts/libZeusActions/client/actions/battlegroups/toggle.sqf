private _statement = {
	params ["_position", "_objects", "_groups", "_waypoints", "_markers", "_hoveredEntity", "_args"];
	[(format ["~~~AdminAction~~~ - Toggle BattleGroup (User: %1, %2)", (name player), BATTLESPACE_BATTLEGROUPS_ALLOWED])] remoteExec ["diag_log", 2];
	remoteExec ["battlegroup_spawn_toggle_remote", 2];
};


private _action = ["ToggleBattlegroup", "Toggle Battlegroup Spawns", ["", [1,1,1,1]], _statement, { true }, [], {}, {

	params ["_action", "_parameters"];

	if(BATTLESPACE_BATTLEGROUPS_ALLOWED) then {

		_action set [1, "Toggle Battlegroup Spawns OFF"];
	} else {
		_action set [1, "Toggle Battlegroup Spawns ON"];
	};

}] call zen_context_menu_fnc_createAction;
[_action, ["KarmaLibRoot", "Battlegroups"], 0] call zen_context_menu_fnc_addAction;