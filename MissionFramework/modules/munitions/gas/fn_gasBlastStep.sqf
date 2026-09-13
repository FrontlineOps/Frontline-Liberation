/* One bounded work unit. Geometry, evolution, recipient sampling and replay
   extraction yield between units; a snapshot never mixes different solver times.
   Blocked connections can be refined and rechecked; body visibility is current. */
if (!isServer || {isRemoteExecuted}) exitWith {};
params ["_job"];
private _id = _job get "gasHandle";
private _phase = _job get "phase";
if (_phase == "GAS_PRIMARY") exitWith {[_job] call KPLIB_fnc_blastPrimary};
if (_phase == "GAS_ASSETS") exitWith {[_job] call KPLIB_fnc_gasAssetStep};
if (_phase == "GAS_OPENINGS") exitWith {[_job] call KPLIB_fnc_gasOpeningStep};
private _fail = {
    params ["_reason"];
    _job set ["gasReason", _reason];
    _job set ["truncated", true];
    _job set ["phase", "DONE"];
};
if (_phase == "GAS_SEED") exitWith {
    private _part = [1,0.25] select ((_job get "profile") get "thermal");
    private _reply = ["fill", [_id,_job get "gasCentre",1,1.2,0,0,0,101325 + (_job get "gasSourcePressure") * _part,1]] call KPLIB_fnc_gasNative;
    if !(_reply select 0) exitWith {[_reply select 2] call _fail};
    _job set ["gasSeedPart", _part];
    _job set ["gasFrameRows", []];
    _job set ["gasFrameCursor", 0];
    _job set ["gasAfterFrame", "GAS_EVOLVE"];
    _job set ["phase", "GAS_FRAME"];
    _job set ["gasReason", "Running; sampled openings; prescribed heat is not combustion"];
    _job set ["gasGeometryMs", 1000 * (CBA_missionTime - (_job get "at"))];
    _job deleteAt "gasGeometryPositions";
};
if (_phase == "GAS_GEOMETRY") exitWith {
    private _first = _job get "gasFaceCursor";
    if (_first >= (_job get "gasFaceCount")) exitWith {
        private _candidates = _job getOrDefault ["gasOpeningCandidates", []];
        _candidates sort true;
        private _supported = (missionNamespace getVariable ["KPLIB_gasNativeSchema", [0]]) select 0 >= 3;
        private _enabled = missionNamespace getVariable ["KPLIB_munitions_gas_openings", true];
        private _edges = if (_supported && {_enabled}) then {_candidates select [0,128]} else {[]};
        _job set ["gasOpeningOmissions", count _candidates - count _edges];
        _job set ["gasOpeningEdges", _edges];
        _job set ["gasOpeningCursor", 0];
        _job set ["gasOpeningAfter", "GAS_SEED"];
        _job set ["phase", "GAS_OPENINGS"];
        _job deleteAt "gasOpeningCandidates";
        private _watch = [];
        {
            private _object = _x;
            private _names = ((animationNames _object) select {
                private _name = toLower _x;
                _name find "door" >= 0 || {_name find "window" >= 0} || {_name find "gate" >= 0}
            }) select [0,32];
            private _parts = getAllHitPointsDamage _object;
            private _state = [damage _object, if (_parts isEqualTo []) then {[]} else {_parts select 2}, _names apply {_object animationPhase _x}];
            _watch pushBack [_object, _names, _state];
        } forEach (if (_edges isEqualTo []) then {[]} else {
            (nearestObjects [ASLToAGL (_job get "origin"), ["House"], (_job get "gasRadius") + 3, true]) select [0,8]
        });
        _job set ["gasGeometryWatch", _watch];
        _job set ["gasGeometryCheckAt", CBA_missionTime + 0.5];
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
    private _candidates = _job getOrDefault ["gasOpeningCandidates", []];
    private _surfaces = _job getOrDefault ["gasSurfaceCells", createHashMap];
    {
        if (!_x) then {
            private _slot = _indices select _forEachIndex;
            _mask = _mask + 2^_slot;
            _job set ["gasWalls", 1 + (_job get "gasWalls")];
            private _face = _faces select _slot;
            private _ray = _rays select _forEachIndex;
            _surfaces set [_face select 0, true];
            if (_face select 1 >= 0) then {
                _surfaces set [_face select 1, true];
                _candidates pushBack [(_ray select 0) distance (_job get "origin"), _first + _slot, _ray select 0, _ray select 1, _face select 2, _face select 3, 0];
            };
        };
    } forEach ([_rays] call KPLIB_fnc_blastClearBatch);
    _job set ["gasOpeningCandidates", _candidates];
    _job set ["gasSurfaceCells", _surfaces];
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
    private _KPLIB_gasDustContext = true;
    [_job, _indices, _reply select 1] call KPLIB_fnc_gasDust;
    _job set ["gasFrameCursor", _cursor + count _indices];
};
if (_phase == "GAS_TARGETS") exitWith {[_job] call KPLIB_fnc_gasTargetsStep};
if (_phase != "GAS_EVOLVE") exitWith {};
private _geometryChanged = false;
if (CBA_missionTime >= (_job getOrDefault ["gasGeometryCheckAt", 1e10])) then {
    _job set ["gasGeometryCheckAt", CBA_missionTime + 0.5];
    {
        _x params ["_object", "_names", "_previous"];
        private _parts = getAllHitPointsDamage _object;
        private _state = [damage _object, if (_parts isEqualTo []) then {[]} else {_parts select 2}, _names apply {_object animationPhase _x}];
        if (_state isNotEqualTo _previous || {isNull _object}) then {
            _geometryChanged = true;
            _x set [2, _state];
        };
    } forEach (_job getOrDefault ["gasGeometryWatch", []]);
    _job set ["gasGeometryWatch", (_job getOrDefault ["gasGeometryWatch", []]) select {!isNull (_x select 0)}];
};
if (_geometryChanged && {(_job getOrDefault ["gasOpeningEdges", []]) isNotEqualTo []}) exitWith {
    if ((_job getOrDefault ["gasOpeningPasses", 0]) < 4) then {
        _job set ["gasOpeningCursor", 0];
        _job set ["gasOpeningAfter", "GAS_EVOLVE"];
        _job set ["phase", "GAS_OPENINGS"];
    } else {
        _job set ["gasOpeningRechecksOmitted", true];
    };
};
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
    _job set ["gasFramePending", _nextPhase == "GAS_TARGETS"];
    _job set ["phase", ["GAS_FRAME", "GAS_TARGETS"] select (_nextPhase == "GAS_TARGETS")];
} else {
    _job set ["phase", _nextPhase];
};
