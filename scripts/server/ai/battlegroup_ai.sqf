params [
    ["_grp", grpNull, [grpNull]],
    ["_startPoint", []]
];

if (isNull _grp) exitWith {};
if (isNil "reset_battlegroups_ai") then {reset_battlegroups_ai = false};

private _objPos = [_startPoint] call KPLIB_fnc_getNearestBluforObjective;

if(_objPos isEqualTo []) exitWith {
    diag_log format ["Battlegroup AI Group %1 could not find nearest blufor objective", groupId _grp];
};

[_objPos] remoteExec ["remote_call_incoming"];

private _startpos = getPos (leader _grp);

private _waypoint = [];

while {!((waypoints _grp) isEqualTo [])} do {deleteWaypoint ((waypoints _grp) select 0);};
{_x doFollow leader _grp} forEach units _grp;

_startpos = getPos (leader _grp);

_waypoint = _grp addWaypoint [_objPos, 175];
_waypoint setWaypointType "MOVE";
_waypoint setWaypointSpeed "NORMAL";
_waypoint setWaypointBehaviour "AWARE";
_waypoint setWaypointCombatMode "YELLOW";
_waypoint setWaypointCompletionRadius 30;

_waypoint = _grp addWaypoint [_objPos, 175];
_waypoint setWaypointType "SAD";
_waypoint = _grp addWaypoint [_objPos, 175];
_waypoint setWaypointType "SAD";
_waypoint = _grp addWaypoint [_objPos, 175];
_waypoint setWaypointType "SAD";
_waypoint = _grp addWaypoint [_objPos, 175];
_waypoint setWaypointType "CYCLE";



[
    {
        params ["_grp", "_objPos"];
        (((units _grp) select {alive _x}) isEqualTo []) || reset_battlegroups_ai
    },
    {
        params ["_grp", "_objPos"];
        if((((units _grp) select {alive _x}) isEqualTo [])) exitWith {};
        [
            {
                reset_battlegroups_ai = false;
            },
            [_grp],
            5
        ] call CBA_fnc_waitAndExecute;

        [
            {
                params ["_grp",  "_objPos"];


                
                if (!((units _grp) isEqualTo []) && (GRLIB_endgame == 0)) then {
            
                    [_grp, _objPos] call battlegroup_ai;
                };
            },
            [_grp, _objPos],
            GRLIB_battlegroup_delay
        ] call CBA_fnc_waitAndExecute;
    },
    [_grp, _objPos]
] call CBA_fnc_waitUntilAndExecute;
