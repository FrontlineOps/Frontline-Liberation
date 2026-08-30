/*
    File: fn_addActionsPlayer.sqf
    Author: KP Liberation Dev Team - https://github.com/KillahPotatoes
    Date: 2020-04-13
    Last Update: 2020-08-07
    License: MIT License - http://www.opensource.org/licenses/MIT

    Description:
        Adds Liberation player actions to the given player.

    Parameter(s):
        _player - Player to add the actions to [OBJECT, defaults to player]

    Returns:
        Function reached the end [BOOL]
*/

params [
    ["_player", player, [objNull]]
];

if !(isPlayer _player) exitWith {["No player given"] call BIS_fnc_error; false};

if (isNil "KP_liberation_resources_global") then {KP_liberation_resources_global = false;};

_redeployEvaluation = "
            isNull (objectParent _originalTarget)
            && {alive _originalTarget}
            && {
                _originalTarget getVariable ['KPLIB_fobDist', 99999] < 40
                || {_originalTarget getVariable ['KPLIB_isNearMobRespawn', false]}
                || {_originalTarget getVariable ['KPLIB_isNearStart', false]}
            }
            && {build_confirmed isEqualTo 0}
        ";

// Todo: how to constantly evalute for nearby spawn trucks w/o screwing the client's perf???
// Actually, it might be a good thing that KOG can't re-redeploy from a truck lol
if (playerside isEqualTo GRLIB_side_enemy) then {
    _redeployEvaluation = "
            isNull (objectParent _originalTarget)
            && {alive _originalTarget}
            && {
                (markerPos 'kog_base') distance player < 20
                || {[_originalTarget, 20] call kplib_fnc_isNearFriendlyPB}
            }
            && {build_confirmed isEqualTo 0}
        ";
};

_player addAction [
    ["<t color='#80FF80'>", localize "STR_DEPLOY_ACTION", "</t><img size='2' image='res\ui_redeploy.paa'/>"] joinString "",
    {GRLIB_force_redeploy = true;},
    nil,
    -720,
    false,
    true,
    "",
    _redeployEvaluation
];

// Build
_player addAction [
    ["<t color='#FFFF00'>", localize "STR_BUILD_ACTION", "</t><img size='2' image='res\ui_build.paa'/>"] joinString "",
    "scripts\client\build\open_build_menu.sqf",
    nil,
    -750,
    false,
    true,
    "",
    "
        isNull (objectParent _originalTarget)
        && {alive _originalTarget}
        && {_originalTarget getVariable ['KPLIB_fobDist', 99999] < (GRLIB_fob_range * 0.8)}
        && {
            _originalTarget getVariable ['KPLIB_hasDirectAccess', false]
            || {getPlayerUID _originalTarget in karmaLibBuild}
        }
        && {build_confirmed isEqualTo 0}
    "
];

// Shared intelligence analysis terminal
if (KPLIB_intelligence_enabled) then {
    _player addAction [
        "<t color='#7FC9FF'>Intelligence Analysis</t>",
        {[] call KPLIB_INTEL_CLIENT_OPEN_DIALOG},
        nil,
        -760,
        false,
        true,
        "",
        "
            isNull (objectParent _originalTarget)
            && {alive _originalTarget}
            && {side _originalTarget isEqualTo GRLIB_side_friendly}
            && {
                _originalTarget getVariable ['KPLIB_fobDist', 99999] < KPLIB_intelligence_terminal_distance
              || {_originalTarget getVariable ['KPLIB_isNearStart', false]}
            }
            && {build_confirmed isEqualTo 0}
        "
    ];
};

// Build sector storage
_player addAction [
    ["<t color='#FFFF00'>", localize "STR_SECSTORAGEBUILD_ACTION", "</t>"] joinString "",
    "scripts\client\build\do_sector_build.sqf",
    [KP_liberation_small_storage_building],
    -770,
    false,
    true,
    "",
    "
        !(_originalTarget getVariable ['KPLIB_nearProd', []] isEqualTo [])
        && {isNull (objectParent _originalTarget)}
        && {alive _originalTarget}
        && {
            _originalTarget getVariable ['KPLIB_hasDirectAccess', false]
            || {getPlayerUID _originalTarget in karmaLibBuild}
            || {(_originalTarget getVariable ['resupplySquadGroupFlag', 'NONE']) == 'LOGI'}
        }
        && {(_originalTarget getVariable ['KPLIB_nearProd', []] select 3) isEqualTo []}
        && {build_confirmed isEqualTo 0}
    "
];

// Build supply facility
_player addAction [
    ["<t color='#FFFF00'>", localize "STR_SECSUPPLYBUILD_ACTION", "</t>"] joinString "",
    "scripts\client\build\do_sector_build.sqf",
    ["supply"],
    -780,
    false,
    true,
    "",
    "
        !(_originalTarget getVariable ['KPLIB_nearProd', []] isEqualTo [])
        && {isNull (objectParent _originalTarget)}
        && {alive _originalTarget}
        && {
            _originalTarget getVariable ['KPLIB_hasDirectAccess', false]
            || {getPlayerUID _originalTarget in karmaLibBuild}
            || {(_originalTarget getVariable ['resupplySquadGroupFlag', 'NONE']) == 'LOGI'}
        }
        && {!((_originalTarget getVariable ['KPLIB_nearProd', []] select 3) isEqualTo [])}
        && {!((_originalTarget getVariable ['KPLIB_nearProd', []]) select 4)}
        && {build_confirmed isEqualTo 0}
    "
];

