/*
 * Author: nkenny
 * Adapted from LAMBS Danger.fsm taskReset.
 * Source: addons/wp/functions/fnc_taskReset.sqf
 * Upstream commit: 63122df5d9403a52f10bf50198ac75a49f0a3d6b
 * Adapted 2026-08-27 for KPLIB state and deterministic waypoint cleanup.
 * License: see NOTICE.md and LICENSE.LAMBS in this directory.
 */

params [
    ["_group", grpNull, [grpNull, objNull]],
    ["_softReset", false, [true]],
    ["_resetWaypoints", true, [true]]
];

if (!local _group) exitWith {_group};
if (_group isEqualType objNull) then {_group = group _group};
if (isNull _group) exitWith {grpNull};

private _units = units _group select {!isPlayer _x};
if (_resetWaypoints) then {
    [_group] call CBA_fnc_clearWaypoints;
};

_group setVariable ["KPLIB_lambs_enableGroupReinforce", nil];
_group setVariable ["KPLIB_lambs_currentTactic", nil];
_group setVariable ["KPLIB_lambs_baseGroup", nil];
_group setVariable ["KPLIB_lambs_taskPatrolRadius", nil, true];
_group setVariable ["KPLIB_lambs_taskPatrolPosition", nil, true];
_group setVariable ["KPLIB_lambs_taskPatrolArea", nil, true];

private _leader = leader _group;
{
    private _unit = _x;
    _unit doMove (getPosASL _unit);
    {
        _unit enableAI _x;
    } forEach ["MOVE", "PATH", "COVER", "SUPPRESSION", "FSM", "TARGET", "AUTOTARGET", "ANIM"];

    _unit forceSpeed -1;
    _unit setUnitPos "AUTO";
    _unit setUnitPosWeak "AUTO";

    if (isNull objectParent _unit && {_unit call KPLIB_fnc_isAlive}) then {
        [_unit, "", 2] call KPLIB_fnc_doAnimation;
        _unit playMove ([
            "AmovPercMstpSlowWrflDnon",
            "AmovPercMstpSnonWnonDnon"
        ] select (primaryWeapon _unit isEqualTo ""));
    };

    _unit setVariable ["KPLIB_lambs_currentTask", nil];
    _unit setVariable ["KPLIB_lambs_currentTarget", nil];
    _unit setVariable ["KPLIB_lambs_forceMove", nil];

    [_unit, _unit getVariable ["KPLIB_lambs_taskEventHandlers", []]] call KPLIB_fnc_removeLambsEventHandlers;
    [_unit, _unit getVariable ["KPLIB_lambs_garrisonEventHandlers", []]] call KPLIB_fnc_removeLambsEventHandlers;
    _unit setVariable ["KPLIB_lambs_taskEventHandlers", nil];
    _unit setVariable ["KPLIB_lambs_garrisonEventHandlers", nil];
    _unit doFollow _leader;
} forEach _units;

if (_softReset) exitWith {
    _units joinSilent _group;
    _group
};

private _newGroup = createGroup [side _group, true];
_newGroup setGroupIdGlobal [groupId _group];
_newGroup setFormation (formation _group);
_units joinSilent _newGroup;

if (dynamicSimulationEnabled _group) then {
    [_newGroup, true] remoteExecCall ["enableDynamicSimulation", 2];
};

_newGroup setBehaviour "AWARE";
_group deleteGroupWhenEmpty true;
_newGroup
