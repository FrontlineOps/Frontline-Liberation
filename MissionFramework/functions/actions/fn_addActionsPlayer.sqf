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

if (side group _player != GRLIB_side_friendly) exitWith {false};

if (isNil "KP_liberation_resources_global") then {KP_liberation_resources_global = false;};

_redeployEvaluation = "
            isNull (objectParent _originalTarget)
            && {alive _originalTarget}
            && {
                _originalTarget getVariable ['KPLIB_fobDist', 99999] < 40
                || {_originalTarget getVariable ['KPLIB_isNearMobRespawn', false]}
                || {_originalTarget getVariable ['KPLIB_isNearStart', false]}
                || {!isNil 'KPLIB_COPS_CLIENT_IS_NEAR' && {[_originalTarget] call KPLIB_COPS_CLIENT_IS_NEAR}}
            }
            && {build_confirmed isEqualTo 0}
        ";

_player addAction [
    [localize "STR_DEPLOY_ACTION", "#80FF80"] call KPLIB_fnc_actionLabel,
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
    [localize "STR_BUILD_ACTION", "#FFFF00"] call KPLIB_fnc_actionLabel,
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
        && {[_originalTarget, 'BUILD'] call KPLIB_fnc_hasPermission}
        && {build_confirmed isEqualTo 0}
    "
];

// Reopen the local field guide without starting the introduction camera.
_player addAction [
    [localize "STR_TUTO_ACTION"] call KPLIB_fnc_actionLabel,
    {howtoplay = 1;},
    nil,
    -755,
    false,
    true,
    "",
    "alive _originalTarget && {!dialog} && {howtoplay == 0} && {build_confirmed == 0}"
];

// Build sector storage
_player addAction [
    [localize "STR_SECSTORAGEBUILD_ACTION", "#FFFF00"] call KPLIB_fnc_actionLabel,
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
        && {[_originalTarget, 'BUILD'] call KPLIB_fnc_hasPermission}
        && {(_originalTarget getVariable ['KPLIB_nearProd', []] select 3) isEqualTo []}
        && {build_confirmed isEqualTo 0}
    "
];

// Build supply facility
_player addAction [
    [localize "STR_SECSUPPLYBUILD_ACTION", "#FFFF00"] call KPLIB_fnc_actionLabel,
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
        && {[_originalTarget, 'BUILD'] call KPLIB_fnc_hasPermission}
        && {!((_originalTarget getVariable ['KPLIB_nearProd', []] select 3) isEqualTo [])}
        && {!((_originalTarget getVariable ['KPLIB_nearProd', []]) select 4)}
        && {build_confirmed isEqualTo 0}
    "
];

// Build ammo facility
_player addAction [
    [localize "STR_SECAMMOBUILD_ACTION", "#FFFF00"] call KPLIB_fnc_actionLabel,
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
        && {[_originalTarget, 'BUILD'] call KPLIB_fnc_hasPermission}
        && {!((_originalTarget getVariable ['KPLIB_nearProd', []] select 3) isEqualTo [])}
        && {!((_originalTarget getVariable ['KPLIB_nearProd', []]) select 5)}
        && {build_confirmed isEqualTo 0}
    "
];

// Build fuel facility
_player addAction [
    [localize "STR_SECFUELBUILD_ACTION", "#FFFF00"] call KPLIB_fnc_actionLabel,
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
        && {[_originalTarget, 'BUILD'] call KPLIB_fnc_hasPermission}
        && {!((_originalTarget getVariable ['KPLIB_nearProd', []] select 3) isEqualTo [])}
        && {!((_originalTarget getVariable ['KPLIB_nearProd', []]) select 6)}
        && {build_confirmed isEqualTo 0}
    "
];

// Switch global/local resources
_player addAction [
    [localize "STR_RESOURCE_GLOBAL_ACTION", "#FFFF00"] call KPLIB_fnc_actionLabel,
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
    [localize "STR_PRODUCTION_ACTION", "#FF8000"] call KPLIB_fnc_actionLabel,
    "scripts\client\commander\open_production.sqf",
    nil,
    -820,
    false,
    true,
    "",
    "
        isNull (objectParent _originalTarget)
        && {[_originalTarget, 'PRODUCTION'] call KPLIB_fnc_hasPermission}
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
        [localize "STR_REASSIGN_ZEUS", "#FF0000"] call KPLIB_fnc_actionLabel,
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
    [localize "STR_CLEARANCE_ACTION", "#FFFF00"] call KPLIB_fnc_actionLabel,
    {[player getVariable ["KPLIB_fobPos", [0, 0, 0]], GRLIB_fob_range * 0.9, true] call KPLIB_fnc_createClearanceConfirm;},
    nil,
    -850,
    false,
    true,
    "",
    "
        [_originalTarget, 'BUILD'] call KPLIB_fnc_hasPermission
        && {isNull (objectParent _originalTarget)}
        && {alive _originalTarget}
        && {_originalTarget getVariable ['KPLIB_fobDist', 99999] < (GRLIB_fob_range * 0.8)}
        && {build_confirmed isEqualTo 0}
    "
];

_player addAction [
    ["Reload arsenal", "#80FF80"] call KPLIB_fnc_actionLabel,
    { 
        {
            private _box = _x;
            if (!isNull _box) then 
            {
                //KARMA_ARSENAL_CRATES deleteAt (KARMA_ARSENAL_CRATES find _x);
                [_box, player] call KPLIB_fnc_initPlayerArsenal;
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
    ["Disable damage", "#80FF80"] call KPLIB_fnc_actionLabel,
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


_player addAction [
    ["Player Permissions", "#FFFF00"] call KPLIB_fnc_actionLabel,
    {[] call KPLIB_fnc_openPermissions},
    nil, -880, false, true, "",
    "alive _originalTarget && {[_originalTarget] call KPLIB_fnc_isPermissionAdmin} && {build_confirmed == 0}"
];

true
