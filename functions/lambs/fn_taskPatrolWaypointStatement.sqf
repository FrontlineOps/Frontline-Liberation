/*
 * Author: nkenny
 * Extracted from the LAMBS Danger.fsm taskPatrol waypoint statement.
 * Source: addons/wp/functions/fnc_taskPatrol.sqf
 * Upstream commit: 63122df5d9403a52f10bf50198ac75a49f0a3d6b
 * Adapted 2026-08-27 as a globally registered KPLIB function so waypoint
 * statements remain valid if group locality changes.
 * License: see NOTICE.md and LICENSE.LAMBS in this directory.
 */

private _statementGroup = group this;
if (isNull _statementGroup || {!local _statementGroup}) exitWith {false};

private _statementRadius = _statementGroup getVariable ["KPLIB_lambs_taskPatrolRadius", 200];
private _statementPos = _statementGroup getVariable [
    "KPLIB_lambs_taskPatrolPosition",
    getPos (leader _statementGroup)
];
private _statementArea = _statementGroup getVariable ["KPLIB_lambs_taskPatrolArea", []];

{
    if (currentWaypoint _statementGroup != (_x select 1)) then {
        private _nextPos = _statementPos getPos [
            _statementRadius * (1 - abs random [-1, 0, 1]),
            random 360
        ];
        if (_statementArea isNotEqualTo []) then {
            _nextPos = _statementPos getPos [
                (_statementRadius * 1.2) * (1 - abs random [-1, 0, 1]),
                random 360
            ];
            _statementArea params ["_a", "_b", "_angle", "_isRectangle", ["_c", -1]];
            while {!(_nextPos inArea [_statementPos, _a, _b, _angle, _isRectangle, _c])} do {
                _nextPos = _statementPos getPos [
                    (_statementRadius * 1.2) * (1 - abs random [-1, 0, 1]),
                    random 360
                ];
            };
        };
        if (surfaceIsWater _nextPos) then {
            _nextPos = _statementPos;
        };
        _x setWPPos _nextPos;
    };
} forEach waypoints _statementGroup;

true
