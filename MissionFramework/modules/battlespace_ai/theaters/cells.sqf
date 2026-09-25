/* Territorial control cells (server; Zeus and the AI only). Land cells tile every theater,
   dead space included. Each keeps a derived, unsaved control value from -1 (OPFOR) to +1
   (BLUFOR): a baseline from the nearest OPFOR sector versus the nearest BLUFOR anchor
   (sector, start base, FOB), pushed by ground presence and frozen while contested.
   Cell row: [center, theater, control, contestedUntil, observedAt, baseline, sectorDistance, [cx, cy]]. */
BATTLESPACE_CELL_SIZE = 250 max (worldSize / 64);
BATTLESPACE_CELL_COLUMNS = ceil (worldSize / BATTLESPACE_CELL_SIZE);
BATTLESPACE_CELL_CONTEST_TIME = 180;
BATTLESPACE_CELL_DEAD_SPACE = 400;       // dead space: at least this far from every sector marker
BATTLESPACE_CELLS = [];
BATTLESPACE_CELL_LOOKUP = createHashMap; // cx * columns + cy -> row index
BATTLESPACE_CELL_BASELINE_SIGNATURE = [];
BATTLESPACE_CELL_CIVILIANS_AT = 0;

if (isServer) then {
    private _started = diag_tickTime;
    private _sectors = sectors_allSectors apply {[markerPos _x, BATTLESPACE_THEATER_OF_SECTOR get _x]};
    for "_cx" from 0 to BATTLESPACE_CELL_COLUMNS - 1 do {
        for "_cy" from 0 to BATTLESPACE_CELL_COLUMNS - 1 do {
            private _center = [(_cx + 0.5) * BATTLESPACE_CELL_SIZE, (_cy + 0.5) * BATTLESPACE_CELL_SIZE, 0];
            if (surfaceIsWater _center) then {continue};
            private _nearest = 1e9;
            private _theater = -1;
            {
                private _distance = _center distance2D (_x select 0);
                if (_distance < _nearest) then {_nearest = _distance; _theater = _x select 1};
            } forEach _sectors;
            BATTLESPACE_CELL_LOOKUP set [_cx * BATTLESPACE_CELL_COLUMNS + _cy, count BATTLESPACE_CELLS];
            BATTLESPACE_CELLS pushBack [_center, _theater, 0, -1, -1e9, 0, _nearest, [_cx, _cy]];
        };
    };
    [format ["Generated %1 land cells of %2 m in %3 ms", count BATTLESPACE_CELLS, round BATTLESPACE_CELL_SIZE, round ((diag_tickTime - _started) * 1000)], "BATTLESPACE"] call KPLIB_fnc_log;
};

// Row index of the land cell containing a position, or -1.
BATTLESPACE_CELL_INDEX_AT = {
    params ["_position"];
    if !(_position isEqualType [] && {count _position >= 2}) exitWith {-1};
    _position params ["_px", "_py"];
    if (_px < 0 || {_py < 0} || {_px >= worldSize} || {_py >= worldSize}) exitWith {-1};
    BATTLESPACE_CELL_LOOKUP getOrDefault [floor (_px / BATTLESPACE_CELL_SIZE) * BATTLESPACE_CELL_COLUMNS + floor (_py / BATTLESPACE_CELL_SIZE), -1]
};

// Row indices of a cell and its land neighbours within the given ring.
BATTLESPACE_CELL_AROUND = {
    params ["_index", ["_ring", 1]];
    ((BATTLESPACE_CELLS select _index) select 7) params ["_cx", "_cy"];
    private _around = [];
    for "_dx" from -_ring to _ring do {
        for "_dy" from -_ring to _ring do {
            private _nx = _cx + _dx;
            private _ny = _cy + _dy;
            if (_nx < 0 || {_ny < 0} || {_nx >= BATTLESPACE_CELL_COLUMNS} || {_ny >= BATTLESPACE_CELL_COLUMNS}) then {continue};
            private _other = BATTLESPACE_CELL_LOOKUP getOrDefault [_nx * BATTLESPACE_CELL_COLUMNS + _ny, -1];
            if (_other >= 0) then {_around pushBack _other};
        };
    };
    _around
};

// A contact report (sighting, heard fire, casualties, lost contact) contests its cell.
BATTLESPACE_CELL_CONTEST = {
    params ["_position"];
    private _index = [_position] call BATTLESPACE_CELL_INDEX_AT;
    if (_index < 0) exitWith {};
    private _cell = BATTLESPACE_CELLS select _index;
    _cell set [3, CBA_missionTime + BATTLESPACE_CELL_CONTEST_TIME];
    _cell set [4, CBA_missionTime];
};

