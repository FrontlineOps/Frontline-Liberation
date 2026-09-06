// Derived assignments are rebuilt from ownership and terrain, never saved as a second campaign.
// A saved operation owns one assignment ID and its last destination.
BATTLESPACE_DEFENSE_ASSIGNMENTS = createHashMap;
BATTLESPACE_DEFENSE_BLOCKED_ASSIGNMENTS = createHashMap;
BATTLESPACE_DEFENSE_LAYOUT_SIGNATURE = [];

BATTLESPACE_DEFENSE_POSITION_IS_FRIENDLY = {
    params ["_position"];
    private _nearest = [sectors_allSectors + ["startbase_marker"], _position] call BIS_fnc_nearestPosition;
    _nearest == "startbase_marker" || {_nearest in blufor_sectors}
};

BATTLESPACE_DEFENSE_ADD_FIELD_ASSIGNMENT = {
    params ["_id", "_sector", "_other", "_point", "_bearing"];
    if (surfaceIsWater _point || {[_point] call BATTLESPACE_DEFENSE_POSITION_IS_FRIENDLY}) exitWith {};
    if (sectors_allSectors findIf {getMarkerPos _x distance2D _point < 450} >= 0) exitWith {};
    private _position = +_point;
    private _role = "RECON_SCREEN";
    private _roads = _point nearRoads 200;
    if (_roads isNotEqualTo []) then {
        private _road = [_roads, _point] call BIS_fnc_nearestPosition;
        _position = getPosATL _road;
        _role = "DEFENSIVE_PATROL";
    } else {
        private _places = selectBestPlaces [_point, 150, "3 * hills + 2 * forest + trees - 100 * sea", 50, 1];
        if (_places isNotEqualTo []) then {_position = +((_places select 0) select 0)};
        private _concealment = (selectBestPlaces [_position, 10, "forest + trees", 10, 1]) param [0, [[], 0]];
        if ((_concealment select 1) > 0.5) then {_role = "AMBUSH"};
    };
    _position set [2, 0];
    if (surfaceIsWater _position || {[_position] call BATTLESPACE_DEFENSE_POSITION_IS_FRIENDLY}) exitWith {};
    if ((surfaceNormal _position select 2) < 0.8) exitWith {};
    if (sectors_allSectors findIf {getMarkerPos _x distance2D _position < 400} >= 0) exitWith {};
    private _duplicate = false;
    {
        if ((_y get "kind") == "FIELD" && {(_y get "position") distance2D _position < BATTLESPACE_FIELD_COVERAGE_MERGE_DISTANCE}) exitWith {_duplicate = true};
    } forEach BATTLESPACE_DEFENSE_ASSIGNMENTS;
    if (_duplicate) exitWith {};
    BATTLESPACE_DEFENSE_ASSIGNMENTS set [_id, createHashMapFromArray [
        ["kind", "FIELD"], ["sector", _sector], ["otherSector", _other],
        ["position", _position], ["bearing", _bearing], ["role", _role], ["target", 7], ["depth", 0]
    ]];
};

BATTLESPACE_DEFENSE_REBUILD_LAYOUT = {
    if (!isServer || {isNil "NETWORKED_SECTORS_LINKED"} || {!NETWORKED_SECTORS_LINKED}) exitWith {};
    private _sectors = keys BATTLESPACE_SECTOR_STATES;
    _sectors sort true;
    private _owners = _sectors apply {[_x, (BATTLESPACE_SECTOR_STATES get _x) getOrDefault ["owner", ""]]};
    private _signature = [_owners, BATTLESPACE_STRATEGIC_DEFENDER_MANPOWER_BY_DEPTH, BATTLESPACE_STRATEGIC_DEFENDER_FRONT_FORMATIONS, BATTLESPACE_FIELD_COVERAGE_SPACING, BATTLESPACE_FIELD_COVERAGE_MERGE_DISTANCE];
    if (_signature isEqualTo BATTLESPACE_DEFENSE_LAYOUT_SIGNATURE) exitWith {};
    BATTLESPACE_DEFENSE_LAYOUT_SIGNATURE = _signature;
    BATTLESPACE_DEFENSE_ASSIGNMENTS = createHashMap;
    private _depths = createHashMap;
    {
        private _state = BATTLESPACE_SECTOR_STATES get _x;
        if ((_state getOrDefault ["owner", ""]) != "OPFOR") then {continue};
        private _depth = [_x] call BATTLESPACE_DEFENSE_GET_FRONT_DEPTH;
        _depths set [_x, _depth];
        private _target = [_state getOrDefault ["type", ""], _depth] call BATTLESPACE_DEFENSE_GET_MANPOWER_TARGET;
        if (_target <= 0) then {continue};
        BATTLESPACE_DEFENSE_ASSIGNMENTS set ["OBJECTIVE:" + _x, createHashMapFromArray [
            ["kind", "OBJECTIVE"], ["sector", _x], ["position", getMarkerPos _x],
            ["role", "GARRISON"], ["target", _target], ["depth", _depth]
        ]];
    } forEach _sectors;
    private _edges = createHashMap;
    {
        private _sector = _x;
        if (_depths getOrDefault [_sector, 69] != 0) then {continue};
        private _origin = getMarkerPos _sector;
        private _links = +((NETWORKED_SECTORS getOrDefault [_sector, createHashMap]) getOrDefault ["Links", []]);
        _links sort true;
        {
            private _other = _x;
            private _friendly = _other in blufor_sectors || {_other == "startbase_marker"};
            if (!_friendly && {_depths getOrDefault [_other, 69] > 1}) then {continue};
            private _pair = [_sector, _other];
            _pair sort true;
            private _edge = _pair joinString ":";
            if (_edges getOrDefault [_edge, false]) then {continue};
            _edges set [_edge, true];
            private _end = getMarkerPos _other;
            private _length = _origin distance2D _end;
            private _direction = _origin getDir _end;
            private _available = if (_friendly) then {_length * 0.45} else {_length - 500};
            private _steps = 1 max ceil (_available / (BATTLESPACE_FIELD_COVERAGE_SPACING max 650));
            for "_step" from 1 to _steps do {
                private _distance = if (_friendly) then {_available * _step / _steps} else {_length * _step / (_steps + 1)};
                if (_distance < 500) then {continue};
                private _point = _origin getPos [_distance, _direction];
                [format ["FIELD:%1:%2", _edge, _step], _sector, _other, _point, _direction] call BATTLESPACE_DEFENSE_ADD_FIELD_ASSIGNMENT;
            };
        } forEach _links;
    } forEach _sectors;
};

