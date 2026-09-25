// Theaters: mandatory sector clusters generated from the map at start. Each keeps a
// decaying alert fed by contact reports (sightings, gunfire, casualties, lost groups).
// Alert is transient (not saved); it enlarges garrisons, speeds reserve responses and
// thins civilians. Territorial control cells (cells.sqf) fill each theater's area.
// ZEN shows both on the strategic overlay.
BATTLESPACE_THEATER_SPAN = 2500;         // seed-to-member distance when clustering
BATTLESPACE_THEATER_MAX_SECTORS = 6;
BATTLESPACE_THEATER_REACH = 1500;        // a report belongs to its nearest sector's theater within this range
BATTLESPACE_THEATER_HALF_LIFE = 600;
BATTLESPACE_THEATER_LEVELS = [25, 60];   // ALERT, HIGH
BATTLESPACE_THEATER_LEVEL_NAMES = ["CALM", "ALERT", "HIGH"];
BATTLESPACE_THEATER_NOTE_INTERVAL = 20;  // per theater and report kind
BATTLESPACE_THEATER_POINTS = [8, 4, 10, 20]; // sighting, then BATTLESPACE_CONTACT_UNCONFIRMED order
BATTLESPACE_THEATERS = [];
BATTLESPACE_THEATER_SECTORS = [];        // [position, theater index]
BATTLESPACE_THEATER_OF_SECTOR = createHashMap;
// Set when any theater's level rises; the strategic loop runs defender allocation early.
BATTLESPACE_THEATER_RAISED = false;

if (isServer) then {
    private _positions = createHashMap;
    {_positions set [_x, markerPos _x]} forEach sectors_allSectors;
    private _neighbours = createHashMap;
    {
        private _origin = _positions get _x;
        _neighbours set [_x, sectors_allSectors select {(_positions get _x) distance2D _origin <= BATTLESPACE_THEATER_SPAN}];
    } forEach sectors_allSectors;
    // Greedy and deterministic: seed on the densest unassigned sector, take its nearest free neighbours.
    private _taken = createHashMap;
    private _free = +sectors_allSectors;
    while {_free isNotEqualTo []} do {
        private _seed = _free select 0;
        private _most = -1;
        {
            private _count = {!(_x in _taken)} count (_neighbours get _x);
            if (_count > _most) then {_seed = _x; _most = _count};
        } forEach _free;
        private _origin = _positions get _seed;
        private _members = ((_neighbours get _seed) select {!(_x in _taken)}) apply {[(_positions get _x) distance2D _origin, _x]};
        _members sort true;
        _members = (_members select [0, BATTLESPACE_THEATER_MAX_SECTORS]) apply {_x select 1};
        {_taken set [_x, true]} forEach _members;
        _free = _free select {!(_x in _taken)};
        private _center = [0, 0, 0];
        {_center = _center vectorAdd (_positions get _x)} forEach _members;
        _center = _center vectorMultiply (1 / count _members);
        _center set [2, 0];
        private _radius = 0;
        {_radius = _radius max ((_positions get _x) distance2D _center)} forEach _members;
        private _town = _members findIf {_x in sectors_bigtown};
        private _label = markerText (_members select (_town max 0));
        if (_label == "") then {_label = _seed};
        private _index = count BATTLESPACE_THEATERS;
        {
            BATTLESPACE_THEATER_SECTORS pushBack [_positions get _x, _index];
            BATTLESPACE_THEATER_OF_SECTOR set [_x, _index];
        } forEach _members;
        BATTLESPACE_THEATERS pushBack createHashMapFromArray [
            ["name", format ["T%1 %2", _index + 1, _label]],
            ["sectors", _members],
            ["center", _center],
            ["radius", _radius + 600],
            ["alert", 0],
            ["level", 0],
            ["tickAt", CBA_missionTime],
            ["noted", createHashMap]
        ];
    };
    [format ["Generated %1 theaters from %2 sectors", count BATTLESPACE_THEATERS, count sectors_allSectors], "BATTLESPACE"] call KPLIB_fnc_log;
};