// Baseline follows sector ownership and FOBs; recomputed only when they change.
BATTLESPACE_CELL_UPDATE_BASELINE = {
    private _blue = ((blufor_sectors + ["startbase_marker"]) apply {markerPos _x}) + (GRLIB_all_fobs apply {+_x});
    private _red = ((keys BATTLESPACE_SECTOR_STATES) select {((BATTLESPACE_SECTOR_STATES get _x) getOrDefault ["owner", ""]) == "OPFOR"}) apply {markerPos _x};
    private _signature = [_blue, _red];
    if (_signature isEqualTo BATTLESPACE_CELL_BASELINE_SIGNATURE) exitWith {};
    private _first = BATTLESPACE_CELL_BASELINE_SIGNATURE isEqualTo [];
    BATTLESPACE_CELL_BASELINE_SIGNATURE = _signature;
    {
        private _center = _x select 0;
        private _toBlue = 1e9;
        {_toBlue = _toBlue min (_center distance2D _x)} forEach _blue;
        private _toRed = 1e9;
        {_toRed = _toRed min (_center distance2D _x)} forEach _red;
        private _baseline = -1 max (((_toRed - _toBlue) / 1500) min 1);
        _x set [5, _baseline];
        if (_first) then {_x set [2, _baseline]};
    } forEach BATTLESPACE_CELLS;
};

// Called from the theater tick (strategic loop, every 30 s).
BATTLESPACE_CELL_TICK = {
    if (!isServer || {BATTLESPACE_CELLS isEqualTo []}) exitWith {};
    [] call BATTLESPACE_CELL_UPDATE_BASELINE;
    private _now = CBA_missionTime;
    private _presence = createHashMap; // row index -> [blue, red]
    private _add = {
        params ["_position", "_blue"];
        private _index = [_position] call BATTLESPACE_CELL_INDEX_AT;
        if (_index < 0) exitWith {};
        private _row = _presence getOrDefault [_index, [0, 0]];
        private _slot = [1, 0] select _blue;
        _row set [_slot, (_row select _slot) + 1];
        _presence set [_index, _row];
        // OPFOR on the ground keeps its surroundings observed.
        if (!_blue) then {{(BATTLESPACE_CELLS select _x) set [4, _now]} forEach ([_index] call BATTLESPACE_CELL_AROUND)};
    };
    {
        private _leader = leader _x;
        if (!alive _leader || {(vehicle _leader) isKindOf "Air"}) then {continue};
        if (side _x == GRLIB_side_friendly) then {[getPosATL _leader, true] call _add; continue};
        if (side _x == GRLIB_side_enemy) then {[getPosATL _leader, false] call _add};
    } forEach allGroups;
    // Simulated OPFOR formations hold ground too; aircraft only observe (UAV recon wider).
    {
        _y params ["_type", "_position", "", "", ["_activeGroups", []], "", ["_side", east]];
        if (_side != GRLIB_side_enemy || {_type == "Civilians"} || {_activeGroups isNotEqualTo [] && {!(_type in ["UAV Recon", "Air Response", "Airborne Transport"])}}) then {continue};
        if (_type in ["UAV Recon", "Air Response", "Airborne Transport"]) then {
            private _index = [_position] call BATTLESPACE_CELL_INDEX_AT;
            if (_index >= 0) then {{(BATTLESPACE_CELLS select _x) set [4, _now]} forEach ([_index, [1, 3] select (_type == "UAV Recon")] call BATTLESPACE_CELL_AROUND)};
            continue;
        };
        [_position, false] call _add;
    } forEach BATTLESPACE_TASK_FORCES;
    // Both sides at or next to the same cell: contested.
    {
        if ((_y select 0) == 0) then {continue};
        private _around = [_x] call BATTLESPACE_CELL_AROUND;
        if (_around findIf {((_presence getOrDefault [_x, [0, 0]]) select 1) > 0} >= 0) then {
            {(BATTLESPACE_CELLS select _x) set [3, _now + BATTLESPACE_CELL_CONTEST_TIME]} forEach _around;
        };
    } forEach _presence;
    // Presence pulls a cell toward its side within a few minutes; otherwise it relaxes to baseline.
    {
        if (_now < (_x select 3)) then {continue};
        private _row = _presence getOrDefault [_forEachIndex, [0, 0]];
        private _push = (_row select 0) - (_row select 1);
        private _target = if (_push == 0) then {_x select 5} else {[-1, 1] select (_push > 0)};
        private _control = _x select 2;
        _x set [2, _control + (_target - _control) * ([0.05, 0.2] select (_push != 0))];
    } forEach BATTLESPACE_CELLS;
    [] call BATTLESPACE_CELL_CIVILIANS_TICK;
};

BATTLESPACE_CELL_IS_CONTESTED = {
    params ["_position"];
    private _index = [_position] call BATTLESPACE_CELL_INDEX_AT;
    _index >= 0 && {CBA_missionTime < ((BATTLESPACE_CELLS select _index) select 3)}
};

// Theaters that still hold an OPFOR sector (dead space worth patrolling and surveying).
BATTLESPACE_CELL_OPFOR_THEATERS = {
    private _theaters = createHashMap;
    {
        if (((BATTLESPACE_SECTOR_STATES getOrDefault [_x, createHashMap]) getOrDefault ["owner", ""]) == "OPFOR") then {
            _theaters set [BATTLESPACE_THEATER_OF_SECTOR get _x, true];
        };
    } forEach sectors_allSectors;
    _theaters
};

