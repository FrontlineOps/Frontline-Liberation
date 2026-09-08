/* Capture context on the server before surrender detaches a soldier from its force.
   Documents register when spawned. Neither object variables nor client arguments
   can manufacture the private source record or its one-time reward lead. */
localNamespace setVariable ["KPLIB_INTEL_SOURCES", createHashMap];

KPLIB_INTEL_SERVER_CAPTURE_SOURCE = {
    params ["_object", ["_sector", ""], ["_prisoner", false]];
    if (!(call KPLIB_INTEL_SERVER_INTERNAL) || {isNull _object} || {!KPLIB_intelligence_enabled}) exitWith {};
    if (isNil "BATTLESPACE_STRATEGIC_OPERATIONS") exitWith {};
    private _sources = localNamespace getVariable "KPLIB_INTEL_SOURCES";
    private _key = netId _object;
    if (!isNil {_sources get _key}) exitWith {};
    if (_sector == "") then {_sector = [getPosATL _object] call KPLIB_INTEL_SERVER_NEAREST_SECTOR};
    // Informants and prisoners from captured sectors can identify the nearest remaining enemy network.
    if !([_sector] call KPLIB_INTEL_SERVER_ENEMY_SECTOR) then {
        private _enemies = keys BATTLESPACE_SECTOR_STATES select {[_x] call KPLIB_INTEL_SERVER_ENEMY_SECTOR};
        if (_enemies isNotEqualTo []) then {
            _sector = ([_enemies, [], {_object distance2D markerPos _x}, "ASCEND"] call BIS_fnc_sortBy) # 0;
        };
    };
    private _raw = call KPLIB_INTEL_SERVER_COLLECT_RAW_REPORTS;
    private _forceId = "";
    if (_prisoner) then {
        {
            if ((group _object) in (_y param [4, []])) exitWith {_forceId = if (_x isEqualType "") then {_x} else {str _x}};
        } forEach BATTLESPACE_TASK_FORCES;
    };
    private _report = [_sector, _raw, _forceId] call KPLIB_INTEL_SERVER_SOURCE_REPORT;
    _report set [0, "LEAD_" + (_report # 0)];
    private _meta = _report # 12;
    _meta set ["status", "RECOVERED LEAD"];
    _meta set ["taskEligible", random 1 < (0 max KPLIB_intelligence_task_chance min 1)];
    _meta set ["priority", 80];
    _meta set ["title", (["Documents: ", "Interrogation: "] select _prisoner) + (_meta get "title")];
    _meta set ["confidence", "SOURCE REPORT - information dates from document recovery context or capture"];
    _meta set ["window", "Single-source lead, not live coverage. Reconnoitre the area to confirm current activity."];
    private _kind = switch (true) do {
        case (((_report # 1) find "ARTILLERY") >= 0): {"FIRE_SUPPORT"};
        case ((_report # 1) == "CONVOY"): {"LOGISTICS"};
        default {(selectRandom ["LOGISTICS", "FIRE_SUPPORT", "COMMAND"])};
    };
    _sources set [_key, [_object, _report, CBA_missionTime, _sector, _kind]];
    // Bound abandoned document/corpse context without growing a permanent identity registry.
    if (count _sources > 256) then {
        private _oldest = [keys _sources, [], {(_sources get _x) # 2}, "ASCEND"] call BIS_fnc_sortBy;
        private _protected = values (localNamespace getVariable "KPLIB_INTEL_CASES") apply {_x getOrDefault ["target", objNull]};
        private _evict = _oldest findIf {!(((_sources get _x) # 0) in _protected)};
        if (_evict >= 0) then {_sources deleteAt (_oldest # _evict)};
    };
};

KPLIB_INTEL_SERVER_REVEAL_SOURCE = {
    params ["_source", ["_createCase", true]];
    if (!(call KPLIB_INTEL_SERVER_INTERNAL) || {count _source < 5}) exitWith {false};
    private _report = _source # 1;
    private _id = call KPLIB_INTEL_SERVER_NEW_ID;
    _report set [0, _id];
    KPLIB_INTEL_LEADS set [_id, createHashMapFromArray [
        ["report", _report], ["expiresAt", CBA_missionTime + KPLIB_intelligence_lead_duration]
    ]];
    if (_createCase && {(_report # 12) getOrDefault ["taskEligible", false]}) then {[_source # 3, _source # 4] call KPLIB_INTEL_SERVER_NEW_CASE};
    call KPLIB_INTEL_SERVER_CHANGED;
    true
};

localNamespace setVariable ["KPLIB_INTEL_CLAIM_LEAD", {
    params ["_object"];
    if !(call KPLIB_INTEL_SERVER_INTERNAL) exitWith {false};
    private _sources = localNamespace getVariable "KPLIB_INTEL_SOURCES";
    private _entry = _sources getOrDefault [netId _object, []];
    if (_entry isEqualTo [] || {(_entry # 0) isNotEqualTo _object}) exitWith {false};
    _sources deleteAt (netId _object);
    [_entry] call KPLIB_INTEL_SERVER_REVEAL_SOURCE
}];
