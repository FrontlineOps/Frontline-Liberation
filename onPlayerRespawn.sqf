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


private _role = [player] call RoleArsenal_DetermineRole;

abortPlayerWithoutPerms = {
    ["You have selected a role you do not have permissions for. If you would like to request or apply, visit 8ID Discord. You will be kicked to the lobby, please select a different role.", "Restricted Role", "I Understand"] call BIS_fnc_guiMessage;
    endMission "END1"; 
};

abortNonKogPlayer = {
    ["OPFOR slots are reserved for KOG members.", "Restricted Role", "I Understand"] call BIS_fnc_guiMessage;
    endMission "EndNonKOG"; 
};
if (side player == GRLIB_side_friendly) then {
    switch (_role) do {
        case "Odin": {
            if (!(getPlayerUID player in KP_liberation_commander_actions)) then {[] call abortPlayerWithoutPerms};
            localnamespace setvariable [ "AdminSlot", true ];
            showChat true;
        };
        case "CO";
        case "XO": {
            if (!(getPlayerUID player in karmaLibCompanyCmd)) then {[] call abortPlayerWithoutPerms};
        };
        case "PL";
        case "PSgt": {
            if (!(getPlayerUID player in karmaLibPltLead)) then {[] call abortPlayerWithoutPerms};
        };
        case "PLTO";
        case "HAAL";
        case "SGoblin";
        case "WTL";
        case "SL": {
            if (!(getPlayerUID player in karmaLibSL)) then {[] call abortPlayerWithoutPerms};
        };
        case "PMed": {
            if (!(getPlayerUID player in karmaLibPltMed)) then {[] call abortPlayerWithoutPerms};
            if (_role == "PMed" && (getPlayerUID player in karmaLibMedicBlacklist)) then {[] call abortPlayerWithoutPerms};
        };
        case "JFOLeader";
        case "JFO": { 
            if (!(getPlayerUID player in karmaLibSiren)) then {[] call abortPlayerWithoutPerms};
        }; 
        case "ShadowTL";
        case "ShadowE": {
            if (!(getPlayerUID player in (karmaLibSiren + karmaLibFixedWing))) then {[] call abortPlayerWithoutPerms};
        };
        // 2022-07-11 Oats - Vehicle Driver and Gunner slots added to each Squad, can sometimes operate non-perm vehicles
        case "ButcherGunner";
        case "ButcherDriver";
        case "ButcherCommander": {
            if (!(getPlayerUID player in karmaLibArmor)) then {[] call abortPlayerWithoutPerms};
        };
        case "Hermes"; 
        case "BansheePilot": {
            if (!(getPlayerUID player in karmaLibRotaryLogi)) then {[] call abortPlayerWithoutPerms};
        };
        case "Hades": {
            if (!(getPlayerUID player in karmaLibRotaryCas)) then {[] call abortPlayerWithoutPerms};
        };
        case "Chevy";
        case "Reaper": {
            if (!(getPlayerUID player in karmaLibFixedWing)) then {[] call abortPlayerWithoutPerms};
        };
        case "FoxSniper";
        case "FoxSpotter";
        case "FoxScout": {
            if (!(getPlayerUID player in karmaLibPhantom)) then {[] call abortPlayerWithoutPerms};
        };
        case "BNTL";
        case "BNM": {
            if (!(getPlayerUID player in karmaLibBanshee)) then {[] call abortPlayerWithoutPerms};
        };
        case "Medic": {
            if (getPlayerUID player in karmaLibMedicBlacklist) then {[] call abortPlayerWithoutPerms};
        };
        default { };
    };
};

//--- This should work, just teleports them back requardless then the abortPlayerWithoutPerms will do the rest
if ( playerside isequalto GRLIB_side_enemy ) then {
    if ( !( getplayeruid player in KOGFOR ) ) then { [] call abortNonKogPlayer };
    //private _marker = "kog_base";
    //player setposatl getmarkerpos _marker;
    //player setdir markerdir _marker;
};

// Support Module handling
if ([
    false,
    player isEqualTo ([] call KPLIB_fnc_getCommander) || (getPlayerUID player) in KP_liberation_suppMod_whitelist,
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
