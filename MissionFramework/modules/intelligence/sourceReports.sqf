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
