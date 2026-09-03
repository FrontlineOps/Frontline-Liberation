if (hasInterface) then {
	private _logisticsSpawnMarkers = allMapMarkers select {
		_x find "logistics_spawn" == 0
	};
	{
		_x setMarkerAlphaLocal 0;
	} forEach _logisticsSpawnMarkers;
	[format ["Hid %1 logistics entry markers locally", count _logisticsSpawnMarkers], "BATTLESPACE"] call KPLIB_fnc_log;
};

[] call compileFinal preprocessFileLineNumbers "modules\battlespace_ai\config.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\battlespace_ai\networked_sectors\index.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\battlespace_ai\sams\index.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\battlespace_ai\defenders\index.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\battlespace_ai\artillery\index.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\battlespace_ai\task_forces\index.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\battlespace_ai\logistics\index.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\battlespace_ai\battlegroup\index.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\battlespace_ai\tactical\index.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\battlespace_ai\airborne_reinforcement\index.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\battlespace_ai\air_response\index.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\battlespace_ai\fortifications\index.sqf";

if (!isNil { BATTLESPACE_LOCAL_TESTING }) then {
	KPLIB_fnc_addObjectInit = {};
	// Depth and Length in actuality adds up to 2x the listed value
	// Length / Depth should be a multiple of the Gap
	BATTLESPACE_AT_MINE_LENGTH = 50;
	BATTLESPACE_AT_MINE_DEPTH = 20;
	BATTLESPACE_AT_MINE_GAP = 10;

	BATTLESPACE_AP_MINE_LENGTH = 96;
	BATTLESPACE_AP_MINE_DEPTH = 40;
	BATTLESPACE_AP_MINE_GAP = 8;
	air_weight = 0;
	infantry_weight = 0;
	armor_weight = 0;
	combat_readiness = 0;
	BATTLESPACE_UNIT_CAP = 200;
	GRLIB_side_enemy = east;
	GRLIB_side_friendly = west;
	GRLIB_side_guerilla = resistance;
	GRLIB_side_civilian = civilian;

	sectors_allSectors = [];
	sectors_bigtown = [];
	sectors_capture = [];
	sectors_factory = [];
	sectors_military = [];
	sectors_opfor = [];
	sectors_tower = [];

	civilians = [
		"UK3CB_ADC_C_CIV_ISL_01", 
		"UK3CB_ADC_C_HUNTER_CHR", 
		"UK3CB_ADC_C_CIT", 
		"UK3CB_ADC_C_WOOD", 
		"UK3CB_ADC_C_DOC_ISL", 
		"UK3CB_ADC_C_LABOURER_ISL", 
		"UK3CB_ADC_C_CIV_ISL", 
		"UK3CB_ADC_C_SPOT_ISL", 
		"UK3CB_TKC_C_CIV", 
		"UK3CB_TKC_C_SPOT", 
		"UK3CB_TKC_C_WORKER"
	];

	civilians_lower = civilian apply {toLower _x};


	{
		switch (true) do {
			case (_x find "bigtown" == 0): {sectors_bigtown pushBack _x; sectors_allSectors pushBack _x;};
			case (_x find "capture" == 0): {sectors_capture pushBack _x; sectors_allSectors pushBack _x;};
			case (_x find "factory" == 0): {sectors_factory pushBack _x; sectors_allSectors pushBack _x;};
			case (_x find "military" == 0): {sectors_military pushBack _x; sectors_allSectors pushBack _x;};
			case (_x find "opfor_point" == 0): {sectors_opfor pushBack _x;};
			case (_x find "tower" == 0): {sectors_tower pushBack _x; if (isServer) then {_x setMarkerText format ["%1 %2",markerText _x, mapGridPosition (markerPos _x)];}; sectors_allSectors pushBack _x;};
		};
	} forEach allMapMarkers;


	blufor_sectors = ["startbase_marker", "capture_2"];

	sector_to_blufor = createHashMap;

	{
		sector_to_blufor set [_x, true];
	} forEach blufor_sectors;
};
// Live strategic layer:
// - Every current sector has a finite server-owned resource stockpile.
// - Threshold-driven transfers use interceptable Convoy task forces.
// - Resource-backed military-sector attacks use Battlegroup task forces.
// - OPFOR objectives spend construction stock on persistent defensive sites.
// - The strategic decision interval is configured in kp_liberation_config.sqf.
//
// Tactical defenders, airborne/air responses, artillery/SAM expenditure, and
// ZEN diagnostics consume the same server-owned stockpiles.
