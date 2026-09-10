#include "script_component.hpp"
/*
 * Author: nkenny
 * Adapted from LAMBS Danger.fsm taskGarrison.
 * Source: addons/wp/functions/fnc_taskGarrison.sqf
 * Upstream commit: 63122df5d9403a52f10bf50198ac75a49f0a3d6b
 * Adapted 2026-08-27: KPLIB namespace, mission-local helpers, and the
 * documented -2 random exit-condition default; LAMBS debug hooks removed.
 * Adapted 2026-09-10: shared server reservations and cancellable movement.
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

if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {false};

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

// Reset old movement callbacks before publishing this owner's new request.
[_group, true, true] call KPLIB_fnc_taskReset;
_group setVariable ["BATTLESPACE_ROUTE_WAYPOINT_TOKEN", 1 + (_group getVariable ["BATTLESPACE_ROUTE_WAYPOINT_TOKEN", 0])];
_group setVariable ["BATTLESPACE_TRANSPORT_ROUTE_TOKEN", 1 + (_group getVariable ["BATTLESPACE_TRANSPORT_ROUTE_TOKEN", 0])];
private _serial = 1 + (localNamespace getVariable ["KPLIB_garrisonSerial", 0]);
localNamespace setVariable ["KPLIB_garrisonSerial", _serial];
private _token = [clientOwner, _serial];
private _units = (units _group) select {
    _x call KPLIB_fnc_isAlive && {!isPlayer _x} && {!captive _x} && {isNull objectParent _x}
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
                _eventUnit setVariable ["KPLIB_garrisonToken", [], true];
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
                _eventUnit setVariable ["KPLIB_garrisonToken", [], true];
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
                    _eventUnit setVariable ["KPLIB_garrisonToken", [], true];
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
                _eventUnit setVariable ["KPLIB_garrisonToken", [], true];
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
    _x setVariable ["KPLIB_garrisonToken", _token, true];
    if (_exitCondition == -1) then {
        for "_i" from 0 to 4 do {
            [_x, _i] call _addReleaseEventHandler;
        };
    } else {
        [_x, _exitCondition] call _addReleaseEventHandler;
    };
} forEach _units;

private _args = [_group, _units, _pos, _radius, _area, _teleport, _sortBasedOnHeight, _token];
if (isServer) then {
    _args call KPLIB_fnc_garrisonAssign;
} else {
    _args remoteExecCall ["KPLIB_fnc_garrisonAssign", 2];
};

_pos = +_pos;
_pos set [2, 0];
private _waypoint = _group addWaypoint [_pos, _radius / 5];
_waypoint setWaypointType "HOLD";
_waypoint setWaypointCompletionRadius _radius;

true
