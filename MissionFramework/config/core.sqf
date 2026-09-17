/* Frontline authored core data and internal constants.
   Admin-facing options are registered in modules/settings/sections.
   Original mission configuration: https://github.com/KillahPotatoes/KP-Liberation */

KPLIB_roleAuditInterval = 1;

KPLIB_roleAuditBatchSize = 8;

GRLIB_save_key = "KP_LIBERATION_" + (toUpper worldName) + "_SAVEGAME";

KPLIB_permissions_save_key = GRLIB_save_key + "_PLAYER_PERMISSIONS";

KPLIB_COPS_SAVE_KEY = GRLIB_save_key + "_COPS";

DEBUG_PLAYER_COUNT_OVERRIDE = -1;

KPLIB_guidance_seeker_interval = 0.1;

KPLIB_guidance_search_interval = 0.5;

KPLIB_guidance_candidates_per_scan = 24;

KPLIB_guidance_max_countermeasures = 512;

KPLIB_guidance_track_memory = 1.5;

KPLIB_guidance_reacquire_time = 6;

KPLIB_guidance_max_step = 0.05;

KPLIB_guidance_overrides = [];

KPLIB_munitions_blast_gain = 0.08;

KPLIB_munitions_blast_max_radius = 120;

KPLIB_munitions_blast_cells = 256;

KPLIB_munitions_blast_cells_per_tick = 12;

KPLIB_munitions_thermal_duration = 2;

KPLIB_munitions_gas_radius = 24;

KPLIB_munitions_gas_cell = 2;

KPLIB_munitions_gas_grid_max = 11;

KPLIB_munitions_gas_energy_per_hit = 2000;

KPLIB_munitions_gas_damage_gain = 1;

KP_liberation_sector_monitor_pass_interval = 1;

KP_liberation_resource_reconcile_interval = 15;

KP_liberation_aircraft_count_refresh_interval = 5;

KP_liberation_state_sync_poll_interval = 1;

KP_liberation_zeus_sync_interval = 15;

KP_liberation_zeus_sync_batch_interval = 0.2;

KP_liberation_client_state_refresh_interval = 2;

KP_liberation_client_action_refresh_interval = 5;

KP_liberation_client_marker_refresh_interval = 10;

GRLIB_side_friendly = WEST;

GRLIB_side_enemy = EAST;

GRLIB_side_resistance = RESISTANCE;

GRLIB_side_civilian = CIVILIAN;

GRLIB_respawn_marker = "respawn";

GRLIB_color_friendly = "ColorBLUFOR";

GRLIB_color_enemy = "ColorOPFOR";

GRLIB_color_enemy_bright = "ColorRED";

KPLIB_intelligence_reconcile_interval = 2;

KPLIB_trashCleanup_interval = 5;

GRLIB_endgame = 0;
