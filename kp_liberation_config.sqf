// https://github.com/KillahPotatoes/KP-Liberation

/* Automatic factions (required)

    Select one or more CfgFactionClasses classnames per side. Multiple entries
    merge split factions (useful for mods which separate infantry and vehicles).

    All four selections are mandatory. Invalid, wrong-side, empty, or sparse
    selections stop preset initialization instead of loading legacy faction data.
*/
KP_liberation_autoFaction_blufor = ["CUP_B_US_Army"];
KP_liberation_autoFaction_opfor = ["CUP_O_RU"];
KP_liberation_autoFaction_resistance = ["CUP_I_NAPA"];
KP_liberation_autoFaction_civilians = ["CUP_C_RU"];

// Include loaded compatibility equipment in the generated restricted arsenal.
KP_liberation_autoFaction_includeAceMedical = true;
KP_liberation_autoFaction_includeAceTools = true;
KP_liberation_autoFaction_includeTfarRadios = true;
KP_liberation_autoFaction_arsenalExtraItems = [];
KP_liberation_autoFaction_arsenalBlacklist = [];

// Limit generated faction ammunition boxes in the squad resupply menu. A value
// below 1 disables the cap.
KP_liberation_autoFaction_resupplyCrateLimit = 16;

// Baseline build costs [supplies, ammunition, fuel]. Vehicle config cost and
// threat apply a bounded multiplier; all results are rounded to steps of 25.
KP_liberation_autoFaction_priceDefaults = createHashMapFromArray [
    ["infantry",       [25,   0,   0]],
    ["light",          [75,  25,  50]],
    ["recon",         [100,  50,  75]],
    ["medical",       [100,   0,  75]],
    ["groundLogistics",[125,  0, 125]],
    ["artillery",     [500, 600, 150]],
    ["atgm",          [300, 350, 100]],
    ["aa",            [500, 600, 150]],
    ["heavy",         [700, 750, 250]],
    ["rotaryLogistics",[350,  0, 300]],
    ["rotaryCas",     [650, 700, 400]],
    ["fixedWing",    [1000,1000, 500]],
    ["static",        [125, 150,   0]]
];

// Idle fuel consumption (min)
KP_liberation_fuel_neutral = 180;

// Normal speed (w) fuel consumption (min)
KP_liberation_fuel_normal = 90;

// Max speed (shift+w) fuel consumption (min)
KP_liberation_fuel_max = 45;

// Name of the savegame namespace inside of the [ServerProfileName].vars.Arma3Profile file
GRLIB_save_key = "KP_LIBERATION_" + (toUpper worldName) + "_SAVEGAME";

// Used to simulate a different role for quickly testing the role arsenal
// Note this changes the role of EVERY player on the server so should be cleared when done.
DEBUG_ARSENAL_ROLE_OVERRIDE = "";

// Used for development to simulate a different player count for e.g. battlespace AI spawns
DEBUG_PLAYER_COUNT_OVERRIDE = -1;

// 10 default
BATTLESPACE_UNIT_CAP = 200;

// Depth and Length in actuality adds up to 2x the listed value
// Length / Depth should be a multiple of the Gap
BATTLESPACE_AT_MINE_LENGTH = 50;
BATTLESPACE_AT_MINE_DEPTH = 20;
BATTLESPACE_AT_MINE_GAP = 10;

BATTLESPACE_AP_MINE_LENGTH = 96;
BATTLESPACE_AP_MINE_DEPTH = 40;
BATTLESPACE_AP_MINE_GAP = 8;

// How far a given unit will proc (materialise) from active players
// For how units spawn around a point, see battlespace_ai\defenders\index.sqf
//
// Distance from the current average position of a cluster where a blufor player will be added to the cluster
BLUFOR_CLUSTER_DISTANCE = 200;
// NOTE: Make sure to update GRLIB_sector_size too, that's how far away the sector
// will activate at all to start spawning virtual groups (doesn't despawn until restart)
BATTLESPACE_UNIT_PROC_RANGE = 1175;
BATTLESPACE_MINEFIELD_PROC_RANGE = 1125;
BATTLESPACE_AA_PROC_RANGE = 2500;
BATTLESPACE_AIR_PROC_RANGE = 1500; // How far e.g. CAS defenders will spawn