// Build ammo facility
_player addAction [
    ["<t color='#FFFF00'>", localize "STR_SECAMMOBUILD_ACTION", "</t>"] joinString "",
    "scripts\client\build\do_sector_build.sqf",
    ["ammo"],
    -790,
    false,
    true,
    "",
    "
        !(_originalTarget getVariable ['KPLIB_nearProd', []] isEqualTo [])
        && {isNull (objectParent _originalTarget)}
        && {alive _originalTarget}
        && {
            _originalTarget getVariable ['KPLIB_hasDirectAccess', false]
            || {getPlayerUID _originalTarget in karmaLibBuild}
            || {(_originalTarget getVariable ['resupplySquadGroupFlag', 'NONE']) == 'LOGI'}
        }
        && {!((_originalTarget getVariable ['KPLIB_nearProd', []] select 3) isEqualTo [])}
        && {!((_originalTarget getVariable ['KPLIB_nearProd', []]) select 5)}
        && {build_confirmed isEqualTo 0}
    "
];

// Build fuel facility
_player addAction [
    ["<t color='#FFFF00'>", localize "STR_SECFUELBUILD_ACTION", "</t>"] joinString "",
    "scripts\client\build\do_sector_build.sqf",
    ["fuel"],
    -800,
    false,
    true,
    "",
    "
        !(_originalTarget getVariable ['KPLIB_nearProd', []] isEqualTo [])
        && {isNull (objectParent _originalTarget)}
        && {alive _originalTarget}
        && {
            _originalTarget getVariable ['KPLIB_hasDirectAccess', false]
            || {getPlayerUID _originalTarget in karmaLibBuild}
            || {(_originalTarget getVariable ['resupplySquadGroupFlag', 'NONE']) == 'LOGI'}
        }
        && {!((_originalTarget getVariable ['KPLIB_nearProd', []] select 3) isEqualTo [])}
        && {!((_originalTarget getVariable ['KPLIB_nearProd', []]) select 6)}
        && {build_confirmed isEqualTo 0}
    "
];

// Switch global/local resources
_player addAction [
    ["<t color='#FFFF00'>", localize "STR_RESOURCE_GLOBAL_ACTION", "</t>"] joinString "",
    {KP_liberation_resources_global = !KP_liberation_resources_global},
    nil,
    -810,
    false,
    true,
    "",
    "
        alive _originalTarget
        && {_originalTarget getVariable ['KPLIB_fobDist', 99999] < (GRLIB_fob_range * 0.8)}
        && {build_confirmed isEqualTo 0}
    "
];

// Production
_player addAction [
    ["<t color='#FF8000'>", localize "STR_PRODUCTION_ACTION", "</t>"] joinString "",
    "scripts\client\commander\open_production.sqf",
    nil,
    -820,
    false,
    true,
    "",
    "
        isNull (objectParent _originalTarget)
        && {
            _originalTarget getVariable ['KPLIB_hasDirectAccess', false]
            || {getPlayerUID _originalTarget in karmaLibBuild
            && {(_originalTarget getVariable ['resupplySquadGroupFlag', 'NONE']) == 'LOGI'}}
        }
        && {alive _originalTarget}
        && {!(KP_liberation_production isEqualTo [])}
        && {
            _originalTarget getVariable ['KPLIB_fobDist', 99999] < (GRLIB_fob_range * 0.8)
            || {!(_originalTarget getVariable ['KPLIB_nearProd', []] isEqualTo [])}
        }
        && {build_confirmed isEqualTo 0}
    "
];

// Reassign Zeus
if (player == ([] call KPLIB_fnc_getCommander)) then {
    _player addAction [
        ["<t color='#FF0000'>", localize "STR_REASSIGN_ZEUS", "</t>"] joinString "",
        {[] call KPLIB_fnc_requestZeus},
        nil,
        -870,
        false,
        true,
        "",
        "
            alive _originalTarget
            && {isNull (_originalTarget getVariable ['KPLIB_ownedZeusModule', objNull])}
            && {build_confirmed isEqualTo 0}
        "
    ];
};

// Create FOB clearance
_player addAction [
    ["<t color='#FFFF00'>", localize "STR_CLEARANCE_ACTION", "</t>"] joinString "",
    {[player getVariable ["KPLIB_fobPos", [0, 0, 0]], GRLIB_fob_range * 0.9, true] call KPLIB_fnc_createClearanceConfirm;},
    nil,
    -850,
    false,
    true,
    "",
    "
        _originalTarget getVariable ['KPLIB_hasDirectAccess', false]
        && {isNull (objectParent _originalTarget)}
        && {alive _originalTarget}
        && {_originalTarget getVariable ['KPLIB_fobDist', 99999] < (GRLIB_fob_range * 0.8)}
        && {build_confirmed isEqualTo 0}
    "
];

