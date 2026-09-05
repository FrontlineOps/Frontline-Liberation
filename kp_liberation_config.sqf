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

// BLUFOR patrol base (PB).
KPLIB_COPS_MAX = 1;
KPLIB_COPS_MIN_FOB_DISTANCE = 500;
KPLIB_COPS_SECTOR_SEARCH_DISTANCE = 2500;
KPLIB_COPS_MIN_HOSTILE_SECTOR_DISTANCE = 500;
KPLIB_COPS_CONTEST_RADIUS = 300;
KPLIB_COPS_CONTEST_COUNT = 3;
KPLIB_COPS_REDEPLOY_RADIUS = 20;
KPLIB_COPS_REDEPLOY_REFRESH = 1;
KPLIB_COPS_REQUEST_COOLDOWN = 2;
KPLIB_COPS_MARKER_TEXT = "PB";
KPLIB_COPS_MARKER_OFFSET = [-17, 11, 0];
// Admin-managed permission grants use their own server profile record.
KPLIB_permissions_save_key = GRLIB_save_key + "_PLAYER_PERMISSIONS";

KPLIB_COPS_SAVE_KEY = GRLIB_save_key + "_COPS";

// [classname, model-space offset, model-space direction, principal structure]
KPLIB_COPS_COMPOSITION = [
    ["Land_MedicalTent_01_NATO_generic_inner_F", [-16, 11, 0], [1, 0, 0], true],
    ["Flag_Blue_F", [-10, 7, -0.3], [1, 0, 0], false]
];
KPLIB_COPS_FLAG_TEXTURE = "\A3\Data_F\Flags\flag_blue_CO.paa";

// Used to simulate a different role for quickly testing the role arsenal
// Note this changes the role of EVERY player on the server so should be cleared when done.
DEBUG_ARSENAL_ROLE_OVERRIDE = "";

// Used for development to simulate a different player count for e.g. battlespace AI spawns
DEBUG_PLAYER_COUNT_OVERRIDE = -1;

// 10 default
BATTLESPACE_UNIT_CAP = 200;

// Pace physical task-force materialization without changing proc eligibility.
// The manager admits one new force per one-second pass; entity creation yields
// briefly so large forces are distributed across scheduler frames.
BATTLESPACE_TASK_FORCE_SPAWN_MAX_CONCURRENT = 8;
BATTLESPACE_TASK_FORCE_SPAWN_ENTITY_YIELD = 0.01;

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
// Rural routes may cross roads, but do not prefer following them.
BATTLESPACE_PATHFIND_RURAL_ROAD_MULTIPLIER = 2.25;
// Maximum real route nodes sent per task force to an authorized ZEN curator.
BATTLESPACE_ZEN_ROUTE_SNAPSHOT_POINT_LIMIT = 256;