// How many units should be in each OPFOR squad
BATTLESPACE_SQUAD_SIZE = 7;

// Server-owned hybrid routing for virtual and materialized Battlespace forces.
// Ground vehicles use an A* road trunk with terrain-grid A* connectors; infantry
// uses the terrain grid, while all-air forces retain direct flight routing.
BATTLESPACE_PATHFIND_GRID_SIZE = 100;
BATTLESPACE_PATHFIND_ROAD_SNAP = 900;
BATTLESPACE_PATHFIND_WEIGHT = 1.12;
BATTLESPACE_PATHFIND_EXPANSIONS_PER_TICK = 120;
BATTLESPACE_PATHFIND_WORKER_INTERVAL = 0.1;
BATTLESPACE_PATHFIND_MAX_EXPANSIONS = 12000;
BATTLESPACE_PATHFIND_ROAD_MAX_EXPANSIONS = 20000;
BATTLESPACE_PATHFIND_CACHE_TTL = 300;
BATTLESPACE_PATHFIND_CACHE_LIMIT = 128;
BATTLESPACE_PATHFIND_TERRAIN_CACHE_LIMIT = 24000;
BATTLESPACE_PATHFIND_THREAT_RADIUS = 1600;
BATTLESPACE_PATHFIND_FINAL_APPROACH_RADIUS = 600;
BATTLESPACE_PATHFIND_CONGESTION_MULTIPLIER = 1.2;
BATTLESPACE_PATHFIND_VEHICLE_MAX_SLOPE = 0.45;
BATTLESPACE_PATHFIND_INFANTRY_MAX_SLOPE = 1.0;
// Maximum real route nodes sent per task force to an authorized ZEN curator.
BATTLESPACE_ZEN_ROUTE_SNAPSHOT_POINT_LIMIT = 1024;

