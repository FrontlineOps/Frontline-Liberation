private _statement = {
	params ["_position", "_objects", "_groups", "_waypoints", "_markers", "_hoveredEntity", "_args"];
	RENDER_BATTLESPACE_AI = !RENDER_BATTLESPACE_AI;

	if(RENDER_BATTLESPACE_AI) then {
		[] remoteExecCall ["BATTLESPACE_TASK_FORCE_RENDER_REQUEST", 2];
		if(RENDER_BATTLESPACE_AI_PFH_ID < 0) then {
			RENDER_BATTLESPACE_AI_PFH_ID = [
			{  _this call RENDER_BATTLESPACE_AI_PFH },
			0,
			[CBA_missionTime + 5]
			] call CBA_fnc_addPerFrameHandler;
		};
		["Battlespace live curator renderer enabled", "BATTLESPACE"] call KPLIB_fnc_log;
	} else {
		if(RENDER_BATTLESPACE_AI_PFH_ID >= 0) then {
			[RENDER_BATTLESPACE_AI_PFH_ID] call CBA_fnc_removePerFrameHandler;
			RENDER_BATTLESPACE_AI_PFH_ID = -1;
		};
		BATTLESPACE_TASK_FORCE_RENDER_DATA = [[], []];
		["Battlespace live curator renderer disabled", "BATTLESPACE"] call KPLIB_fnc_log;
	};
};


private _action = ["renderBattlespaceAI", "Toggle Task Forces + Live Routes", ["", [1,1,1,1]], _statement, { true }] call zen_context_menu_fnc_createAction;
[_action, ["battlespaceAI"], 0] call zen_context_menu_fnc_addAction;
