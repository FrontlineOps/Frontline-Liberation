/* Server-only placement. The expensive search runs scheduled, yields per candidate and
   produces a private plan. The case worker revalidates it before paying/spawning. */
KPLIB_INTEL_SERVER_SITE_CLEAR = {
    params ["_position", ["_radius", 0]];
    allPlayers findIf {alive _x && {_x distance2D _position < KPLIB_intelligence_spawn_clearance + _radius}} < 0
};

KPLIB_INTEL_SERVER_GROUND_POSITION = {
    params ["_position", "_radius"];
    if (surfaceIsWater _position || {isOnRoad _position} || {(surfaceNormal _position) # 2 < 0.96}) exitWith {[]};
    private _gradient = [0.12, 0.25] select (_radius < 1);
    private _safe = _position isFlatEmpty [_radius, -1, _gradient, _radius max 1, 0, false, objNull];
    if (_safe isEqualTo []) exitWith {[]};
    private _result = ASLToATL _safe;
    _result set [2, 0];
    _result
};

KPLIB_INTEL_SERVER_INTERIOR_POSITION = {
    params ["_building", "_position", ["_ignore", objNull]];
    private _asl = ATLToASL _position;
    private _floor = lineIntersectsSurfaces [_asl vectorAdd [0, 0, 0.4], _asl vectorAdd [0, 0, -0.6], _ignore, objNull, true, 1, "GEOM", "NONE"];
    if (_floor isEqualTo [] || {((_floor # 0) # 1) # 2 < 0.8}) exitWith {[]};
    private _feet = ((_floor # 0) # 0) vectorAdd [0, 0, 0.05];
    private _head = _feet vectorAdd [0, 0, 1.85];
    if (lineIntersectsSurfaces [_feet vectorAdd [0, 0, 0.15], _head, _ignore, objNull, true, 1, "GEOM", "NONE"] isNotEqualTo []) exitWith {[]};
    private _roof = lineIntersectsSurfaces [_head, _head vectorAdd [0, 0, 15], _ignore, objNull, true, 1, "GEOM", "NONE"];
    if (_roof isEqualTo [] || {!(_building in [(_roof # 0) # 2, (_roof # 0) # 3])}) exitWith {[]};
    private _blocked = false;
    {
        private _end = (_feet vectorAdd [0, 0, 0.8]) vectorAdd [0.45 * sin _x, 0.45 * cos _x, 0];
        if (lineIntersectsSurfaces [_feet vectorAdd [0, 0, 0.8], _end, _ignore, objNull, true, 1, "GEOM", "NONE"] isNotEqualTo []) exitWith {_blocked = true};
    } forEach [0, 90, 180, 270];
    if (_blocked) exitWith {[]};
    ASLToATL _feet
};

KPLIB_INTEL_SERVER_FIRE_LANES = {
    params ["_position", "_direction"];
    private _eye = (ATLToASL _position) vectorAdd [0, 0, 1.5];
    private _score = 0;
    {
        private _angle = _direction + _x;
        {
            private _end = ATLToASL (_position getPos [_x, _angle]);
            _end = _end vectorAdd [0, 0, 1.2];
            if (lineIntersectsSurfaces [_eye, _end, objNull, objNull, true, 1, "FIRE", "NONE"] isEqualTo []) then {_score = _score + 1};
        } forEach [65, 130, 220];
    } forEach [-25, 0, 25];
    _score
};

KPLIB_INTEL_SERVER_ROOM_TABLE_FITS = {
    params ["_position"];
    private _center = ATLToASL _position;
    private _fits = true;
    {
        private _corner = _center vectorAdd _x;
        private _floor = lineIntersectsSurfaces [_corner vectorAdd [0, 0, 0.2], _corner vectorAdd [0, 0, -0.25], objNull, objNull, true, 1, "GEOM", "NONE"];
        if (_floor isEqualTo [] || {lineIntersectsSurfaces [_center vectorAdd [0, 0, 0.8], _corner vectorAdd [0, 0, 0.8], objNull, objNull, true, 1, "GEOM", "NONE"] isNotEqualTo []}) exitWith {_fits = false};
    } forEach [[-0.7, -0.5, 0], [-0.7, 0.5, 0], [0.7, -0.5, 0], [0.7, 0.5, 0]];
    _fits
};

KPLIB_INTEL_SERVER_PLAN_SITE = {
    params ["_case", "_stage"];
    if (!(call KPLIB_INTEL_SERVER_INTERNAL) || {!canSuspend}) exitWith {createHashMap};
    private _center = markerPos (_case get "sector");
    private _buildings = nearestObjects [_center, ["House"], KPLIB_intelligence_site_radius];
    private _occupied = values (localNamespace getVariable "KPLIB_INTEL_CASES") select {(_x get "status") == "ACTIVE"};
    // Cheap filtering precedes a strict bound on geometry probes.
    _buildings = _buildings select {
        private _building = _x;
        alive _building && {count (_building buildingPos -1) >= 4}
            && {[getPosATL _building, 100] call KPLIB_INTEL_SERVER_SITE_CLEAR}
            && {_occupied findIf {(_x get "position") distance2D _building < 125} < 0}
    };
    private _ranked = [];
    {
        private _building = _x;
        if ((_case get "status") != "QUEUED" || {(_case get "stage") != _stage}) exitWith {};
        private _exit = _building buildingExit 0;
        if (_exit isEqualTo [0, 0, 0]) then {continue};
        private _positions = [];
        {
            private _pos = [_building, _x] call KPLIB_INTEL_SERVER_INTERIOR_POSITION;
            if (_pos isNotEqualTo [] && {_positions findIf {_x distance _pos < 1.8} < 0}) then {_positions pushBack _pos};
        } forEach ((_building buildingPos -1) select [0, 32]);
        if (count _positions >= 4) then {
            private _score = (count _positions min 12) * 3 - (_building distance2D _center) / 100;
            _ranked pushBack [_score, _forEachIndex, _building, _positions, _exit];
        };
        uiSleep 0.001;
    } forEach (_buildings select [0, 32]);
    _ranked sort false;
    private _result = createHashMap;
    {
        _x params ["_score", "_index", "_building", "_rooms", "_exit"];
        private _origin = getPosATL _building;
        private _roomScores = [];
        {
            private _position = _x;
            private _exposure = 0;
            private _bestLane = -1;
            private _watch = 0;
            for "_angle" from 0 to 315 step 45 do {
                private _lane = [_position, _angle] call KPLIB_INTEL_SERVER_FIRE_LANES;
                _exposure = _exposure + _lane;
                if (_lane > _bestLane) then {_bestLane = _lane; _watch = _angle};
            };
            // Prefer rooms away from exits and exposed windows for the source.
            _roomScores pushBack [(_position distance2D _exit) - 2 * _exposure, _forEachIndex, _position, _watch, _bestLane];
            uiSleep 0.001;
        } forEach _rooms;
        _roomScores sort false;
        private _targetIndex = if (_stage == 0) then {_roomScores findIf {[_x # 2] call KPLIB_INTEL_SERVER_ROOM_TABLE_FITS}} else {0};
        if (_targetIndex < 0) then {continue};
        private _target = +((_roomScores # _targetIndex) # 2);
        private _approach = _origin getDir _exit;
        private _roads = _origin nearRoads 150;
        if (_roads isNotEqualTo []) then {
            private _road = ([_roads, [], {_origin distance2D _x}, "ASCEND"] call BIS_fnc_sortBy) # 0;
            _approach = _origin getDir _road;
        };
        private _outdoor = [];
        for "_i" from 0 to 95 do {
            private _direction = (_approach + _i * 137.508) mod 360;
            private _pos = [_origin getPos [18 + 17 * (_i mod 4), _direction], 0.75] call KPLIB_INTEL_SERVER_GROUND_POSITION;
            if (_pos isEqualTo []) then {continue};
            // Face outward: neither the source room nor other posts are in the near firing line.
            private _watch = _origin getDir _pos;
            private _lanes = [_pos, _watch] call KPLIB_INTEL_SERVER_FIRE_LANES;
            {
                private _candidateDirection = (_origin getDir _pos) + _x;
                private _candidateLanes = [_pos, _candidateDirection] call KPLIB_INTEL_SERVER_FIRE_LANES;
                if (_candidateLanes > _lanes) then {_lanes = _candidateLanes; _watch = _candidateDirection};
            } forEach [-40, 40];
            private _rear = (ATLToASL (_pos getPos [8, _watch + 180])) vectorAdd [0, 0, 0.8];
            private _cover = count (lineIntersectsSurfaces [(ATLToASL _pos) vectorAdd [0, 0, 0.8], _rear, objNull, objNull, true, 1, "FIRE", "NONE"]);
            private _approachWeight = 1 + cos (_watch - _approach);
            _outdoor pushBack [3 * _lanes + _cover + _approachWeight, _i, _pos, _watch, _lanes];
            uiSleep 0.001;
        };
        _outdoor sort false;
        private _posts = [];
        private _gunCount = (KPLIB_intelligence_site_statics max 0) min 2;
        private _savedAssets = _case getOrDefault ["assetRoster", []];
        {if ((_x # 3) == "GUN") then {_gunCount = _gunCount max (1 + (_x # 4))}} forEach _savedAssets;
        {
            if (count _posts >= _gunCount) exitWith {};
            private _candidate = _x;
            if ((_candidate # 4) < 3) then {continue};
            if ([_candidate # 2, 2.1] call KPLIB_INTEL_SERVER_GROUND_POSITION isEqualTo []) then {continue};
            if (_posts findIf {(_x # 2) distance2D (_candidate # 2) < 18 || {cos ((_x # 3) - (_candidate # 3)) > 0.707}} >= 0) then {continue};
            _posts pushBack _candidate;
        } forEach _outdoor;
        if (count _posts < _gunCount) then {continue};
        private _guardPositions = _posts apply {[_x # 2, _x # 3, "GUN"]};
        // Interior sentries retain authored walkable positions. Best window lanes watch outside.
        {
            if (count _guardPositions >= _gunCount + 6) exitWith {};
            if ((_x # 2) distance _target >= 2) then {_guardPositions pushBack [_x # 2, _x # 3, "ROOM"]};
        } forEach _roomScores;
        private _reserved = _posts apply {_x # 2};
        _reserved pushBack _target;
        {
            private _pos = _x # 2;
            if (_reserved findIf {_x distance2D _pos < 8} < 0) then {
                _guardPositions pushBack [_pos, _x # 3, "PERIMETER"];
                _reserved pushBack _pos;
            };
            if (count _guardPositions >= 22) exitWith {};
        } forEach _outdoor;
        private _needed = if (_case getOrDefault ["funded", false]) then {count (_case get "roster")} else {KPLIB_intelligence_site_guards # _stage};
        if (count _guardPositions < _needed) then {continue};
        // Support equipment is in the defended yard; HVT and papers stay inside.
        if (_stage == 2) then {
            private _yard = _outdoor findIf {private _pos = _x # 2; _reserved findIf {_x distance2D _pos < 5} < 0};
            if (_yard < 0) then {continue};
            _target = +((_outdoor # _yard) # 2);
        };
        private _fences = [];
        {
            private _pos = _x # 2;
            private _dir = _x # 3;
            // Low flanking sandbags leave the weapon's forward arc and rear access clear.
            {
                private _candidate = [_pos getPos [3.6, _dir + _x], 1.7] call KPLIB_INTEL_SERVER_GROUND_POSITION;
                if (_candidate isNotEqualTo []) then {_fences pushBack [_candidate, _dir + 90]};
            } forEach [-90, 90];
        } forEach _posts;
        _result = createHashMapFromArray [
            ["building", _building], ["target", _target], ["guards", _guardPositions], ["posts", _posts],
            ["fences", _fences], ["direction", getDir _building], ["createdAt", CBA_missionTime], ["stage", _stage]
        ];
        private _neededFences = _gunCount;
        {if ((_x # 3) == "FENCE") then {_neededFences = _neededFences max (1 + (_x # 4))}} forEach _savedAssets;
        if (count _fences >= _neededFences) exitWith {};
        _result = createHashMap;
    } forEach (_ranked select [0, 6]);
    _result
};

KPLIB_INTEL_SERVER_ASSET_ALIVE = {
    params ["_asset"];
    private _object = _asset # 0;
    !isNull _object && {alive _object} && {!(_object getVariable ["KPLIB_captured", false])}
        && {crew _object findIf {isPlayer _x || {side group _x == GRLIB_side_friendly}} < 0}
};

KPLIB_INTEL_SERVER_ASSET_REFUND = {
    params ["_sector", "_assets"];
    private _refund = createHashMap;
    {
        _x params ["_class", "_resource", "_cost"];
        if (_resource != "" && {_cost > 0}) then {_refund set [_resource, (_refund getOrDefault [_resource, 0]) + _cost]};
    } forEach _assets;
    if (count _refund > 0) then {[_sector, _refund] call BATTLESPACE_RESOURCE_DEPOSIT_CLAMPED};
};

KPLIB_INTEL_SERVER_DEPLOY_SITE = {
    params ["_case", "_plan"];
    if (!(call KPLIB_INTEL_SERVER_MUTATION_ALLOWED) || {(_case get "status") != "QUEUED"}) exitWith {false};
    private _stage = _case get "stage";
    private _sector = _case get "sector";
    private _building = _plan get "building";
    private _position = _plan get "target";
    if (!alive _building || {!([getPosATL _building, 100] call KPLIB_INTEL_SERVER_SITE_CLEAR)}) exitWith {false};
    if (values (localNamespace getVariable "KPLIB_INTEL_CASES") findIf {(_x get "status") == "ACTIVE" && {(_x get "position") distance2D _building < 125}} >= 0) exitWith {
        _case deleteAt "plan";
        false
    };
    private _funded = _case getOrDefault ["funded", false];
    private _roster = +(_case getOrDefault ["roster", []]);
    private _definitions = +(_case getOrDefault ["assetRoster", []]);
    private _cost = createHashMap;
    if (!_funded) then {
        private _roles = ["opfor_squad_leader", "opfor_medic", "opfor_machinegunner", "opfor_grenadier", "opfor_rpg", "opfor_marksman", "opfor_rifleman"];
        for "_i" from 0 to ((KPLIB_intelligence_site_guards # _stage) - 1) do {
            private _class = missionNamespace getVariable [_roles # (_i mod count _roles), opfor_rifleman];
            if (!isClass (configFile >> "CfgVehicles" >> _class)) then {_class = opfor_rifleman};
            _roster pushBack _class;
        };
        _cost set ["manpower", -(count _roster + ([0, 1] select (_stage == 1)))];
        private _statics = (missionNamespace getVariable ["BATTLESPACE_DEFENDERS_STATIC_CLASSES", []]) select {
            isClass (configFile >> "CfgVehicles" >> _x) && {_x isKindOf "StaticMGWeapon" || {_x isKindOf "StaticATWeapon"}}
        };
        if (_statics isNotEqualTo []) then {
            {
                _definitions pushBack [selectRandom _statics, "car", 1, "GUN", _forEachIndex];
            } forEach (_plan get "posts");
        };
        {
            _definitions pushBack ["Land_BagFence_Long_F", "construction_supplies", 1, "FENCE", _forEachIndex];
        } forEach (_plan get "fences");
        {
            _x params ["_class", "_resource", "_amount"];
            _cost set [_resource, (_cost getOrDefault [_resource, 0]) - _amount];
        } forEach _definitions;
    };
    // Lack of compatible emplacements queues a new site instead of silently weakening it.
    if (!_funded && {{(_x # 3) == "GUN"} count _definitions < (KPLIB_intelligence_site_statics min 2)}) exitWith {false};
    private _reservations = 0;
    {_reservations = _reservations + (_y # 0)} forEach (missionNamespace getVariable ["BATTLESPACE_TASK_FORCE_SPAWN_RESERVATIONS", createHashMap]);
    private _count = [] call KPLIB_fnc_getOpforCap;
    if (_count + _reservations + count _roster + 1 > BATTLESPACE_UNIT_CAP) exitWith {false};
    if (count _cost > 0 && {!([_sector, _cost] call BATTLESPACE_RESOURCE_APPLY_STRICT)}) exitWith {false};
    private _group = createGroup [GRLIB_side_enemy, true];
    private _patrol = createGroup [GRLIB_side_enemy, true];
    private _guards = [];
    private _assets = [];
    private _props = [];
    private _failed = isNull _group || {isNull _patrol};
    {_x setVariable ["acex_headless_blacklist", true, true]} forEach [_group, _patrol];
    if (!_failed) then {
        {
            _x params ["_class", "_resource", "_amount", "_role", "_index"];
            private _slot = if (_role == "GUN") then {
                private _post = (_plan get "posts") # _index;
                [_post # 2, _post # 3]
            } else {(_plan get "fences") param [_index, []]};
            if (_slot isEqualTo []) exitWith {_failed = true};
            _slot params ["_pos", "_dir"];
            private _object = createVehicle [_class, _pos, [], 0, "CAN_COLLIDE"];
            if (isNull _object) exitWith {_failed = true};
            private _up = surfaceNormal _pos;
            private _forward = [sin _dir, cos _dir, 0];
            private _right = vectorNormalized (_forward vectorCrossProduct _up);
            _object setVectorDirAndUp [_up vectorCrossProduct _right, _up];
            _object setPosATL _pos;
            _object setVariable ["KPLIB_intelligenceMission", true, true];
            _assets pushBack [_object, +_x];
            // Check actual model footprint, including faction weapons with unusually large bases.
            (boundingBoxReal _object) params ["_min", "_max"];
            private _radius = 0.5 * sqrt (((_max # 0) - (_min # 0)) ^ 2 + ((_max # 1) - (_min # 1)) ^ 2);
            if (_pos isFlatEmpty [_radius, -1, 0.12, _radius max 2, 0, false, _object] isEqualTo []) then {_failed = true};
        } forEach _definitions;
    };
    private _guns = (_assets select {((_x # 1) # 3) == "GUN"}) apply {_x # 0};
    if (!_failed) then {
        {
            private _slot = (_plan get "guards") # _forEachIndex;
            _slot params ["_pos", "_dir", "_role"];
            private _mobile = _role == "PERIMETER" && {_forEachIndex >= (count _roster - 4)};
            private _unit = [_x, _pos, [_group, _patrol] select _mobile] call KPLIB_fnc_createManagedUnit;
            if (isNull _unit) exitWith {_failed = true};
            _unit setPosATL _pos;
            _unit setDir _dir;
            _unit setVariable ["KPLIB_intelligenceMission", true, true];
            _guards pushBack _unit;
            if (_forEachIndex < count _guns) then {
                private _gun = _guns # _forEachIndex;
                _unit assignAsGunner _gun;
                _unit moveInGunner _gun;
                if (gunner _gun isNotEqualTo _unit) then {_failed = true};
            } else {
                if (!_mobile) then {
                    doStop _unit;
                    _unit disableAI "PATH";
                    _unit doWatch (_pos getPos [100, _dir]);
                    _unit setUnitPos (["AUTO", "UP"] select (_role == "ROOM"));
                };
            };
        } forEach _roster;
    };
    private _target = objNull;
    if (!_failed) then {
        if (_stage == 1) then {
            _target = [opfor_officer, _position, _group] call KPLIB_fnc_createManagedUnit;
            if (!isNull _target) then {
                _target setPosATL _position;
                removeAllWeapons _target;
                _target disableAI "PATH";
                _target setVariable ["KPLIB_intelligenceHVT", _case get "id", true];
                [_target, _sector, true] call KPLIB_INTEL_SERVER_CAPTURE_SOURCE;
            };
        } else {
            private _class = if (_stage == 0) then {KPLIB_intelObjectClasses # 0} else {"Land_CargoBox_V1_F"};
            if (_stage == 0) then {
                private _table = createVehicle ["Land_CampingTable_small_F", _position, [], 0, "CAN_COLLIDE"];
                if (!isNull _table) then {
                    _table setPosATL _position;
                    _props pushBack _table;
                    private _top = lineIntersectsSurfaces [(ATLToASL _position) vectorAdd [0, 0, 1.5], (ATLToASL _position) vectorAdd [0, 0, 0.2], objNull, objNull, true, 1, "GEOM", "NONE"];
                    if (_top isNotEqualTo [] && {_table in [(_top # 0) # 2, (_top # 0) # 3]}) then {
                        _position = ASLToATL (((_top # 0) # 0) vectorAdd [0, 0, 0.02]);
                    } else {_failed = true};
                } else {_failed = true};
            };
            _target = createVehicle [_class, _position, [], 0, "CAN_COLLIDE"];
            if (!isNull _target) then {
                _target setPosATL _position;
                _target setVariable ["KPLIB_intelligenceObjective", _case get "id", true];
                if (_stage == 0) then {[_target, _sector, false] call KPLIB_INTEL_SERVER_CAPTURE_SOURCE};
            };
        };
    };
    if (_failed || {isNull _target}) exitWith {
        {deleteVehicle _x} forEach (_guards + (_assets apply {_x # 0}) + _props + [_target]);
        {if (!isNull _x) then {deleteGroup _x}} forEach [_group, _patrol];
        private _refund = createHashMap;
        {_refund set [_x, -_y]} forEach _cost;
        if (count _refund > 0) then {[_sector, _refund] call BATTLESPACE_RESOURCE_RESTORE_TRANSFER};
        _case deleteAt "plan";
        false
    };
    _target setVariable ["KPLIB_intelligenceMission", true, true];
    {
        _x setBehaviourStrong "AWARE";
        _x setCombatMode "RED";
    } forEach [_group, _patrol];
    private _route = (_plan get "guards") select {(_x # 2) == "PERIMETER"};
    {
        private _wp = _patrol addWaypoint [_x # 0, 0];
        _wp setWaypointType "MOVE";
        _wp setWaypointSpeed "LIMITED";
        _wp setWaypointCompletionRadius 6;
    } forEach (_route select [0, 4]);
    if (_route isNotEqualTo []) then {(_patrol addWaypoint [(_route # 0) # 0, 0]) setWaypointType "CYCLE"};
    _case set ["target", _target];
    _case set ["position", getPosATL _target];
    _case set ["guards", _guards];
    _case set ["group", _group];
    _case set ["groups", [_group, _patrol]];
    _case set ["assets", _assets];
    _case set ["props", _props];
    _case set ["assetRoster", _definitions];
    _case set ["roster", _roster];
    _case set ["funded", true];
    _case set ["restoredPending", false];
    _case deleteAt "plan";
    _case set ["status", "ACTIVE"];
    if (_case getOrDefault ["restoreDestroyed", false]) then {
        _case set ["restoreDestroyed", false];
        [_case] call KPLIB_INTEL_SERVER_COMPLETE_CASE;
    };
    call KPLIB_INTEL_SERVER_CHANGED;
    true
};