// Resource-backed OPFOR strategic logistics and operational battlegroups.
BATTLESPACE_STRATEGIC_ENABLED = true;
BATTLESPACE_STRATEGIC_INITIAL_STOCK_RATIO = 0.75;
BATTLESPACE_STRATEGIC_INITIAL_DELAY = 300;
BATTLESPACE_STRATEGIC_DECISION_INTERVAL = 1800;
BATTLESPACE_STRATEGIC_SAVE_INTERVAL = 300;
BATTLESPACE_STRATEGIC_MAX_ACTIVE_CONVOYS = 3;
BATTLESPACE_STRATEGIC_MAX_ACTIVE_BATTLEGROUPS = 2;
BATTLESPACE_STRATEGIC_MAX_CONVOYS_PER_TICK = 2;
BATTLESPACE_STRATEGIC_MAX_BATTLEGROUPS_PER_TICK = 1;
BATTLESPACE_STRATEGIC_RESUPPLY_COOLDOWN = 1800;
BATTLESPACE_STRATEGIC_BATTLEGROUP_COOLDOWN = 3600;
BATTLESPACE_STRATEGIC_RETREAT_STRENGTH_RATIO = 0.35;
BATTLESPACE_STRATEGIC_BATTLEGROUP_MANPOWER = 28;
BATTLESPACE_STRATEGIC_CONVOY_MANPOWER = 8;
BATTLESPACE_STRATEGIC_CONVOY_TRUCKS = 2;
BATTLESPACE_TASK_FORCES_PERSISTENT = true;
BATTLESPACE_STRATEGIC_CASUALTY_RESPONSE_THRESHOLD = 8;
BATTLESPACE_STRATEGIC_EMERGENCY_COOLDOWN = 900;
BATTLESPACE_STRATEGIC_REINFORCEMENT_COOLDOWN = 1200;
BATTLESPACE_STRATEGIC_REINFORCEMENT_MANPOWER = 14;
BATTLESPACE_STRATEGIC_MAX_ACTIVE_REINFORCEMENTS = 3;
BATTLESPACE_STRATEGIC_MAX_ACTIVE_AIRBORNE_TRANSPORTS = 2;
BATTLESPACE_STRATEGIC_AIRBORNE_MAX_RANGE = 20000;
BATTLESPACE_STRATEGIC_AIRBORNE_MIN_MANPOWER = 4;
BATTLESPACE_STRATEGIC_AIRBORNE_DROP_RADIUS = 600;
BATTLESPACE_STRATEGIC_AIRBORNE_RETURN_RADIUS = 500;
BATTLESPACE_STRATEGIC_AIRBORNE_FLIGHT_HEIGHT = 300;
BATTLESPACE_STRATEGIC_AIRBORNE_DEPLOYMENT_DURATION = 900;
BATTLESPACE_STRATEGIC_MAX_ACTIVE_PATROLS = 8;
BATTLESPACE_STRATEGIC_PATROL_MANPOWER = 7;
BATTLESPACE_STRATEGIC_PATROL_COOLDOWN = 2400;
BATTLESPACE_STRATEGIC_PATROL_DURATION = 1200;
BATTLESPACE_STRATEGIC_PATROL_FORWARD_RATIOS = [0.35, 0.60];
BATTLESPACE_STRATEGIC_PATROL_REAR_SCREEN_RANGE = [150, 350];
BATTLESPACE_STRATEGIC_PATROL_LATERAL_OFFSET = 250;
BATTLESPACE_STRATEGIC_PATROL_BLUFOR_STANDOFF = 350;
BATTLESPACE_STRATEGIC_AIR_RESPONSE_INITIAL_DELAY = 600;
BATTLESPACE_STRATEGIC_AIR_RESPONSE_DECISION_INTERVAL = 60;
BATTLESPACE_STRATEGIC_MAX_ACTIVE_AIR_RESPONSES = 2;
BATTLESPACE_STRATEGIC_MAX_AIR_RESPONSES_PER_TICK = 1;
BATTLESPACE_STRATEGIC_AIR_RESPONSE_COOLDOWN = 1800;
BATTLESPACE_STRATEGIC_AIR_RESPONSE_MIN_AGGRESSIVITY = 0.9;
BATTLESPACE_STRATEGIC_AIR_RESPONSE_MIN_READINESS = 70;
BATTLESPACE_STRATEGIC_AIR_RESPONSE_MIN_WEIGHT = 50;
BATTLESPACE_STRATEGIC_AIR_RESPONSE_MAX_RANGE = 18000;
BATTLESPACE_STRATEGIC_AIR_RESPONSE_MIN_SEPARATION = 3000;
BATTLESPACE_STRATEGIC_AIR_RESPONSE_REACQUIRE_RANGE = 4000;
BATTLESPACE_STRATEGIC_AIR_RESPONSE_CONTACT_GRACE = 120;
BATTLESPACE_STRATEGIC_AIR_RESPONSE_ON_STATION_DURATION = 900;
BATTLESPACE_STRATEGIC_AIR_RESPONSE_MAX_LIFETIME = 1800;
BATTLESPACE_STRATEGIC_AIR_RESPONSE_ARRIVAL_RADIUS = 600;
BATTLESPACE_STRATEGIC_AIR_RESPONSE_RETARGET_DISTANCE = 500;
BATTLESPACE_STRATEGIC_AIR_RESPONSE_ORBIT_RADIUS = 1200;
BATTLESPACE_STRATEGIC_MAX_ACTIVE_FORTIFICATIONS = 48;
BATTLESPACE_STRATEGIC_MAX_FORTIFICATIONS_PER_SECTOR = 3;
BATTLESPACE_STRATEGIC_MAX_FORTIFICATIONS_PER_TICK = 2;
BATTLESPACE_STRATEGIC_FORTIFICATION_COOLDOWN = 1800;
BATTLESPACE_STRATEGIC_FORTIFICATION_COSTS = [4, 7, 12];
BATTLESPACE_STRATEGIC_FORTIFICATION_MANPOWER_BY_TIER = [4, 5, 7];
BATTLESPACE_ARTILLERY_CREW_PER_PIECE = 3;
BATTLESPACE_SAM_STRATEGIC_MISSILES_PER_LAUNCHER = 8;
BATTLESPACE_SAM_TACTICAL_MISSILES_PER_LAUNCHER = 4;
BATTLESPACE_SAM_RELOAD_BATCH = 4;

KP_liberation_save_interval = 60;            			// Save interval (sec)

