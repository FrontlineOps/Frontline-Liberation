/* Server-owned functional exposure history. Responses are dimensionless;
   physical readings are retained for inspection, never used as injury rules. */
if (!isServer || {isRemoteExecuted} || {isNil "_KPLIB_blastTraumaServerContext"}) exitWith {};
params ["_job", "_unit", "_response", ["_reading", []]];
if (!(missionNamespace getVariable ["KPLIB_munitions_trauma_enabled", true])
    || {isNull _unit} || {!alive _unit} || {!isDamageAllowed _unit}
    || {!(_unit getVariable ["ace_medical_allowDamage", true])}) exitWith {};
if (_response findIf {_x > 0} < 0) exitWith {};
private _now = CBA_missionTime;
private _at = _job get "at";
if (_now - _at > 8) exitWith {};
private _states = localNamespace getVariable "KPLIB_blastTraumaStates";
private _key = netId _unit;
if (_key in ["", "0:0"]) then {_key = str _unit};
private _state = _states getOrDefault [_key, createHashMap];
if (count _state == 0) then {
    if (count _states >= 512) exitWith {};
    _state = createHashMapFromArray [
        ["unit", _unit], ["at", _now], ["scores", [0, 0]], ["events", []],
        ["revision", 0], ["count", 0], ["last", _at], ["owner", -1], ["reset", -1]
    ];
    _states set [_key, _state];
};
if (count _state == 0 || {_state get "unit" != _unit} || {_at <= (_state get "reset")}) exitWith {};
private _events = (_state get "events") select {_now - (_x select 1) < 12};
private _id = _job get "id";
private _index = _events findIf {_x select 0 == _id};
private _previous = [0, 0];
if (_index >= 0) then {
    _previous = (_events select _index) select 2;
} else {
    if (count _events >= 64) exitWith {};
    _index = count _events;
};
if (_index < 0) exitWith {};
private _current = [(_response select 0) max (_previous select 0), (_response select 1) max (_previous select 1)];
private _delta = [(_current select 0) - (_previous select 0), (_current select 1) - (_previous select 1)];
if (_delta findIf {_x > 0.0001} < 0) exitWith {};
private _first = _index == count _events;
private _scores = [_state get "scores", _now - (_state get "at")] call KPLIB_fnc_blastTraumaDecay;
// A late refinement belongs to the original exposure time, not arrival time.
private _aged = [_delta, _now - _at] call KPLIB_fnc_blastTraumaDecay;
_scores = [((_scores select 0) + (_aged select 0)) min 3, ((_scores select 1) + (_aged select 1)) min 3];
_events set [_index, [_id, _at, _current]];
_state set ["events", _events];
_state set ["scores", _scores];
_state set ["at", _now];
_state set ["last", (_state get "last") max _at];
_state set ["reading", _reading];
if (_first) then {_state set ["count", 1 + (_state get "count")]};
[_state] call KPLIB_fnc_blastTraumaSend;

