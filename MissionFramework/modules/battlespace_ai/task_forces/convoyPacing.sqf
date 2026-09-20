/*
    Native convoy pacing. The server owns membership and spacing; the vehicle
    owner applies speed caps. No steering, waypoint replacement or cargo state.
    Runtime handlers disappear when a force is virtual, removed or reassigned.
*/
BATTLESPACE_CONVOY_PACE_APPLY = {
    if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {};
    if (!isRemoteExecuted && {!isServer}) exitWith {};
    params [["_vehicle", objNull, [objNull]], ["_id", "", [""]], ["_limit", -1, [0]], ["_braking", true, [true]]];
    if (isNull _vehicle || {!local _vehicle} || {!(_vehicle isKindOf "LandVehicle")}) exitWith {};
    private _previous = _vehicle getVariable ["BATTLESPACE_CONVOY_PACE_LIMIT", []];
    if (_limit < 0) exitWith {
        // After locality transfer the previous owner's local marker is absent.
        if (_previous isEqualTo [] || {(_previous param [0, ""]) == _id}) then {
            _vehicle limitSpeed (2 * getNumber (configOf _vehicle >> "maxSpeed"));
            _vehicle forceSpeed (_previous param [2, -1]);
            _vehicle setVariable ["BATTLESPACE_CONVOY_PACE_LIMIT", nil];
        };
    };
    private _driver = driver _vehicle;
    // TASKFORCEID is server-local metadata. Membership was checked by TICK;
    // a headless owner authenticates the server instead of reading that field.
    if (_id == "" || {isNull _driver}
        || {isPlayer _driver} || {!alive _driver} || {captive _driver}
        || {_vehicle getVariable ["KPLIB_captured", false]}) exitWith {};
    _vehicle limitSpeed _limit;
    private _original = _previous param [2, getForcedSpeed _vehicle];
    // limitSpeed alone does not reliably stop native road AI at zero.
    _vehicle forceSpeed ([_original, _limit / 3.6] select _braking);
    _vehicle setVariable ["BATTLESPACE_CONVOY_PACE_LIMIT", [_id, _limit, _original]];
};

BATTLESPACE_CONVOY_PACE_SEND = {
    params ["_vehicle", "_id", "_limit", ["_braking", true]];
    if (!isServer || {isRemoteExecuted} || {isNull _vehicle}) exitWith {};
    if (local _vehicle) then {
        [_vehicle, _id, _limit, _braking] call BATTLESPACE_CONVOY_PACE_APPLY;
    } else {
        [_vehicle, _id, _limit, _braking] remoteExecCall ["BATTLESPACE_CONVOY_PACE_APPLY", owner _vehicle];
    };
};

BATTLESPACE_CONVOY_PACE_PROGRESS = {
    params ["_position", "_segments", ["_first", 0]];
    private _nearest = 1e30;
    private _result = [0, 0, 1e30, [0, 1, 0]];
    if (_segments isEqualTo []) exitWith {_result};
    _first = (0 max _first) min (count _segments - 1);
    // Initial followers can be behind the logical leader. Once acquired, only
    // adjacent segments are considered; a crossing cannot jump route branches.
    for "_i" from 1 to 8 do {
        if (_first <= 0) exitWith {};
        if (_position distance2D ((_segments select (_first - 1)) select 0) >= _position distance2D ((_segments select _first) select 0)) exitWith {};
        _first = _first - 1;
    };
    for "_i" from _first to ((count _segments - 1) min (_first + 8)) do {
        (_segments select _i) params ["_start", "_direction", "_length", "_offset"];
        private _along = (_position vectorDiff _start) vectorDotProduct _direction;
        private _bounded = (_along max 0) min _length;
        private _distance = _position distance2D (_start vectorAdd (_direction vectorMultiply _bounded));
        if (_distance >= _nearest) exitWith {};
        _nearest = _distance;
        if (_i > 0) then {_along = _along max 0};
        if (_i < count _segments - 1) then {_along = _along min _length};
        _result = [_offset + _along, _i, _distance, _direction];
    };
    _result
};

