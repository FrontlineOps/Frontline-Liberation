#include "script_component.hpp"
/*
 * Author: nkenny
 * Adapted from LAMBS Danger.fsm taskCreep.
 * Source: addons/wp/functions/fnc_taskCreep.sqf
 * Upstream commit: 63122df5d9403a52f10bf50198ac75a49f0a3d6b
 * Adapted 2026-09-23: KPLIB namespace and mission-local state; the loop ends
 * when taskReset clears the tactic (soft resets keep the group); the FiredNear
 * failsafe is registered for taskReset cleanup; LAMBS debug hooks were removed.
 * License: see NOTICE.md and LICENSE.LAMBS in this directory.
 *
 * Creep up close: the group creeps as close as possible before opening fire.
 * Stance is based on distance and cover, speed is always limited, and fire is
 * held for as long as possible.
 *
 * Arguments:
 * 0: Group performing action, either unit <OBJECT> or group <GROUP>
 * 1: Range of tracking, default 1000 meters <NUMBER>
 * 2: Delay of cycle, default 30 seconds <NUMBER>
 * 3: Area the AI camps in, default [] <ARRAY>
 * 4: Center position; empty uses the group and follows it, default [] <ARRAY>
 * 5: Only players, default false <BOOL>
 *
 * Return Value: success <BOOL>
 */

if (!canSuspend) exitWith {
    _this spawn KPLIB_fnc_creep;
};

params [
    ["_group", grpNull, [grpNull, objNull]],
    ["_radius", TASK_CREEP_SIZE, [0]],
    ["_cycle", TASK_CREEP_CYCLETIME, [0]],
    ["_area", [], [[]]],
    ["_pos", [], [[]]],
    ["_onlyPlayers", TASK_CREEP_PLAYERSONLY, [false]]
];

private _fnc_creepOrders = {
    params ["_group", "_target"];

    // distance
    private _newDist = (leader _group) distance2D _target;
    private _in_forest = ((selectBestPlaces [getPos (leader _group), 2, "(forest + trees)*0.5", 1, 1]) select 0) select 1;

    // danger mode? go for it!
    if (behaviour (leader _group) isEqualTo "COMBAT") exitWith {
        _group setCombatMode "RED";
        {
            _x setUnitPos "MIDDLE";
            _x doMove (getPosATL _target);
            true
        } count (units _group);
    };

    // vehicle? wait for it
    if (_newDist < 150 && {vehicle _target isKindOf "Landvehicle"}) exitWith {
        _group reveal _target;
        { _x setUnitPos "DOWN"; true } count (units _group);
    };

    // adjust behaviour
    if (_in_forest > 0.9 || _newDist > 200) then { { _x setUnitPos "UP"; true} count (units _group); };
    if (_in_forest < 0.6 || _newDist < 100) then { { _x setUnitPos "MIDDLE"; true} count (units _group); };
    if (_in_forest < 0.4 || _newDist < 50) then { { _x setUnitPos "DOWN"; true} count (units _group); };
    if (_newDist < 40) exitWith { _group setCombatMode "RED"; _group setBehaviour "STEALTH"; };

    // move
    private _i = 0;
    {
        _x doMove (_target getPos [_i, random 360]);
        _i = _i + random 10;
        true
    } count (units _group);
};

if (!local _group) exitWith {false};
if (_group isEqualType objNull) then {_group = group _group};
if (isNull _group) exitWith {false};

_group setBehaviour "AWARE";
_group setFormation "WEDGE";
_group setSpeedMode "LIMITED";
_group setCombatMode "GREEN";
_group enableAttack false;
_group setVariable ["KPLIB_lambs_currentTactic", "taskCreep"];

// failsafe!
{
    private _firedNear = _x addEventHandler ["FiredNear", {
        params ["_unit"];
        _unit setCombatMode "RED";
        (group _unit) enableAttack true;
        _unit removeEventHandler ["FiredNear", _thisEventHandler];
        _unit setVariable ["KPLIB_lambs_taskEventHandlers", nil];
    }];
    _x setVariable ["KPLIB_lambs_taskEventHandlers", [["FiredNear", _firedNear]]];
    true
} count units _group;

private _active = {!isNull _group && {(_group getVariable ["KPLIB_lambs_currentTactic", ""]) == "taskCreep"}};

waitUntil {
    waitUntil {
        sleep 1;
        !(call _active) || {simulationEnabled leader _group}
    };
    if !(call _active) exitWith {true};

    private _target = [_group, _radius, _area, _pos, _onlyPlayers] call KPLIB_fnc_findClosestTarget;
    if (isNull _target) then {
        _group setCombatMode "GREEN";
        sleep (_cycle * 4);
    } else {
        [_group, _target] call _fnc_creepOrders;
        sleep _cycle;
    };
    !(call _active) || {(units _group) findIf {_x call KPLIB_fnc_isAlive} == -1}
};

true