// Behavior-preserving scheduler tuning.
KP_liberation_sector_monitor_pass_interval = 1;
KP_liberation_sector_monitor_sector_yield = 0.01;
KP_liberation_high_command_refresh_interval = 2;
KP_liberation_resource_reconcile_interval = 15;
KP_liberation_unit_cap_refresh_interval = 5;
KP_liberation_state_sync_poll_interval = 1;
KP_liberation_zeus_sync_interval = 15;
KP_liberation_client_state_refresh_interval = 2;
KP_liberation_client_action_refresh_interval = 5;
KP_liberation_client_marker_refresh_interval = 10;
KP_liberation_runtime_diagnostics = false;
KP_liberation_admin_log_limit = 250;

GRLIB_side_friendly = WEST;                  			// Friendly side
GRLIB_side_enemy = EAST;                     			// Enemy side
GRLIB_side_resistance = RESISTANCE;          			// Guerilla side
GRLIB_side_civilian = CIVILIAN;              			// Civilian side
GRLIB_respawn_marker = "respawn";            			// Respawn marker name

GRLIB_color_friendly = "ColorBLUFOR";        			// Friendly sector color
GRLIB_color_enemy = "ColorOPFOR";            			// Enemy sector color
GRLIB_color_enemy_bright = "ColorRED";       			// Enemy active sector color

GRLIB_fob_range = 300;                       			// FOB building range
GRLIB_halo_altitude = 0;                     			// HALO jump altitude
GRLIB_recycling_percentage = 0.6;            			// Recycling return
KP_liberation_production_interval = 120;      			// Resource production time (min), when resources multiplier set to 1
KP_liberation_allow_fob_vehcile_building = false;		// Allow building vehicles at FOBs
KP_liberation_allow_fixedwing_at_fobs = false;			// Allow fixed wing aircraft to be built at FOBs (Only applicable if KP_liberation_allow_fob_vehcile_building is false)

// Player intelligence network. All observations are generated and sanitized by the server.
KPLIB_intelligence_enabled = true;
KPLIB_intelligence_tier_costs = [10, 25, 45];            // Activity, tracking, identification
KPLIB_intelligence_coverage_duration = 1800;             // Seconds per activation or renewal
KPLIB_intelligence_max_frontline_depth = 2;              // OPFOR regions available for analysis
KPLIB_intelligence_region_hops = 1;                      // Linked sectors covered around the selected region
KPLIB_intelligence_reconcile_interval = 15;              // Server observation pass cadence
KPLIB_intelligence_refresh_intervals = [180, 90, 30];    // Observation age by tier
KPLIB_intelligence_uncertainty_radii = [1200, 600, 200]; // Position uncertainty by tier
KPLIB_intelligence_strength_bands = [12, 30];            // Moderate and heavy weighted-strength thresholds
KPLIB_intelligence_vehicle_strength_weight = 4;
KPLIB_intelligence_max_reports = 40;
KPLIB_intelligence_max_reports_per_region = 10;
KPLIB_intelligence_route_point_limit = 12;
KPLIB_intelligence_terminal_distance = 75;
KPLIB_intelligence_interaction_distance = 4;
KPLIB_intelligence_delivery_distance = 40;
KPLIB_intelligence_document_yield = [8, 15];
KPLIB_intelligence_prisoner_yield_militia = [3, 6];
KPLIB_intelligence_prisoner_yield_opfor = [6, 12];
KPLIB_intelligence_operation_kinds = [
    "CONVOY",
    "BATTLEGROUP",
    "PATROL",
    "REINFORCEMENT",
    "AIR_RESPONSE",
    "AIRBORNE_TRANSPORT",
    "AIRBORNE_REINFORCEMENT",
    "FORTIFICATION"
];

GRLIB_sector_size = 3000;                    			// Sector activation range
GRLIB_capture_size = 225;                    			// Sector cap circle size
GRLIB_defended_buildingpos_part = 0.7;       			// Multiplier for defenders in buildings
GRLIB_battlegroup_size = 4;                  			// Battlegroup size
GRLIB_vulnerability_timer = 840;             			// OPFOR sector cap timer (sec)
GRLIB_radiotower_size = 2500;                			// Radio tower range
GRLIB_surrender_chance = 60;                 			// Surrender after heavy losses chance

GRLIB_cleanup_delay = 250;                   			// Corpse cleanup time (sec)

GRLIB_blufor_cap = 171;                      			// Cap for BLUFOR
GRLIB_sector_cap = 480;     			// Cap for sector defenders

