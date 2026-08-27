[] call compileFinal preprocessFileLineNumbers "scripts\client\misc\init_markers.sqf";

if(roleDescription player find "Odin" > -1) then {
	if (!(getPlayerUID player in KP_liberation_commander_actions)) then 
    {
        ["The Odin slot is reserved for administrators. You will be kicked back to the lobby.", "Restricted Role", "I Understand"] call BIS_fnc_guiMessage;
        endMission "END1"; 
    };
};

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

execVM "scripts\client\actions\intel_manager.sqf";
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
//Remove permissions warning for new perms system.
//execVM "scripts\client\misc\permissions_warning.sqf";
if (!KP_liberation_ace) then {execVM "scripts\client\misc\resupply_manager.sqf";};
execVM "scripts\client\misc\secondary_jip.sqf";
execVM "scripts\client\misc\synchronise_vars.sqf";
execVM "scripts\client\misc\synchronise_eco.sqf";
execVM "scripts\client\misc\playerNamespace.sqf";
execVM "scripts\client\spawn\redeploy_manager.sqf";
execVM "scripts\client\ui\ui_manager.sqf";
execVM "scripts\client\ui\tutorial_manager.sqf";
execVM "scripts\client\markers\update_production_sites.sqf";
execVM "scripts\client\misc\restrict_gamma.sqf";

player addMPEventHandler ["MPKilled", {_this spawn kill_manager;}];
player addEventHandler ["GetInMan", {[_this select 2] spawn kp_fuel_consumption;}];
player addEventHandler ["GetInMan", {[_this select 2] call KPLIB_fnc_setVehicleSeized;}];
player addEventHandler ["GetInMan", {[_this select 2] call KPLIB_fnc_setVehicleCaptured;}];
player addEventHandler ["HandleRating", {if ((_this select 1) < 0) then {0};}];

// Disable stamina, if selected in parameter
if (!GRLIB_fatigue) then {
    player enableStamina false;
    player addEventHandler ["Respawn", {player enableStamina false;}];
};

// Reduce aim precision coefficient, if selected in parameter
if (!KPLIB_sway) then {
    player setCustomAimCoef 0.1;
    player addEventHandler ["Respawn", {player setCustomAimCoef 0.1;}];
};

execVM "scripts\client\ui\intro.sqf";

//--- Spawn them at the OPFOR place but wait for the game to be started
/*
private _marker = "kog_base";
if ( playerside isequalto GRLIB_side_enemy && { !isnil "_marker" } ) then {
    [ 
        { dostartgame == 1 }, 
        {
            private _marker = param [ 0, "", [""] ];
            player setposatl getmarkerpos _marker;
            player setdir markerdir _marker
        },
        [ _marker ]   
    ] call CBA_fnc_waituntilAndExecute
};
*/

// Commander init
if (player isEqualTo ([] call KPLIB_fnc_getCommander)) then {
    // Start tutorial
    if (KP_liberation_tutorial) then {
        [] call KPLIB_fnc_tutorial;
    };
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

// Check if unit is not an elevated player.
if !((getPlayerUID player) in KP_liberation_commander_actions) then {
    // Arsenal Enforcement applies to all non-elevated players
    execVM "scripts\client\misc\enforced_arsenal.sqf";
};

// ADMINISTRATIVE EH's (CLIENT)
call compileFinal preprocessFileLineNumbers "modules\admin_log\client\index.sqf";
