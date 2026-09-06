#include "script_component.hpp"
/*
 * Author: nkenny
 * Adapted from LAMBS Danger.fsm taskGarrison.
 * Source: addons/wp/functions/fnc_taskGarrison.sqf
 * Upstream commit: 63122df5d9403a52f10bf50198ac75a49f0a3d6b
 * Adapted 2026-08-27: KPLIB namespace, mission-local helpers, and the
 * documented -2 random exit-condition default; LAMBS debug hooks removed.
 * License: see NOTICE.md and LICENSE.LAMBS in this directory.
 *
 * Arguments:
 * 0: Group performing action, either unit <OBJECT> or group <GROUP>
 * 1: Position to occupy, default group location <ARRAY or OBJECT>
 * 2: Range, default 50 meters <NUMBER>
 * 3: Garrison area, default [] <ARRAY>
 * 4: Teleport units to position <BOOL>
 * 5: Sort positions by height <BOOL>
 * 6: Exit condition (-2 random, -1 all, 0 none, 1 hit, 2 fired,
 *    3 fired-near, 4 suppressed) <NUMBER>
 * 7: Split off a patrol <BOOL>
 *
 * Return Value: success <BOOL>
 */

if (canSuspend) exitWith {[KPLIB_fnc_garrison, _this] call CBA_fnc_directCall};

params [
    ["_group", grpNull, [grpNull, objNull]],
    ["_pos", []],
    ["_radius", TASK_GARRISON_SIZE, [0]],
    ["_area", [], [[]]],
    ["_teleport", TASK_GARRISON_TELEPORT, [false]],
    ["_sortBasedOnHeight", TASK_GARRISON_SORTBYHEIGHT, [false]],
    ["_exitCondition", TASK_GARRISON_EXITCONDITIONS, [0]],
    ["_patrol", TASK_GARRISON_PATROL, [false]]
];

if (!local _group) exitWith {false};
if (_group isEqualType objNull) then {
    _group = group _group;
};
if (isNull _group) exitWith {false};

if (_pos isEqualTo []) then {
    _pos = _group;
};
_pos = _pos call CBA_fnc_getPos;

private _weapons = nearestObjects [_pos, ["LandVehicle"], _radius, true];
_weapons = _weapons select {
    simulationEnabled _x
    && {!isObjectHidden _x}
    && {locked _x != 2}
    && {(_x emptyPositions "Gunner") > 0}
};

private _buildingPositions = [_pos, _radius, true, false] call KPLIB_fnc_findBuildings;

if (_area isNotEqualTo []) then {
    _area params ["_a", "_b", "_angle", "_isRectangle", ["_c", -1]];
    _buildingPositions = _buildingPositions select {
        _x inArea [_pos, _a, _b, _angle, _isRectangle, _c]
    };
    _weapons = _weapons select {
        (getPos _x) inArea [_pos, _a, _b, _angle, _isRectangle, _c]
    };
};

private _outsidePositions = [];
{
    if !(lineIntersects [AGLToASL _x, (AGLToASL _x) vectorAdd [0, 0, 6]]) then {
        _outsidePositions pushBack _x;
    };
} forEach _buildingPositions;
_buildingPositions = _buildingPositions - _outsidePositions;

private _units = (units _group) select {
    !isPlayer _x && {isNull objectParent _x}
};

if (count _units >= count _buildingPositions) then {
    _buildingPositions append _outsidePositions;
} else {
    _buildingPositions append (_outsidePositions select {RND(0.5)});
};

if (_sortBasedOnHeight) then {
    _buildingPositions = [_buildingPositions, [], {_x select 2}, "DESCEND"] call BIS_fnc_sortBy;
} else {
    [_buildingPositions, true] call CBA_fnc_Shuffle;
};

_group setBehaviour "SAFE";
_group enableAttack false;
_group setVariable ["KPLIB_lambs_currentTactic", "taskGarrison"];

reverse _units;
if (_patrol && {_units isNotEqualTo []}) then {
    private _patrolGroup = createGroup [side _group, true];
    [_units deleteAt 0] join _patrolGroup;
    if (count _units > 4) then {
        [_units deleteAt 0] join _patrolGroup;
    };

    if (dynamicSimulationEnabled _group) then {
        [_patrolGroup, true] remoteExec ["enableDynamicSimulation", 2];
    };

    _patrolGroup setGroupIdGlobal [format ["Patrol (%1)", groupId _patrolGroup]];

    if (_area isEqualTo []) then {
        [_patrolGroup, _pos, _radius, 4, [], true, false, _teleport] call KPLIB_fnc_taskPatrol;
    } else {
        private _patrolArea = +_area;
        _patrolArea set [0, (_patrolArea select 0) * 2];
        _patrolArea set [1, (_patrolArea select 1) * 2];
        [_patrolGroup, _pos, _radius, 4, _patrolArea, true, false, _teleport] call KPLIB_fnc_taskPatrol;
    };

    _group setVariable ["KPLIB_lambs_baseGroup", _patrolGroup];
    _group addEventHandler ["CombatModeChanged", {
        params ["_eventGroup"];
        private _patrolGroup = _eventGroup getVariable ["KPLIB_lambs_baseGroup", grpNull];
        (units _patrolGroup) joinSilent _eventGroup;
        _eventGroup removeEventHandler [_thisEvent, _thisEventHandler];
    }];
};

