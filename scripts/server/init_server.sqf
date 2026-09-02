// AI
building_defence_ai = compileFinal preprocessFileLineNumbers "scripts\server\ai\building_defence_ai.sqf";

// Game
check_victory_conditions = compileFinal preprocessFileLineNumbers "scripts\server\game\check_victory_conditions.sqf";

// Sector
attack_in_progress_fob = compileFinal preprocessFileLineNumbers "scripts\server\sector\attack_in_progress_fob.sqf";
attack_in_progress_sector = compileFinal preprocessFileLineNumbers "scripts\server\sector\attack_in_progress_sector.sqf";
manage_one_sector = compileFinal preprocessFileLineNumbers "scripts\server\sector\manage_one_sector.sqf";
wait_to_spawn_sector = compileFinal preprocessFileLineNumbers "scripts\server\sector\wait_to_spawn_sector.sqf";

// Autohealer script
[] call compileFinal preprocessFileLineNumbers "scripts\server\base\medical_building.sqf";

// Globals
active_sectors = []; publicVariable "active_sectors";

execVM "scripts\server\base\huron_manager.sqf";
execVM "scripts\server\base\startvehicle_spawn.sqf";
[] call KPLIB_fnc_createSuppModules;
execVM "scripts\server\game\cleanup_vehicles.sqf";
if (!KP_liberation_fog_param) then {execVM "scripts\server\game\fucking_set_fog.sqf";};
execVM "scripts\server\game\manage_time.sqf";
execVM "scripts\server\game\manage_weather.sqf";
execVM "scripts\server\game\playtime.sqf";
execVM "scripts\server\game\save_manager.sqf";
execVM "scripts\server\game\spawn_radio_towers.sqf";
execVM "scripts\server\game\synchronise_vars.sqf";
execVM "scripts\server\game\synchronise_eco.sqf";
execVM "scripts\server\game\zeus_synchro.sqf";
execVM "scripts\server\game\show_fps.sqf";
execVM "scripts\server\resources\manage_resources.sqf";
execVM "scripts\server\resources\recalculate_resources.sqf";
execVM "scripts\server\resources\recalculate_timer.sqf";
execVM "scripts\server\resources\recalculate_timer_sector.sqf";
execVM "scripts\server\resources\unit_cap.sqf";
execVM "scripts\server\sector\lose_sectors.sqf";

KPLIB_fsm_sectorMonitor = [] call KPLIB_fnc_sectorMonitor;
if (KP_liberation_high_command) then {KPLIB_fsm_highcommand = [] call KPLIB_fnc_highcommand;};

// The automatic faction system uses the mission's standard FOB compositions.
KPLIB_fob_templates = [
    "scripts\fob_templates\default\template1.sqf",
    "scripts\fob_templates\default\template2.sqf",
    "scripts\fob_templates\default\template3.sqf",
    "scripts\fob_templates\default\template4.sqf",
    "scripts\fob_templates\default\template5.sqf",
    "scripts\fob_templates\default\template6.sqf",
    "scripts\fob_templates\default\template7.sqf",
    "scripts\fob_templates\default\template8.sqf",
    "scripts\fob_templates\default\template9.sqf",
    "scripts\fob_templates\default\template10.sqf"
];

// Civil Reputation
execVM "scripts\server\civrep\init_module.sqf";

// Civil Informant
execVM "scripts\server\civinformant\init_module.sqf";

// Periodically mark groups for deletion when empty.
execVM "scripts\server\ai\group_cleanup.sqf";

{
    if ((_x != player) && (_x distance (markerPos GRLIB_respawn_marker) < 200 )) then {
        deleteVehicle _x;
    };
} forEach allUnits;

// Server Restart Script from K4s0
if (KP_liberation_restart > 0) then {
    execVM "scripts\server\game\server_restart.sqf";
};
