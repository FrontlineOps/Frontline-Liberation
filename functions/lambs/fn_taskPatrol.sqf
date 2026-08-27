#include "script_component.hpp"
/*
 * Author: nkenny
 * Adapted from LAMBS Danger.fsm taskPatrol.
 * Source: addons/wp/functions/fnc_taskPatrol.sqf
 * Upstream commit: 63122df5d9403a52f10bf50198ac75a49f0a3d6b
 * Adapted 2026-08-27: KPLIB namespace and mission-safe state variables;
 * LAMBS debug hooks were removed.
 * License: see NOTICE.md and LICENSE.LAMBS in this directory.
 *
 * Arguments:
 * 0: Group performing action, either unit <OBJECT> or group <GROUP>
 * 1: Position being searched, default group position <OBJECT or ARRAY>
 * 2: Range of tracking, default 200 meters <NUMBER>
 * 3: Waypoint count, default 4 <NUMBER>
 * 4: Patrol area, default [] <ARRAY>
 * 5: Dynamically move patrol waypoints <BOOL>
 * 6: Enable dynamic reinforcement when LAMBS is present <BOOL>
 * 7: Teleport group to a randomly selected waypoint <BOOL>
 *
 * Return Value: success <BOOL>
 */

if (canSuspend) exitWith {[KPLIB_fnc_taskPatrol, _this] call CBA_fnc_directCall};

params [
    ["_group", grpNull, [grpNull, objNull]],
    ["_pos", []],
    ["_radius", TASK_PATROL_SIZE, [0]],
    ["_waypointCount", TASK_PATROL_WAYPOINTCOUNT, [0]],
    ["_area", [], [[]]],
    ["_moveWaypoints", TASK_PATROL_MOVEWAYPOINTS, [false]],
    ["_enableReinforcement", TASK_PATROL_ENABLEREINFORCEMENT, [false]],
    ["_teleport", TASK_PATROL_TELEPORT, [false]]
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

[_group] call CBA_fnc_clearWaypoints;

_group setBehaviour "SAFE";
_group setSpeedMode "LIMITED";
_group setCombatMode "YELLOW";
_group setFormation selectRandom ["STAG COLUMN", "WEDGE", "ECH LEFT", "ECH RIGHT", "VEE", "DIAMOND"];
_group enableGunLights "forceOn";
_group setVariable ["KPLIB_lambs_currentTactic", "taskPatrol"];

if (_enableReinforcement) then {
    _group setVariable ["KPLIB_lambs_enableGroupReinforce", true];
};

private _firstWaypointId = 0;

private _waypoint = [];
for "_i" from 1 to (_waypointCount max 1) do {
    private _nextPos = _pos getPos [
        _radius * (1 - abs random [-1, 0, 1]),
        random 360
    ];
    if (_area isNotEqualTo []) then {
        _nextPos = _pos getPos [
            (_radius * 1.2) * (1 - abs random [-1, 0, 1]),
            random 360
        ];
        _area params ["_a", "_b", "_angle", "_isRectangle", ["_c", -1]];
        while {!(_nextPos inArea [_pos, _a, _b, _angle, _isRectangle, _c])} do {
            _nextPos = _pos getPos [
                (_radius * 1.2) * (1 - abs random [-1, 0, 1]),
                random 360
            ];
        };
    };
    if (surfaceIsWater _nextPos) then {
        _nextPos = _pos;
    };

    _waypoint = _group addWaypoint [_nextPos, 10];
    _waypoint setWaypointType "MOVE";
    _waypoint setWaypointTimeout [8, 10, 15];
    _waypoint setWaypointCompletionRadius 10;
    _waypoint setWaypointStatements ["true", "if (local this) then {(group this) enableGunLights 'forceOn';}"];

    if (_i == 1) then {
        _firstWaypointId = _waypoint select 1;
    };
};

_group setVariable ["KPLIB_lambs_taskPatrolRadius", _radius, true];
_group setVariable ["KPLIB_lambs_taskPatrolPosition", _pos, true];
_group setVariable ["KPLIB_lambs_taskPatrolArea", _area, true];

if (_moveWaypoints) then {
    _waypoint setWaypointStatements [
        "true",
        format [
            "if (local this) then {(group this) enableGunLights 'forceOn'; (group this) setCurrentWaypoint [(group this), %1]; call KPLIB_fnc_taskPatrolWaypointStatement;};",
            _firstWaypointId
        ]
    ];
} else {
    _waypoint setWaypointStatements [
        "true",
        format [
            "if (local this) then {(group this) enableGunLights 'forceOn'; (group this) setCurrentWaypoint [(group this), %1];};",
            _firstWaypointId
        ]
    ];
};

if (_teleport) then {
    private _teleportDestination = waypointPosition (selectRandom (waypoints _group));
    {
        (vehicle _x) setVehiclePosition [_teleportDestination, [], precision (vehicle _x), "NONE"];
    } forEach units _group;
};

true
