/* Server-side, bounded construction geometry. Only cached model dimensions live
   outside a plan; temporary local probes are deleted before returning. */
localNamespace setVariable ["BATTLESPACE_FORTIFICATION_BOUNDS", createHashMap];

BATTLESPACE_FORTIFICATION_GET_BOUNDS = {
    params ["_class"];
    if (!isServer || {isRemoteExecuted}) exitWith {[]};
    private _cache = localNamespace getVariable "BATTLESPACE_FORTIFICATION_BOUNDS";
    private _bounds = _cache getOrDefault [_class, []];
    if (_bounds isNotEqualTo []) exitWith {_bounds};
    private _probe = createSimpleObject [_class, [0, 0, -100], true];
    if (isNull _probe) exitWith {[]};
    _bounds = boundingBoxReal _probe;
    deleteVehicle _probe;
    _cache set [_class, _bounds];
    _bounds
};

BATTLESPACE_FORTIFICATION_FIT_STRUCTURE = {
    params ["_class", "_position", "_heading", ["_validate", true]];
    private _bounds = [_class] call BATTLESPACE_FORTIFICATION_GET_BOUNDS;
    if (count _bounds < 2 || {count _position < 2}) exitWith {createHashMap};
    _bounds params ["_minimum", "_maximum"];
    private _earthwork = (_class find "HBarrier") >= 0 || {(_class find "BagFence") >= 0};
    private _weapon = _class isKindOf "StaticWeapon";
    private _normal = surfaceNormal _position;
    private _maxSlope = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_FORTIFICATION_MAX_SLOPE", 25];
    if (_validate && {surfaceIsWater _position || {(_normal # 2) < cos ([_maxSlope, 15] select _weapon)}}) exitWith {createHashMap};
    // Earthworks and tripods follow their own patch of ground. Occupied bunkers
    // need a level, supported floor; reject a hillside that cannot provide one.
    private _up = if (_earthwork || {_weapon}) then {_normal} else {[0, 0, 1]};
    if ((_up # 2) < 0.1) exitWith {createHashMap};
    private _forward = vectorNormalized [sin _heading, cos _heading,
        -(((_up # 0) * sin _heading + (_up # 1) * cos _heading) / (_up # 2))];
    private _right = _forward vectorCrossProduct _up;
    private _samples = [];
    private _heights = [];
    private _clear = true;
    {
        private _across = _x;
        {
            private _along = _x;
            private _offset = ((_right vectorMultiply _across) vectorAdd (_forward vectorMultiply _along)) vectorAdd (_up vectorMultiply (_minimum # 2));
            private _point = [(_position # 0) + (_offset # 0), (_position # 1) + (_offset # 1), 0];
            if (_validate && {surfaceIsWater _point || {isOnRoad _point}}) then {_clear = false};
            _samples pushBack [_point, _offset];
            _heights pushBack ((getTerrainHeightASL _point) - (_offset # 2));
        } forEach [_minimum # 1, ((_minimum # 1) + (_maximum # 1)) / 2, _maximum # 1];
    } forEach [_minimum # 0, ((_minimum # 0) + (_maximum # 0)) / 2, _maximum # 0];
    private _error = (selectMax _heights) - (selectMin _heights);
    private _tolerance = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_FORTIFICATION_TERRAIN_TOLERANCE", 0.3];
    if (_validate && {!_clear || {_error > _tolerance}}) exitWith {createHashMap};
    // Seat the lower edge slightly into soil rather than leaving a floating edge.
    private _world = [_position # 0, _position # 1, (selectMin _heights) - 0.03];
    if (_validate) then {
        // Dedicated-server rays can miss distant terrain geometry until its
        // objects are queried. Resolve this bounded footprint before casting.
        private _terrainRadius = ((_maximum vectorDistance _minimum) / 2) + 10;
        nearestTerrainObjects [_position, [], _terrainRadius, false, true];
        private _height = ((_maximum # 2) - (_minimum # 2)) max 1.8;
        private _obstacleSamples = +_samples;
        if (_weapon) then {
            // Collision feet can extend beyond the visible tripod bounds.
            // Leave a small clear margin without changing the planned pose.
            {
                private _across = _x;
                {
                    private _offset = (_right vectorMultiply _across) vectorAdd (_forward vectorMultiply _x);
                    _obstacleSamples pushBack [[(_position # 0) + (_offset # 0), (_position # 1) + (_offset # 1), 0]];
                } forEach [(_minimum # 1) - 0.35, ((_minimum # 1) + (_maximum # 1)) / 2, (_maximum # 1) + 0.35];
            } forEach [(_minimum # 0) - 0.35, ((_minimum # 0) + (_maximum # 0)) / 2, (_maximum # 0) + 0.35];
        };
        private _bottom = [];
        {
            private _point = _x # 0;
            private _ground = ATLToASL _point;
            // Start above compound walls: a short segment wholly inside a
            // stacked barrier can report no intersection. Also catch low feet.
            private _from = _ground vectorAdd [0, 0, 0.01];
            private _to = _ground vectorAdd [0, 0, (_height + 2) max 10];
            if (lineIntersectsSurfaces [_to, _from, objNull, objNull, true, 1, "GEOM", "NONE"] isNotEqualTo []) then {_clear = false};
            _bottom pushBack (_ground vectorAdd [0, 0, 0.15]);
        } forEach _obstacleSamples;
        // Perimeter and diagonals catch walls/fences between the vertical probes.
        {
            _x params ["_a", "_b"];
            {
                private _lift = [0, 0, _x];
                if (lineIntersectsSurfaces [(_bottom # _a) vectorAdd _lift, (_bottom # _b) vectorAdd _lift,
                    objNull, objNull, true, 1, "GEOM", "NONE"] isNotEqualTo []) then {_clear = false};
            } forEach [0, 0.8, (_height - 0.2) max 0];
        } forEach [[0, 2], [2, 8], [8, 6], [6, 0], [0, 8], [2, 6]];
    };
    if (!_clear && {_validate}) exitWith {createHashMap};
    createHashMapFromArray [["position", ASLToATL _world], ["rotation", _heading],
        ["className", _class], ["vectorDir", _forward], ["vectorUp", _up], ["ignoreCollision", true]]
};

BATTLESPACE_FORTIFICATION_APPLY_POSE = {
    params ["_object", "_definition", "_heading"];
    if (isNull _object || {!local _object} || {isRemoteExecuted}) exitWith {};
    private _pose = _definition;
    if (count (_pose getOrDefault ["vectorUp", []]) != 3) then {
        // Older saves retain their layout/identity, but earthworks are grounded
        // when next materialized. Never move or regenerate a paid old site.
        _pose = [typeOf _object, _definition get "position", _heading, false] call BATTLESPACE_FORTIFICATION_FIT_STRUCTURE;
    };
    if (count _pose == 0) exitWith {_object setDir _heading};
    _object setVectorDirAndUp [_pose get "vectorDir", _pose get "vectorUp"];
    _object setPosWorld (ATLToASL (_pose get "position"));
};

BATTLESPACE_FORTIFICATION_FIRE_LANE_CLEAR = {
    params ["_position", "_heading"];
    // Include off-camera terrain objects along the entire prospective lane.
    nearestTerrainObjects [_position getPos [50, _heading], [], 65, false, true];
    private _eye = (ATLToASL _position) vectorAdd [0, 0, 1.4];
    private _clear = 0;
    {
        private _end = (ATLToASL (_position getPos [100, _heading + _x])) vectorAdd [0, 0, 1.2];
        if (!terrainIntersectASL [_eye, _end]
            && {lineIntersectsSurfaces [_eye, _end, objNull, objNull, true, 1, "FIRE", "NONE"] isEqualTo []}) then {
            _clear = _clear + 1;
        };
    } forEach [-20, 0, 20];
    _clear >= 2
};