// Resource-backed OPFOR strategic logistics and operational battlegroups.
BATTLESPACE_STRATEGIC_ENABLED = true;
BATTLESPACE_STRATEGIC_INITIAL_STOCK_RATIO = 0.75;
BATTLESPACE_STRATEGIC_INITIAL_DELAY = 300;
BATTLESPACE_STRATEGIC_DECISION_INTERVAL = 1800;
BATTLESPACE_STRATEGIC_SAVE_INTERVAL = 300;
BATTLESPACE_STRATEGIC_MAX_ACTIVE_CONVOYS = 4;
BATTLESPACE_STRATEGIC_MAX_ACTIVE_BATTLEGROUPS = 2;
BATTLESPACE_STRATEGIC_MAX_CONVOYS_PER_TICK = 2; // Shared by front-stock evacuation and normal resupply.
BATTLESPACE_STRATEGIC_MAX_BATTLEGROUPS_PER_TICK = 1;
BATTLESPACE_STRATEGIC_RESUPPLY_COOLDOWN = 1800;
// Once below a resource's Resupply trigger, continue bounded deliveries to this fill ratio.
BATTLESPACE_STRATEGIC_RESUPPLY_TARGET_RATIO = 1.0;
BATTLESPACE_STRATEGIC_BATTLEGROUP_COOLDOWN = 3600;
BATTLESPACE_STRATEGIC_BATTLEGROUP_TARGET_COOLDOWN = [5400, 8100]; // Random cooldown before any origin may attack the same objective again (sec)
BATTLESPACE_STRATEGIC_RETREAT_STRENGTH_RATIO = 0.35;
// Ground offensives retain the Battlegroup save identity. These are finite,
// opportunity-led maneuver forces, not periodic marker-directed attack waves.
// Creation shares BATTLESPACE_STRATEGIC_DEFENDER_DECISION_INTERVAL below.
BATTLESPACE_OFFENSIVE_RETURN_RETRY_INTERVAL = 120;
BATTLESPACE_OFFENSIVE_OBSERVERS_PER_TICK = 8;
BATTLESPACE_OFFENSIVE_CONTACT_MAX_AGE = 180;
BATTLESPACE_OFFENSIVE_RECENT_CAPTURE_WINDOW = 1800;
BATTLESPACE_OFFENSIVE_SOURCE_RESERVE_RATIO = 0.5;
BATTLESPACE_OFFENSIVE_OBSERVE_DURATION = [120, 240];
BATTLESPACE_OFFENSIVE_TOUR_DURATION = 3600;
BATTLESPACE_OFFENSIVE_LEG_TIMEOUT = 600;
BATTLESPACE_OFFENSIVE_MAX_SHIFTS = 3;
BATTLESPACE_OFFENSIVE_MAX_PROBES = 2;
BATTLESPACE_OFFENSIVE_STEP_DISTANCE = 350;
BATTLESPACE_OFFENSIVE_LATERAL_DISTANCE = 300;
BATTLESPACE_OFFENSIVE_ARRIVAL_RADIUS = 100;
BATTLESPACE_OFFENSIVE_TARGET_STANDOFF = 450;
BATTLESPACE_OFFENSIVE_CONTACT_RADIUS = 1200;
BATTLESPACE_OFFENSIVE_RETREAT_RATIO = [0.45, 0.60];
BATTLESPACE_OFFENSIVE_SECURE_DURATION = 600;
// [formation name, infantry, desired vehicle categories]; unsupported vehicles
// fall back to a fully paid infantry force. Weights favor small probing forces.
BATTLESPACE_STRATEGIC_BATTLEGROUP_FORMATIONS = [
    ["INFANTRY", 14, []],
    ["MOTORIZED", 14, ["car"]],
    ["MECHANIZED", 21, ["ifv", "apc"]],
    ["ARMORED", 21, ["tanks", "ifv"]]
];
BATTLESPACE_OFFENSIVE_FORMATION_WEIGHTS = [0.35, 0.35, 0.20, 0.10];
BATTLESPACE_STRATEGIC_CONVOY_MANPOWER = 8;
BATTLESPACE_STRATEGIC_CONVOY_TRUCKS = 2;
BATTLESPACE_STRATEGIC_CONVOY_CRATE_VALUE = 100;
BATTLESPACE_STRATEGIC_CONVOY_APC_CHANCE = 25;
BATTLESPACE_TASK_FORCES_PERSISTENT = true;
BATTLESPACE_STRATEGIC_CASUALTY_RESPONSE_THRESHOLD = 8;
BATTLESPACE_STRATEGIC_DEFENDER_RETREAT_MANPOWER = 3;
BATTLESPACE_STRATEGIC_DEFENDER_RETURN_RADIUS = 100;
BATTLESPACE_STRATEGIC_EMERGENCY_COOLDOWN = 900;
// Uncommitted stock shrinks toward the frontline. Indices are graph depths 0-3+;
// stock stranded above a reduced allowance waits for a finite convoy to move it deeper.
BATTLESPACE_STRATEGIC_FRONT_STOCK_CAPACITY_MULTIPLIERS = [0.25, 0.5, 0.75, 1.0];
// Paid defensive groups are formed in depth and dispatched as persistent task forces.
// Fill frontline strength deficits before rear coverage; ordinary objectives allow one of each role.
BATTLESPACE_STRATEGIC_MAX_ACTIVE_DEFENDERS = 48;
BATTLESPACE_STRATEGIC_MAX_DEFENDERS_PER_TICK = 6;
BATTLESPACE_STRATEGIC_DEFENDER_DECISION_INTERVAL = 600;
// Desired surviving infantry at front depths 0/1/2/3; incoming groups count toward the target.
// Whole groups may exceed a target. Existing forces are never culled to meet it.
BATTLESPACE_STRATEGIC_DEFENDER_MANPOWER_BY_DEPTH = [16, 9, 9, 9];
// [frontline objective type, total manpower target, manpower allowance per role]
// The physical spawner splits larger formations into nine-man squads.
BATTLESPACE_STRATEGIC_DEFENDER_FRONT_FORMATIONS = [
    ["military", 36, 9],
    ["bigtown", 72, 18]
];
BATTLESPACE_STRATEGIC_DEFENDER_QUIET_TIME = 300;
BATTLESPACE_STRATEGIC_DEFENDER_SOURCE_RESERVE_RATIO = 0.4;
BATTLESPACE_STRATEGIC_DEFENDER_ARRIVAL_RADIUS = 100;
BATTLESPACE_STRATEGIC_DEFENSIVE_PATROL_VEHICLE_CHANCE = 0.20; // At most one light vehicle per patrol.
// [purpose, model, manpower, global cap, max target depth, objective types, on-station duration range]
BATTLESPACE_STRATEGIC_DEFENDER_ROLES = [
    ["GARRISON", "Garrison", 9, 16, 3, ["military", "bigtown", "factory", "capture", "tower"], [0, 0]],
    ["DEFENSIVE_PATROL", "Defensive Patrol", 7, 16, 2, ["military", "bigtown", "factory", "capture", "tower"], [2400, 3600]],
    ["RECON_SCREEN", "Reconnaissance Patrol", 7, 10, 1, ["military", "bigtown", "factory", "capture", "tower"], [1800, 3000]],
    ["AMBUSH", "Ambush Patrol", 7, 6, 1, ["military", "bigtown", "factory", "capture", "tower"], [2400, 3600]]
];
// Mobile reserves replace the former casualty-created 14-man/one-vehicle reinforcement.
BATTLESPACE_STRATEGIC_RESERVE_RESPONSE_COOLDOWN = 600;
BATTLESPACE_STRATEGIC_RESERVE_MANPOWER = 14;
BATTLESPACE_STRATEGIC_MAX_ACTIVE_RESERVES = 3;
BATTLESPACE_STRATEGIC_MAX_RESERVES_PER_TICK = 1;
BATTLESPACE_STRATEGIC_RESERVE_MIN_FRONT_DEPTH = 1; // Staging: depth 0 is the frontline itself.
BATTLESPACE_STRATEGIC_RESERVE_MAX_FRONT_DEPTH = 2;
BATTLESPACE_STRATEGIC_RESERVE_SOURCE_RATIO = 0.5;
BATTLESPACE_STRATEGIC_RESERVE_RESPONSE_MAX_HOPS = 5;
BATTLESPACE_STRATEGIC_RESERVE_HOLD_DURATION = 900;
BATTLESPACE_STRATEGIC_RESERVE_MINIMUM_MANPOWER = 8;
BATTLESPACE_STRATEGIC_RESERVE_ARRIVAL_RADIUS = 150;
BATTLESPACE_STRATEGIC_MAX_ACTIVE_AIRBORNE_TRANSPORTS = 2;
BATTLESPACE_STRATEGIC_AIRBORNE_MANPOWER = 14;
BATTLESPACE_STRATEGIC_AIRBORNE_MAX_RANGE = 20000;
BATTLESPACE_STRATEGIC_AIRBORNE_MIN_MANPOWER = 4;
BATTLESPACE_STRATEGIC_AIRBORNE_DROP_RADIUS = 600;
BATTLESPACE_STRATEGIC_AIRBORNE_RETURN_RADIUS = 500;
BATTLESPACE_STRATEGIC_AIRBORNE_FLIGHT_HEIGHT = 300;
BATTLESPACE_STRATEGIC_AIRBORNE_DEPLOYMENT_DURATION = 900;
BATTLESPACE_STRATEGIC_MAX_ACTIVE_DEEP_RECON = 8;
BATTLESPACE_STRATEGIC_DEEP_RECON_MANPOWER = 7;
BATTLESPACE_STRATEGIC_DEEP_RECON_COOLDOWN = 2400;
BATTLESPACE_STRATEGIC_DEEP_RECON_DURATION = [2400, 3600];
BATTLESPACE_STRATEGIC_DEEP_RECON_TARGET_STANDOFF = 350;
BATTLESPACE_STRATEGIC_DEEP_RECON_MAX_STANDOFF = 750;
BATTLESPACE_STRATEGIC_DEEP_RECON_ARC_HALF_ANGLE = 75;
BATTLESPACE_STRATEGIC_DEEP_RECON_MIN_SEPARATION = 450;
BATTLESPACE_STRATEGIC_AIR_RESPONSE_INITIAL_DELAY = 600;
BATTLESPACE_STRATEGIC_AIR_RESPONSE_DECISION_INTERVAL = 60;
BATTLESPACE_STRATEGIC_MAX_ACTIVE_AIR_RESPONSES = 2;
BATTLESPACE_STRATEGIC_MAX_AIR_RESPONSES_PER_TICK = 1;
BATTLESPACE_STRATEGIC_AIR_RESPONSE_COOLDOWN = 1800;
BATTLESPACE_STRATEGIC_AIR_RESPONSE_TARGET_COOLDOWN = 600;
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
// Paid persistent minefields built by quiet OPFOR sectors near the front.
BATTLESPACE_STRATEGIC_MAX_ACTIVE_MINEFIELDS = 68;
BATTLESPACE_STRATEGIC_MAX_MINEFIELDS_PER_SECTOR = 4;
BATTLESPACE_STRATEGIC_MAX_MINEFIELDS_PER_TICK = 1;
BATTLESPACE_STRATEGIC_MINEFIELD_COOLDOWN = 3600;
BATTLESPACE_STRATEGIC_MINEFIELD_CONSTRUCTION_COST = 6;
BATTLESPACE_STRATEGIC_MINEFIELD_MINE_COUNT = 24;
BATTLESPACE_STRATEGIC_MINEFIELD_AT_RATIO = 0.25;
BATTLESPACE_STRATEGIC_MINEFIELD_MAX_FRONT_DEPTH = 1;
BATTLESPACE_STRATEGIC_MINEFIELD_QUIET_TIME = 600;
BATTLESPACE_STRATEGIC_MINEFIELD_PLAYER_EXCLUSION_RADIUS = 2500;
BATTLESPACE_ARTILLERY_CREW_PER_PIECE = 3;
// Artillery observer-network and post-mission timing.
BATTLESPACE_ARTILLERY_POLL_COOLDOWN = 10;
BATTLESPACE_ARTILLERY_MINIMUM_CYCLES_TO_SWAP = 5;
BATTLESPACE_ARTILLERY_MAXIMUM_CYCLES_TO_SWAP = 8; // Exclusive: produces 5-7 cycles.
BATTLESPACE_ARTILLERY_COOLDOWN_PER_SHELL = 30;
BATTLESPACE_ARTILLERY_MIN_COOLDOWN = 60;
BATTLESPACE_ARTILLERY_MAX_COOLDOWN = 120;
BATTLESPACE_ARTILLERY_SMOKE_CHANCE = 0.15; // Probability per observer update; 0 disables smoke requests, 1 always requests smoke.
BATTLESPACE_ARTILLERY_FIRE_ORDER_TIMEOUT = 90; // Seconds allowed for each salvo/ripple to fire before aborting and refunding unfired rounds.
BATTLESPACE_ARTILLERY_TARGET_MOVEMENT_ACCURACY_LOSS_BAND_DISTANCE = 90; // Target movement before 10% of accumulated observer accuracy is lost (m)
BATTLESPACE_ARTILLERY_TARGET_MOVEMENT_ACCURACY_LOSS_DISTANCE = 175; // Target movement before 40% of accumulated observer accuracy is lost (m)
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
KP_liberation_zeus_sync_batch_size = 32;       // Maximum new/removed curator entities processed together
KP_liberation_zeus_sync_batch_interval = 0.2;  // Seconds between curator entity batches
KP_liberation_client_state_refresh_interval = 2;
KP_liberation_client_action_refresh_interval = 5;
KP_liberation_client_marker_refresh_interval = 10;
KP_liberation_runtime_diagnostics = false;

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
KPLIB_intelligence_informant_interval = [5400, 10800];     // Minimum and maximum seconds between contact attempts
KPLIB_intelligence_informant_chance = 75;                 // Spawn chance once a contact attempt is eligible
KPLIB_intelligence_informant_yield = 15;
KPLIB_intelligence_informant_lifetime = 1200;             // Unattended lifetime; pauses while players are nearby
KPLIB_intelligence_informant_pause_distance = 150;
KPLIB_intelligence_informant_min_reputation = 0;          // Neutral or better; current civilian reputation tops out at zero
KPLIB_intelligence_operation_kinds = [
    "CONVOY",
    "BATTLEGROUP",
    "DEFENDER",
    "RESERVE",
    "DEEP RECONNAISSANCE PATROL",
    "REINFORCEMENT",
    "AIR_RESPONSE",
    "AIRBORNE_TRANSPORT",
    "AIRBORNE_REINFORCEMENT",
    "FORTIFICATION"
];