KP_liberation_cr_kill_penalty = 25;          			// Civrep civilian kill penalty
KP_liberation_cr_building_penalty = 15;      			// Civrep destroy/damage penatly
KP_liberation_cr_vehicle_penalty = 7;        			// Civrep stolen vehicle penalty
KP_liberation_cr_resistance_penalty = 15;    			// Civrep friendly guerilla kill penalty
KP_liberation_cr_sector_gain = 5;           			// Civrep sector capture gain
KP_liberation_cr_wounded_chance = 15;        			// Wounded civ chance
KP_liberation_cr_wounded_gain = 3;           			// Wounded civ healed civrep gain

KP_liberation_civinfo_min = 5400;            			// Civ informant min spawn time (sec)
KP_liberation_civinfo_max = 10800;           			// Civ informant max spawn time (sec)
KP_liberation_civinfo_chance = 75;           			// Civ informant spawn chance
KP_liberation_civinfo_intel = 15;             			// Civ informant intel amount
KP_liberation_civinfo_duration = 1200;       			// Civ informant despawn timer (sec)

KP_liberation_convoy_ambush_chance = 0;      			// AI logistics (unused)
KP_liberation_convoy_ambush_duration = 0; 				// AI logistics (unused)

KP_liberation_resistance_tier2 = 30;         			// Guerilla strength at tier 2
KP_liberation_resistance_tier3 = 70;         			// Guerilla strength at tier 3
KP_liberation_resistance_at_chance = 50;     			// RPG chance (tier 2 and 3)
KP_liberation_resistance_sector_chance = 75; 			// Guerilla chance to join ongoing attack
KP_liberation_resistance_ambush_chance = 80; 			// Guerilla spawn in BLUFOR sectors at low civrep

KP_liberation_sector_resource_chance = 40;   			// BLUFOR sector random resources chance on capping civvie sector

// Remove terrain objects around battlegroup spawns
KP_liberation_battlegroup_clearance = [];

// Commandant actions access regardless of slot
// NOTE: Remember to update enableDebugConsole in description.ext!! And on Training Server description.ext + map composition
KP_liberation_commander_actions = [
    "76561198343484805",         // Azraeel
	"76561198874160679"          // Felix
];

KP_liberation_medical_vehicles = [
	// Prairie Fire
	//
	"UK3CB_LDF_O_SUV_Armoured",// (LDF)Lavonein Defense Force) OPFOR medvic
    "vtx_HH60",
    "rhsusf_m113d_usarmy_medical",
    "CUP_B_nM997_USA_DES"
];

KP_liberation_medical_facilities = [
	// Prairie Fire
	//
    "US_WarfareBFieldhHospital_Base_EP1",
	"rhsusf_M1085A1P2_B_D_Medical_fmtv_usarmy", // CSBD Truck
	"rhsusf_M1085A1P2_B_WD_Medical_fmtv_usarmy", // CSBD Truck
    "Land_MedicalTent_01_white_generic_outer_F", // Deployable CCP classname
	"vtx_stretcher_3" // New CCP
	
];

KP_liberation_ace_crates = [];

// Whitelist for BI support framework access
KP_liberation_suppMod_whitelist = [
    "76561198343484805",
	"76561198874160679"
];

// Randomly selected radio tower classnames
KPLIB_radioTowerClassnames = [
	"Land_Vysilac_vez",
	"Land_TTowerBig_2_F"
];

// Obsolete arsenal blacklist
blacklisted_from_arsenal = [];

// Obsolete arsenal whitelist
KP_liberation_allowed_items_extension = [];

/* Vehicle resource loading config
	[
		"vehicle",
		distance behind vehicle to unload crate,
		[+right/-left, +forward/-back, +up/-down]
	]
*/
	
