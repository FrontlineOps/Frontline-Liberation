private _statement = {
	params ["_position", "_objects", "_groups", "_waypoints", "_markers", "_hoveredEntity", "_args"];
	RENDER_BATTLESPACE_AI = !RENDER_BATTLESPACE_AI;

	if(RENDER_BATTLESPACE_AI == true) then {

		[
			{  _this call RENDER_BATTLESPACE_AI_PFH },
			0,
			[]
		] call CBA_fnc_addPerFrameHandler;
	};
};


private _action = ["renderBattlespaceAI", "Toggle Battlespace AI Rendering", ["", [1,1,1,1]], _statement, { true }] call zen_context_menu_fnc_createAction;
[_action, ["battlespaceAI"], 0] call zen_context_menu_fnc_addAction;