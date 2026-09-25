// Derived assignments are rebuilt from ownership, terrain and control cells, never saved as a
// second campaign. A saved operation owns one assignment ID and its last destination.
// OBJECTIVE: sector garrisons. CELL: dead-space squads on control cells ("CELL:cx:cy").
BATTLESPACE_DEFENSE_ASSIGNMENTS = createHashMap;
BATTLESPACE_DEFENSE_CELLS_READY = false;
// A cell squad keeps its cell this long before the cell competes with the rest of dead space.
BATTLESPACE_DEAD_SPACE_DWELL = 900;
BATTLESPACE_DEFENSE_BLOCKED_ASSIGNMENTS = createHashMap;
BATTLESPACE_DEFENSE_LAYOUT_SIGNATURE = [];

BATTLESPACE_DEFENSE_POSITION_IS_FRIENDLY = {
    params ["_position"];
    // Sector markers never move: resolve them once instead of on every query.
    if (isNil "BATTLESPACE_DEFENSE_FRIENDLY_MARKERS") then {
        BATTLESPACE_DEFENSE_FRIENDLY_MARKERS = sectors_allSectors + ["startbase_marker"];
        BATTLESPACE_DEFENSE_FRIENDLY_POSITIONS = BATTLESPACE_DEFENSE_FRIENDLY_MARKERS apply {getMarkerPos _x};
    };
    private _distances = BATTLESPACE_DEFENSE_FRIENDLY_POSITIONS apply {_position distance _x};
    private _nearest = BATTLESPACE_DEFENSE_FRIENDLY_MARKERS select (_distances find selectMin _distances);
    _nearest == "startbase_marker" || {_nearest in blufor_sectors}
};

BATTLESPACE_DEFENSE_ADD_CELL_ASSIGNMENT = {
    params ["_id", "_sector", "_point", "_bearing"];
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
    BATTLESPACE_DEFENSE_ASSIGNMENTS set [_id, createHashMapFromArray [
        ["kind", "CELL"], ["sector", _sector],
        ["position", _position], ["bearing", _bearing], ["role", _role], ["target", 7], ["depth", 0]
    ]];
};

BATTLESPACE_DEFENSE_REBUILD_LAYOUT = {
    if (!isServer || {isNil "NETWORKED_SECTORS_LINKED"} || {!NETWORKED_SECTORS_LINKED}) exitWith {};
    private _sectors = keys BATTLESPACE_SECTOR_STATES;
    _sectors sort true;
    private _owners = _sectors apply {[_x, (BATTLESPACE_SECTOR_STATES get _x) getOrDefault ["owner", ""]]};
    private _signature = [_owners, BATTLESPACE_STRATEGIC_DEFENDER_MANPOWER_BY_DEPTH, BATTLESPACE_STRATEGIC_DEFENDER_FRONT_FORMATIONS];
    if (_signature isEqualTo BATTLESPACE_DEFENSE_LAYOUT_SIGNATURE) exitWith {};
    BATTLESPACE_DEFENSE_LAYOUT_SIGNATURE = _signature;
    // Objectives follow ownership; cell assignments are owned by BATTLESPACE_DEFENSE_SELECT_CELLS.
    private _cells = createHashMap;
    {if ((_y get "kind") == "CELL") then {_cells set [_x, _y]}} forEach BATTLESPACE_DEFENSE_ASSIGNMENTS;
    BATTLESPACE_DEFENSE_ASSIGNMENTS = _cells;
    {
        private _state = BATTLESPACE_SECTOR_STATES get _x;
        if ((_state getOrDefault ["owner", ""]) != "OPFOR") then {continue};
        private _depth = [_x] call BATTLESPACE_DEFENSE_GET_FRONT_DEPTH;
        private _target = [_state getOrDefault ["type", ""], _depth] call BATTLESPACE_DEFENSE_GET_MANPOWER_TARGET;
        if (_target <= 0) then {continue};
        BATTLESPACE_DEFENSE_ASSIGNMENTS set ["OBJECTIVE:" + _x, createHashMapFromArray [
            ["kind", "OBJECTIVE"], ["sector", _x], ["position", getMarkerPos _x],
            ["role", "GARRISON"], ["target", _target], ["baseTarget", _target], ["depth", _depth]
        ]];
    } forEach _sectors;
};

