/* Server snapshots are delivered only to the current medical owner. */
if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {};
if (!isRemoteExecuted && {!isServer || {isNil "_KPLIB_blastTraumaDeliveryContext"}}) exitWith {};
params [
    ["_unit", objNull, [objNull]], ["_revision", -1, [0]], ["_sent", -1, [0]],
    ["_at", -1, [0]], ["_scores", [], [[]]], ["_count", 0, [0]],
    ["_last", -1, [0]], ["_reading", [], [[]]], ["_reset", -1, [0]], ["_lease", "", [""]]
];
if (isNull _unit || {!local _unit} || {!(_unit isKindOf "CAManBase")}
    || {[_revision, _sent, _at, _count, _last, _reset] findIf {!finite _x} >= 0}
    || {_revision < 0} || {_revision != floor _revision} || {_count < 0}
    || {_sent > CBA_missionTime + 0.5} || {CBA_missionTime - _sent > 5}
    || {_at > _sent} || {count _scores != 2}
    || {_scores findIf {!(_x isEqualType 0) || {!finite _x} || {_x < 0} || {_x > 3}} >= 0}
    || {count _reading > 8} || {_lease == ""} || {count _lease > 96}) exitWith {};
private _previous = _unit getVariable ["KPLIB_blastTraumaLocal", []];
if (_previous isNotEqualTo [] && {_revision <= (_previous select 0)}) exitWith {};
private _healed = _unit getVariable ["KPLIB_blastTraumaHealed", -1];
if (_last <= _healed && {_reset < _healed}) exitWith {};
private _snapshot = [_revision, _sent, _at, +_scores, _count, _last, _reading, _reset];
_unit setVariable ["KPLIB_blastTraumaLocal", _snapshot];
_unit setVariable ["KPLIB_blastTraumaSnapshot", _snapshot];
_unit setVariable ["KPLIB_blastTraumaLease", _lease];
private _units = localNamespace getVariable "KPLIB_blastTraumaLocalUnits";
_units pushBackUnique _unit;
private _oldCount = if (_previous isEqualTo []) then {0} else {_previous select 4};
if (_count > _oldCount && {selectMax _scores > 0.15} && {alive _unit}
    && {!isNil "ace_medical_treatment_fnc_addToLog"}) then {
    [_unit, "activity", "Blast exposure: disorientation and balance recovery being monitored.", []] call ace_medical_treatment_fnc_addToLog;
};
