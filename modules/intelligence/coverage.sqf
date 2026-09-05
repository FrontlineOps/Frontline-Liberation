/* Server-owned, session-only coverage and observation lifecycle. */
KPLIB_INTEL_SERVER_BUILD_PAYLOAD = {
    private _coverages = [];
    {_coverages pushBack [_x, _y get "tier", _y get "expiresAt"]} forEach KPLIB_INTEL_COVERAGE;
    _coverages sort true;
    private _reports = [];
    {_reports pushBack (_y get "report")} forEach KPLIB_INTEL_OBSERVATIONS;
    {_reports pushBack (_y get "report")} forEach KPLIB_INTEL_LOST_CONTACTS;
    {_reports pushBack (_y get "report")} forEach KPLIB_INTEL_LEADS;
    _reports = [_reports, [], {((_x # 12) get "priority")}, "DESCEND"] call BIS_fnc_sortBy;
    // Version 2 adds report metadata, without changing the first five payload fields.
    [KPLIB_INTEL_REVISION, missionNamespace getVariable ["resources_intel", 0], _coverages, _reports, +KPLIB_INTEL_ELIGIBLE_REGIONS, 2]
};

KPLIB_INTEL_SERVER_SEND_PAYLOAD = {
    params [["_targets", [], [[], objNull]]];
    if (!isServer || {isRemoteExecuted && {remoteExecutedOwner != 2}}) exitWith {};
    if (_targets isEqualType [] && {_targets isEqualTo []}) exitWith {};
    [call KPLIB_INTEL_SERVER_BUILD_PAYLOAD] remoteExecCall ["KPLIB_INTEL_CLIENT_RECEIVE_SNAPSHOT", _targets];
};

KPLIB_INTEL_SERVER_SELECT_CANDIDATES = {
    params ["_rawReports"];
    private _candidates = createHashMap;
    private _counts = createHashMap;
    private _regions = keys KPLIB_INTEL_COVERAGE;
    _regions sort true;
    private _totalLimit = KPLIB_intelligence_max_reports max 1;
    private _regionLimit = KPLIB_intelligence_max_reports_per_region max 1;
    // Reserve a baseline assessment for each paid region before contact admission.
    {
        if (count _candidates >= _totalLimit) then {continue};
        private _coverage = KPLIB_INTEL_COVERAGE get _x;
        private _raw = [_x, _coverage get "sectors", _rawReports] call KPLIB_INTEL_SERVER_ASSESS_REGION;
        _candidates set [_raw get "id", [_raw, _coverage get "tier", [_x]]];
        _counts set [_x, 1];
    } forEach _regions;
    private _sorted = [_rawReports, [], {_x get "priority"}, "DESCEND"] call BIS_fnc_sortBy;
    {
        if (count _candidates >= _totalLimit) exitWith {};
        private _raw = _x;
        private _membership = _regions select {
            (_raw get "sector") in ((KPLIB_INTEL_COVERAGE get _x) get "sectors")
        };
        private _tier = 0;
        private _admitRegion = "";
        {
            private _coverageTier = (KPLIB_INTEL_COVERAGE get _x) get "tier";
            if (_coverageTier > _tier) then {_tier = _coverageTier};
            if (_admitRegion == "" && {(_counts getOrDefault [_x, 0]) < _regionLimit}) then {_admitRegion = _x};
        } forEach _membership;
        if (_admitRegion == "" || {_tier < (_raw getOrDefault ["minTier", 1])}) then {continue};
        _counts set [_admitRegion, 1 + (_counts getOrDefault [_admitRegion, 0])];
        // Shared reports are visible under every overlapping region, at the best paid tier.
        _candidates set [_raw get "id", [_raw, _tier, _membership]];
    } forEach _sorted;
    _candidates
};

KPLIB_INTEL_SERVER_RECONCILE = {
    params [["_force", false, [false]]];
    if (!isServer || {isRemoteExecuted && {remoteExecutedOwner != 2}} || {!KPLIB_intelligence_enabled}) exitWith {};
    call KPLIB_INTEL_SERVER_UPDATE_INFORMANT;
    if (isNil "BATTLESPACE_STRATEGIC_OPERATIONS" || {isNil "BATTLESPACE_TASK_FORCES"}) exitWith {};
    call KPLIB_INTEL_SERVER_REBUILD_REGIONS;
    private _now = CBA_missionTime;
    {
        // A captured anchor keeps its already-paid regional coverage until expiry.
        if (((KPLIB_INTEL_COVERAGE get _x) get "expiresAt") <= _now) then {KPLIB_INTEL_COVERAGE deleteAt _x};
    } forEach keys KPLIB_INTEL_COVERAGE;
    private _rawReports = [];
    if (count KPLIB_INTEL_COVERAGE > 0) then {_rawReports = call KPLIB_INTEL_SERVER_COLLECT_RAW_REPORTS};
    private _candidates = [_rawReports] call KPLIB_INTEL_SERVER_SELECT_CANDIDATES;
    {
        private _id = _x;
        _y params ["_raw", "_tier", "_regions"];
        private _old = KPLIB_INTEL_OBSERVATIONS getOrDefault [_id, createHashMap];
        private _refresh = _now >= (_old getOrDefault ["refreshAt", 0])
            || {_tier != (_old getOrDefault ["tier", 0])}
            || {_regions isNotEqualTo (_old getOrDefault ["regions", []])};
        if (_refresh) then {
            private _report = [_raw, _tier, _regions, _rawReports] call KPLIB_INTEL_SERVER_BUILD_OBSERVATION;
            private _activity = (_raw get "men") + 4 * count (_raw get "classes");
            if ((_raw get "kind") == "SECTOR ASSESSMENT") then {
                private _previous = _old getOrDefault ["activity", -1];
                private _trend = "First assessment; no earlier comparison available.";
                if (_previous >= 0) then {
                    _trend = if (_activity > _previous) then {"Defensive strength increasing since the previous assessment."} else {
                        if (_activity < _previous) then {"Defensive strength reduced since the previous assessment."} else {"No change in reported defensive strength since the previous assessment."}
                    };
                };
                ((_report # 12) get "details") pushBack _trend;
                ((_report # 12) get "details") pushBack "Assessment covers assigned defenders; an empty report does not certify clear ground.";
            };
            KPLIB_INTEL_OBSERVATIONS set [_id, createHashMapFromArray [
                ["tier", _tier], ["regions", _regions], ["activity", _activity],
                ["refreshAt", _now + (KPLIB_intelligence_refresh_intervals # (_tier - 1))], ["report", _report]
            ]];
        };
        KPLIB_INTEL_LOST_CONTACTS deleteAt _id;
    } forEach _candidates;
    {
        if (!isNil {_candidates get _x}) then {continue};
        private _old = KPLIB_INTEL_OBSERVATIONS deleteAt _x;
        private _report = _old get "report";
        if ((_report # 1) == "SECTOR ASSESSMENT") then {continue};
        private _meta = _report # 12;
        _meta set ["status", "CONTACT LOST"];
        _meta set ["window", "No current opportunity confirmed. This is the last observation, not a live track."];
        _meta set ["priority", 15];
        _meta set ["confidence", "STALE - current position, route and destination unconfirmed"];
        KPLIB_INTEL_LOST_CONTACTS set [_x, createHashMapFromArray [
            ["report", _report], ["expiresAt", _now + KPLIB_intelligence_lost_contact_duration]
        ]];
    } forEach keys KPLIB_INTEL_OBSERVATIONS;
    {
        private _collection = _x;
        {
            if (((_collection get _x) get "expiresAt") <= _now) then {_collection deleteAt _x};
        } forEach keys _collection;
        private _oldest = [keys _collection, [], {((_collection get _x) get "report") # 6}, "ASCEND"] call BIS_fnc_sortBy;
        while {count _oldest > (KPLIB_intelligence_max_archived_reports max 0)} do {_collection deleteAt (_oldest deleteAt 0)};
    } forEach [KPLIB_INTEL_LOST_CONTACTS, KPLIB_INTEL_LEADS];
    private _sources = localNamespace getVariable ["KPLIB_INTEL_SOURCES", createHashMap];
    {
        if (isNull ((_sources get _x) # 0)) then {_sources deleteAt _x};
    } forEach keys _sources;
    private _payload = call KPLIB_INTEL_SERVER_BUILD_PAYLOAD;
    private _fingerprint = str (_payload select [1]);
    if (_force || {_fingerprint != KPLIB_INTEL_LAST_FINGERPRINT}) then {
        KPLIB_INTEL_LAST_FINGERPRINT = _fingerprint;
        KPLIB_INTEL_REVISION = KPLIB_INTEL_REVISION + 1;
        [allPlayers select {isPlayer _x && {side group _x == GRLIB_side_friendly}}] call KPLIB_INTEL_SERVER_SEND_PAYLOAD;
    };
};
