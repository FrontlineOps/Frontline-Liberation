[] call compileFinal preprocessFileLineNumbers "scripts\client\misc\init_markers.sqf";

if (typeOf player == "VirtualSpectator_F") exitWith {
    execVM "scripts\client\markers\empty_vehicles_marker.sqf";
    execVM "scripts\client\markers\fob_markers.sqf";
    execVM "scripts\client\markers\group_icons.sqf";
    execVM "scripts\client\markers\hostile_groups.sqf";
    execVM "scripts\client\markers\sector_manager.sqf";
    execVM "scripts\client\markers\spot_timer.sqf";
    execVM "scripts\client\misc\synchronise_vars.sqf";
    execVM "scripts\client\ui\ui_manager.sqf";
};

// This causes the script error with not defined variable _display in File A3\functions_f_bootcamp\Inventory\fn_arsenal.sqf [BIS_fnc_arsenal], line 2122
// ["Preload"] call BIS_fnc_arsenal;
spawn_camera = compileFinal preprocessFileLineNumbers "scripts\client\spawn\spawn_camera.sqf";
cinematic_camera = compileFinal preprocessFileLineNumbers "scripts\client\ui\cinematic_camera.sqf";
write_credit_line = compileFinal preprocessFileLineNumbers "scripts\client\ui\write_credit_line.sqf";
do_load_box = compileFinal preprocessFileLineNumbers "scripts\client\ammoboxes\do_load_box.sqf";
kp_fuel_consumption = compileFinal preprocessFileLineNumbers "scripts\client\misc\kp_fuel_consumption.sqf";

[] call KPLIB_INTEL_CLIENT_INIT;
[] call KPLIB_COPS_CLIENT_INIT;
execVM "scripts\client\actions\recycle_manager.sqf";

_role = [player] call RoleArsenal_DetermineRole;
if (_role in ["OgreTL", "CE"]) then {
    execVM "scripts\client\actions\unflip_manager.sqf";
};

execVM "scripts\client\ammoboxes\ammobox_action_manager.sqf";
execVM "scripts\client\build\build_overlay.sqf";
execVM "scripts\client\build\do_build.sqf";
if (side player != GRLIB_side_enemy) then {
    if (KP_liberation_mapmarkers) then {execVM "scripts\client\markers\empty_vehicles_marker.sqf";};
};
execVM "scripts\client\markers\fob_markers.sqf";
if (!KP_liberation_high_command && KP_liberation_mapmarkers) then {execVM "scripts\client\markers\group_icons.sqf";};
execVM "scripts\client\markers\hostile_groups.sqf";
if (KP_liberation_mapmarkers) then {execVM "scripts\client\markers\huron_marker.sqf";} else {deleteMarkerLocal "huronmarker"};
execVM "scripts\client\markers\sector_manager.sqf";
execVM "scripts\client\markers\spot_timer.sqf";
execVM "scripts\client\misc\broadcast_squad_colors.sqf";
execVM "scripts\client\misc\init_arsenal.sqf";
if (!KP_liberation_ace) then {execVM "scripts\client\misc\resupply_manager.sqf";};
execVM "scripts\client\misc\synchronise_vars.sqf";
execVM "scripts\client\misc\synchronise_eco.sqf";
execVM "scripts\client\misc\playerNamespace.sqf";
execVM "scripts\client\spawn\redeploy_manager.sqf";
execVM "scripts\client\ui\ui_manager.sqf";
execVM "scripts\client\ui\tutorial_manager.sqf";
execVM "scripts\client\markers\update_production_sites.sqf";
execVM "scripts\client\misc\restrict_gamma.sqf";

player addMPEventHandler ["MPKilled", {_this spawn kill_manager;}];
["KPLIB_PLAYER_GET_IN", "GetInMan", {
    private _vehicle = _this select 2;
    [_vehicle] spawn kp_fuel_consumption;
    [_vehicle] call KPLIB_fnc_setVehicleSeized;
    [_vehicle] call KPLIB_fnc_setVehicleCaptured;
}] call CBA_fnc_addBISPlayerEventHandler;
["KPLIB_PLAYER_RATING", "HandleRating", {if ((_this select 1) < 0) then {0};}] call CBA_fnc_addBISPlayerEventHandler;

// Disable stamina, if selected in parameter
if (!GRLIB_fatigue) then {
    player enableStamina false;
    ["KPLIB_PLAYER_STAMINA", "Respawn", {player enableStamina false;}] call CBA_fnc_addBISPlayerEventHandler;
};

// Reduce aim precision coefficient, if selected in parameter
if (!KPLIB_sway) then {
    player setCustomAimCoef 0.1;
    ["KPLIB_PLAYER_SWAY", "Respawn", {player setCustomAimCoef 0.1;}] call CBA_fnc_addBISPlayerEventHandler;
};

execVM "scripts\client\ui\intro.sqf";

// Commander init
if (player isEqualTo ([] call KPLIB_fnc_getCommander)) then {
    // Request Zeus if enabled
    if (KP_liberation_commander_zeus) then {
        [] spawn {
            sleep 5;
            [] call KPLIB_fnc_requestZeus;
        };
    };
};

// ENFORCED ARSENAL //

// GRAB OUR GLOBAL BYPASS VARIABLE FOR ENFORCED ARSENAL FROM SERVER, INITIALLY.
BYPASS_ENFORCED_ARSENAL = [missionNamespace, "BYPASS_ENFORCED_ARSENAL", false] call BIS_fnc_getServerVariable;

// Faction arsenal rules apply equally to all players.
execVM "scripts\client\misc\enforced_arsenal.sqf";
