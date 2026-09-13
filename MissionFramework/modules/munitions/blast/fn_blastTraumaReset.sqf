/* Full-heal callback or a single-use request from the current medical owner.
   A private server lease is required when native caller metadata is lost. */
params [["_unit", objNull, [objNull]], ["_at", CBA_missionTime, [0]], ["_lease", "", [""]]];
if (isNull _unit || {!(_unit isKindOf "CAManBase")} || {!finite _at}) exitWith {};
private _localHeal = !isRemoteExecuted && {!isNil "_KPLIB_blastTraumaHealContext"} && {local _unit};
if (!_localHeal && {!isServer}) exitWith {};
if (isRemoteExecuted && {remoteExecutedOwner != owner _unit}) exitWith {};
if (_at > CBA_missionTime + 0.5 || {CBA_missionTime - _at > 5}) exitWith {};
if (_localHeal) then {
    _unit setVariable ["KPLIB_blastTraumaHealed", _at];
    _unit setVariable ["KPLIB_blastTraumaLocal", []];
    [_unit, "forceWalk", "frontline_blast", false] call ace_common_fnc_statusEffect_set;
};
if (!isServer) exitWith {
    _lease = _unit getVariable ["KPLIB_blastTraumaLease", ""];
    if (_lease != "") then {[_unit, _at, _lease] remoteExecCall ["KPLIB_fnc_blastTraumaReset", 2]};
};
private _states = localNamespace getVariable "KPLIB_blastTraumaStates";
private _key = netId _unit;
if (_key in ["", "0:0"]) then {_key = str _unit};
private _state = _states getOrDefault [_key, createHashMap];
if (count _state == 0 || {_state get "unit" != _unit}) exitWith {};
if (!_localHeal && {
    _lease == "" || {count _lease > 96} || {_lease != (_state getOrDefault ["lease", ""])}
        || {owner _unit != (_state get "owner")} || {_at <= (_state get "reset")}
}) exitWith {};
private _damage = _unit getVariable ["ace_medical_bodyPartDamage", []];
if (count _damage != 6 || {_damage findIf {_x > 0.001} >= 0}
    || {_unit getVariable ["ace_medical_isBleeding", false]}
    || {_unit getVariable ["ace_medical_inCardiacArrest", false]}) exitWith {};
_state set ["scores", [0, 0]];
_state set ["events", []];
_state set ["at", CBA_missionTime];
_state set ["reset", _at];
_state set ["lease", ""];
// Send from a local callback; do not inherit the reset request's remote scope.
[{
    private _KPLIB_blastTraumaServerContext = true;
    _this call KPLIB_fnc_blastTraumaSend;
}, [_state]] call CBA_fnc_execNextFrame;