BATTLESPACE_DEFENSE_ASSIGNMENT_ID = {
    params ["_operation"];
    private _id = _operation getOrDefault ["coverageId", ""];
    if (_id == "" && {(_operation getOrDefault ["defenseRole", ""]) == "GARRISON"}) then {
        _id = "OBJECTIVE:" + (_operation getOrDefault ["assignedSector", ""]);
    };
    _id
};

BATTLESPACE_DEFENSE_READ_COVERAGE = {
    private _coverage = createHashMap;
    {
        if ((_y getOrDefault ["kind", ""]) != "DEFENDER") then {continue};
        if !((_y getOrDefault ["phase", ""]) in ["DEPLOYING", "ON_STATION", "ENGAGED", "DISPLACING"]) then {continue};
        private _id = [_y] call BATTLESPACE_DEFENSE_ASSIGNMENT_ID;
        private _assignment = BATTLESPACE_DEFENSE_ASSIGNMENTS get _id;
        private _force = BATTLESPACE_TASK_FORCES get _x;
        if (isNil "_assignment" || {isNil "_force"}) then {continue};
        private _manpower = (_force param [3, createHashMap]) getOrDefault ["manpower", 0];
        if (_manpower <= 0) then {continue};
        private _field = (_assignment get "kind") == "FIELD";
        if (_field && {_manpower < BATTLESPACE_STRATEGIC_DEFENDER_RETREAT_MANPOWER}) then {continue};
        private _radius = if (_field) then {BATTLESPACE_FIELD_COVERAGE_RADIUS + 100} else {350};
        private _position = _force param [1, []];
        private _present = (_y getOrDefault ["phase", ""]) != "DEPLOYING" && {_position distance2D (_assignment get "position") <= _radius};
        private _counts = _coverage getOrDefault [_id, [0, 0, []]];
        private _index = [1, 0] select _present;
        _counts set [_index, (_counts select _index) + _manpower];
        (_counts select 2) pushBack _x;
        _coverage set [_id, _counts];
    } forEach BATTLESPACE_STRATEGIC_OPERATIONS;
    _coverage
};

BATTLESPACE_DEFENSE_FIELD_LEG = {
    params ["_id", "_force", "_operation"];
    private _center = _operation getOrDefault ["coveragePosition", []];
    if (_center isEqualTo []) exitWith {false};
    private _direction = _operation getOrDefault ["coverageBearing", 0];
    private _leg = 1 + (_operation getOrDefault ["coverageLeg", 0]);
    _operation set ["coverageLeg", _leg];
    private _destination = _center getPos [BATTLESPACE_FIELD_COVERAGE_RADIUS * 0.65, _direction + ([0, 180] select (_leg mod 2 == 0))];
    if (surfaceIsWater _destination || {[_destination] call BATTLESPACE_DEFENSE_POSITION_IS_FRIENDLY} || {(surfaceNormal _destination select 2) < 0.8}) then {_destination = +_center};
    _destination set [2, 0];
    _force set [2, _destination];
    BATTLESPACE_TASK_FORCE_PATHS deleteAt _id;
    [_id, _force param [1, []], _destination] call QUEUE_PATHFIND_REQUEST
};
