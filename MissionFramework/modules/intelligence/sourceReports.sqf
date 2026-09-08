/* Category selection prevents high-priority artillery from crowding out other information.
   Reports contain actual campaign records, frozen when the source is captured/recovered. */
KPLIB_INTEL_SERVER_STOCK_REPORT = {
    params ["_sector", "_theater", "_raw"];
    private _stock = createHashMap;
    private _count = 0;
    {
        if ((_y getOrDefault ["owner", ""]) != "OPFOR" || {!_theater && {_x != _sector}}) then {continue};
        _count = _count + 1;
        {_stock set [_x, (_stock getOrDefault [_x, 0]) + _y]} forEach (_y getOrDefault ["resources", createHashMap]);
    } forEach BATTLESPACE_SECTOR_STATES;
    private _details = [format ["Recorded stock across %1 enemy-held objective(s) at capture time:", _count]];
    private _keys = keys _stock;
    _keys sort true;
    {
        private _label = switch (_x) do {
            case "manpower": {"Unassigned personnel"};
            case "construction_supplies": {"Construction supplies"};
            case "rockets": {"Artillery ammunition"};
            default {(_x splitString "_") joinString " "};
        };
        _details pushBack format ["%1: %2", _label, floor (_stock get _x)];
    } forEach _keys;
    _details pushBack "These are available strategic reserves, not soldiers or vehicles already deployed in the field.";
    if (_theater) then {
        private _transit = createHashMap;
        {
            if ((_x get "kind") == "CONVOY") then {
                {_transit set [_x, (_transit getOrDefault [_x, 0]) + _y]} forEach (_x get "cargo");
            };
        } forEach _raw;
        private _cargo = [];
        {_cargo pushBack format ["%1 %2", floor _y, (_x splitString "_") joinString " "]} forEach _transit;
        _cargo sort true;
        _details pushBack ("Separately, cargo in active convoys: " + (if (_cargo isEqualTo []) then {"none recorded"} else {_cargo joinString ", "}));
    };
    private _kind = ["OBJECTIVE STOCK", "FORCE-WIDE STOCK"] select _theater;
    private _meta = createHashMapFromArray [
        ["title", ["Stock at " + ([_sector] call KPLIB_INTEL_SERVER_LABEL), "Enemy force-wide stock ledger"] select _theater],
        ["details", _details], ["status", "RECOVERED LEAD"], ["priority", 80], ["regions", [_sector]],
        ["confidence", "Recorded stock at capture time"], ["window", "Production, losses and dispatches change these figures."],
        ["mapVisible", !_theater]
    ];
    ["STOCK_" + _sector, _kind, "RECORDED", _sector, markerPos _sector, 0, CBA_missionTime, "", [], "Stock ledger", [], 3, _meta]
};

KPLIB_INTEL_SERVER_SOURCE_REPORT = {
    params ["_sector", "_raw", "_forceId"];
    private _categories = ["OBJECTIVE STOCK", "FORCE-WIDE STOCK"];
    private _pools = createHashMap;
    {
        private _category = switch (_x get "kind") do {
            case "ARTILLERY": {"ARTILLERY"};
            case "ARTILLERY TRP": {"FIRE PLANS"};
            case "FORTIFICATION": {"FORTIFICATIONS"};
            case "CONVOY": {"CONVOYS"};
            case "SAM": {"AIR DEFENSE"};
            default {"TROOP POSITIONS"};
        };
        private _pool = _pools getOrDefault [_category, []];
        _pool pushBack _x;
        _pools set [_category, _pool];
        _categories pushBackUnique _category;
    } forEach _raw;
    private _category = selectRandom _categories;
    if (_category in ["OBJECTIVE STOCK", "FORCE-WIDE STOCK"]) exitWith {
        [_sector, _category == "FORCE-WIDE STOCK", _raw] call KPLIB_INTEL_SERVER_STOCK_REPORT
    };
    private _pool = _pools get _category;
    private _related = _pool select {
        (_x get "id") == _forceId || {(_x get "sector") == _sector}
            || {(_x getOrDefault ["funding", ""]) == _sector}
            || {(_x getOrDefault ["assigned", ""]) == _sector}
    };
    private _record = selectRandom (if (_related isEqualTo []) then {_pool} else {_related});
    [_record, 3, [_record get "sector"], _raw] call KPLIB_INTEL_SERVER_BUILD_OBSERVATION
};

// Captured towers intercept current traffic; they never create a prisoner mission chain.
KPLIB_INTEL_SERVER_INTERCEPT = {
    params ["_towerSector"];
    if (!(call KPLIB_INTEL_SERVER_MUTATION_ALLOWED) || {!KPLIB_intelligence_enabled}) exitWith {false};
    private _entry = (localNamespace getVariable ["KPLIB_RADIO_TOWERS", createHashMap]) getOrDefault [_towerSector, createHashMap];
    if (count _entry == 0 || {!(_towerSector in blufor_sectors)} || {_entry get "destroyed"}
        || {!alive (_entry get "object")}) exitWith {false};
    private _raw = call KPLIB_INTEL_SERVER_COLLECT_RAW_REPORTS;
    if (_raw isEqualTo []) exitWith {
        [format ["Tower %1 found no actionable enemy traffic this interval", _towerSector], "RADIO"] call KPLIB_fnc_log;
        false
    };
    // Select a category first so numerous ground patrols cannot crowd out other traffic.
    private _kinds = [];
    {_kinds pushBackUnique (_x get "kind")} forEach _raw;
    private _kind = selectRandom _kinds;
    private _record = selectRandom (_raw select {(_x get "kind") == _kind});
    private _report = [_record, 2, [_record get "sector"], _raw] call KPLIB_INTEL_SERVER_BUILD_OBSERVATION;
    private _meta = _report # 12;
    _meta set ["status", "INTERCEPTED COMMS"];
    _meta set ["title", "Intercept: " + (_meta get "title")];
    _meta set ["confidence", "Intercepted enemy traffic; information dates from interception"];
    _meta set ["window", "Dated communications intercept. Reconnoitre to confirm current activity."];
    _meta set ["taskEligible", false];
    (_meta get "details") pushBack format ["Intercepted through %1.", _entry get "label"];
    private _published = [[objNull, _report, CBA_missionTime, _towerSector, ""], false] call KPLIB_INTEL_SERVER_REVEAL_SOURCE;
    if (_published) then {
        [format ["Tower %1 intercepted %2 traffic (report=%3)", _towerSector, _kind, _report # 0], "RADIO"] call KPLIB_fnc_log;
    };
    _published
};
