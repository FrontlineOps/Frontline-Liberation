/* Server coordinator for owner-issued garrison requests. Human clients cannot
 * allocate positions. The owner supplies its cancellation token, not a slot.
 */
if (!isServer) exitWith {false};
params [
    ["_group", grpNull, [grpNull]],
    ["_units", [], [[]]],
    ["_center", [], [[]]],
    ["_radius", 50, [0]],
    ["_area", [], [[]]],
    ["_teleport", false, [false]],
    ["_height", false, [false]],
    ["_token", [], [[]]]
];
if !(_group isEqualType grpNull && {_units isEqualTypeAll objNull} && {_token isEqualTypeAll 0}
    && {count _token == 2} && {_area isEqualType []} && {count _area in [0, 4, 5]}
    && {_teleport isEqualType false} && {_height isEqualType false}) exitWith {false};
if (_area isNotEqualTo [] && {
    !((_area select [0, 3]) isEqualTypeAll 0)
    || {!((_area select 3) isEqualType false)}
    || {count _area == 5 && {!((_area select 4) isEqualType 0)}}
}) exitWith {false};
if (isNull _group || {_units isEqualTo []}) exitWith {false};
if (isRemoteExecuted && {
    remoteExecutedOwner != groupOwner _group
    || {allPlayers findIf {_x isKindOf "HeadlessClient_F" && {owner _x == remoteExecutedOwner}} < 0}
}) exitWith {false};
if !(_center isEqualTypeAll 0 && {count _center in [2, 3]}
    && {_radius isEqualType 0} && {_radius > 0 && {_radius <= 500}}
    && {_center distance2D leader _group <= 1000}) exitWith {false};
if (isRemoteExecuted) exitWith {
    [{_this call KPLIB_fnc_garrisonAssign}, _this] call CBA_fnc_execNextFrame;
    true
};
if (canSuspend) exitWith {
    [KPLIB_fnc_garrisonAssign, _this] call CBA_fnc_directCall
};
private _jobs = localNamespace getVariable ["KPLIB_garrisonJobs", createHashMap];
_units = _units arrayIntersect _units;
_units = _units select {
    group _x == _group && {_x call KPLIB_fnc_isAlive} && {!isPlayer _x}
    && {!captive _x} && {isNull objectParent _x}
    && {(_x getVariable ["KPLIB_garrisonToken", []]) isEqualTo _token}
    && {((_jobs getOrDefault [netId _x, []]) param [0, []]) isNotEqualTo _token}
};
private _assignments = [_units, _center, _radius, _area, _height, _token] call KPLIB_fnc_garrisonSelect;
private _retained = createHashMap;
{
    private _unit = _x select 0;
    private _key = netId _unit;
    private _job = _jobs get _key;
    if (!isNil "_job") then {_retained set [_key, _job]};
} forEach (localNamespace getVariable ["KPLIB_garrisonReservations", []]);
localNamespace setVariable ["KPLIB_garrisonJobs", _retained];
{
    _x params ["_unit", "_slot"];
    _retained set [netId _unit, [_token, _group, _center, _radius, _area, _height, 0, [], _slot, CBA_missionTime]];
    private _args = [_unit, _token, _slot, _teleport, 0];
    if (local _unit) then {_args call KPLIB_fnc_garrisonMove} else {_args remoteExecCall ["KPLIB_fnc_garrisonMove", _unit]};
} forEach _assignments;
true