KPLIB_transportConfigs = [
    [
		"USAF_C130J_Cargo",
		-9.5,
		[-0.75,	8,		2],
		[0.75,	8,		2],
		[-0.75,	7,		2],
		[0.75,	7,		2],
		[-0.75,	6,		2],
		[0.75,	6,		2],
		[-0.75,	5,		2],
		[0.75,	5,		2],
		[-0.75,	4,		2],
		[0.75,	4,		2],
		[-0.75,	3,		2],
		[0.75,	3,		2],
		[-0.75,	2,		2],
		[0.75,	2,		2],
		[-0.75,	1,		2],
		[0.75,	1,		2],
		[-0.75,	0,		2],
		[0.75,	0,		2],
		[-0.75,	-1,		2],
		[0.75,	-1,		2],
		[-0.75,	-2,		2],
		[0.75,	-2,		2]
	],	// 22 crates
    [
		"USAF_C17",
		-15,
		[-0.75,	14.5,		-0.5],
		[0.75,	14.5,		-0.5],
		[-0.75,	13,			-0.5],
		[0.75,	13,			-0.5],
		[-0.75,	11.5,		-0.5],
		[0.75,	11.5,		-0.5],
		[-0.75,	10,			-0.5],
		[0.75,	10,			-0.5],
		[-0.75,	8.5,		-0.5],
		[0.75,	8.5,		-0.5],
		[-0.75,	7,			-0.5],
		[0.75,	7,			-0.5],
		[-0.75,	5.5,		-0.5],
		[0.75,	5.5,		-0.5],
		[-0.75,	4,			-0.5],
		[0.75,	4,			-0.5],
		[-0.75,	2.5,		-0.5],
		[0.75,	2.5,		-0.5],
		[-0.75,	1,			-0.5],
		[0.75,	1,			-0.5],
		[-0.75,	-0.5,		-0.5],
		[0.75,	-0.5,		-0.5],
		[-0.75,	-2,			-0.5],
		[0.75,	-2,			-0.5],
		[-0.75,	-3.5,		-0.5],
		[0.75,	-3.5,		-0.5],
		[-0.75,	-5,			-0.5],
		[0.75,	-5,			-0.5],
		[-0.75,	14.5,		0.55],
		[0.75,	14.5,		0.55],
		[-0.75,	13,			0.55],
		[0.75,	13,			0.55],
		[-0.75,	11.5,		0.55],
		[0.75,	11.5,		0.55],
		[-0.75,	10,			0.55],
		[0.75,	10,			0.55],
		[-0.75,	8.5,		0.55],
		[0.75,	8.5,		0.55],
		[-0.75,	7,			0.55],
		[0.75,	7,			0.55],
		[-0.75,	5.5,		0.55],
		[0.75,	5.5,		0.55],
		[-0.75,	4,			0.55],
		[0.75,	4,			0.55],
		[-0.75,	2.5,		0.55],
		[0.75,	2.5,		0.55],
		[-0.75,	1,			0.55],
		[0.75,	1,			0.55],
		[-0.75,	-0.5,		0.55],
		[0.75,	-0.5,		0.55],
		[-0.75,	-2,			0.55],
		[0.75,	-2,			0.55],
		[-0.75,	-3.5,		0.55],
		[0.75,	-3.5,		0.55],
		[-0.75,	-5,			0.55],
		[0.75,	-5,			0.55]
	],	// 56 crates
    [
		"RHS_CH_47F_cargo",
		-9,
		[0,		-3.5,		-2],
		[0,		-2.5,		-2],
		[0,		-1.5,		-2],
		[0,		-0.5,		-2],
		[0,		0.5,		-2],
		[0,		1.5,		-2],
		[0,		2.5,		-2],
		[0,		3.5,		-2]
	],	// 8 crates
		["rhsusf_CH53e_USMC_cargo",
	 	-11.0, 
		[0,	2.5,	-3.3], 
		[0,	2.5,	-2.1], 
		[0,	1.0,	-3.3], 
		[0,	1.0,	-2.1], 
		[0,	-0.5,	-3.3], 
		[0,	-0.5,	-2.1], 
		[0,	-0.5,	-3.3], 
		[0,	-0.5,	-2.1], 
		[0,	-2.0,	-3.3], 
		[0,	-2.5,	-2.1]
	 ],
		[
		"rhsusf_M977A4_usarmy_wd",
		-6.5,
		[0.28,	.6,		0.9],
		[-.32,	.6,		0.9],
		[.28,	-.7,	0.9],
		[-.32,	-.7,	0.9],
		[.28,	-2,		0.9],
		[-.32,	-2,		0.9],
		[.28,	-3.3,	0.9],
		[-.32,	-3.3,	0.9]
	],	// 8 crates
		[
		"rhsusf_M977A4_usarmy_d",
		-6.5,
		[0.28,	.6,		0.9],
		[-.32,	.6,		0.9],
		[.28,	-.7,	0.9],
		[-.32,	-.7,	0.9],
		[.28,	-2,		0.9],
		[-.32,	-2,		0.9],
		[.28,	-3.3,	0.9],
		[-.32,	-3.3,	0.9]
	],	// 8 crates
	[
		"rhsusf_M977A4_BKIT_usarmy_wd",
		-6.5,
		[0.28,	.6,		0.9],
		[-.32,	.6,		0.9],
		[.28,	-.7,	0.9],
		[-.32,	-.7,	0.9],
		[.28,	-2,		0.9],
		[-.32,	-2,		0.9],
		[.28,	-3.3,	0.9],
		[-.32,	-3.3,	0.9]
	],	// 8 crates
	[
		"rhsusf_M977A4_BKIT_usarmy_d",
		-6.5,
		[0.28,	.6,		0.9],
		[-.32,	.6,		0.9],
		[.28,	-.7,	0.9],
		[-.32,	-.7,	0.9],
		[.28,	-2,		0.9],
		[-.32,	-2,		0.9],
		[.28,	-3.3,	0.9],
		[-.32,	-3.3,	0.9]
	],	// 8 crates
	[
		"rhsusf_M977A4_BKIT_M2_usarmy_wd",
		-6.5,
		[0.28,	.6,		-0.1],
		[-.32,	.6,		-0.1],
		[.28,	-.7,	-0.1],
		[-.32,	-.7,	-0.1],
		[.28,	-2,		-0.1],
		[-.32,	-2,		-0.1],
		[.28,	-3.3,	-0.1],
		[-.32,	-3.3,	-0.1]
	],	// 8 crates
	[
		"rhsusf_M977A4_BKIT_M2_usarmy_d",
		-6.5,
		[0.28,	.6,		-0.1],
		[-.32,	.6,		-0.1],
		[.28,	-.7,	-0.1],
		[-.32,	-.7,	-0.1],
		[.28,	-2,		-0.1],
		[-.32,	-2,		-0.1],
		[.28,	-3.3,	-0.1],
		[-.32,	-3.3,	-0.1]
	],	// 8 crates
	[
		"rhsusf_M1084A1R_SOV_M2_D_fmtv_socom",
		-6.5,
		[.30,	.6,		0.6],
		[-.42,	.6,		0.6],
		[.37,	-0.8,	0.6],
		[-.42,	-0.8,	0.6],
		[.37,	-2.25,	0.6],
		[-.42,	-2.25,	0.6]
	],
    [
		"rhsusf_M1084A1P2_B_WD_fmtv_usarmy",
		-6.5,
		[.30,	.6,		0.6],
		[-.42,	.6,		0.6],
		[.37,	-0.8,	0.6],
		[-.42,	-0.8,	0.6],
		[.37,	-2.25,	0.6],
		[-.42,	-2.25,	0.6]
	],	// 6 crates
	
	[
		"UK3CB_B_MTVR_Recovery_WDL",
		-6.5,
		[.30,	.6,		0.6],
		[-.42,	.6,		0.6],
		[.37,	-0.8,	0.6],
		[-.42,	-0.8,	0.6],
		[.37,	-2.25,	0.6],
		[-.42,	-2.25,	0.6]
	],	// 6 crates
	[
		"DEGA_V22_Vehicle_B_NATO",
		-6.5,
		[0,	 	  2.3,	1.8],
		[0,		   .6,	1.8],
		[0,	       -1,	1.8],
		[0,		 -2.7,	1.8]
	],	// 4 crates
	[
		"vtx_UH60M_SLICK",
		-9.5,
		[0,		1.2,	-0.7],
		[0,		3,	-0.7]
	]	// 2 crates
];

