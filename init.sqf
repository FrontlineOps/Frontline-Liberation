/*
    Init Rewrite
    - Split init between playerLocalInit and serverInit 
    - Optimize & Refactor logical so start time is reduced
*/

KPLIB_init = false;
// Version of the KP Liberation framework
KP_liberation_version = [0, 96, "7a"];

enableSaving [ false, false ];

cleanUpBodies = 
{
    diag_log "cleanUpBodies - Cleaning up all dead bodies.";
    {
        deleteVehicle _x;
    } forEach allDeadMen;

    private _groundObjects = allMissionObjects "GroundWeaponHolder";

    { 
        deleteVehicle _x;
    } forEach _groundObjects;

    [cleanUpBodies, [], 600] call CBA_fnc_waitAndExecute;
};

if (isDedicated) then {debug_source = "Server";} else {debug_source = name player;};

[] call KPLIB_fnc_initSectors;
if (!isServer) then {waitUntil {!isNil "KPLIB_initServer"};};

//Initialize global list of arsenal crates (added in kp_objectinits)
KARMA_ARSENAL_CRATES = [];
OPFOR_ARSENAL_CRATES = [];

[] call compileFinal preprocessFileLineNumbers "scripts\shared\fetch_params.sqf";
[] call compileFinal preprocessFileLineNumbers "kp_liberation_config.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\battlespace_ai\index.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\intelligence\index.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\COPS\index.sqf";

if (isDedicated) then 
{
    [] call compileFinal preprocessFileLineNumbers "\userconfig\perms\perms.sqf";
    [] call compileFinal preprocessFileLineNumbers "\userconfig\KOG\KOGWhitelist.sqf";
    publicVariable "KOGFOR";
};
if (isServer && hasInterface) then 
{
    [] call compileFinal preprocessFileLineNumbers "perms_non_dedicated.sqf";
};

[] call compileFinal preprocessFileLineNumbers "presets\init_presets.sqf";
[] call compileFinal preprocessFileLineNumbers "arsenal_presets\rolearsenal.sqf";
OPFORArsenalItems = +(missionNamespace getVariable ["KPLIB_autoFactionOpforArsenal", []]);
if (OPFORArsenalItems isEqualTo [] || {opfor_uniforms isEqualTo []}) then {
    private _message = "Generated OPFOR arsenal or starting uniforms are empty; automatic faction initialization cannot continue";
    [_message, "FACTIONS"] call KPLIB_fnc_log;
    throw _message;
};
OpforArsenal_DetermineGear = {
    +(missionNamespace getVariable ["KPLIB_autoFactionOpforArsenal", []])
};
OpForStartingUniform = opfor_uniforms select 0;
Op_StartingItems = +(missionNamespace getVariable ["KPLIB_autoFactionOpforStartingItems", []]);
[] call compileFinal preprocessFileLineNumbers "kp_objectInits.sqf";
[] call compileFinal preprocessFileLineNumbers "scripts\crate-resupply\init.sqf";
[] call compileFinal preprocessFileLineNumbers "scripts\fireteams\init.sqf";

[] call compileFinal preprocessFileLineNumbers "scripts\shared\init_shared.sqf";
[] call compileFinal preprocessFileLineNumbers "karmakut\init_shared.sqf";
[] call compileFinal preprocessFileLineNumbers "scripts\libZeusActions\index.sqf";

[] call compileFinal preprocessFileLineNumbers "modules\missileGuidance\index.sqf";
if (isServer) then {
    [] call compileFinal preprocessFileLineNumbers "scripts\server\ewr\init.sqf";
    [] call compileFinal preprocessFileLineNumbers "scripts\server\init_server.sqf";
    [] call compileFinal preprocessFileLineNumbers "karmakut\init_server.sqf";
	
	[{removeAllMissionEventHandlers "handledisconnect";}, [], 120] call CBA_fnc_waitAndExecute;
	[] call cleanUpBodies;


};

if (!isDedicated && hasInterface) then {

    [] call compileFinal preprocessFileLineNumbers "scripts\ragequitblocker\index.sqf";
    // Add EH for curator to add kill manager and object init recognition for zeus spawned units/vehicles
    {
        _x addEventHandler ["CuratorObjectPlaced", {[_this select 1] call KPLIB_fnc_handlePlacedZeusObject;}];
    } forEach allCurators;

    waitUntil {alive player};
    if (debug_source != name player) then {debug_source = name player};
    [] call compileFinal preprocessFileLineNumbers "scripts\client\init_client.sqf";
    [] call compileFinal preprocessFileLineNumbers "karmakut\init_client.sqf";

	addMissionEventHandler 
		["HandleDisconnect", 
			{
				params ["_unit", "_id", "_uid", "_name"];
				_unit setDamage 1;
			}
		];

} else {
    setViewDistance 1600;
};

KPLIB_init = true;

// Notify clients that server is ready
if (isServer) then {
    KPLIB_initServer = true;
    publicVariable "KPLIB_initServer";
    AWS_AMS_Disable = true;
    publicVariable "AWS_AMS_Disable";
    

    [east, 1000, 
        [
            ["Land_SandbagBarricade_01_F", 1],
            ["Land_SandbagBarricade_01_hole_F", 1],
            ["Land_BagFence_01_long_green_F", 1],
            ["Land_BagFence_01_round_green_F", 1],
            ["cwa_ShedSmall", 1],
            ["Land_fortified_nest_small", 1],
            ["Land_Ind_Timbers", 1],
            ["TK_WarfareBBarrier5x_EP1", 1],
            ["US_WarfareBBarrier10x_EP1", 1],
            ["Land_House_L_1_EP1", 1],
            ["Fort_Barricade", 1],
            ["Fortress2", 1],
            ["Hedgehog_EP1", 1],
            ["pook_siteFlag_TK_INS", 1],
            ["Flag_MEE", 1]
        ]
    ] call ace_fortify_fnc_registerObjects;

    [west, 500, 
        [
            ["Land_BarGate_F", 5],
            ["Land_CzechHedgehog_01_new_F", 5],
            ["Land_BagFence_Round_F", 10],
            ["Land_BagFence_Short_F", 10],
            ["Land_BagFence_Long_F", 10],
            ["Land_BagFence_Corner_F", 10],
            ["Land_BagFence_End_F", 10],
            ["Land_fort_bagfence_long", 15],
            ["Land_fort_bagfence_corner", 15],
            ["Land_fort_bagfence_round", 15],
            ["Land_DragonsTeeth_01_4x2_new_redwhite_F", 15],
            ["Land_fort_rampart", 30]
            
        ]
    ] call ace_fortify_fnc_registerObjects;


};
CHBN_adjustBrightness = 0.1;

if(isServer) then {
    [] call compileFinal preprocessFileLineNumbers "scripts\server\ai\fixLoadoutBug.sqf";
};
