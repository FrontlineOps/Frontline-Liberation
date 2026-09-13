/* Game damage uses dimensionless response relative to the declared game source.
   No medical pressure thresholds. Stationary samples use native integrated
   impulse; changing cells does not replay that cell's old pressure history. */
if (!isServer || {isRemoteExecuted}) exitWith {};
params ["_job", "_index"];
private _unit = (_job get "targets") select _index;
private _debug = CBA_missionTime < (localNamespace getVariable ["KPLIB_munitionsUntil", -1]);
private _trace = _job getOrDefault ["gasTrace", createHashMap];
private _key = str _index;
private _age = CBA_missionTime - (_job get "at");
if (_debug) then {_job set ["gasTrace", _trace]};
if (isNull _unit || {!alive _unit}) exitWith {
    if (_debug) then {_trace set [_key, ["missing/dead recipient", _age]]};
};
private _profile = _job get "profile";
private _body = aimPos _unit;
private _cellSize = _job get "gasCell";
private _n = _job get "gasN";
private _grid = ((_body vectorDiff (_job get "origin")) vectorMultiply (1 / _cellSize)) apply {floor (_x + _n / 2)};
private _time = _job get "gasTime";
private _states = _job get "gasMeasures";
private _state = _states getOrDefault [_key, [0,-1,0,0,0,0,0]];
// State = sampled time, cell, field impulse, gauge pressure, normalized heat,
// recipient impulse and peak. Leaving the domain resets sampling, not dosage.
if (_grid findIf {_x < 0 || {_x >= _n}} >= 0) exitWith {
    if (_debug) then {_trace set [_key, ["outside sampled gas domain", _age, _grid, _n]]};
    _state set [0, _time];
    _state set [1, -2];
    _state set [3, 0];
    _state set [4, 0];
    _states set [_key, _state];
};
private _cell = (_grid select 0) + _n * ((_grid select 1) + _n * (_grid select 2));
// A coarse cell center can lie across a thin floor from the recipient.
// Select the nearest visible center from this cell and its six face neighbours.
// Never select by pressure or pass a native wall/terrain obstruction.
private _candidates = [];
{
    private _coords = _grid vectorAdd _x;
    if (_coords findIf {_x < 0 || {_x >= _n}} < 0) then {
        private _index = (_coords select 0) + _n * ((_coords select 1) + _n * (_coords select 2));
        private _point = [_job, _index] call KPLIB_fnc_gasPosition;
        _candidates pushBack [_point distance _body, _index, _point];
    };
} forEach [[0,0,0],[1,0,0],[-1,0,0],[0,1,0],[0,-1,0],[0,0,1],[0,0,-1]];
_candidates sort true;
private _fraction = 0;
{
    _x params ["", "_candidate", "_point"];
    private _visible = 0;
    if (_point select 2 >= getTerrainHeightASL _point) then {
        {
            if ([_point, _x, _unit] call KPLIB_fnc_blastClear) then {_visible = _visible + 1 / 3};
        } forEach [eyePos _unit, _body, (getPosASL _unit) vectorAdd [0,0,0.35]];
    };
    if (_visible > 0) exitWith {_cell = _candidate; _fraction = _visible};
} forEach _candidates;
private _reply = ["sample", [_job get "gasHandle",_cell,287.05]] call KPLIB_fnc_gasNative;
if !(_reply select 0) exitWith {
    _job set ["gasReason", _reply select 2];
    _job set ["truncated", true];
    if (_debug) then {_trace set [_key, ["native sample failed", _age, _reply select 2]]};
};
private _sample = _reply select 1;
private _dt = (_time - (_state select 0)) max 0;
private _pressure = ((_sample select 1) - 101325) max 0;
private _same = _cell == (_state select 1);
if (_state select 1 == -1) then {
    private _initial = (_job get "gasInitialPositions") select _index;
    private _initialGrid = ((_initial vectorDiff (_job get "origin")) vectorMultiply (1 / _cellSize)) apply {floor (_x + _n / 2)};
    _same = _initialGrid isEqualTo _grid && {_initial distance _body < 0.25 * _cellSize};
};
private _increment = if (_same) then {((_sample select 3) - (_state select 2)) max 0} else {0.5 * ((_state select 3) + _pressure) * _dt};
private _impulse = (_state select 5) + _increment * _fraction;
private _peak = (_state select 6) max (([_pressure, _sample select 2] select _same) * _fraction);
private _referenceP = (_job get "gasSourcePressure") max 1;
private _referenceI = _referenceP * _cellSize / 340;
private _heat = (((_sample select 5) - 101325 / (1.2 * 287.05)) max 0) / (_referenceP / (1.2 * 287.05)) * ((_sample select 10) max 0) * _fraction;
private _dose = (_job get "dose") getOrDefault [_key, [0,0]];
// Refine this event's cumulative maximum through the bounded job lifetime.
// Native credits match the original event time even when geometry was delayed.
private _gameDose = (_profile get "strength") * KPLIB_munitions_gas_damage_gain * (missionNamespace getVariable ["KPLIB_munitions_pressure_gain", 8]) * (0.5 * _peak / _referenceP + 0.5 * _impulse / _referenceI);
if (_age <= 8) then {
    _dose set [0, (_dose select 0) max (_gameDose min 24)];
} else {
    _job set ["gasLatePressure", true];
};
if (_profile get "thermal") then {
    _dose set [1, ((_dose select 1) + (_profile get "strength") * KPLIB_munitions_gas_damage_gain * 0.3 * 0.5 * ((_state select 4) + _heat) * _dt / (_job get "gasEnd")) min 12];
};
_states set [_key, [_time,_cell,_sample select 3,_pressure,_heat,_impulse,_peak]];
(_job get "dose") set [_key, _dose];
private _sent = _job getOrDefault ["sentDose", createHashMap];
_job set ["sentDose", _sent];
private _previous = _sent getOrDefault [_key, [0,0]];
private _delta = [((_dose select 0) - (_previous select 0)) max 0, ((_dose select 1) - (_previous select 1)) max 0];
// Keep tiny pressure refinements together before ACE's discrete wound processing.
if (_delta select 0 < 0.25 && {_time < (_job get "gasEnd") - 0.00001}) then {_delta set [0, 0]};
if (_delta select 1 < 0.5 && {_time < (_job get "gasEnd") - 0.00001}) then {_delta set [1, 0]};
if (_debug) then {
    private _first = _job getOrDefault ["gasFirstSampleAge", createHashMap];
    _job set ["gasFirstSampleAge", _first];
    if (isNil {_first get _key}) then {_first set [_key, _age]};
    private _status = if (_delta findIf {_x > 0} >= 0) then {"dispatch pending"} else {"no new dose"};
    if (_fraction == 0) then {_status = "sample-to-body cover"};
    if (_age > 8) then {_status = "eight-second work deadline exceeded"};
    _trace set [_key, [_status, "owner", owner _unit, "first/last age", [_first get _key,_age], "solver s", _time, "cell", _cell, "visible fraction", _fraction, "current/peak Pa", [_pressure,_peak], "positive impulse", _impulse, "candidate pressure", _gameDose min 24, "accepted", +_dose, "previous dispatch", +_previous, "delta", +_delta]];
};
if (_delta findIf {_x > 0} < 0) exitWith {};
_sent set [_key, [(_previous select 0) + (_delta select 0), (_previous select 1) + (_delta select 1)]];
private _serial = 1 + (_job getOrDefault ["serial", 0]);
_job set ["serial", _serial];
private _payload = [_unit, (_job get "id") + ":" + str _serial, _profile get "ammo", _job get "at", _job get "origin", _delta, _job get "source"];
[_unit, _payload select 1, "DISPATCH", [_profile get "ammo", "field", _job get "id", "target index", _index, "age", _age, "dose", _delta, ["REMOTE SENT; inspect owner RPT", "LOCAL CALL"] select local _unit]] call KPLIB_fnc_blastTrace;
if (local _unit) then {_payload call KPLIB_fnc_blastApply} else {_payload remoteExecCall ["KPLIB_fnc_blastApply", owner _unit]};
[objNull, "GAS GAME DOSE", _body, [_job get "id", _time, _pressure, _impulse, _fraction, _delta], _unit] call KPLIB_fnc_munitionsEvent;
