/* Timely game exposure before the diagnostic/refinement grid is ready.
   The native GAS result shares this event's cumulative dose, never adds a
   second complete pulse. Solid cover still requires a clear native ray. */
if (!isServer || {isRemoteExecuted}) exitWith {};
params ["_job"];
private _index = _job get "targetIndex";
private _targets = _job get "targets";
if (_index >= count _targets) exitWith {
    _job set ["targetIndex", 0];
    _job set ["primaryDoneAt", CBA_missionTime - (_job get "at")];
    _job set ["phase", "GAS_GEOMETRY"];
};
_job set ["targetIndex", _index + 1];
private _unit = _targets select _index;
if (isNull _unit || {!alive _unit}) exitWith {};
private _exposure = [_job, _unit, _job get "gasRadius"] call KPLIB_fnc_blastExposure;
_exposure params ["_pressure", "_path", "_fraction"];
_pressure = (_pressure * (missionNamespace getVariable ["KPLIB_munitions_pressure_gain", 8])) min 24;
// Direct exposure is provisional; the same event can later refine each channel.
private _KPLIB_blastTraumaServerContext = true;
[_job, _unit, [(_pressure * 0.2) min 2, (_pressure * 0.08) min 2], ["DIRECT", _pressure, _fraction]] call KPLIB_fnc_blastTrauma;
private _key = str _index;
private _dose = (_job get "dose") getOrDefault [_key, [0,0]];
private _sent = _job getOrDefault ["sentDose", createHashMap];
_job set ["sentDose", _sent];
private _previous = _sent getOrDefault [_key, [0,0]];
_dose set [0, (_dose select 0) max _pressure];
(_job get "dose") set [_key, _dose];
private _delta = ((_dose select 0) - (_previous select 0)) max 0;
private _rows = _job getOrDefault ["primaryExposure", []];
_rows pushBack [_index, CBA_missionTime - (_job get "at"), _pressure, _fraction, _path];
_job set ["primaryExposure", _rows];
if (_delta <= 0) exitWith {};
_sent set [_key, [_dose select 0, _previous select 1]];
private _profile = _job get "profile";
private _payload = [_unit, (_job get "id") + ":P:" + _key, _profile get "ammo", _job get "at", _job get "origin", [_delta,0], _job get "source"];
[_unit, _payload select 1, "PRIMARY DISPATCH", ["direct-cover GAME exposure", "age", CBA_missionTime - (_job get "at"), "fraction", _fraction, "dose", _delta]] call KPLIB_fnc_blastTrace;
if (local _unit) then {_payload call KPLIB_fnc_blastApply} else {_payload remoteExecCall ["KPLIB_fnc_blastApply", owner _unit]};
