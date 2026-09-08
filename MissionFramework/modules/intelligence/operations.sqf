KPLIB_INTEL_SERVER_ENEMY_SECTOR = {
    params ["_sector"];
    private _state = (missionNamespace getVariable ["BATTLESPACE_SECTOR_STATES", createHashMap]) getOrDefault [_sector, createHashMap];
    _sector != "" && {(_state getOrDefault ["owner", ""]) == "OPFOR"}
};

KPLIB_INTEL_SERVER_NEW_CASE = {
    params ["_sector", ["_kind", "COMMAND"]];
    if !(_kind in ["LOGISTICS", "FIRE_SUPPORT", "COMMAND"]) exitWith {""};
    if (!(call KPLIB_INTEL_SERVER_MUTATION_ALLOWED) || {!([_sector] call KPLIB_INTEL_SERVER_ENEMY_SECTOR)}) exitWith {""};
    private _cases = localNamespace getVariable "KPLIB_INTEL_CASES";
    private _live = values _cases select {(_x get "status") in ["ACTIVE", "QUEUED"]};
    if (count _live >= KPLIB_intelligence_max_cases || {_live findIf {(_x get "sector") == _sector && {(_x get "kind") == _kind}} >= 0}) exitWith {""};
    private _id = call KPLIB_INTEL_SERVER_NEW_ID;
    _cases set [_id, createHashMapFromArray [
        ["id", _id], ["sector", _sector], ["kind", _kind], ["stage", 0], ["status", "QUEUED"],
        ["position", markerPos _sector], ["history", ["Recovered source information identified an enemy support network."]],
        ["deadline", CBA_missionTime + KPLIB_intelligence_stage_duration], ["target", objNull],
        ["guards", []], ["group", grpNull], ["roster", []], ["funded", false], ["retryAt", 0]
    ]];
    call KPLIB_INTEL_SERVER_CHANGED;
    _id
};

KPLIB_INTEL_SERVER_RETIRE_SITE = {
    if !(call KPLIB_INTEL_SERVER_MUTATION_ALLOWED) exitWith {};
    params ["_case"];
    if (_case getOrDefault ["funded", false] && {_case getOrDefault ["restoredPending", false]}) then {
        private _refund = count (_case getOrDefault ["roster", []]);
        if ((_case get "stage") == 1) then {_refund = _refund + 1};
        [_case get "sector", _case getOrDefault ["assetRoster", []]] call KPLIB_INTEL_SERVER_ASSET_REFUND;
        if (_refund > 0) then {[_case get "sector", createHashMapFromArray [["manpower", _refund]]] call BATTLESPACE_RESOURCE_DEPOSIT_CLAMPED};
    };
    private _target = _case getOrDefault ["target", objNull];
    private _guards = +(_case getOrDefault ["guards", []]);
    if (!isNull _target && {_target isKindOf "Man"} && {!(_target getVariable ["KPLIB_intelligencePrisoner", false])}) then {_guards pushBackUnique _target};
    private _prop = if (!isNull _target && {!(_target isKindOf "Man")}) then {_target} else {objNull};
    (localNamespace getVariable "KPLIB_INTEL_RETIRED") pushBack [
        _case get "sector", _guards, _prop, _case getOrDefault ["group", grpNull],
        _case getOrDefault ["assets", []], _case getOrDefault ["groups", []], _case getOrDefault ["props", []]
    ];
    _case set ["assets", []];
    _case set ["assetRoster", []];
    _case set ["groups", []];
    _case set ["props", []];
    _case deleteAt "plan";
    private _planner = _case getOrDefault ["planner", scriptNull];
    if (!scriptDone _planner) then {terminate _planner};
    _case set ["planner", scriptNull];
    _case set ["target", objNull];
    _case set ["guards", []];
    _case set ["group", grpNull];
    _case set ["roster", []];
    _case set ["funded", false];
    _case set ["restoredPending", false];
};

KPLIB_INTEL_SERVER_END_CASE = {
    params ["_case", "_status", "_reason"];
    if (!(call KPLIB_INTEL_SERVER_MUTATION_ALLOWED) || {!((_case get "status") in ["ACTIVE", "QUEUED"])}) exitWith {};
    _case set ["status", _status];
    (_case get "history") pushBack _reason;
    _case set ["deadline", CBA_missionTime + KPLIB_intelligence_archive_duration];
    [_case] call KPLIB_INTEL_SERVER_RETIRE_SITE;
    call KPLIB_INTEL_SERVER_CHANGED;
};

