waitUntil {!isNil "KPLIB_initServer"};

params ["_newUnit", "_oldUnit"];

if (typeOf player == "VirtualSpectator_F") exitWith {};
if (side group player != GRLIB_side_friendly) exitWith {endMission "BLUFOROnly"};

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

if ((localNamespace getVariable ["KPLIB_manualFactions", false])) then {
    localNamespace setVariable ["KPLIB_permissionsReady", false];
    localNamespace setVariable ["KPLIB_pendingRoleStarter", true];
} else {
    // Starter gear is generated from the selected faction during preset initialization.
    private _acreLoaded = isClass (configFile >> "CfgPatches" >> "acre_main");
    private _giveStartingItem = {
        params ["_item"];
        private _cfg = configFile >> "CfgWeapons" >> _item;
        if (_acreLoaded && {
            toLower _item == "itemradio" ||
            {getNumber (_cfg >> "tf_radio") > 0} ||
            {getText (_cfg >> "tf_dialog") != ""} ||
            {getText (_cfg >> "tf_subtype") != ""}
        }) exitWith {};
        if (_acreLoaded && {getNumber (_cfg >> "acre_isRadio") == 1}) exitWith {
            private _base = getText (_cfg >> "acre_baseClass");
            if (_base == "") then {_base = _item};
            if (player canAdd _base) then {player addItem _base};
        };
        player linkItem _item;
    };

    if (side player == GRLIB_side_friendly) then {

        if (RA_StartingHeadwear isNotEqualTo []) then {player addHeadgear selectRandom RA_StartingHeadwear};
        if (RA_StartingGoggles isNotEqualTo []) then {player addGoggles selectRandom RA_StartingGoggles};
        if (RA_StartingUniforms isNotEqualTo []) then {player forceAddUniform selectRandom RA_StartingUniforms};
        {
            [_x] call _giveStartingItem;
        } forEach RA_StartingItems;
    };


    if (_acreLoaded) then {[player] call KPLIB_fnc_ensurePlayerRadio};
};

[] call KPLIB_fnc_addActionsPlayer; 

// Loop through all arsenals, and init role restricted arsenal.
// This fixes a bug where when a player joins, 
// they don't have their description or some shit like that.
{
    private _box = _x;
    if (!isNull _box) then 
    {
        //KARMA_ARSENAL_CRATES deleteAt (KARMA_ARSENAL_CRATES find _x);
        [_box, player] call KPLIB_fnc_initPlayerArsenal;
    };
} forEach KARMA_ARSENAL_CRATES;


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