// Dead space: each OPFOR-held theater keeps BATTLESPACE_DEAD_SPACE_SQUADS_PER_THEATER cell
// assignments on its contested, blue-pushing and longest-unvisited cells. A held cell stays
// for BATTLESPACE_DEAD_SPACE_DWELL; afterwards it competes, so squads roam the theater.
// Dropped cells free their squads for reassignment in the same allocation pass.
BATTLESPACE_DEFENSE_SELECT_CELLS = {
    if (!isServer || {BATTLESPACE_CELLS isEqualTo []}) exitWith {};
    [] call BATTLESPACE_CELL_UPDATE_BASELINE;
    BATTLESPACE_DEFENSE_CELLS_READY = true;
    private _held = createHashMap;
    {
        private _id = _y getOrDefault ["coverageId", ""];
        if ((_y getOrDefault ["kind", ""]) != "DEFENDER" || {(_id find "CELL:") != 0} || {(_y getOrDefault ["phase", ""]) in ["RETURNING", "LOST"]}) then {continue};
        // A cell restored from a save has no assignment yet and starts a fresh dwell.
        private _assignment = BATTLESPACE_DEFENSE_ASSIGNMENTS getOrDefault [_id, createHashMap];
        if (CBA_missionTime - (_assignment getOrDefault ["createdAt", CBA_missionTime]) < BATTLESPACE_DEAD_SPACE_DWELL) then {_held set [_id, true]};
    } forEach BATTLESPACE_STRATEGIC_OPERATIONS;
    private _picked = createHashMap;
    {
        private _theater = _forEachIndex;
        private _sectors = (_x get "sectors") select {((BATTLESPACE_SECTOR_STATES getOrDefault [_x, createHashMap]) getOrDefault ["owner", ""]) == "OPFOR"};
        if (_sectors isEqualTo []) then {continue};
        private _candidates = [];
        {
            _x params ["_center", "_cellTheater", "_control", "_contestedUntil", "_observedAt", "_baseline", "_sectorDistance", "_grid"];
            if (_cellTheater != _theater || {_sectorDistance < BATTLESPACE_CELL_DEAD_SPACE} || {_baseline > 0.5}) then {continue};
            private _id = format ["CELL:%1:%2", _grid select 0, _grid select 1];
            _candidates pushBack [
                ([0, 1000] select (_id in _held))
                    + ([0, 100] select (CBA_missionTime < _contestedUntil))
                    + ([0, 60] select (_control - _baseline > 0.2))
                    + (((CBA_missionTime - _observedAt) / 60) min 30),
                _id, _center
            ];
        } forEach BATTLESPACE_CELLS;
        _candidates sort false;
        private _chosen = [];
        {
            if (count _chosen >= BATTLESPACE_DEAD_SPACE_SQUADS_PER_THEATER) exitWith {};
            _x params ["", "_id", "_center"];
            if (_chosen findIf {_x distance2D _center < 700} >= 0) then {continue};
            _chosen pushBack _center;
            _picked set [_id, [_center, _sectors]];
        } forEach _candidates;
    } forEach BATTLESPACE_THEATERS;
    {BATTLESPACE_DEFENSE_ASSIGNMENTS deleteAt _x} forEach ((keys BATTLESPACE_DEFENSE_ASSIGNMENTS) select {
        ((BATTLESPACE_DEFENSE_ASSIGNMENTS get _x) get "kind") == "CELL" && {!(_x in _picked)}
    });
    {
        if (_x in BATTLESPACE_DEFENSE_ASSIGNMENTS) then {continue};
        _y params ["_center", "_sectors"];
        private _sector = [_sectors, _center] call BIS_fnc_nearestPosition;
        // Terrain picks the role: road -> defensive patrol, forest -> ambush, open -> recon screen.
        [_x, _sector, _center, (_center getDir getMarkerPos _sector) + 90] call BATTLESPACE_DEFENSE_ADD_CELL_ASSIGNMENT;
        private _assignment = BATTLESPACE_DEFENSE_ASSIGNMENTS get _x;
        if (!isNil "_assignment") then {_assignment set ["createdAt", CBA_missionTime]};
    } forEach _picked;
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
        if !((_y getOrDefault ["phase", ""]) in ["DEPLOYING", "ON_STATION", "CREEPING", "ENGAGED", "DISPLACING"]) then {continue};
        private _id = [_y] call BATTLESPACE_DEFENSE_ASSIGNMENT_ID;
        private _assignment = BATTLESPACE_DEFENSE_ASSIGNMENTS get _id;
        private _force = BATTLESPACE_TASK_FORCES get _x;
        if (isNil "_assignment" || {isNil "_force"}) then {continue};
        private _manpower = (_force param [3, createHashMap]) getOrDefault ["manpower", 0];
        if (_manpower <= 0) then {continue};
        private _cell = (_assignment get "kind") == "CELL";
        if (_cell && {_manpower < BATTLESPACE_STRATEGIC_DEFENDER_RETREAT_MANPOWER}) then {continue};
        private _radius = if (_cell) then {BATTLESPACE_CELL_SIZE + 100} else {350};
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

// Patrol legs cross the squad's cell along its bearing.
BATTLESPACE_DEFENSE_CELL_LEG = {
    params ["_id", "_force", "_operation"];
    private _center = _operation getOrDefault ["coveragePosition", []];
    if (_center isEqualTo []) exitWith {false};
    private _direction = _operation getOrDefault ["coverageBearing", 0];
    private _leg = 1 + (_operation getOrDefault ["coverageLeg", 0]);
    _operation set ["coverageLeg", _leg];
    private _destination = _center getPos [BATTLESPACE_CELL_SIZE * 0.65, _direction + ([0, 180] select (_leg mod 2 == 0))];
    if (surfaceIsWater _destination || {[_destination] call BATTLESPACE_DEFENSE_POSITION_IS_FRIENDLY} || {(surfaceNormal _destination select 2) < 0.8}) then {_destination = +_center};
    _destination set [2, 0];
    _force set [2, _destination];
    BATTLESPACE_TASK_FORCE_PATHS deleteAt _id;
    [_id, _force param [1, []], _destination] call QUEUE_PATHFIND_REQUEST
};