KPLIB_aiResupplySources = [];
vehicle_repair_sources = [];
vehicle_rearm_sources = [];
vehicle_refuel_sources = [];

// Boat classnames, enables building on water
boats_names = [
	"B_Boat_Transport_01_F",
	"UK3CB_TKA_B_RHIB",
	"UK3CB_TKA_B_RHIB_Gunboat",
	"rhsusf_mkvsoc"
];

KP_liberation_suppMod_artyVeh = [];

// Intel objects
KPLIB_intelObjectClasses = [
    "Land_File1_F",
    "Land_Document_01_F"
];

// Buildings that can spawn intel
KPLIB_intelBuildingClasses = [
	//
    "Land_Cargo_House_V1_F",
    "Land_Cargo_House_V2_F",
    "Land_Cargo_House_V3_F",
    "Land_Cargo_HQ_V1_F",
    "Land_Cargo_HQ_V2_F",
    "Land_Cargo_HQ_V3_F",
    "Land_i_Barracks_V1_dam_F",
    "Land_i_Barracks_V1_F",
    "Land_i_Barracks_V2_dam_F",
    "Land_i_Barracks_V2_F",
    "Land_Medevac_house_V1_F",
    "Land_Medevac_HQ_V1_F",
    "Land_MilOffices_V1_F",
    "Land_Research_house_V1_F",
    "Land_Research_HQ_F",
    "Land_u_Barracks_V2_F"
];