_player addAction [
    ["<t color='#80FF80'>", "Reload Arsenal", "</t>"] joinString "",
    { 
        {
            private _box = _x;
            if (!isNull _box) then 
            {
                //KARMA_ARSENAL_CRATES deleteAt (KARMA_ARSENAL_CRATES find _x);
                [_box, player] call roleArsenal;
            };
        } forEach KARMA_ARSENAL_CRATES;
    },
    nil,
    -860,
    false,
    true,
    "",
    "
        alive _originalTarget
        && {_originalTarget getVariable ['KPLIB_fobDist', 99999] < (GRLIB_fob_range * 0.8)}
    "
];

_player addAction [
    ["<t color='#80FF80'>", "Place PB", "</t>"] joinString "",
    { [player, side player] execVM "modules\COPS\copBuildandMove.sqf"},
    nil,
    -860,
    false,
    true,
    "",
    "
        alive _originalTarget
        && {side _originalTarget == GRLIB_side_friendly}
        && {[_originalTarget] call RoleArsenal_DetermineRole == 'PL'}
        && {GRLIB_cop_count < GRLIB_max_cops}
    "
];

_player addAction [
    ["<t color='#80FF80'>", "Place PB", "</t>"] joinString "",
    { [player, side player] execVM "modules\COPS\copBuildandMove.sqf"},
    nil,
    -860,
    false,
    true,
    "",
    "
        alive _originalTarget
        && {side _originalTarget == GRLIB_side_enemy}
        && {(roleDescription _originalTarget) find 'Detachment Commander' > -1
        || (roleDescription _originalTarget) find 'Squad Leader' > -1
        || (roleDescription _originalTarget) find 'Team Leader' > -1}
        && {(roleDescription _originalTarget) find 'Engineer Team Leader' == -1}
        && {OPFOR_cop_count < OPFOR_max_cops}
    "
];

_player addAction [
    ["<t color='#80FF80'>", "Disable Damage", "</t>"] joinString "",
    { 
        player allowDamage false;
        hintSilent "Damage has been disabled.";
    },
    nil,
    -860,
    false,
    true,
    "",
    "
        alive _originalTarget
        && {(roleDescription _originalTarget) find 'Guide' > -1}
        && {isDamageAllowed player == true}
        && {_originalTarget getVariable ['KPLIB_fobDist', 99999] < (GRLIB_fob_range * 0.8)}
    "
];

private _getCoordsScript = {
	private _gpsLastCheckTime = localnamespace getVariable [ "GPSCheckTime", 0 ];
	
	if (CBA_missionTime >= _gpsLastCheckTime) then {
        private _coordinates = mapGridPosition player;
		[_coordinates] spawn {
            params ["_coordinates"];
            [format ["Coordinates - %1", _coordinates], "Coordinates", "ok"] call BIS_fnc_guiMessage;
            //hint format ["Coordinates - %1", _coordinates];
        };
	    localnamespace setVariable [ "GPSCheckTime", (CBA_missionTime + (10 * 60)) ];
	} else {
		hint format ["You must wait %1 seconds before using this again.", (ceil (_gpsLastCheckTime - CBA_missionTime))];
	};

	0 spawn {sleep 1.0; 
	hintSilent "";};
};

private _getCoords = ["GetCoords","Get Coordinates","",_getCoordsScript,{visibleMap}] call ace_interact_menu_fnc_createAction;
[_player, 1, ["ACE_SelfActions"], _getCoords] call ace_interact_menu_fnc_addActionToObject;


// Destroy PB (only for OPFOR, disabled for now)
/*
_player addAction [
    ["<t color='#FF0000'>", "Destroy PB", "</t>"] joinString "",
    {
        params ["_target", "_caller", "_actionId", "_arguments"];
        private _marker = nil;
        {
            if (getMarkerPos _x distance2D getPos _caller < 10) then {
                _marker = _x;
            };
        } forEach GRLIB_all_cops;

        if (!isNil "_marker") then {
            ["lib_admin_notification", ["PB Lost", format ["PB - %1 has been destroyed!", mapGridPosition (getMarkerPos _marker)], "res\notif\ui_notif_sec_los.paa"]] remoteExec ["bis_fnc_shownotification"];
            deleteMarker _marker;
            GRLIB_all_cops = GRLIB_all_cops - [_marker];
            publicVariable "GRLIB_all_cops";
        };
    },
    nil,
    -860,
    false,
    true,
    "",
    "
        alive _originalTarget
        && {side _originalTarget == GRLIB_side_enemy}
        && {GRLIB_cop_count >= 1}
        && {
            {
                getMarkerPos _x distance2D getPos _originalTarget < 10
            } forEach GRLIB_all_cops;
        }
    "
];
*/

true
