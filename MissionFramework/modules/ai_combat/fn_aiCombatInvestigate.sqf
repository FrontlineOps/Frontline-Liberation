/* Sound is an area cue, not a target. Idle groups and patrols investigate; other
   assigned orders are never replaced. A patrol detour lives on the group, so a
   new leader can finish it, and restores the same patrol afterwards. */
params ["_state"];
if (!isServer || {isRemoteExecuted}) exitWith {};
private _unit = _state get "unit";
if (isNull _unit || {!local _unit}) exitWith {};
private _group = group _unit;
private _tactic = _group getVariable ["KPLIB_lambs_currentTactic", ""];
private _detour = _group getVariable ["KPLIB_aiCombat_soundPatrol", []];
if (_detour isNotEqualTo [] && {leader _group == _unit}) exitWith {
    _detour params ["_until", "_patrol", "_destination"];
    // Re-tasked by its owner meanwhile (new waypoints or tactic): leave the new orders alone.
    if (count waypoints _group > 0 || {_tactic != "taskPatrol"}) exitWith {_group setVariable ["KPLIB_aiCombat_soundPatrol", nil]};
    // Linger briefly on arrival, then rebuild the same patrol.
    if (_unit distance2D _destination < 25) then {_until = _until min (CBA_missionTime + 15); _detour set [0, _until]};
    if (CBA_missionTime >= _until) then {
        _group setVariable ["KPLIB_aiCombat_soundPatrol", nil];
        _patrol call KPLIB_fnc_taskPatrol;
        if (KPLIB_aiCombat_debug) then {["Patrol resumed after investigating gunfire", "AI COMBAT"] call KPLIB_fnc_log};
    };
};
private _search = _state getOrDefault ["soundSearch", []];
private _ready = [_unit, true] call KPLIB_fnc_aiCombatEligible == ""
    && {leader _group == _unit}
    && {(units _group) findIf {isPlayer _x || {!isNull remoteControlled _x}} < 0}
    && {(units _group) findIf {
        (_x getVariable ["KPLIB_garrisonToken", []]) isNotEqualTo []
        || {!(_x checkAIFeature "PATH")}
        || {_x getVariable ["KPLIB_lambs_forceMove", false]}
        || {!isNull getAttackTarget _x}
    } < 0}
    && {behaviour _unit != "STEALTH"}
    && {count (_state get "job") == 0}
    && {isNull (_state get "target")};
private _patrol = _ready && {_tactic == "taskPatrol"} && {_detour isEqualTo []};
private _free = _ready
    && {count waypoints _group <= 1}
    && {_group getVariable ["TASKFORCEID", ""] == ""}
    && {_unit getVariable ["TASKFORCEID", ""] == ""}
    && {_tactic == ""};
if (_search isNotEqualTo []) exitWith {
    _search params ["_origin", "_destination", "_until", "_returning", "_ownerGroup"];
    // A new movement command belongs to its issuer; never restore over it.
    private _ours = currentCommand _unit in ["MOVE", ""]
        && {((expectedDestination _unit) select 0) distance2D _destination < 5};
    if (!_free || {_group != _ownerGroup} || {!_ours}) exitWith {
        if (_ours && {_group == _ownerGroup} && {count waypoints _group <= 1}
            && {_group getVariable ["TASKFORCEID", ""] == ""}
            && {_group getVariable ["KPLIB_lambs_currentTactic", ""] == ""}) then {doStop _unit};
        _state deleteAt "soundSearch";
    };
    if (_returning) exitWith {
        if (_unit distance2D _origin < 5 || {CBA_missionTime >= _until}) then {
            doStop _unit;
            _state deleteAt "soundSearch";
        };
    };
    if (!KPLIB_aiCombat_hearing || {CBA_missionTime >= _until}) then {
        _unit doMove _origin;
        _state set ["soundSearch", [_origin, _origin, CBA_missionTime + KPLIB_aiCombat_soundMemory, true, _group]];
    };
};
if (!(_free || {_patrol}) || {!KPLIB_aiCombat_hearing} || {_free && {!(currentCommand _unit in ["", "STOP"])}}) exitWith {};
private _heard = [_group, KPLIB_aiCombat_soundMemory] call KPLIB_fnc_aiCombatHeard;
if (_heard isEqualTo [] || {(_heard select 1) <= (_state getOrDefault ["soundInvestigatedAt", -1000])}
    || {CBA_missionTime < (_state getOrDefault ["nextSoundSearch", 0])}) exitWith {};
private _origin = getPosATL _unit;
private _estimate = ASLToATL (_heard select 0);
// Patrols look as far as their own patrol radius; idle groups step up to 100 m.
private _reach = if (_patrol) then {_group getVariable ["KPLIB_lambs_taskPatrolRadius", 200]} else {100};
private _distance = (_origin distance2D _estimate) min _reach;
if (_distance < 5) exitWith {};
private _destination = _origin getPos [_distance, _origin getDir _estimate];
if (surfaceIsWater _destination) exitWith {};
if (_patrol) then {
    private _waypoints = waypoints _group;
    private _resume = [_group, _group getVariable ["KPLIB_lambs_taskPatrolPosition", _origin], _reach,
        (count _waypoints) max 1, _group getVariable ["KPLIB_lambs_taskPatrolArea", []],
        _waypoints findIf {"taskPatrolWaypointStatement" in ((waypointStatements _x) select 1)} >= 0,
        _group getVariable ["KPLIB_lambs_enableGroupReinforce", false]];
    // With no waypoints nothing overrides the leader's move; the patrol ring is
    // rebuilt on resume rather than edited in place.
    [_group] call CBA_fnc_clearWaypoints;
    _group setSpeedMode "NORMAL";
    _unit doMove _destination;
    _group setVariable ["KPLIB_aiCombat_soundPatrol", [CBA_missionTime + 3 * KPLIB_aiCombat_soundMemory, _resume, _destination]];
} else {
    _unit doMove _destination;
    _state set ["soundSearch", [_origin, _destination, CBA_missionTime + KPLIB_aiCombat_soundMemory, false, _group]];
};
_state set ["soundInvestigatedAt", _heard select 1];
_state set ["nextSoundSearch", CBA_missionTime + 3 * KPLIB_aiCombat_soundMemory];
if (KPLIB_aiCombat_debug) then {
    [format ["%1 %2 investigating uncertain gunfire within %3 m", typeOf _unit, ["idle group", "patrol"] select _patrol, round _distance], "AI COMBAT"] call KPLIB_fnc_log;
};