KPLIB_INTEL_SERVER_ADVANCE_CASE = {
    params ["_case", "_reason"];
    if (!(call KPLIB_INTEL_SERVER_MUTATION_ALLOWED) || {(_case get "status") != "ACTIVE"}) exitWith {};
    [_case] call KPLIB_INTEL_SERVER_RETIRE_SITE;
    (_case get "history") pushBack _reason;
    _case set ["stage", 1 + (_case get "stage")];
    _case set ["status", "QUEUED"];
    _case set ["deadline", CBA_missionTime + KPLIB_intelligence_stage_duration];
    _case set ["retryAt", 0];
    call KPLIB_INTEL_SERVER_CHANGED;
};

KPLIB_INTEL_SERVER_COMPLETE_CASE = {
    params ["_case"];
    if (!(call KPLIB_INTEL_SERVER_MUTATION_ALLOWED) || {(_case get "status") != "ACTIVE"} || {(_case get "stage") != 2}) exitWith {false};
    private _sector = _case get "sector";
    if !([_sector] call KPLIB_INTEL_SERVER_ENEMY_SECTOR) exitWith {
        [_case, "SUCCEEDED", "The sector is already secure; no enemy stock or support remains to disrupt."] call KPLIB_INTEL_SERVER_END_CASE;
        true
    };
    private _kind = _case get "kind";
    private _result = "";
    private _applied = true;
    if (_kind == "LOGISTICS") then {
        private _stock = (BATTLESPACE_SECTOR_STATES get _sector) get "resources";
        private _debit = createHashMap;
        {
            private _amount = floor ((_stock getOrDefault [_x, 0]) * KPLIB_intelligence_stock_loss);
            if (_amount > 0) then {_debit set [_x, -_amount]};
        } forEach ["manpower", "construction_supplies", "rockets", "truck"];
        if (count _debit > 0) then {_applied = [_sector, _debit] call BATTLESPACE_RESOURCE_APPLY_STRICT};
        private _losses = [];
        {_losses pushBack format ["%1 %2", -_y, (["personnel", "supply crates", "rockets", "trucks"] # (["manpower", "construction_supplies", "rockets", "truck"] find _x))]} forEach _debit;
        _result = "Supply site destroyed. Enemy stock removed: " + (_losses joinString ", ") + ".";
    } else {
        private _key = _sector + ":" + _kind;
        private _effects = localNamespace getVariable "KPLIB_INTEL_EFFECTS";
        _effects set [_key, (_effects getOrDefault [_key, 0]) max (CBA_missionTime + KPLIB_intelligence_disruption_duration)];
        _result = ([_case] call KPLIB_INTEL_SERVER_CASE_BRIEF) # 2;
    };
    if (!_applied) exitWith {false};
    [format ["Case %1 completed at %2: %3", _case get "id", _sector, _result], "INTELLIGENCE"] call KPLIB_fnc_log;
    [_case, "SUCCEEDED", _result] call KPLIB_INTEL_SERVER_END_CASE;
    true
};

KPLIB_INTEL_SERVER_SPAWN_STAGE = {
    params ["_case"];
    if (!(call KPLIB_INTEL_SERVER_MUTATION_ALLOWED) || {(_case get "status") != "QUEUED"}) exitWith {false};
    if (count (localNamespace getVariable "KPLIB_INTEL_RETIRED") >= 12) exitWith {false};
    if !([_case get "sector"] call KPLIB_INTEL_SERVER_ENEMY_SECTOR) exitWith {false};
    _case set ["retryAt", CBA_missionTime + 30];
    private _plan = _case getOrDefault ["plan", createHashMap];
    if (count _plan > 0 && {CBA_missionTime - (_plan get "createdAt") > 60 || {!alive (_plan get "building")}}) then {
        _case deleteAt "plan";
        _plan = createHashMap;
    };
    if (count _plan == 0) exitWith {
        // At most one geometry search runs across all queued cases.
        if (!scriptDone (localNamespace getVariable ["KPLIB_INTEL_SITE_PLANNER", scriptNull])) exitWith {false};
        if (scriptDone (_case getOrDefault ["planner", scriptNull])) then {
            private _worker = [_case, _case get "stage"] spawn {
                params ["_case", "_stage"];
                private _plan = [_case, _stage] call KPLIB_INTEL_SERVER_PLAN_SITE;
                if ((_case get "status") == "QUEUED" && {(_case get "stage") == _stage}) then {
                    _case set ["plan", _plan];
                    if (count _plan > 0) then {_case set ["retryAt", 0]};
                };
            };
            _case set ["planner", _worker];
            localNamespace setVariable ["KPLIB_INTEL_SITE_PLANNER", _worker];
        };
        false
    };
    private _success = false;
    // Funding, materialization and activation share one unscheduled transaction.
    isNil {_success = [_case, _plan] call KPLIB_INTEL_SERVER_DEPLOY_SITE};
    _success
};

KPLIB_INTEL_SERVER_TICK_CASES = {
    if !(call KPLIB_INTEL_SERVER_MUTATION_ALLOWED) exitWith {};
    private _retired = localNamespace getVariable "KPLIB_INTEL_RETIRED";
    for "_i" from (count _retired - 1) to 0 step -1 do {
        (_retired # _i) params ["_sector", "_people", "_prop", "_group", ["_assets", []], ["_groups", []], ["_props", []]];
        private _owned = _people select {!isNull _x && {!isPlayer _x} && {!(_x getVariable ["KPLIB_intelligencePrisoner", false])}};
        private _objects = _owned + ([_prop] select {!isNull _x}) + _props;
        private _ownedAssets = _assets select {
            private _obj = _x # 0;
            !(_obj getVariable ["KPLIB_captured", false]) && {crew _obj findIf {isPlayer _x || {side group _x == GRLIB_side_friendly}} < 0}
        };
        _objects append (_ownedAssets apply {_x # 0});
        if (_objects findIf {private _obj = _x; allPlayers findIf {alive _x && {_x distance2D _obj < 500}} >= 0} >= 0) then {continue};
        private _survivors = {alive _x && {!captive _x}} count _owned;
        [_sector, (_ownedAssets select {[_x] call KPLIB_INTEL_SERVER_ASSET_ALIVE}) apply {_x # 1}] call KPLIB_INTEL_SERVER_ASSET_REFUND;
        {deleteVehicle _x} forEach _objects;
        _groups pushBackUnique _group;
        {if (!isNull _x && {units _x isEqualTo []}) then {deleteGroup _x}} forEach _groups;
        if (_survivors > 0) then {[_sector, createHashMapFromArray [["manpower", _survivors]]] call BATTLESPACE_RESOURCE_DEPOSIT_CLAMPED};
        _retired deleteAt _i;
        call KPLIB_INTEL_SERVER_CHANGED;
    };
    private _cases = localNamespace getVariable "KPLIB_INTEL_CASES";
    private _active = {(_x get "status") == "ACTIVE"} count values _cases;
    {
        private _case = _cases get _x;
        private _status = _case get "status";
        if !(_status in ["ACTIVE", "QUEUED"]) then {
            if ((_case get "deadline") <= CBA_missionTime) then {_cases deleteAt _x};
            continue;
        };
        if ((_case get "deadline") <= CBA_missionTime) then {
            [_case, "FAILED", "The lead expired before this stage was resolved."] call KPLIB_INTEL_SERVER_END_CASE;
            continue;
        };
        private _target = _case getOrDefault ["target", objNull];
        if (!([_case get "sector"] call KPLIB_INTEL_SERVER_ENEMY_SECTOR) && {!(_target getVariable ["KPLIB_intelligenceDetained", false])}) then {
            [_case, "CANCELED", "Friendly forces secured the sector before this lead was resolved."] call KPLIB_INTEL_SERVER_END_CASE;
            continue;
        };
        if (_status == "ACTIVE") then {
            if (isNull _target || {!alive _target}) then {
                if ((_case get "stage") == 2 && {!isNull _target}) then {
                    [_case] call KPLIB_INTEL_SERVER_COMPLETE_CASE;
                } else {
                    [_case, "FAILED", "The source was killed or the evidence was lost."] call KPLIB_INTEL_SERVER_END_CASE;
                };
            };
        } else {
            if (_active < KPLIB_intelligence_max_active_cases && {CBA_missionTime >= (_case get "retryAt")}) then {
                if ([_case] call KPLIB_INTEL_SERVER_SPAWN_STAGE) then {_active = _active + 1};
            };
        };
    } forEach keys _cases;
};
