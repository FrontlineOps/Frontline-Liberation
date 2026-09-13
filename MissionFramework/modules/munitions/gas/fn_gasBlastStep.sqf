/* One bounded work unit. Geometry, evolution, recipient sampling and replay
   extraction yield between units; a snapshot never mixes different solver times.
   Cover is sampled once, and recipient-to-cell visibility is checked again. */
if (!isServer || {isRemoteExecuted}) exitWith {};
params ["_job"];
private _id = _job get "gasHandle";
private _phase = _job get "phase";
if (_phase == "GAS_PRIMARY") exitWith {[_job] call KPLIB_fnc_blastPrimary};
if (_phase == "GAS_ASSETS") exitWith {[_job] call KPLIB_fnc_gasAssetStep};
private _fail = {
    params ["_reason"];
    _job set ["gasReason", _reason];
    _job set ["truncated", true];
    _job set ["phase", "DONE"];
};
if (_phase == "GAS_GEOMETRY") exitWith {
    private _first = _job get "gasFaceCursor";
    if (_first >= (_job get "gasFaceCount")) exitWith {
        private _part = [1,0.25] select ((_job get "profile") get "thermal");
        private _reply = ["fill", [_id,_job get "gasCentre",1,1.2,0,0,0,101325 + (_job get "gasSourcePressure") * _part,1]] call KPLIB_fnc_gasNative;
        if !(_reply select 0) exitWith {[_reply select 2] call _fail};
        _job set ["gasSeedPart", _part];
        _job set ["gasFrameRows", []];
        _job set ["gasFrameCursor", 0];
        _job set ["gasAfterFrame", "GAS_EVOLVE"];
        _job set ["phase", "GAS_FRAME"];
        _job set ["gasReason", "Running; static sampled geometry; prescribed heat is not combustion"];
        _job set ["gasGeometryMs", 1000 * (CBA_missionTime - (_job get "at"))];
        _job deleteAt "gasGeometryPositions";
    };
    // Topology is fixed by the validated cubic grid and native ABI. Cache only
    // index definitions; world obstructions are always queried for this event.
    private _topologies = localNamespace getVariable ["KPLIB_gasFaceTopology", createHashMap];
    localNamespace setVariable ["KPLIB_gasFaceTopology", _topologies];
    private _topology = _topologies getOrDefault [_job get "gasN", createHashMap];
    _topologies set [_job get "gasN", _topology];
    private _faces = _topology getOrDefault [_first, []];
    private _reply = [];
    if (_faces isEqualTo []) then {
        _reply = ["faces", [_id,_first,16]] call KPLIB_fnc_gasNative;
        if (_reply select 0) then {
            _faces = _reply select 1;
            _topology set [_first, _faces];
        };
    };
    if (_faces isEqualTo []) exitWith {[_reply select 2] call _fail};
    private _positions = _job getOrDefault ["gasGeometryPositions", createHashMap];
    _job set ["gasGeometryPositions", _positions];
    private _position = {
        params ["_index"];
        private _point = _positions get _index;
        if (isNil "_point") then {
            _point = [_job, _index] call KPLIB_fnc_gasPosition;
            _positions set [_index, _point];
        };
        _point
    };
    private _mask = 0;
    private _rays = [];
    private _indices = [];
    {
        _x params ["_a", "_b", "_axis", "_sign"];
        private _from = [_a] call _position;
        private _to = if (_b >= 0) then {[_b] call _position} else {
            private _offset = [0,0,0];
            _offset set [_axis, _sign * 0.5 * (_job get "gasCell")];
            _from vectorAdd _offset
        };
        if (_from select 2 >= getTerrainHeightASL _from && {_to select 2 >= getTerrainHeightASL _to}) then {
            _rays pushBack [_from, _to];
            _indices pushBack _forEachIndex;
        } else {
            _mask = _mask + 2^_forEachIndex;
            _job set ["gasWalls", 1 + (_job get "gasWalls")];
        };
    } forEach _faces;
    {
        if (!_x) then {
            _mask = _mask + 2^(_indices select _forEachIndex);
            _job set ["gasWalls", 1 + (_job get "gasWalls")];
        };
    } forEach ([_rays] call KPLIB_fnc_blastClearBatch);
    _reply = ["walls", [_id,_first,count _faces,_mask]] call KPLIB_fnc_gasNative;
    if !(_reply select 0) exitWith {[_reply select 2] call _fail};
    _job set ["gasFaceCursor", _first + count _faces];
};
if (_phase == "GAS_FRAME") exitWith {
    private _cursor = _job get "gasFrameCursor";
    private _indices = (_job get "gasProbes") select [_cursor,8];
    if (_indices isEqualTo []) exitWith {
        (_job get "gasFrames") pushBack [_job get "gasTime", _job get "gasFrameRows"];
        if ((_job get "gasFrameTimes") isNotEqualTo []) then {(_job get "gasFrameTimes") deleteAt 0};
        _job set ["phase", _job get "gasAfterFrame"];
    };
    private _reply = ["samples", [_id] + _indices] call KPLIB_fnc_gasNative;
    if !(_reply select 0) exitWith {[_reply select 2] call _fail};
    {
        (_job get "gasFrameRows") pushBack [(_x select 1) - 101325, _x select 5, _x select 10, _x select 3];
    } forEach (_reply select 1);
    _job set ["gasFrameCursor", _cursor + count _indices];
};
if (_phase == "GAS_TARGETS") exitWith {
    private _index = _job get "targetIndex";
    if (_index >= count (_job get "targets")) exitWith {
        _job set ["targetIndex", 0];
        _job set ["gasNextDose", (_job get "gasTime") + 0.1];
        if (_job get "gasTime" >= (_job get "gasEnd") - 0.00001) then {
            _job set ["phase", "GAS_ASSETS"];
            _job set ["gasReason", "Applying bounded vehicle/building game pressure floors"];
        } else {
            _job set ["phase", "GAS_EVOLVE"];
        };
    };
    [_job, _index] call KPLIB_fnc_gasBlastDose;
    _job set ["targetIndex", _index + 1];
};
if (_phase != "GAS_EVOLVE") exitWith {};
private _remaining = (_job get "gasEnd") - (_job get "gasTime");
if (_remaining > 0.00001) then {
    private _reply = ["advance", [_id,_remaining min 0.04,8,0.4]] call KPLIB_fnc_gasNative;
    if !(_reply select 0) exitWith {[_reply select 2] call _fail};
    _job set ["gasTime", (_reply select 1) select 0];
    _job set ["gasSteps", (_reply select 1) select 1];
    _job set ["gasMaxBatchMs", (_job getOrDefault ["gasMaxBatchMs", 0]) max ((_reply select 1) select 4)];
    // Prescribed energy release is a game input, not fuel chemistry. Account for
    // actual solver time advanced, including a budget-limited partial batch.
    if ((_job get "profile") get "thermal") then {
        private _desired = (_job get "gasEnergy") * (1 - (_job get "gasSeedPart")) * (((_job get "gasTime") / (0.5 * (_job get "gasEnd"))) min 1);
        private _joules = (_desired - (_job get "gasHeatAdded")) max 0;
        if (_joules > 0) then {
            _reply = ["heat", [_id,_job get "gasCentre",_joules]] call KPLIB_fnc_gasNative;
            if !(_reply select 0) exitWith {[_reply select 2] call _fail};
            _job set ["gasHeatAdded", _desired];
        };
    };
};
if (_job get "phase" == "DONE") exitWith {};
private _time = _job get "gasTime";
private _end = _job get "gasEnd";
private _nextPhase = if (_time >= (_job get "gasNextDose") || {_time >= _end - 0.00001}) then {"GAS_TARGETS"} else {"GAS_EVOLVE"};
private _frames = _job get "gasFrameTimes";
if (_frames isNotEqualTo [] && {_time >= (_frames select 0) - 0.00001}) then {
    _job set ["gasFrameRows", []];
    _job set ["gasFrameCursor", 0];
    _job set ["gasAfterFrame", _nextPhase];
    _job set ["phase", "GAS_FRAME"];
} else {
    _job set ["phase", _nextPhase];
};
