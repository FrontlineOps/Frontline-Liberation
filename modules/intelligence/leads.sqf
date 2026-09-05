/* Capture context on the server before surrender detaches a soldier from its force.
   Documents register when spawned. Neither object variables nor client arguments
   can manufacture the private source record or its one-time reward lead. */
localNamespace setVariable ["KPLIB_INTEL_SOURCES", createHashMap];

KPLIB_INTEL_SERVER_CAPTURE_SOURCE = {
    params ["_object", ["_sector", ""], ["_prisoner", false]];
    if (!isServer || {isRemoteExecuted && {remoteExecutedOwner != 2}} || {isNull _object} || {!KPLIB_intelligence_enabled}) exitWith {};
    if (isNil "BATTLESPACE_STRATEGIC_OPERATIONS") exitWith {};
    private _sources = localNamespace getVariable "KPLIB_INTEL_SOURCES";
    private _key = netId _object;
    if (!isNil {_sources get _key}) exitWith {};
    if (_sector == "") then {_sector = [getPosATL _object] call KPLIB_INTEL_SERVER_NEAREST_SECTOR};
    private _raw = call KPLIB_INTEL_SERVER_COLLECT_RAW_REPORTS;
    private _forceId = "";
    if (_prisoner) then {
        {
            if ((group _object) in (_y param [4, []])) exitWith {_forceId = if (_x isEqualType "") then {_x} else {str _x}};
        } forEach BATTLESPACE_TASK_FORCES;
    };
    private _related = _raw select {(_x get "id") == _forceId};
    if (_related isEqualTo []) then {
        _related = _raw select {
            (_x get "sector") == _sector
                || {(_x getOrDefault ["funding", ""]) == _sector}
                || {(_x getOrDefault ["assigned", ""]) == _sector}
                || {(_x getOrDefault ["objective", ""]) == _sector}
        };
        _related = [_related, [], {_x get "priority"}, "DESCEND"] call BIS_fnc_sortBy;
    };
    private _record = if (_related isNotEqualTo []) then {_related # 0} else {
        [_sector, [_sector], _raw] call KPLIB_INTEL_SERVER_ASSESS_REGION
    };
    private _report = [_record, [3, 2] select _prisoner, [_sector], _raw] call KPLIB_INTEL_SERVER_BUILD_OBSERVATION;
    _report set [0, "LEAD_" + (_report # 0)];
    private _meta = _report # 12;
    _meta set ["status", "RECOVERED LEAD"];
    _meta set ["priority", 80];
    _meta set ["title", (["Documents: ", "Debrief: "] select _prisoner) + (_meta get "title")];
    _meta set ["confidence", "SOURCE REPORT - information dates from document recovery context or capture"];
    _meta set ["window", "Single-source lead, not live coverage. Reconnoitre or purchase regional analysis to confirm current activity."];
    _sources set [_key, [_object, _report, CBA_missionTime]];
    // Bound abandoned document/corpse context without growing a permanent identity registry.
    if (count _sources > 256) then {
        private _oldest = [keys _sources, [], {(_sources get _x) # 2}, "ASCEND"] call BIS_fnc_sortBy;
        _sources deleteAt (_oldest # 0);
    };
};

// Only validated collection/debrief handlers call this private closure.
localNamespace setVariable ["KPLIB_INTEL_CLAIM_LEAD", {
    params ["_object"];
    private _sources = localNamespace getVariable "KPLIB_INTEL_SOURCES";
    private _key = netId _object;
    private _entry = _sources getOrDefault [_key, []];
    if (_entry isEqualTo [] || {(_entry # 0) isNotEqualTo _object}) exitWith {false};
    _sources deleteAt _key;
    private _report = _entry # 1;
    KPLIB_INTEL_LEADS set [_report # 0, createHashMapFromArray [
        ["report", _report], ["expiresAt", CBA_missionTime + KPLIB_intelligence_lead_duration]
    ]];
    true
}];
