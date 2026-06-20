RENDER_NETWORK = false;
RENDER_LINKS = false;
RENDER_IN_DEPTH_LINKS = false;
ROAD_RENDER = false;
RENDER_EVALUATIONS = false;
private _toggleRoadRendering = {
	params ["_position", "_objects", "_groups", "_waypoints", "_markers", "_hoveredEntity", "_args"];
	ROAD_RENDER = !ROAD_RENDER;

	if(ROAD_RENDER == true) then {

		[
			{ _this call RENDER_ROADS_PFH },
			0,
			[]
		] call CBA_fnc_addPerFrameHandler;
	};
};


private _toggleRoadEvaluations = {
	params ["_position", "_objects", "_groups", "_waypoints", "_markers", "_hoveredEntity", "_args"];
	RENDER_EVALUATIONS = !RENDER_EVALUATIONS;
};


private _toggleNetworkRendering = {
	params ["_position", "_objects", "_groups", "_waypoints", "_markers", "_hoveredEntity", "_args"];
	RENDER_NETWORK = !RENDER_NETWORK;

	if(RENDER_NETWORK == true) then {

		[
			{ _this call RENDER_NETWORK_PFH },
			0,
			[]
		] call CBA_fnc_addPerFrameHandler;
	};
};


private _toggleNetworkLinkRendering = {
	params ["_position", "_objects", "_groups", "_waypoints", "_markers", "_hoveredEntity", "_args"];
	RENDER_LINKS = !RENDER_LINKS;
};

private _toggleNetworkLinkInDepthRendering = {
	params ["_position", "_objects", "_groups", "_waypoints", "_markers", "_hoveredEntity", "_args"];
	RENDER_IN_DEPTH_LINKS = !RENDER_IN_DEPTH_LINKS;
};

private _rootAction = ["NetworkedSectors", "Networked Sectors", "", {}, { true }] call zen_context_menu_fnc_createAction;

[_rootAction, [], 0] call zen_context_menu_fnc_addAction;




private _action = ["ToggleRoadRender", "Toggle Path Rendering", ["", [1,1,1,1]], _toggleRoadRendering, { true }] call zen_context_menu_fnc_createAction;
[_action, ["NetworkedSectors"], 0] call zen_context_menu_fnc_addAction;

_action = ["ToggleRoadEvaluations", "Toggle In-depth Path Rendering", ["", [1,1,1,1]], _toggleRoadEvaluations, { true }] call zen_context_menu_fnc_createAction;
[_action, ["NetworkedSectors"], 0] call zen_context_menu_fnc_addAction;

_action = ["ToggleNetworkRender", "Toggle Network Rendering", ["", [1,1,1,1]], _toggleNetworkRendering, { true }] call zen_context_menu_fnc_createAction;
[_action, ["NetworkedSectors"], 0] call zen_context_menu_fnc_addAction;

_action = ["ToggleNetworkLinkRender", "Toggle Network Links Rendering", ["", [1,1,1,1]], _toggleNetworkLinkRendering, { true }] call zen_context_menu_fnc_createAction;
[_action, ["NetworkedSectors"], 0] call zen_context_menu_fnc_addAction;

_action = ["ToggleNetworkInDepthLinkRender", "Toggle In-Depth Link Rendering", ["", [1,1,1,1]], _toggleNetworkLinkInDepthRendering, { true }] call zen_context_menu_fnc_createAction;
[_action, ["NetworkedSectors"], 0] call zen_context_menu_fnc_addAction;




