#include "script_component.hpp"
/*
 * Author: nkenny
 * Adapted from LAMBS Danger.fsm taskRush.
 * Source: addons/wp/functions/fnc_taskRush.sqf
 * Upstream commit: 63122df5d9403a52f10bf50198ac75a49f0a3d6b
 * Adapted 2026-08-27 for the KPLIB namespace and mission-local state.
 * License: see NOTICE.md and LICENSE.LAMBS in this directory.
 */

if (!canSuspend) exitWith {
    _this spawn KPLIB_fnc_rush;
};

params [
    ["_group", grpNull, [grpNull, objNull]],
    ["_radius", TASK_RUSH_SIZE, [0]],
    ["_cycle", TASK_RUSH_CYCLETIME, [0]],
    ["_area", [], [[]]],
    ["_pos", [], [[]]],
    ["_onlyPlayers", TASK_RUSH_PLAYERSONLY, [false]]
];

private _rushOrders = {
    params ["_rushGroup", "_target"];
    private _distance = (leader _rushGroup) distance _target;

    if (_distance < 200 && {(vehicle _target) isKindOf "Air"}) exitWith {
        units _rushGroup commandSuppressiveFire _target;
    };

    private _launcherUnits = [_rushGroup] call KPLIB_fnc_getLauncherUnits;
    if (_distance < 80 && {(vehicle _target) isKindOf "Tank"}) exitWith {
        {
            if (_x in _launcherUnits) then {
                _x setUnitPos "MIDDLE";
                _x selectWeapon (secondaryWeapon _x);
            } else {
                _x setUnitPos "DOWN";
                _x doSuppressiveFire _target;
            };
            true
        } count units _rushGroup;
        _rushGroup enableGunLights "forceOff";
    };

    private _movePos = call {
        private _targetPos = getPosATL _target;
        if (insideBuilding _target == 1 || {_distance < 20}) exitWith {_targetPos};
        private _emptyPos = _targetPos findEmptyPosition [0, 20, "O_MRAP_02_F"];
        if (_emptyPos isEqualTo []) exitWith {_targetPos};
        _emptyPos
    };

    {
        _x forceSpeed -1;
        _x setUnitPos (["UP", "MIDDLE"] select ((unitPos _x) isEqualTo "Down"));
        _x doMove _movePos;
        true
    } count units _rushGroup;
    _rushGroup enableGunLights "forceOn";
};

if (!local _group) exitWith {false};
if (_group isEqualType objNull) then {_group = group _group};
if (isNull _group) exitWith {false};

_group setSpeedMode "FULL";
_group enableAttack false;
_group allowFleeing 0;
{
    _x disableAI "AUTOCOMBAT";
    _x disableAI "FSM";

    private _firedEvent = _x addEventHandler ["Fired", {
        params ["_unit"];
        _unit forceSpeed 3;
    }];
    private _suppressedEvent = _x addEventHandler ["Suppressed", {
        params ["_unit", "", "_shooter"];
        private _unitPos = unitPos _unit;
        if (_unitPos isEqualTo "Down") exitWith {};
        if (_unitPos isEqualTo "Middle" && {_unit distance2D _shooter > 30}) exitWith {
            _unit setUnitPos "DOWN";
        };
        _unit setUnitPos "MIDDLE";
    }];

    _x setVariable [
        "KPLIB_lambs_taskEventHandlers",
        [["Fired", _firedEvent], ["Suppressed", _suppressedEvent]]
    ];
    doStop _x;
    true
} count units _group;

_group setVariable ["KPLIB_lambs_currentTactic", "taskRush"];

waitUntil {
    waitUntil {
        sleep 1;
        isNull _group || {simulationEnabled leader _group}
    };

    if (isNull _group) exitWith {true};
    private _target = [_group, _radius, _area, _pos, _onlyPlayers] call KPLIB_fnc_findClosestTarget;
    if (isNull _target) then {
        sleep (_cycle * 4);
    } else {
        [_group, _target] call _rushOrders;
        sleep (linearConversion [
            1000,
            2000,
            (leader _group) distance2D _target,
            _cycle,
            _cycle * 4,
            true
        ]);
    };

    (units _group) findIf {_x call KPLIB_fnc_isAlive} == -1
};

true
