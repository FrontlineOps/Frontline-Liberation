waitUntil {!isNil "KPLIB_initServer"};

params ["_newUnit", "_oldUnit"];

[player] remoteExec ["requestResupplyFlags", 2];

removeAllWeapons player;
removeAllItems player;
removeAllAssignedItems player;
removeVest player;
removeBackpack player;
removeHeadgear player;
removeGoggles player;
player unassignItem "";
player removeItem "";

// Starter gear is generated from the selected faction during preset initialization.
if (side player == GRLIB_side_friendly) then {

    if (RA_StartingHeadwear isNotEqualTo []) then {player addHeadgear selectRandom RA_StartingHeadwear};
    if (RA_StartingGoggles isNotEqualTo []) then {player addGoggles selectRandom RA_StartingGoggles};
    if (RA_StartingUniforms isNotEqualTo []) then {player forceAddUniform selectRandom RA_StartingUniforms};
    {
        player linkItem _x;
    } forEach RA_StartingItems;
};

if (side player == GRLIB_side_enemy) then {

    if (OpForStartingUniform != "") then {player forceAddUniform OpForStartingUniform};
    {
        player linkItem _x;
    } forEach Op_StartingItems;
};

[] call KPLIB_fnc_addActionsPlayer; 
if (!isNil "KPLIB_COPS_CLIENT_INSTALL_ACTION") then {
    [player] call KPLIB_COPS_CLIENT_INSTALL_ACTION;
};

// Loop through all arsenals, and init role restricted arsenal.
// This fixes a bug where when a player joins, 
// they don't have their description or some shit like that.
{
    private _box = _x;
    if (!isNull _box) then 
    {
        //KARMA_ARSENAL_CRATES deleteAt (KARMA_ARSENAL_CRATES find _x);
        [_box, player] call roleArsenal;
    };
} forEach KARMA_ARSENAL_CRATES;

{
    private _box = _x;
    if (!isNull _box) then 
    {
        if (side player == GRLIB_side_enemy) then {
            [_box, false] call ace_arsenal_fnc_removeBox;
	        private _items = [player] call OpforArsenal_DetermineGear;
	        [_box, _items, false] call ace_arsenal_fnc_initBox;
        };
    };
} forEach OPFOR_ARSENAL_CRATES;

private _blacklistedMods = ["CH Bright Nights"];

private _loadedMods = getLoadedModsInfo;
{
    _modName = _x;
    {
        if  (_x#0 find _modName > -1 || _x#1 find _modName > -1) then {
            [format ["You are using a mod that isn't allowed on the KC Liberation server. (%1)", _modName], "Use of Unapproved Mod", "I Understand"] call BIS_fnc_guiMessage;
            endMission "BlacklistedMod";
        };
    } forEach _loadedMods;
} forEach _blacklistedMods;


[false] remoteExecCall ["KPLIB_fnc_requestPermissions", 2];

// Support Module handling
if ([
    false,
    player isEqualTo ([] call KPLIB_fnc_getCommander),
    true
] select KP_liberation_suppMod) then {
    waitUntil {!isNil "KPLIB_suppMod_req" && !isNil "KPLIB_suppMod_arty" && time > 5};

    // Remove link to corpse, if respawned
    if (!isNull _oldUnit) then {
        KPLIB_suppMod_req synchronizeObjectsRemove [_oldUnit];
        _oldUnit synchronizeObjectsRemove [KPLIB_suppMod_req];
    };

    // Link player to support modules
    [player, KPLIB_suppMod_req, KPLIB_suppMod_arty] call BIS_fnc_addSupportLink;

    // Init modules, if newly joined and not client host
    if (isNull _oldUnit && !isServer) then {
        [KPLIB_suppMod_req] call BIS_fnc_moduleSupportsInitRequester;
        [KPLIB_suppMod_arty] call BIS_fnc_moduleSupportsInitProvider;
    };
};