// Large storage area crate config
KP_liberation_large_storage_positions = [
    [-5.59961,3.60938,0.6],
    [-3.99902,3.60938,0.6],
    [-2.39941,3.60938,0.6],
    [-0.799805,3.60938,0.6],
    [0.800781,3.60938,0.6],
    [2.40039,3.60938,0.6],
    [4.00098,3.60938,0.6],
    [5.60059,3.60938,0.6],
    [-5.59961,1.80859,0.6],
    [-3.99902,1.80859,0.6],
    [-2.39941,1.80859,0.6],
    [-0.799805,1.80859,0.6],
    [0.800781,1.80859,0.6],
    [2.40039,1.80859,0.6],
    [4.00098,1.80859,0.6],
    [5.60059,1.80859,0.6],
    [-5.59961,0.00976563,0.6],
    [-3.99902,0.00976563,0.6],
    [-2.39941,0.00976563,0.6],
    [-0.799805,0.00976563,0.6],
    [0.800781,0.00976563,0.6],
    [2.40039,0.00976563,0.6],
    [4.00098,0.00976563,0.6],
    [5.60059,0.00976563,0.6],
    [-5.59961,-1.79102,0.6],
    [-3.99902,-1.79102,0.6],
    [-2.39941,-1.79102,0.6],
    [-0.799805,-1.79102,0.6],
    [0.800781,-1.79102,0.6],
    [2.40039,-1.79102,0.6],
    [4.00098,-1.79102,0.6],
    [5.60059,-1.79102,0.6],
    [-5.59961,-3.58984,0.6],
    [-3.99902,-3.58984,0.6],
    [-2.39941,-3.58984,0.6],
    [-0.799805,-3.58984,0.6],
    [0.800781,-3.58984,0.6],
    [2.40039,-3.58984,0.6],
    [4.00098,-3.58984,0.6],
    [5.60059,-3.58984,0.6]
];	// 40 crates

// Small storage area crate config
KP_liberation_small_storage_positions = [
    [-2.34961,1.80078,0.6],
    [-0.75,1.80078,0.6],
    [0.850586,1.80078,0.6],
    [2.4502,1.80078,0.6],
    [-2.34961,0,0.6],
    [-0.75,0,0.6],
    [0.850586,0,0.6],
    [2.4502,0,0.6],
    [-2.34961,-1.79883,0.6],
    [-0.75,-1.79883,0.6],
    [0.850586,-1.79883,0.6],
    [2.4502,-1.79883,0.6]
];	// 12 crates

// DO NOT CHANGE (unless you know what you are doing)
GRLIB_endgame = 0;
// KP_liberation_production_interval = ceil (KP_liberation_production_interval / GRLIB_resources_multiplier);
GRLIB_battlegroup_size = GRLIB_battlegroup_size * (sqrt GRLIB_unitcap) * (sqrt GRLIB_csat_aggressivity);
GRLIB_blufor_cap = (GRLIB_blufor_cap * GRLIB_unitcap) min 100;
GRLIB_sector_cap = GRLIB_sector_cap * GRLIB_unitcap;
GRLIB_kog_trucks = ["UK3CB_ARD_O_GAZ_Vodnik"];//"vn_o_wheeled_z157_01_vcmf"rhs_ka60_grey
