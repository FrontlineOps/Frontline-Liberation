/* Sound is an area cue, not a target. Never replace an assigned group's orders. */
params ["_state"];
if (!isServer || {isRemoteExecuted}) exitWith {};
private _unit = _state get "unit";
if (isNull _unit || {!local _unit}) exitWith {};
private _group = group _unit;
private _search = _state getOrDefault ["soundSearch", []];
private _free = [_unit, true] call KPLIB_fnc_aiCombatEligible == ""
    && {leader _group == _unit}
    && {(units _group) findIf {isPlayer _x || {!isNull remoteControlled _x}} < 0}
    && {count waypoints _group <= 1}
    && {_group getVariable ["TASKFORCEID", ""] == ""}
    && {_unit getVariable ["TASKFORCEID", ""] == ""}
    && {_group getVariable ["KPLIB_lambs_currentTactic", ""] == ""}
    && {(units _group) findIf {
        (_x getVariable ["KPLIB_garrisonToken", []]) isNotEqualTo []
        || {!(_x checkAIFeature "PATH")}
        || {_x getVariable ["KPLIB_lambs_forceMove", false]}
        || {!isNull getAttackTarget _x}
    } < 0}
    && {behaviour _unit != "STEALTH"}
    && {count (_state get "job") == 0}
    && {isNull (_state get "target")};
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
if (!_free || {!KPLIB_aiCombat_hearing} || {!(currentCommand _unit in ["", "STOP"])}) exitWith {};
private _heard = _state get "heard";
if (_heard isEqualTo [] || {CBA_missionTime - (_heard select 1) >= KPLIB_aiCombat_soundMemory}
    || {(_heard select 1) <= (_state getOrDefault ["soundInvestigatedAt", -1000])}
    || {CBA_missionTime < (_state getOrDefault ["nextSoundSearch", 0])}) exitWith {};
private _origin = getPosATL _unit;
private _estimate = ASLToATL (_heard select 0);
private _distance = (_origin distance2D _estimate) min 100;
if (_distance < 5) exitWith {};
private _destination = _origin getPos [_distance, _origin getDir _estimate];
if (surfaceIsWater _destination) exitWith {};
_unit doMove _destination;
_state set ["soundSearch", [_origin, _destination, CBA_missionTime + KPLIB_aiCombat_soundMemory, false, _group]];
_state set ["soundInvestigatedAt", _heard select 1];
_state set ["nextSoundSearch", CBA_missionTime + 3 * KPLIB_aiCombat_soundMemory];
if (KPLIB_aiCombat_debug) then {
    [format ["%1 investigating uncertain gunfire within %2 m", typeOf _unit, round _distance], "AI COMBAT"] call KPLIB_fnc_log;
};