BATTLESPACE_CONVOY_PACE_TICK = {
    params ["_args", "_handle"];
    if (!isServer || {isRemoteExecuted}) exitWith {};
    _args params ["_id", "_state"];
    private _force = BATTLESPACE_TASK_FORCES getOrDefault [_id, []];
    private _previous = _state getOrDefault ["vehicles", []];
    private _objects = _force param [8, []];
    if ((_force param [0, ""]) != "Convoy" || {_objects isEqualTo []} || {_force param [9, false]}) exitWith {
        {[_x, _id, -1] call BATTLESPACE_CONVOY_PACE_SEND} forEach _previous;
        [_handle] call CBA_fnc_removePerFrameHandler;
        (localNamespace getVariable ["BATTLESPACE_CONVOY_PACING", createHashMap]) deleteAt _id;
    };
    private _groups = _force param [4, []];
    private _vehicles = _objects select {
        private _driver = driver _x;
        _x isKindOf "LandVehicle" && {!(_x isKindOf "StaticWeapon")}
        && {alive _x} && {canMove _x} && {fuel _x > 0}
        && {!isNull _driver} && {alive _driver} && {!isPlayer _driver} && {!captive _driver}
        && {lifeState _driver != "INCAPACITATED"} && {group _driver in _groups}
        && {(_x getVariable ["TASKFORCEID", ""]) == _id}
        && {!(_x getVariable ["KPLIB_captured", false])}
    };
    {[_x, _id, -1] call BATTLESPACE_CONVOY_PACE_SEND} forEach (_previous - _vehicles);
    _state set ["vehicles", _vehicles];
    if (_vehicles isEqualTo []) exitWith {};

    private _route = BATTLESPACE_TASK_FORCE_PATHS getOrDefault [_id, []];
    if !(_route isEqualRef (_state getOrDefault ["route", []])) then {
        private _segments = [];
        private _offset = 0;
        for "_i" from 0 to (count _route - 2) do {
            private _a = +(_route select _i);
            private _b = +(_route select (_i + 1));
            _a set [2, 0];
            _b set [2, 0];
            private _length = _a distance2D _b;
            if (_length > 0.1) then {
                _segments pushBack [_a, _a vectorFromTo _b, _length, _offset];
                _offset = _offset + _length;
            };
        };
        _state set ["route", _route];
        _state set ["progress", createHashMap];
        _state set ["segments", _segments];
    };
    private _segments = _state getOrDefault ["segments", []];
    private _ceiling = 1e30;
    {
        private _maxSpeed = getNumber (configOf _x >> "maxSpeed");
        if (_maxSpeed <= 0) then {_maxSpeed = 45};
        _ceiling = _ceiling min _maxSpeed;
    } forEach _vehicles;
    private _cruise = (missionNamespace getVariable ["BATTLESPACE_CONVOY_CRUISE_SPEED", 45]) max 5;
    _cruise = _cruise min (0.8 * _ceiling);
    private _catchUp = (_cruise + 10) min _ceiling;
    private _spacing = ((missionNamespace getVariable ["BATTLESPACE_CONVOY_SPACING", 30]) max 20) min 60;
    private _ranked = [];
    private _forming = false;
    private _progress = _state getOrDefault ["progress", createHashMap];
    private _first = 0 max (((_force param [5, []]) param [1, 0]) - 1);
    {
        private _key = str _x;
        ([getPosATL _x, _segments, _progress getOrDefault [_key, _first]] call BATTLESPACE_CONVOY_PACE_PROGRESS) params ["_along", "_segment", "_distance", "_direction"];
        _progress set [_key, _segment];
        _ranked pushBack [_along, _forEachIndex, _x];
        private _turn = vectorDir _x vectorDotProduct _direction;
        if (_distance > 20 || {_turn < 0.5}) then {_forming = true};
    } forEach _vehicles;
    _ranked sort false;
    private _inCombat = _vehicles findIf {behaviour driver _x == "COMBAT"} >= 0;
    {
        _x params ["_progress", "_index", "_vehicle"];
        private _limit = _cruise;
        private _frontGap = -1;
        private _rearGap = -1;
        if (!_inCombat && {!_forming} && {_segments isNotEqualTo []}) then {
            if (_forEachIndex > 0) then {
                private _front = _ranked select (_forEachIndex - 1);
                _frontGap = (_front select 0) - _progress;
                _limit = _catchUp min (((speed (_front select 2)) max 0) + (_frontGap - _spacing));
            };
            if (_forEachIndex < count _ranked - 1) then {
                private _rear = _ranked select (_forEachIndex + 1);
                _rearGap = _progress - (_rear select 0);
                // Propagate a delayed tail to every vehicle ahead of it, so
                // the leaders cannot leapfrog a middle vehicle that is waiting.
                for "_j" from (_forEachIndex + 1) to (count _ranked - 1) do {
                    private _following = _ranked select _j;
                    private _gap = _progress - (_following select 0);
                    private _allowed = _spacing * (_j - _forEachIndex) + 10;
                    if (_gap > _allowed) then {
                        _limit = _limit min (((speed (_following select 2)) max 0) + 0.7 * (_allowed - _gap));
                    };
                };
            };
        };
        _limit = round ((_limit max 0) min _ceiling);
        [_vehicle, _id, _limit, !_inCombat && {!_forming}] call BATTLESPACE_CONVOY_PACE_SEND;
        _vehicle setVariable ["BATTLESPACE_CONVOY_PACE_SAMPLE", [_limit, _ceiling, _frontGap, _rearGap]];
    } forEach _ranked;
};

BATTLESPACE_CONVOY_PACE_START = {
    params ["_id", "_force"];
    if (!isServer || {isRemoteExecuted} || {(_force param [0, ""]) != "Convoy"}
        || {(_force param [8, []]) isEqualTo []}) exitWith {};
    private _handlers = localNamespace getVariable ["BATTLESPACE_CONVOY_PACING", createHashMap];
    if (_id in _handlers) exitWith {};
    private _args = [_id, createHashMap];
    private _handle = [BATTLESPACE_CONVOY_PACE_TICK, 1, _args] call CBA_fnc_addPerFrameHandler;
    _handlers set [_id, _handle];
    localNamespace setVariable ["BATTLESPACE_CONVOY_PACING", _handlers];
    [_args, _handle] call BATTLESPACE_CONVOY_PACE_TICK;
};
