/* Server-owned, once-per-campaign military records. One desk holds a local dossier.
   Papers survive capture; stocks are frozen before the strategic ledger is cleared.
   Placement is scheduled and bounded. No new defenders or strategic resources. */
localNamespace setVariable ["KPLIB_INTEL_BASES", createHashMap];
localNamespace setVariable ["KPLIB_INTEL_BASE_WORKER", scriptNull];

KPLIB_INTEL_SERVER_BASE_DOSSIER = {
    params ["_sector"];
    private _raw = call KPLIB_INTEL_SERVER_COLLECT_RAW_REPORTS;
    private _related = _raw select {
        _sector in [_x getOrDefault ["sector", ""], _x getOrDefault ["funding", ""],
            _x getOrDefault ["assigned", ""], _x getOrDefault ["objective", ""],
            _x getOrDefault ["origin", ""]]
    };
    // Convoy manifests first, then the most consequential related deployments.
    private _ranked = _related apply {
        [(_x getOrDefault ["priority", 0]) + ([0, 100] select ((_x get "kind") == "CONVOY")), _x get "id", _x]
    };
    _ranked sort false;
    private _stock = [_sector, false, _raw] call KPLIB_INTEL_SERVER_STOCK_REPORT;
    private _details = (_stock # 12) get "details";
    _details pushBack format ["Operations connected to this base: %1. Convoys recorded: %2.", count _related, {(_x get "kind") == "CONVOY"} count _related];
    _details pushBack "Manifests describe active shipments, not a guaranteed future convoy schedule.";
    private _reports = [_stock];
    {
        _reports pushBack ([_x # 2, 3, [_sector], _raw] call KPLIB_INTEL_SERVER_BUILD_OBSERVATION);
    } forEach (_ranked select [0, 6]);
    {
        private _meta = _x # 12;
        _meta set ["title", format ["%1 records: %2", [_sector] call KPLIB_INTEL_SERVER_LABEL, _meta get "title"]];
        _meta set ["status", "RECOVERED RECORD"];
        _meta set ["confidence", "Captured base records; dated information"];
        _meta set ["window", "Recorded before recovery or loss of the base. Reconnoitre to confirm current conditions."];
        _meta set ["taskEligible", false];
        _meta set ["mapVisible", true];
    } forEach _reports;
    _reports
};

KPLIB_INTEL_SERVER_BASE_FREEZE = {
    params ["_sector"];
    if (!(call KPLIB_INTEL_SERVER_INTERNAL) || {!KPLIB_intelligence_enabled}) exitWith {};
    private _entry = (localNamespace getVariable "KPLIB_INTEL_BASES") getOrDefault [_sector, createHashMap];
    if (count _entry == 0 || {(_entry get "status") in ["CLAIMED", "DESTROYED"]}
        || {_entry getOrDefault ["frozen", false]}) exitWith {};
    _entry set ["reports", [_sector] call KPLIB_INTEL_SERVER_BASE_DOSSIER];
    _entry set ["frozen", true];
    call KPLIB_INTEL_SERVER_CHANGED;
};

KPLIB_INTEL_SERVER_BASE_COLLECT = {
    params ["_object"];
    if !(call KPLIB_INTEL_SERVER_MUTATION_ALLOWED) exitWith {false};
    // Called only after the shared collector's actor, class, range and LOS checks.
    private _bases = localNamespace getVariable "KPLIB_INTEL_BASES";
    private _sector = keys _bases select {
        private _entry = _bases get _x;
        (_entry get "status") == "AVAILABLE" && {(_entry getOrDefault ["object", objNull]) isEqualTo _object}
    };
    if (_sector isEqualTo [] || {isNull _object} || {!alive _object}) exitWith {false};
    _sector = _sector # 0;
    private _entry = _bases get _sector;
    private _table = _entry getOrDefault ["table", objNull];
    if (isNull _table || {!alive _table} || {!alive (_entry getOrDefault ["building", objNull])}) exitWith {false};
    if !(_entry getOrDefault ["frozen", false]) then {[_sector] call KPLIB_INTEL_SERVER_BASE_FREEZE};
    // Consume identity before publishing; a second player cannot collect it again.
    _entry set ["status", "CLAIMED"];
    {
        [[objNull, _x, CBA_missionTime, _sector, ""], false] call KPLIB_INTEL_SERVER_REVEAL_SOURCE;
    } forEach (_entry getOrDefault ["reports", []]);
    _entry set ["reports", []];
    _entry set ["object", objNull];
    _object setVariable ["KPLIB_intelligenceCollected", true, true];
    deleteVehicle _object;
    call KPLIB_INTEL_SERVER_CHANGED;
    true
};

KPLIB_INTEL_SERVER_BASE_ACCESS = {
    params ["_building", "_desk"];
    private _candidates = +(_building buildingPos -1);
    {
        private _radius = _x;
        for "_angle" from 0 to 315 step 45 do {
            private _candidate = _desk getPos [_radius, _angle];
            _candidate set [2, _desk # 2];
            _candidates pushBack _candidate;
        };
    } forEach [1.2, 1.8, 2.5];
    private _access = [];
    {
        if (_x distance2D _desk < 1 || {_x distance _desk > 3.5}) then {continue};
        private _feet = [_building, _x] call KPLIB_INTEL_SERVER_INTERIOR_POSITION;
        if (_feet isEqualTo []) then {continue};
        private _eye = (ATLToASL _feet) vectorAdd [0, 0, 1.55];
        private _paper = (ATLToASL _desk) vectorAdd [0, 0, 0.98];
        if (lineIntersectsSurfaces [_eye, _paper, objNull, objNull, true, 1, "GEOM", "NONE"] isEqualTo []) exitWith {_access = _feet};
    } forEach _candidates;
    _access
};

KPLIB_INTEL_SERVER_BASE_GROUND = {
    params ["_position"];
    if (surfaceIsWater _position || {isOnRoad _position}) exitWith {[]};
    private _origin = ATLToASL [_position # 0, _position # 1, 0];
    private _clear = true;
    // Use the small office's footprint. isFlatEmpty's object bounding spheres
    // reject usable clearings alongside the large legacy forest/terrain models.
    {
        private _corner = _origin vectorAdd _x;
        private _ground = getTerrainHeightASL [_corner # 0, _corner # 1];
        if (abs (_ground - (_origin # 2)) > 0.3 || {surfaceIsWater _corner} || {isOnRoad _corner}) exitWith {_clear = false};
        if (lineIntersectsSurfaces [_corner vectorAdd [0,0,0.35], _corner vectorAdd [0,0,3.4], objNull, objNull, true, 1, "GEOM", "NONE"] isNotEqualTo []) exitWith {_clear = false};
    } forEach [[-3,-2,0],[-3,2,0],[3,-2,0],[3,2,0],[0,0,0]];
    if (!_clear) exitWith {[]};
    {
        private _relative = (getPosASL _x) vectorDiff _origin;
        if (abs (_relative # 0) < 3.6 && {abs (_relative # 1) < 2.6}) exitWith {_clear = false};
    } forEach (nearestTerrainObjects [_position, ["TREE", "SMALL TREE", "BUSH", "ROCK", "ROCKS"], 5, false, true]);
    if (!_clear) exitWith {[]};
    {
        private _height = _x;
        for "_y" from -2 to 2 do {
            if (lineIntersectsSurfaces [_origin vectorAdd [-3,_y,_height], _origin vectorAdd [3,_y,_height], objNull, objNull, true, 1, "GEOM", "NONE"] isNotEqualTo []) exitWith {_clear = false};
        };
        for "_x" from -3 to 3 do {
            if (lineIntersectsSurfaces [_origin vectorAdd [_x,-2,_height], _origin vectorAdd [_x,2,_height], objNull, objNull, true, 1, "GEOM", "NONE"] isNotEqualTo []) exitWith {_clear = false};
        };
        if (!_clear) exitWith {};
    } forEach [0.5, 1.5, 2.8];
    if (_clear) then {ASLToATL _origin} else {[]}
};

KPLIB_INTEL_SERVER_BASE_PLAN = {
    params ["_sector"];
    if (!(call KPLIB_INTEL_SERVER_INTERNAL) || {!canSuspend}) exitWith {[]};
    private _result = [];
    private _buildings = nearestObjects [markerPos _sector, ["House"], 200];
    {
        private _building = _x;
        if (!alive _building || {(_building buildingExit 0) isEqualTo [0, 0, 0]}) then {continue};
        {
            private _pos = [_building, _x] call KPLIB_INTEL_SERVER_INTERIOR_POSITION;
            if (_pos isNotEqualTo [] && {[_pos] call KPLIB_INTEL_SERVER_ROOM_TABLE_FITS}
                && {[_building, _pos] call KPLIB_INTEL_SERVER_BASE_ACCESS isNotEqualTo []}) exitWith {
                _result = [_pos, getDir _building];
            };
        } forEach ((_building buildingPos -1) select [0, 24]);
        if (_result isNotEqualTo []) exitWith {};
        uiSleep 0.001;
    } forEach (_buildings select [0, 32]);
    // Bare airfields still need an office. Plan one small prefabricated shelter
    // inside the objective, away from roads, only when no existing room is usable.
    if (_result isEqualTo []) then {
        for "_i" from 0 to 95 do {
            private _candidate = (markerPos _sector) getPos [25 + 20 * (_i mod 9), _i * 137.508];
            private _ground = [_candidate] call KPLIB_INTEL_SERVER_BASE_GROUND;
            if (_ground isNotEqualTo []) exitWith {_result = [[], 0, _ground]};
            uiSleep 0.001;
        };
    };
    _result
};

KPLIB_INTEL_SERVER_BASE_PLACE = {
    params ["_entry", "_plan"];
    if (!(call KPLIB_INTEL_SERVER_MUTATION_ALLOWED) || {(_entry get "status") != "PENDING"} || {_plan isEqualTo []}) exitWith {false};
    _plan params ["_pos", "_dir"];
    if (count _plan == 3) then {
        private _ground = _plan # 2;
        private _office = _entry getOrDefault ["office", objNull];
        if (isNull _office && {[_ground] call KPLIB_INTEL_SERVER_SITE_CLEAR}
            && {[_ground] call KPLIB_INTEL_SERVER_BASE_GROUND isNotEqualTo []}) then {
            _office = createVehicle ["Land_Cargo_House_V1_F", _ground, [], 0, "CAN_COLLIDE"];
            if (!isNull _office) then {
                _office setDir 0;
                _office setPosATL _ground;
                _office setDamage (_entry getOrDefault ["officeDamage", 0]);
                _entry set ["office", _office];
                _entry set ["plan", _plan];
                call KPLIB_INTEL_SERVER_CHANGED;
            };
        };
        _pos = [];
        if (!isNull _office && {alive _office}) then {
            private _rooms = _office buildingPos -1;
            // Authored AI positions hug this small shelter's walls. Also try its
            // interior centre at the authored floor height so the desk fits.
            if (_rooms isNotEqualTo []) then {
                private _height = (_rooms # 0) # 2;
                {
                    private _candidate = _office modelToWorld _x;
                    _candidate set [2, _height];
                    _rooms pushBack _candidate;
                } forEach [[0, 0, 0], [-0.5, 0, 0], [0.5, 0, 0], [0, -0.5, 0], [0, 0.5, 0]];
            };
            {
                private _room = [_office, _x] call KPLIB_INTEL_SERVER_INTERIOR_POSITION;
                if (_room isNotEqualTo [] && {[_room] call KPLIB_INTEL_SERVER_ROOM_TABLE_FITS}
                    && {[_office, _room] call KPLIB_INTEL_SERVER_BASE_ACCESS isNotEqualTo []}) exitWith {_pos = _room};
            } forEach _rooms;
        };
        _plan set [0, _pos];
    };
    if (_pos isEqualTo []) exitWith {false};
    if !([_pos] call KPLIB_INTEL_SERVER_SITE_CLEAR) exitWith {false};
    if !([_pos] call KPLIB_INTEL_SERVER_ROOM_TABLE_FITS) exitWith {false};
    private _roof = lineIntersectsSurfaces [(ATLToASL _pos) vectorAdd [0, 0, 1.9], (ATLToASL _pos) vectorAdd [0, 0, 16], objNull, objNull, true, 1, "GEOM", "NONE"];
    if (_roof isEqualTo []) exitWith {false};
    private _building = (_roof # 0) # 3;
    if (isNull _building) then {_building = (_roof # 0) # 2};
    if (isNull _building || {!alive _building} || {!(_building isKindOf "House")}) exitWith {false};
    private _table = createVehicle ["Land_CampingTable_small_F", _pos, [], 0, "CAN_COLLIDE"];
    if (isNull _table) exitWith {false};
    _table setDir 0; // ROOM_TABLE_FITS validates this table's world-aligned footprint.
    _table setPosATL _pos;
    // These are fixed office props, still damageable. Prevent physics from ejecting
    // light papers from desks on legacy terrain models or moving the saved desk.
    _table enableSimulationGlobal false;
    private _top = lineIntersectsSurfaces [(ATLToASL _pos) vectorAdd [0, 0, 1.5], (ATLToASL _pos) vectorAdd [0, 0, 0.2], objNull, objNull, true, 1, "GEOM", "NONE"];
    if (_top isEqualTo [] || {!(_table in [(_top # 0) # 2, (_top # 0) # 3])}) exitWith {deleteVehicle _table; false};
    private _paperPos = ASLToATL (((_top # 0) # 0) vectorAdd [0, 0, 0.02]);
    private _object = createVehicle [KPLIB_intelObjectClasses # 0, _paperPos, [], 0, "CAN_COLLIDE"];
    if (isNull _object) exitWith {deleteVehicle _table; false};
    _object setDir _dir;
    _object setPosATL _paperPos;
    _object enableSimulationGlobal false;
    _object setDamage (_entry getOrDefault ["damage", 0]);
    _table setDamage (_entry getOrDefault ["tableDamage", 0]);
    {_x setVariable ["KPLIB_intelligenceMission", true, true]} forEach [_table, _object];
    _object setVariable ["KPLIB_intelligenceBaseRecords", true, true];
    _entry set ["object", _object];
    _entry set ["table", _table];
    _entry set ["building", _building];
    _entry set ["plan", _plan];
    _entry set ["status", "AVAILABLE"];
    call KPLIB_INTEL_SERVER_CHANGED;
    true
};

KPLIB_INTEL_SERVER_BASE_TICK = {
    if !(call KPLIB_INTEL_SERVER_MUTATION_ALLOWED) exitWith {};
    private _bases = localNamespace getVariable "KPLIB_INTEL_BASES";
    {
        private _entry = _y;
        if ((_entry get "status") == "AVAILABLE") then {
            private _object = _entry get "object";
            private _table = _entry get "table";
            if (isNull _object || {!alive _object} || {isNull _table} || {!alive _table} || {!alive (_entry getOrDefault ["building", objNull])}) then {
                _entry set ["status", "DESTROYED"];
                _entry set ["reports", []];
                deleteVehicle _object;
                deleteVehicle _table;
                _entry set ["object", objNull];
                _entry set ["table", objNull];
                call KPLIB_INTEL_SERVER_CHANGED;
            };
        };
    } forEach _bases;
    if !(scriptDone (localNamespace getVariable "KPLIB_INTEL_BASE_WORKER")) exitWith {};
    private _pending = keys _bases select {private _entry = _bases get _x; (_entry get "status") == "PENDING" && {CBA_missionTime >= (_entry getOrDefault ["retryAt", 0])}};
    if (_pending isEqualTo []) exitWith {};
    private _sector = _pending # 0;
    private _entry = _bases get _sector;
    _entry set ["retryAt", CBA_missionTime + 300];
    localNamespace setVariable ["KPLIB_INTEL_BASE_WORKER", [_sector, _entry] spawn {
        params ["_sector", "_entry"];
        private _plan = _entry getOrDefault ["plan", []];
        if (_plan isEqualTo []) then {_plan = [_sector] call KPLIB_INTEL_SERVER_BASE_PLAN};
        if (_plan isNotEqualTo []) then {
            // Publish objects and their private save identity in one local callback.
            [{_this call KPLIB_INTEL_SERVER_BASE_PLACE}, [_entry, _plan]] call CBA_fnc_execNextFrame;
        } else {
            if !(_entry getOrDefault ["warned", false]) then {
                [format ["Base records await a usable interior at %1", _sector], "INTELLIGENCE"] call KPLIB_fnc_log;
                _entry set ["warned", true];
            };
        };
    }];
};

KPLIB_INTEL_SERVER_BASE_EXPORT = {
    if !(call KPLIB_INTEL_SERVER_INTERNAL) exitWith {[]};
    private _rows = [];
    {
        private _status = _y get "status";
        private _object = _y getOrDefault ["object", objNull];
        private _table = _y getOrDefault ["table", objNull];
        private _office = _y getOrDefault ["office", objNull];
        if (_status == "AVAILABLE" && {isNull _object || {!alive _object} || {isNull _table} || {!alive _table} || {!alive (_y getOrDefault ["building", objNull])}}) then {_status = "DESTROYED"};
        _rows pushBack [_x, _status, _y getOrDefault ["plan", []], _y getOrDefault ["frozen", false],
            (_y getOrDefault ["reports", []]) apply {[_x] call KPLIB_INTEL_SERVER_PACK_REPORT},
            if (isNull _object) then {_y getOrDefault ["damage", 0]} else {damage _object},
            if (isNull _table) then {_y getOrDefault ["tableDamage", 0]} else {damage _table},
            if (isNull _office) then {_y getOrDefault ["officeDamage", 0]} else {damage _office}];
    } forEach (localNamespace getVariable "KPLIB_INTEL_BASES");
    _rows
};

KPLIB_INTEL_SERVER_BASE_IMPORT = {
    params [["_rows", [], [[]]], ["_blocked", false]];
    if !(call KPLIB_INTEL_SERVER_INTERNAL) exitWith {};
    private _bases = localNamespace getVariable "KPLIB_INTEL_BASES";
    {
        // Legacy friendly bases were already looted in that campaign; do not issue a new reward.
        _bases set [_x, createHashMapFromArray [["status", ["PENDING", "CLAIMED"] select (_blocked || {_x in blufor_sectors})], ["reports", []], ["frozen", false]]];
    } forEach sectors_military;
    {
        if !(_x isEqualType [] && {count _x >= 1} && {(_x # 0) in sectors_military}) then {continue};
        private _entry = _bases get (_x # 0);
        // Malformed known rows fail closed, never replenish an already-issued archive.
        _entry set ["status", "DESTROYED"];
        if !(count _x in [7, 8]) then {continue};
        _x params ["_sector", "_status", "_plan", "_frozen", "_reports", "_damage", "_tableDamage", ["_officeDamage", 0]];
        if !(_status in ["PENDING", "AVAILABLE", "CLAIMED", "DESTROYED"] && {_plan isEqualType []}
            && {_frozen isEqualType true} && {_reports isEqualType []} && {count _reports <= 7}
            && {_reports findIf {!([_x] call KPLIB_INTEL_SERVER_VALID_REPORT)} < 0}
            && {_damage isEqualType 0} && {_tableDamage isEqualType 0} && {_officeDamage isEqualType 0}) then {continue};
        if (_plan isNotEqualTo [] && {!((count _plan in [2, 3]) && {(_plan # 0) isEqualType []} && {count (_plan # 0) in [0, 3]}
            && {(_plan # 0) findIf {!(_x isEqualType 0)} < 0} && {(_plan # 1) isEqualType 0})}) then {continue};
        if (count _plan == 3 && {!((_plan # 2) isEqualType [] && {count (_plan # 2) == 3} && {(_plan # 2) findIf {!(_x isEqualType 0)} < 0})}) then {continue};
        if (_damage >= 1 || {_tableDamage >= 1} || {_officeDamage >= 1}) then {_status = "DESTROYED"};
        _entry set ["status", [_status, "PENDING"] select (_status == "AVAILABLE")];
        _entry set ["plan", _plan];
        _entry set ["frozen", _frozen];
        _entry set ["reports", _reports apply {[_x] call KPLIB_INTEL_SERVER_UNPACK_REPORT}];
        _entry set ["damage", _damage max 0];
        _entry set ["tableDamage", _tableDamage max 0];
        _entry set ["officeDamage", _officeDamage max 0];
    } forEach _rows;
};