// UAV survey: the contested, blue-pushing or longest-unobserved cell in an OPFOR theater.
BATTLESPACE_CELL_SURVEY_TARGET = {
    params ["_watched"];
    private _theaters = [] call BATTLESPACE_CELL_OPFOR_THEATERS;
    private _best = [];
    private _bestScore = 0;
    {
        _x params ["_center", "_theater", "_control", "_contestedUntil", "_observedAt", "_baseline"];
        if !(_theater in _theaters) then {continue};
        if (_watched findIf {_x distance2D _center <= 1500} >= 0) then {continue};
        private _score = ([0, 100] select (CBA_missionTime < _contestedUntil))
            + ([0, 60] select (_control - _baseline > 0.2))
            + (((CBA_missionTime - _observedAt) / 60) min 60)
            + 10 * ((BATTLESPACE_THEATERS select _theater) get "level");
        if (_score > _bestScore) then {_bestScore = _score; _best = +_center};
    } forEach BATTLESPACE_CELLS;
    _best
};

// Ambient civilians in quiet dead space near players (farm, forest and road cells);
// unspawned ones far from every player are removed. Tagged "DEADSPACE" in the home slot.
BATTLESPACE_CELL_CIVILIANS_TICK = {
    if (CBA_missionTime < BATTLESPACE_CELL_CIVILIANS_AT) exitWith {};
    BATTLESPACE_CELL_CIVILIANS_AT = CBA_missionTime + 60;
    private _perCluster = round (2 * GRLIB_civilian_activity);
    private _existing = (keys BATTLESPACE_TASK_FORCES) select {
        private _taskForce = BATTLESPACE_TASK_FORCES get _x;
        (_taskForce select 0) == "Civilians" && {(_taskForce param [12, ""]) isEqualTo "DEADSPACE"}
    };
    {
        private _taskForce = BATTLESPACE_TASK_FORCES get _x;
        if ((_taskForce param [4, []]) isNotEqualTo [] || {_taskForce param [11, false]}) then {continue};
        private _position = _taskForce select 1;
        if (BATTLESPACE_TASK_FORCES_BLUFOR_CLUSTERS findIf {((_x get "Position") distance2D _position) < 3000} >= 0) then {continue};
        BATTLESPACE_TASK_FORCES deleteAt _x;
        BATTLESPACE_TASK_FORCE_PATHS deleteAt _x;
        [_x] call BATTLESPACE_TASK_FORCE_CANCEL_SPAWN_ADMISSION;
    } forEach _existing;
    if (_perCluster <= 0) exitWith {};
    _existing = _existing select {_x in BATTLESPACE_TASK_FORCES};
    {
        private _origin = _x get "Position";
        private _near = {((BATTLESPACE_TASK_FORCES get _x) select 1) distance2D _origin < 2000} count _existing;
        if (_near >= _perCluster || {count _existing >= 4 * _perCluster}) then {continue};
        private _cells = BATTLESPACE_CELLS select {
            private _distance = (_x select 0) distance2D _origin;
            _distance > 600 && {_distance < 1800} && {(_x select 6) >= BATTLESPACE_CELL_DEAD_SPACE} && {CBA_missionTime >= (_x select 3)}
        };
        private _wanted = 2 min (_perCluster - _near);
        // Up to 8 random cells per cluster and minute; only cells with a road or house qualify.
        for "_i" from 1 to 8 do {
            if (_wanted <= 0 || {_cells isEqualTo []}) exitWith {};
            private _center = (_cells deleteAt floor random count _cells) select 0;
            if ((_center nearRoads 150) isEqualTo [] && {(nearestObjects [_center, ["House"], 150]) isEqualTo []}) then {continue};
            private _composition = createHashMapFromArray [["manpower", 1], ["vehicles", []], ["structures", []]];
            private _id = ["Civilians", _composition, _center, _center, _center, GRLIB_side_civilian] call BATTLESPACE_TASK_FORCES_INIT;
            if (_id == "") then {continue};
            (BATTLESPACE_TASK_FORCES get _id) set [12, "DEADSPACE"];
            _existing pushBack _id;
            _wanted = _wanted - 1;
        };
    } forEach BATTLESPACE_TASK_FORCES_BLUFOR_CLUSTERS;
};

// ZEN overlay: cells within 2 km of the curator's cursor: [size, [[x0, y0, theater, control%, contested, squad post]]].
BATTLESPACE_CELL_OVERLAY_ROWS = {
    params ["_center"];
    if (_center isEqualTo []) exitWith {[BATTLESPACE_CELL_SIZE, []]};
    private _rows = [];
    {
        if ((_x select 0) distance2D _center > 2000) then {continue};
        (_x select 7) params ["_cx", "_cy"];
        _rows pushBack [_cx * BATTLESPACE_CELL_SIZE, _cy * BATTLESPACE_CELL_SIZE, _x select 1, round (100 * (_x select 2)), CBA_missionTime < (_x select 3),
            (format ["CELL:%1:%2", _cx, _cy]) in BATTLESPACE_DEFENSE_ASSIGNMENTS];
    } forEach BATTLESPACE_CELLS;
    [BATTLESPACE_CELL_SIZE, _rows]
};
