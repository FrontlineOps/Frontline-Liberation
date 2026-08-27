#include "script_component.hpp"
/*
 * Author: nkenny
 * Adapted from LAMBS Danger.fsm taskHunt.
 * Source: addons/wp/functions/fnc_taskHunt.sqf
 * Upstream commit: 63122df5d9403a52f10bf50198ac75a49f0a3d6b
 * Adapted 2026-08-27 for the KPLIB namespace and mission-local state.
 * License: see NOTICE.md and LICENSE.LAMBS in this directory.
 */

if (!canSuspend) exitWith {
    _this spawn KPLIB_fnc_hunt;
};

params [
    ["_group", grpNull, [grpNull, objNull]],
    ["_radius", TASK_HUNT_SIZE, [0]],
    ["_cycle", TASK_HUNT_CYCLETIME, [0]],
    ["_area", [], [[]]],
    ["_pos", [], [[]]],
    ["_onlyPlayers", TASK_HUNT_PLAYERSONLY, [false]],
    ["_enableReinforcement", TASK_HUNT_ENABLEREINFORCEMENT, [false]],
    ["_doUGL", TASK_HUNT_TRYUGLFLARE, [1, true]]
];

private _launchFlare = {
    params ["_leader"];
    switch (_doUGL) do {
        case true;
        case 1: {
            private _units = units _leader;
            private _remainingUnits = [_units] call KPLIB_fnc_doUgl;
            if (_units isEqualTo _remainingUnits) then {
                private _flare = "F_20mm_Red" createVehicle (_leader modelToWorld [0, 0, 200]);
                _flare setVelocity [0, 0, -10];
            };
        };
        case 2: {
            [group _leader] call KPLIB_fnc_doUgl;
        };
    };
};

if (!local _group) exitWith {false};
if (_group isEqualType objNull) then {_group = group _group};
if (isNull _group) exitWith {false};

_group setBehaviour "SAFE";
_group setSpeedMode "LIMITED";
_group enableAttack false;
_group setVariable ["KPLIB_lambs_currentTactic", "taskHunt"];
_group setVariable ["KPLIB_lambs_enableGroupReinforce", _enableReinforcement];

waitUntil {
    waitUntil {
        sleep 1;
        isNull _group || {simulationEnabled leader _group}
    };

    if (isNull _group) exitWith {true};
    private _target = [_group, _radius, _area, _pos, _onlyPlayers] call KPLIB_fnc_findClosestTarget;
    private _combat = (behaviour (leader _group)) isEqualTo "COMBAT";
    private _onFoot = isNull (objectParent (leader _group));

    if (!isNull _target) then {
        _group move (_target getPos [
            random (linearConversion [50, 1000, (leader _group) distance2D _target, 25, 300, true]),
            random 360
        ]);
        _group setFormDir ((leader _group) getDir _target);
        _group setSpeedMode "NORMAL";
        _group enableGunLights "forceOn";
        _group enableIRLasers true;

        if (!_combat && {_onFoot} && {RND(0.8)}) then {
            [leader _group] call _launchFlare;
        };
    };

    sleep _cycle;
    (units _group) findIf {_x call KPLIB_fnc_isAlive} == -1
};

true
