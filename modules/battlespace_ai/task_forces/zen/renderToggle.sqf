BATTLESPACE_ZEN_START_TASK_FORCE_RENDERER = {
	if (RENDER_BATTLESPACE_AI && {RENDER_BATTLESPACE_AI_PFH_ID >= 0}) exitWith {};
	RENDER_BATTLESPACE_AI = true;
	RENDER_BATTLESPACE_AI_PFH_ID = [{_this call RENDER_BATTLESPACE_AI_PFH}, 0, []] call CBA_fnc_addPerFrameHandler;
	["Battlespace task-force ZEN renderer ENABLED", "BATTLESPACE"] call KPLIB_fnc_log;
};

private _statement = {
	params ["_position", "_objects", "_groups", "_waypoints", "_markers", "_hoveredEntity", "_args"];
	if (RENDER_BATTLESPACE_AI) then {
		private _losWasEnabled = RENDER_BATTLESPACE_LOS_PROC;
		RENDER_BATTLESPACE_AI = false;
		RENDER_BATTLESPACE_LOS_PROC = false;
		if (RENDER_BATTLESPACE_AI_PFH_ID >= 0) then {
			[RENDER_BATTLESPACE_AI_PFH_ID] call CBA_fnc_removePerFrameHandler;
			RENDER_BATTLESPACE_AI_PFH_ID = -1;
		};
		uiNamespace setVariable ["BATTLESPACE_ZEN_LOS_PROC_DEBUG_CACHE", nil];
		["Battlespace task-force ZEN renderer DISABLED", "BATTLESPACE"] call KPLIB_fnc_log;
		if (_losWasEnabled) then {
			["LoS proc ZEN debug DISABLED with task-force renderer", "BATTLESPACE"] call KPLIB_fnc_log;
		};
	} else {
		[] call BATTLESPACE_ZEN_START_TASK_FORCE_RENDERER;
	};
};


private _action = ["renderBattlespaceAI", "Toggle Task Forces + Live Routes", ["", [1,1,1,1]], _statement, { true }] call zen_context_menu_fnc_createAction;
[_action, ["battlespaceAI"], 0] call zen_context_menu_fnc_addAction;

private _losStatement = {
	params ["_position", "_objects", "_groups", "_waypoints", "_markers", "_hoveredEntity", "_args"];
	RENDER_BATTLESPACE_LOS_PROC = !RENDER_BATTLESPACE_LOS_PROC;
	uiNamespace setVariable ["BATTLESPACE_ZEN_LOS_PROC_DEBUG_CACHE", nil];
	if (RENDER_BATTLESPACE_LOS_PROC) then {
		[] call BATTLESPACE_ZEN_START_TASK_FORCE_RENDERER;
	};
	private _state = ["DISABLED", "ENABLED"] select RENDER_BATTLESPACE_LOS_PROC;
	[format ["LoS proc ZEN debug %1", _state], "BATTLESPACE"] call KPLIB_fnc_log;
	hintSilent format ["LoS Proc Footprint Debug %1%2", _state, ["", " - hover within 500 m of a task-force marker"] select RENDER_BATTLESPACE_LOS_PROC];
};

private _losAction = ["renderBattlespaceLoSProc", "Toggle Live LoS Proc Footprint", ["", [0.1,0.9,1,1]], _losStatement, { true }] call zen_context_menu_fnc_createAction;
[_losAction, ["battlespaceAI"], 0] call zen_context_menu_fnc_addAction;