{
    if (_weapons isNotEqualTo []) then {
        private _staticWeapon = _weapons deleteAt 0;
        if (_teleport) then {
            _x moveInGunner _staticWeapon;
        };
        _x assignAsGunner _staticWeapon;
        [_x] orderGetIn true;
        _units set [_forEachIndex, objNull];
    };
} forEach _units;

_units = _units - [objNull];

if (count _units > count _buildingPositions) then {
    _units resize (count _buildingPositions);
};

private _addReleaseEventHandler = {
    params ["_unit", "_type"];
    if (_type == 0) exitWith {};
    if (_type == -2) then {
        _type = floor (random 4);
    };

    private _eventHandlers = _unit getVariable ["KPLIB_lambs_garrisonEventHandlers", []];

    switch (_type) do {
        case 1: {
            private _handle = _unit addEventHandler ["Hit", {
                params ["_eventUnit"];
                [_eventUnit, "PATH"] remoteExec ["enableAI", _eventUnit];
                _eventUnit setCombatMode "RED";
                [_eventUnit, _eventUnit getVariable ["KPLIB_lambs_garrisonEventHandlers", []]] call KPLIB_fnc_removeLambsEventHandlers;
                _eventUnit setVariable ["KPLIB_lambs_garrisonEventHandlers", nil];
            }];
            _eventHandlers pushBack ["Hit", _handle];
        };
        case 2: {
            private _handle = _unit addEventHandler ["Fired", {
                params ["_eventUnit"];
                [_eventUnit, "PATH"] remoteExec ["enableAI", _eventUnit];
                _eventUnit setCombatMode "RED";
                [_eventUnit, _eventUnit getVariable ["KPLIB_lambs_garrisonEventHandlers", []]] call KPLIB_fnc_removeLambsEventHandlers;
                _eventUnit setVariable ["KPLIB_lambs_garrisonEventHandlers", nil];
            }];
            _eventHandlers pushBack ["Fired", _handle];
        };
        case 3: {
            private _handle = _unit addEventHandler ["FiredNear", {
                params ["_eventUnit", "_shooter", "_distance"];
                if (side _eventUnit != side _shooter && {_distance < (10 + random 10)}) then {
                    [_eventUnit, "PATH"] remoteExec ["enableAI", _eventUnit];
                    _eventUnit doMove (getPosATL _shooter);
                    _eventUnit setCombatMode "RED";
                    [_eventUnit, _eventUnit getVariable ["KPLIB_lambs_garrisonEventHandlers", []]] call KPLIB_fnc_removeLambsEventHandlers;
                    _eventUnit setVariable ["KPLIB_lambs_garrisonEventHandlers", nil];
                };
            }];
            _eventHandlers pushBack ["FiredNear", _handle];
        };
        case 4: {
            private _handle = _unit addEventHandler ["Suppressed", {
                params ["_eventUnit"];
                [_eventUnit, "PATH"] remoteExec ["enableAI", _eventUnit];
                _eventUnit setCombatMode "RED";
                [_eventUnit, _eventUnit getVariable ["KPLIB_lambs_garrisonEventHandlers", []]] call KPLIB_fnc_removeLambsEventHandlers;
                _eventUnit setVariable ["KPLIB_lambs_garrisonEventHandlers", nil];
            }];
            _eventHandlers pushBack ["Suppressed", _handle];
        };
    };

    _unit setVariable ["KPLIB_lambs_garrisonEventHandlers", _eventHandlers];
};

{
    doStop _x;
    private _buildingPosition = _buildingPositions deleteAt 0;

    if (_teleport) then {
        if (surfaceIsWater _buildingPosition) then {
            _x doFollow (leader _x);
        } else {
            _x setVehiclePosition [_buildingPosition, [], 0, "CAN_COLLIDE"];
            _x disableAI "PATH";
            _x setUnitPos selectRandom ["UP", "UP", "MIDDLE"];

            if !([_x] call KPLIB_fnc_isIndoor) then {
                _x doWatch AGLToASL (_x getPos [
                    250,
                    (nearestBuilding _buildingPosition) getDir _buildingPosition
                ]);
            };
        };
    } else {
        if (surfaceIsWater _buildingPosition) exitWith {
            _x doFollow (leader _x);
        };
        _x doMove _buildingPosition;
        [
            {
                params ["_unit"];
                unitReady _unit
            },
            {
                params ["_unit", "_target"];
                if (surfaceIsWater (getPosASL _unit) || {_unit distance _target > 1.5}) exitWith {
                    _unit doFollow (leader _unit);
                };
                _unit disableAI "PATH";
                _unit setUnitPos selectRandom ["UP", "UP", "MIDDLE"];
            },
            [_x, _buildingPosition]
        ] call CBA_fnc_waitUntilAndExecute;
    };

    if (_exitCondition == -1) then {
        for "_i" from 0 to 4 do {
            [_x, _i] call _addReleaseEventHandler;
        };
    } else {
        [_x, _exitCondition] call _addReleaseEventHandler;
    };
} forEach _units;

_pos set [2, 0];
private _waypoint = _group addWaypoint [_pos, _radius / 5];
_waypoint setWaypointType "HOLD";
_waypoint setWaypointCompletionRadius _radius;

true
