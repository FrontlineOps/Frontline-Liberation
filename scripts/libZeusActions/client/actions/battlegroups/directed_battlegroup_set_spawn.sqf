
private _statement = {
	params ["_position", "_objects", "_groups", "_waypoints", "_markers", "_hoveredEntity", "_args"];
	_marker = [sectors_allSectors, _position] call BIS_fnc_nearestPosition;
	DIRECTED_BATTLEGROUP_SPAWN = _marker;
	DIRECTED_BATTLEGROUP_ACTUAL_SPAWN = [[2000, 1500] select DIRECTED_BATTLEGROUP_IS_MECHANIZED, [8000, 8000] select DIRECTED_BATTLEGROUP_IS_MECHANIZED, false, markerPos DIRECTED_BATTLEGROUP_SPAWN, false, false] call KPLIB_fnc_getOpforSpawnPoint;
};


private _action = ["DirectedBattlegroupSet", "Set Directed Battlegroup Spawn Point", ["", [1,1,1,1]], _statement, { true }] call zen_context_menu_fnc_createAction;
[_action, ["KarmaLibRoot", "DirectedBattlegroups"], 0] call zen_context_menu_fnc_addAction;

RENDER_BATTLEGROUP_SPAWN_POINT = {
	if(isNull curatorCamera ) exitWith {};

	if(isNil { DIRECTED_BATTLEGROUP_SPAWN }) exitWith {};
	if(isNil { DIRECTED_BATTLEGROUP_ACTUAL_SPAWN }) exitWith {};

	private _distance = (getMarkerPos DIRECTED_BATTLEGROUP_ACTUAL_SPAWN) distance2D (getMarkerPos DIRECTED_BATTLEGROUP_SPAWN);
	drawIcon3D ["\A3\ui_f\data\map\markers\military\flag_CA.paa", [0, 1,0,1], (getMarkerPos DIRECTED_BATTLEGROUP_SPAWN vectorAdd [0,0,100]), 1, 1, 0, format ["DIRECTED BATTLEGROUP SPAWN CENTER"], 1, 0.04, "TahomaB"];
	drawIcon3D ["\A3\ui_f\data\map\markers\military\flag_CA.paa", [1,0,0,1], (getMarkerPos DIRECTED_BATTLEGROUP_ACTUAL_SPAWN vectorAdd [0,0,100]), 1, 1, 0, format ["SPAWN POINT | Distance %1m", _distance], 1, 0.04, "TahomaB"];
	
};

[
	{ _this call RENDER_BATTLEGROUP_SPAWN_POINT },
	0,
	[]
] call CBA_fnc_addPerFrameHandler;