GRLIB_sector_size = 3000;                    			// Sector activation range
GRLIB_capture_size = 225;                    			// Sector cap circle size
GRLIB_defended_buildingpos_part = 0.7;       			// Multiplier for defenders in buildings
GRLIB_vulnerability_timer = 840;             			// OPFOR sector cap timer (sec)
GRLIB_radiotower_size = 2500;                			// Radio tower range
KPLIB_surrender_chance = 40;                 			// Surrender chance after a group breaks or a battle is resolved
KPLIB_surrender_max_prisoners_per_event = 6;			// Maximum prisoners created by one surrender event
KPLIB_surrender_group_survivor_ratio = 0.5;			// Maximum surviving share before a casualty-depleted group may surrender
KPLIB_surrender_player_witness_distance = 500;		// A living BLUFOR player must be this close to a broken group (m)
KPLIB_surrender_escort_break_distance = 150;			// Distance at which an abandoned escorted prisoner escapes (m)

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

KP_liberation_convoy_ambush_chance = 0;      			// AI logistics (unused)
KP_liberation_convoy_ambush_duration = 0; 				// AI logistics (unused)

KP_liberation_resistance_tier2 = 30;         			// Guerilla strength at tier 2
KP_liberation_resistance_tier3 = 70;         			// Guerilla strength at tier 3
KP_liberation_resistance_at_chance = 50;     			// RPG chance (tier 2 and 3)
KP_liberation_resistance_sector_chance = 75; 			// Guerilla chance to join ongoing attack
KP_liberation_resistance_ambush_chance = 80; 			// Guerilla spawn in BLUFOR sectors at low civrep

