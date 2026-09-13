/* One bounded unit of server work. The air field is a game approximation;
   grid openings smaller than a cell can be missed. No CFD or pressure units. */
if (!isServer || {isRemoteExecuted}) exitWith {};
params ["_job"];
if (_job getOrDefault ["backend", "LEGACY"] == "GAS") exitWith {[_job] call KPLIB_fnc_gasBlastStep};
private _profile = _job get "profile";
private _phase = _job get "phase";
if (_phase == "FIELD") exitWith {
    private _nodes = _job get "nodes";
    private _cursor = _job get "cursor";
    if (_cursor >= count _nodes) exitWith {
        _job set ["phase", "PRESSURE"];
        _job set ["thermalAt", CBA_missionTime];
    };
    private _node = _nodes select _cursor;
    _node params ["_position", "_cost", "", "", "_grid"];
    private _step = _profile get "cell";
    private _visited = _job get "visited";
    private _closed = 0;
    {
        private _nextGrid = _grid vectorAdd _x;
        private _next = _position vectorAdd (_x vectorMultiply _step);
        if (_next distance (_job get "origin") <= (_profile get "fieldRadius")) then {
            private _clear = [_position, _next] call KPLIB_fnc_blastClear;
            if (!_clear) then {
                if ((_x select 2) >= 0) then {_closed = _closed + 1};
            } else {
                private _key = str _nextGrid;
                if !(_key in _visited) then {
                    if (count _nodes < KPLIB_munitions_blast_cells) then {
                        _visited set [_key, true];
                        _nodes pushBack [_next, _cost + _step, 0, _cursor, _nextGrid];
                    } else {
                        _job set ["truncated", true];
                    };
                };
            };
        };
    } forEach [[1,0,0],[-1,0,0],[0,1,0],[0,-1,0],[0,0,1],[0,0,-1]];
    // Preserve the wider origin enclosure sample, rather than counting floor contact.
    if (_cursor > 0) then {_node set [2, _closed / 5]};
    _job set ["cursor", _cursor + 1];
    private _metrics = localNamespace getVariable "KPLIB_blastMetrics";
    _metrics set ["cells", 1 + (_metrics get "cells")];
};
if (_phase == "DONE" || {CBA_missionTime < (_job get "next")}) exitWith {};
private _targets = _job get "targets";
private _index = _job get "targetIndex";
if (_index >= count _targets) exitWith {
    _job set ["targetIndex", 0];
    if (_phase == "PRIMARY") then {
        if (_job get "needField") then {
            _job set ["phase", "FIELD"];
        } else {
            // Unobstructed open-air recipients need no grid search.
            _job set ["phase", ["DONE", "THERMAL"] select (_profile get "thermal")];
            _job set ["thermalAt", CBA_missionTime];
            private _last = _job get "last";
            {_last set [_x, 0]} forEach keys _last;
        };
    } else {
        if (_phase == "PRESSURE") then {
            _job set ["phase", ["DONE", "THERMAL"] select (_profile get "thermal")];
        } else {
            if (_job getOrDefault ["thermalFinish", false]) then {
                _job set ["phase", "DONE"];
            } else {
                _job set ["next", CBA_missionTime + 0.1];
            };
        };
    };
};
_job set ["targetIndex", _index + 1];
if (_phase == "THERMAL" && {_index == 0} && {CBA_missionTime - (_job get "thermalAt") >= KPLIB_munitions_thermal_duration}) then {
    _job set ["thermalFinish", true];
};
private _unit = _targets select _index;
if (isNull _unit || {!alive _unit}) exitWith {};
private _exposure = [_job, _unit] call KPLIB_fnc_blastExposure;
_exposure params ["_pressure", "_path", "_fraction", "_closed", "_from", "_body"];
if (_phase == "PRIMARY" && {_fraction < 0.999}) then {_job set ["needField", true]};
private _key = str _index;
private _dose = (_job get "dose") getOrDefault [_key, [0, 0]];
private _sent = _job getOrDefault ["sentDose", createHashMap];
_job set ["sentDose", _sent];
private _previous = _sent getOrDefault [_key, [0, 0]];
private _age = CBA_missionTime - (_job get "thermalAt");
if (_phase in ["PRIMARY", "PRESSURE"]) then {
    _pressure = (_pressure * (missionNamespace getVariable ["KPLIB_munitions_pressure_gain", 8])) min 24;
    private _KPLIB_blastTraumaServerContext = true;
    [_job, _unit, [(_pressure * 0.2) min 2, (_pressure * 0.08) min 2], ["LEGACY", _pressure, _fraction]] call KPLIB_fnc_blastTrauma;
    _dose set [0, (_dose select 0) max _pressure];
    (_job get "last") set [_key, _age];
    private _exposures = _job get "exposures";
    private _entry = [_unit, _pressure, _path, _fraction, _closed, _from, _body];
    private _existing = _exposures findIf {_x select 0 isEqualTo _unit};
    if (_existing < 0) then {_exposures pushBack _entry} else {_exposures set [_existing, _entry]};
    [objNull, "BLAST EXPOSURE", _body, [_job get "id", typeOf _unit, _pressure, _path, _fraction, _closed, CBA_missionTime - (_job get "at")], _unit] call KPLIB_fnc_munitionsEvent;
} else {
    private _duration = KPLIB_munitions_thermal_duration;
    private _last = (_job get "last") getOrDefault [_key, _age];
    // Expanding connected cloud. Smooth cumulative exposure gives frame-rate
    // independent integration for stationary samples; movement is sampled.
    private _before = [_path, _profile get "fieldRadius", _last, _duration, _closed] call KPLIB_fnc_blastEnvelope;
    private _after = [_path, _profile get "fieldRadius", _age, _duration, _closed] call KPLIB_fnc_blastEnvelope;
    private _integral = ((_after select 3) - (_before select 3)) max 0;
    if (_path <= (_profile get "fieldRadius")) then {
        // Venting reduces retained thermal exposure; it does not create a vacuum kill radius.
        private _thermal = (_profile get "strength") * 0.3 * _integral;
        _dose set [1, ((_dose select 1) + _thermal) min 12];
    };
    (_job get "last") set [_key, _age];
};
(_job get "dose") set [_key, _dose];
private _delta = [(_dose select 0) - (_previous select 0), (_dose select 1) - (_previous select 1)];
// Accumulate small heat samples before ACE's discrete wound generation.
if (_phase == "THERMAL" && {_delta select 1 < 0.5} && {_age < KPLIB_munitions_thermal_duration}) exitWith {};
if (_delta findIf {_x > 0} < 0) exitWith {};
_sent set [_key, +_dose];
private _serial = 1 + (_job getOrDefault ["serial", 0]);
_job set ["serial", _serial];
private _payload = [_unit, (_job get "id") + ":" + str _serial, _profile get "ammo", _job get "at", _job get "origin", _delta, _job get "source"];
if (local _unit) then {_payload call KPLIB_fnc_blastApply} else {_payload remoteExecCall ["KPLIB_fnc_blastApply", owner _unit]};
