/* CBA Suppressed event. Cheap event accounting only; recovery uses one worker. */
params ["_unit", ["_distance", 0], ["_shooter", objNull], ["_instigator", objNull]];
if (!isServer || {isRemoteExecuted} || {!KPLIB_aiSkills_enabled}
    || {!KPLIB_aiSkills_suppressionEnabled} || {!([_unit] call KPLIB_fnc_aiSkillsEligible)}) exitWith {};
private _attacker = [_instigator, _shooter] select isNull _instigator;
if (isNull _attacker || {(side group _unit) getFriend (side group _attacker) >= 0.6}) exitWith {};
private _state = (localNamespace getVariable "KPLIB_aiSkills_registry") getOrDefault [netId _unit, createHashMap];
if (count _state == 0) exitWith {};
private _now = CBA_missionTime;
private _decayFrom = (_state get "lastDecay") max ((_state get "lastThreat") + KPLIB_aiSkills_suppressionHold);
private _pressure = 0 max ((_state get "suppression") - (0 max (_now - _decayFrom)) / (0.1 max KPLIB_aiSkills_suppressionRecovery));
_state set ["suppression", 1 min (_pressure + KPLIB_aiSkills_suppressionImpact)];
_state set ["lastThreat", _now];
_state set ["lastDecay", _now];