KP_liberation_sector_resource_chance = 100;  			// BLUFOR sector resource chance on capture
KP_liberation_sector_resource_crate_count = [3, 5];	// Inclusive physical crate count range
KP_liberation_sector_resource_crate_value = 100;		// Base value per crate before resource multiplier

// Remove terrain objects around battlegroup spawns
KP_liberation_battlegroup_clearance = [];


KP_liberation_medical_vehicles = [
	// Prairie Fire
	//
	"UK3CB_LDF_O_SUV_Armoured",// (LDF)Lavonein Defense Force) OPFOR medvic
    "vtx_HH60",
    "rhsusf_m113d_usarmy_medical",
    "CUP_B_nM997_USA_DES"
];

// Deployable field hospital
KPLIB_fieldHospital_classname = "vtx_stretcher_3";
KPLIB_fieldHospital_actionDuration = 15;
KPLIB_fieldHospital_groundTolerance = 0.1;
KPLIB_fieldHospital_repackDistance = 5;

KP_liberation_medical_facilities = [
	// Prairie Fire
	//
    "US_WarfareBFieldhHospital_Base_EP1",
	"rhsusf_M1085A1P2_B_D_Medical_fmtv_usarmy", // CSBD Truck
	"rhsusf_M1085A1P2_B_WD_Medical_fmtv_usarmy", // CSBD Truck
    "Land_MedicalTent_01_white_generic_outer_F", // Deployable CCP classname
	KPLIB_fieldHospital_classname // New CCP
	
];

// Dropped-item cleanup
KPLIB_trashCleanup_lifetime = 240;
KPLIB_trashCleanup_interval = 5;
KPLIB_trashCleanup_batchSize = 25;
KPLIB_trashCleanup_classnames = ["GroundWeaponHolder"];

KP_liberation_ace_crates = [];


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
GRLIB_blufor_cap = (GRLIB_blufor_cap * GRLIB_unitcap) min 100;
GRLIB_sector_cap = GRLIB_sector_cap * GRLIB_unitcap;
GRLIB_kog_trucks = ["UK3CB_ARD_O_GAZ_Vodnik"];//"vn_o_wheeled_z157_01_vcmf"rhs_ka60_grey
