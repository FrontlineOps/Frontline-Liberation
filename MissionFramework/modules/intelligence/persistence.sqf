/* Saved inside the Battlespace logistics snapshot so paid personnel, stock losses and
   completed cases share one generation. No object/group handles or running timers are saved. */
KPLIB_INTEL_SERVER_PACK_REPORT = {
    params ["_report"];
    private _packed = _report select [0, 12];
    _packed set [6, (CBA_missionTime - (_report # 6)) max 0];
    private _meta = [];
    {_meta pushBack [_x, _y]} forEach (_report # 12);
    _packed pushBack _meta;
    _packed
};

KPLIB_INTEL_SERVER_VALID_REPORT = {
    params ["_report"];
    if !(_report isEqualType [] && {count _report == 13}) exitWith {false};
    (_report # 0) isEqualType ""
        && {(_report # 4) isEqualType []}
        && {(_report # 6) isEqualType 0}
        && {(_report # 12) isEqualType []}
        && {(_report # 12) findIf {!(_x isEqualType [] && {count _x == 2} && {(_x # 0) isEqualType ""})} < 0}
        && {private _meta = createHashMapFromArray (_report # 12); (_meta getOrDefault ["details", []]) isEqualType []}
};

KPLIB_INTEL_SERVER_UNPACK_REPORT = {
    params ["_packed"];
    private _report = +_packed;
    _report set [6, CBA_missionTime - (_packed # 6)];
    _report set [12, createHashMapFromArray (_packed # 12)];
    _report
};

KPLIB_INTEL_SERVER_EXPORT = {
    if !(call KPLIB_INTEL_SERVER_INTERNAL) exitWith {[]};
    private _cases = [];
    private _prisoners = [];
    private _refunds = [];
    private _savePrisoner = {
        params ["_unit", "_source", "_caseId", "_site", "_id"];
        if (isNull _unit || {!alive _unit} || {count _source < 5}) exitWith {};
        _prisoners pushBack [_id, typeOf _unit, getPosATL _unit, damage _unit, _caseId, _site,
            [[_source # 1] call KPLIB_INTEL_SERVER_PACK_REPORT, _source # 3, _source # 4]];
    };
    {
        [_y get "unit", _y get "source", _y get "case", _y get "site", _x] call _savePrisoner;
    } forEach (localNamespace getVariable "KPLIB_INTEL_DETAINEES");
    {
        private _case = _y;
        private _target = _case getOrDefault ["target", objNull];
        private _roster = (_case getOrDefault ["guards", []]) select {alive _x && {!captive _x} && {!(_x getVariable ["KPLIB_intelligencePrisoner", false])}} apply {typeOf _x};
        if ((_case get "status") == "QUEUED") then {_roster = +(_case get "roster")};
        private _assets = (_case getOrDefault ["assets", []]) select {[_x] call KPLIB_INTEL_SERVER_ASSET_ALIVE} apply {_x # 1};
        if ((_case get "status") == "QUEUED") then {_assets = +(_case getOrDefault ["assetRoster", []])};
        private _status = _case get "status";
        private _history = +(_case get "history");
        if (_status == "ACTIVE" && {isNull _target || {!alive _target}} && {(_case get "stage") < 2}) then {
            _status = "FAILED";
            _history pushBack "The source was killed or the evidence was lost.";
            _refunds pushBack [_case get "sector", count _roster, _assets];
            _roster = [];
            _assets = [];
        };
        if (_status == "ACTIVE" && {_target getVariable ["KPLIB_intelligencePrisoner", false]}) then {
            if !(_target getVariable ["KPLIB_intelligenceDetained", false]) then {
                private _source = (localNamespace getVariable "KPLIB_INTEL_SOURCES") getOrDefault [netId _target, []];
                [_target, _source, _x, [], ""] call _savePrisoner;
            };
            _refunds pushBack [_case get "sector", count _roster, _assets];
            _roster = [];
            _assets = [];
        };
        _cases pushBack [_x, _case get "sector", _case get "kind", _case get "stage", _status,
            +(_case get "position"), _history, ((_case get "deadline") - CBA_missionTime) max 0,
            _roster, _case get "funded", _status == "ACTIVE" && {(_case get "stage") == 2} && {!alive _target}, _assets];
    } forEach (localNamespace getVariable "KPLIB_INTEL_CASES");
    {
        _x params ["_sector", "_people", "_prop", "_group", ["_assets", []]];
        _refunds pushBack [_sector, {alive _x && {!captive _x} && {!(_x getVariable ["KPLIB_intelligencePrisoner", false])}} count _people, (_assets select {[_x] call KPLIB_INTEL_SERVER_ASSET_ALIVE}) apply {_x # 1}];
    } forEach (localNamespace getVariable "KPLIB_INTEL_RETIRED");
    private _effects = [];
    {_effects pushBack [_x, (_y - CBA_missionTime) max 0]} forEach (localNamespace getVariable "KPLIB_INTEL_EFFECTS");
    private _reports = [];
    {_reports pushBack [[_y get "report"] call KPLIB_INTEL_SERVER_PACK_REPORT, ((_y get "expiresAt") - CBA_missionTime) max 0]} forEach KPLIB_INTEL_LEADS;
    [3, localNamespace getVariable "KPLIB_INTEL_NEXT_ID", _cases, _prisoners, _effects, _reports, _refunds, call KPLIB_INTEL_SERVER_BASE_EXPORT]
};

KPLIB_INTEL_SERVER_IMPORT = {
    params [["_data", [], [[]]]];
    if (!(call KPLIB_INTEL_SERVER_INTERNAL) || {localNamespace getVariable ["KPLIB_INTEL_IMPORTED", false]}) exitWith {false};
    localNamespace setVariable ["KPLIB_INTEL_IMPORTED", true];
    if !((count _data == 7 && {(_data # 0) in [1, 2]}) || {count _data == 8 && {(_data # 0) == 3}}) exitWith {false};
    if !((_data # 1) isEqualType 0 && {(_data select [2]) findIf {!(_x isEqualType [])} < 0}) exitWith {false};
    _data params ["_version", "_next", "_savedCases", "_savedPrisoners", "_savedEffects", "_savedReports", "_refunds"];
    localNamespace setVariable ["KPLIB_INTEL_NEXT_ID", _next max 0];
    private _cases = localNamespace getVariable "KPLIB_INTEL_CASES";
    {
        if !(_x isEqualType [] && {count _x in [11, 12]}) then {continue};
        _x params ["_id", "_sector", "_kind", "_stage", "_status", "_position", "_history", "_remaining", "_roster", "_funded", "_destroyed", ["_assets", []]];
        if !(_id isEqualType "" && {_sector in keys BATTLESPACE_SECTOR_STATES} && {_kind in ["LOGISTICS", "FIRE_SUPPORT", "COMMAND"]} && {_stage in [0, 1, 2]} && {_status in ["QUEUED", "ACTIVE", "SUCCEEDED", "FAILED", "CANCELED"]} && {_position isEqualType []} && {_history isEqualType []} && {_remaining isEqualType 0} && {_roster isEqualType []} && {_funded isEqualType true}) then {continue};
        private _case = createHashMapFromArray [
            ["id", _id], ["sector", _sector], ["kind", _kind], ["stage", _stage], ["status", [ _status, "QUEUED"] select (_status == "ACTIVE")],
            ["position", _position], ["history", _history], ["deadline", CBA_missionTime + (_remaining min KPLIB_intelligence_stage_duration)],
            ["roster", _roster select {_x isEqualType "" && {isClass (configFile >> "CfgVehicles" >> _x)}}], ["funded", _funded],
            ["assetRoster", _assets select {
                _x isEqualType [] && {count _x == 5} && {(_x # 0) isEqualType ""}
                    && {isClass (configFile >> "CfgVehicles" >> (_x # 0))} && {(_x # 1) in ["car", "construction_supplies"]}
                    && {(_x # 2) isEqualType 0} && {(_x # 2) > 0} && {(_x # 3) in ["GUN", "FENCE"]}
                    && {(_x # 4) isEqualType 0} && {(_x # 4) >= 0} && {(_x # 4) < 4}
            }],
            ["assets", []], ["groups", []], ["props", []],
            ["target", objNull], ["guards", []], ["group", grpNull], ["retryAt", 0], ["restoreDestroyed", _destroyed], ["restoredPending", _status in ["ACTIVE", "QUEUED"] && {_funded}]
        ];
        _cases set [_id, _case];
    } forEach (_savedCases select [0, KPLIB_intelligence_max_cases + 24]);
    {
        if !(_x isEqualType [] && {count _x == 7}) then {continue};
        _x params ["_id", "_class", "_pos", "_damage", "_caseId", "_site", "_sourceData"];
        if !(_class isEqualType "" && {_class isKindOf "CAManBase"} && {_pos isEqualType []} && {count _pos == 3} && {_damage isEqualType 0} && {_site isEqualType []} && {_sourceData isEqualType []} && {count _sourceData == 3} && {[_sourceData # 0] call KPLIB_INTEL_SERVER_VALID_REPORT} && {_id isEqualType ""} && {_caseId isEqualType ""}) then {continue};
        private _group = createGroup [GRLIB_side_civilian, true];
        if (isNull _group) then {continue};
        _group setVariable ["acex_headless_blacklist", true, true];
        private _unit = [_class, _pos, _group] call KPLIB_fnc_createManagedUnit;
        if (isNull _unit) then {deleteGroup _group; continue};
        removeAllWeapons _unit;
        _unit setDamage (_damage min 0.9);
        _unit setCaptive true;
        _unit setVariable ["KPLIB_intelligencePrisoner", true, true];
        _unit setVariable ["KPLIB_intelligenceCaptureCounted", _site isNotEqualTo []];
        _unit setVariable ["KPLIB_intelligenceHVT", _caseId, true];
        private _source = [_unit, [_sourceData # 0] call KPLIB_INTEL_SERVER_UNPACK_REPORT, CBA_missionTime, _sourceData # 1, _sourceData # 2];
        private _case = _cases getOrDefault [_caseId, createHashMap];
        if (count _case > 0 && {(_case get "stage") == 1} && {(_case get "status") == "QUEUED"}) then {
            _case set ["target", _unit];
            _case set ["position", +_pos];
            _case set ["restoredPending", false];
            _case set ["status", "ACTIVE"];
        };
        if (_site isNotEqualTo [] && {([_pos] call KPLIB_INTEL_SERVER_GET_SITE) isEqualTo _site}) then {
            if (_id == "") then {_id = call KPLIB_INTEL_SERVER_NEW_ID};
            (localNamespace getVariable "KPLIB_INTEL_DETAINEES") set [_id, createHashMapFromArray [
                ["id", _id], ["unit", _unit], ["source", _source], ["case", _caseId], ["site", _site], ["actor", objNull], ["endsAt", -1], ["startedAt", -1]
            ]];
            _unit setVariable ["KPLIB_intelligenceDelivered", true, true];
            _unit setVariable ["KPLIB_intelligenceDetained", true, true];
        } else {
            (localNamespace getVariable "KPLIB_INTEL_SOURCES") set [netId _unit, _source];
        };
        [_unit] call KPLIB_INTEL_LOCAL_DETAIN;
    } forEach (_savedPrisoners select [0, KPLIB_intelligence_max_detainees + KPLIB_intelligence_max_active_cases]);
    {
        if (_x isEqualType [] && {count _x == 2} && {(_x # 0) isEqualType ""} && {(_x # 1) isEqualType 0}) then {
            (localNamespace getVariable "KPLIB_INTEL_EFFECTS") set [_x # 0, CBA_missionTime + ((_x # 1) min KPLIB_intelligence_disruption_duration)];
        };
    } forEach _savedEffects;
    {
        if (_x isEqualType [] && {count _x == 2} && {(_x # 0) isEqualType []} && {[_x # 0] call KPLIB_INTEL_SERVER_VALID_REPORT} && {(_x # 1) isEqualType 0}) then {
            private _report = [_x # 0] call KPLIB_INTEL_SERVER_UNPACK_REPORT;
            KPLIB_INTEL_LEADS set [_report # 0, createHashMapFromArray [["report", _report], ["expiresAt", CBA_missionTime + ((_x # 1) min KPLIB_intelligence_lead_duration)]]];
        };
    } forEach (_savedReports select [0, KPLIB_intelligence_max_archived_reports]);
    // These guards retired before the restart. Their survivor refunds belong to this stock snapshot only.
    {
        if (_x isEqualType [] && {count _x in [2, 3]} && {(_x # 0) isEqualType ""} && {(_x # 1) isEqualType 0}) then {
            if ((_x # 1) > 0) then {[_x # 0, createHashMapFromArray [["manpower", _x # 1]]] call BATTLESPACE_RESOURCE_DEPOSIT_CLAMPED};
            [_x # 0, _x param [2, []]] call KPLIB_INTEL_SERVER_ASSET_REFUND;
        };
    } forEach _refunds;
    call KPLIB_INTEL_SERVER_CHANGED;
    true
};