// Theater index for a position (its land cell's theater), or -1 off the map.
BATTLESPACE_THEATER_AT = {
    params ["_position"];
    private _cell = [_position] call BATTLESPACE_CELL_INDEX_AT;
    if (_cell >= 0) exitWith {(BATTLESPACE_CELLS select _cell) select 1};
    // Water and coastline: nearest sector within reach.
    private _index = -1;
    private _nearest = BATTLESPACE_THEATER_REACH;
    {
        private _distance = _position distance2D (_x select 0);
        if (_distance < _nearest) then {_nearest = _distance; _index = _x select 1};
    } forEach BATTLESPACE_THEATER_SECTORS;
    _index
};

BATTLESPACE_THEATER_LEVEL_AT = {
    params ["_position"];
    private _index = [_position] call BATTLESPACE_THEATER_AT;
    if (_index < 0) then {0} else {(BATTLESPACE_THEATERS select _index) get "level"}
};

// Multiplier for commander thresholds and cooldowns: alerted theaters are answered sooner.
BATTLESPACE_THEATER_URGENCY = {
    params ["_position"];
    [1, 0.75, 0.5] select ([_position] call BATTLESPACE_THEATER_LEVEL_AT)
};

// Multiplier for a sector's garrison manpower target: alerted theaters hold more troops.
BATTLESPACE_THEATER_GARRISON_SCALE = {
    params ["_position"];
    [1, 1.5, 2] select ([_position] call BATTLESPACE_THEATER_LEVEL_AT)
};

BATTLESPACE_THEATER_NOTE = {
    params ["_position", "_class"];
    [_position] call BATTLESPACE_CELL_CONTEST;
    private _index = [_position] call BATTLESPACE_THEATER_AT;
    if (_index < 0) exitWith {};
    private _theater = BATTLESPACE_THEATERS select _index;
    private _kind = BATTLESPACE_CONTACT_UNCONFIRMED find _class;
    private _noted = _theater get "noted";
    if (CBA_missionTime < (_noted getOrDefault [_kind, -1e9]) + BATTLESPACE_THEATER_NOTE_INTERVAL) exitWith {};
    _noted set [_kind, CBA_missionTime];
    _theater set ["alert", ((_theater get "alert") + (BATTLESPACE_THEATER_POINTS select (_kind + 1))) min 100];
};

// Called from the strategic loop (scheduled, every 30 s).
BATTLESPACE_THEATER_TICK = {
    if (!isServer) exitWith {};
    {
        private _dt = CBA_missionTime - (_x get "tickAt");
        _x set ["tickAt", CBA_missionTime];
        private _alert = (_x get "alert") * 0.5 ^ (_dt / BATTLESPACE_THEATER_HALF_LIFE);
        if (_alert < 1) then {_alert = 0};
        _x set ["alert", _alert];
        private _old = _x get "level";
        private _level = {_alert >= _x} count BATTLESPACE_THEATER_LEVELS;
        // Step down only once alert falls well below the level's threshold.
        if (_level < _old && {_alert >= 0.8 * (BATTLESPACE_THEATER_LEVELS select (_old - 1))}) then {_level = _old};
        if (_level == _old) then {continue};
        _x set ["level", _level];
        [format ["Theater %1 alert %2 -> %3 (%4)", _x get "name", BATTLESPACE_THEATER_LEVEL_NAMES select _old, BATTLESPACE_THEATER_LEVEL_NAMES select _level, round _alert]] call BATTLESPACE_STRATEGIC_LOG;
        if (_level > _old) then {BATTLESPACE_THEATER_RAISED = true};
    } forEach BATTLESPACE_THEATERS;
    [] call BATTLESPACE_CELL_TICK;
};

BATTLESPACE_THEATER_OVERLAY_ROWS = {
    BATTLESPACE_THEATERS apply {[_x get "name", _x get "center", _x get "radius", round (_x get "alert"), _x get "level"]}
};

[] call compileFinal preprocessFileLineNumbers "modules\battlespace_ai\theaters\cells.sqf";
