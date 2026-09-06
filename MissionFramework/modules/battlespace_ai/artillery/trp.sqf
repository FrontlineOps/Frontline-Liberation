/* Prepared fire plans. Registry, battery handles and observer evidence stay on the server.
   Planning never inserts observer requests, reserves ammunition or creates batteries. */
if (isServer) then {
    localNamespace setVariable ["BSA_TRPS", createHashMap];
    localNamespace setVariable ["BSA_TRP_RETIRED", []];
    localNamespace setVariable ["BSA_TRP_CONTACTS", createHashMap];
    localNamespace setVariable ["BSA_TRP_NEXT_PLAN", 0];
    localNamespace setVariable ["BSA_TRP_SEQUENCE", 0];
};

BATTLESPACE_TRP_PIECES = {
    params ["_battery"];
    private _pieces = [];
    {
        private _piece = vehicle _x;
        if (alive _x && {_piece != _x} && {alive _piece} && {side _x == GRLIB_side_enemy}
            && {!(_piece getVariable ["KPLIB_captured", false])}) then {_pieces pushBackUnique _piece};
    } forEach units _battery;
    _pieces
};

BATTLESPACE_TRP_IN_RANGE = {
    params ["_battery", "_position"];
    private _shell = _battery getVariable ["BSAHEShell", ""];
    if (_shell == "") exitWith {false};
    // READY guns are unloaded. Native ballistic checks still run after the paid reload.
    ([_battery] call BATTLESPACE_TRP_PIECES) findIf {
        private _distance = _x distance2D _position;
        ([_x, _shell] call BATTLESPACE_ARTILLERY_GET_AI_FIRE_RANGES) findIf {
            _distance >= (_x # 0) + 250 && {_distance <= (_x # 1) - 250}
        } >= 0
    } >= 0
};

BATTLESPACE_TRP_SOURCES = {
    private _sources = [];
    private _sectors = [];
    {
        private _op = _y;
        private _kind = _op getOrDefault ["kind", ""];
        private _phase = _op getOrDefault ["phase", ""];
        if (_phase in ["RETURNING", "COMPLETED", "DESTROYED", "DISBANDED"]) then {continue};
        if ((_op getOrDefault ["outcome", ""]) != "") then {continue};
        if (_kind == "DEFENDER") then {
            if !(_phase in ["DEPLOYING", "ON_STATION", "ENGAGED", "DISPLACING"]) then {continue};
            private _sector = _op getOrDefault ["assignedSector", ""];
            if (_sector == "" || {_sector in _sectors}) then {continue};
            private _state = BATTLESPACE_SECTOR_STATES getOrDefault [_sector, createHashMap];
            if ((_state getOrDefault ["owner", ""]) != "OPFOR" || {([_sector] call BATTLESPACE_DEFENSE_GET_FRONT_DEPTH) > 1}) then {continue};
            _sectors pushBack _sector;
            // Sector assignments survive ordinary defender rotation; the point does too.
            _sources pushBack ["DEFENSIVE", _sector, "", _sector];
        };
        if (_kind == "BATTLEGROUP" && {(_op getOrDefault ["outcome", ""]) == ""}) then {
            private _target = _op getOrDefault ["targetSector", ""];
            private _anchor = _op getOrDefault ["approachSector", ""];
            if (_target in blufor_sectors && {_anchor != ""}) then {
                _sources pushBack ["OFFENSIVE", _target, _x, _anchor];
            };
        };
    } forEach BATTLESPACE_STRATEGIC_OPERATIONS;
    _sources
};

BATTLESPACE_TRP_INVALID_REASON = {
    params ["_trp", ["_sources", []]];
    if (!BATTLESPACE_ARTILLERY_TRP_ENABLED || {BATTLESPACE_DISABLE_ARTILLERY}) exitWith {"Artillery TRPs disabled"};
    if (CBA_missionTime >= (_trp get "expiresAt")) exitWith {"Fire plan expired"};
    private _battery = _trp get "battery";
    if (isNull _battery || {!(_battery in BATTLESPACE_ARTILLERY_SECTIONS)}) exitWith {"Supporting battery lost"};
    private _pieces = [_battery] call BATTLESPACE_TRP_PIECES;
    if (_pieces isEqualTo []) exitWith {"No surviving enemy guns or crew"};
    if ((_trp get "pieceAnchors") findIf {
        (_x # 0) in _pieces && {(_x # 0) distance2D (_x # 1) > BATTLESPACE_ARTILLERY_TRP_RELOCATION_DISTANCE}
    } >= 0) exitWith {"Battery relocated; registration lost"};
    private _sector = _trp get "sector";
    private _sectorState = BATTLESPACE_SECTOR_STATES getOrDefault [_sector, createHashMap];
    private _owner = _sectorState getOrDefault ["owner", ""];
    if (_owner != (["OPFOR", "BLUFOR"] select ((_trp get "kind") == "OFFENSIVE"))) exitWith {"Objective ownership changed"};
    if ((_sectorState getOrDefault ["lastOwnerChange", 0]) != (_trp get "ownershipAt")) exitWith {"Objective changed hands since registration"};
    private _source = _trp get "source";
    private _sourceValid = _source in _sources;
    if (count _this < 2) then {
        // Request/debug validation checks this assignment only, avoiding a full front-plan rebuild.
        if ((_trp get "kind") == "DEFENSIVE") then {
            _sourceValid = ([_sector] call BATTLESPACE_DEFENSE_GET_FRONT_DEPTH) <= 1 && {
                (values BATTLESPACE_STRATEGIC_OPERATIONS) findIf {
                    (_x getOrDefault ["kind", ""]) == "DEFENDER"
                        && {(_x getOrDefault ["assignedSector", ""]) == _sector}
                        && {(_x getOrDefault ["phase", ""]) in ["DEPLOYING", "ON_STATION", "ENGAGED", "DISPLACING"]}
                        && {(_x getOrDefault ["outcome", ""]) == ""}
                } >= 0
            };
        } else {
            private _op = BATTLESPACE_STRATEGIC_OPERATIONS getOrDefault [_source # 2, createHashMap];
            _sourceValid = (_op getOrDefault ["kind", ""]) == "BATTLEGROUP"
                && {(_op getOrDefault ["targetSector", ""]) == _sector}
                && {(_op getOrDefault ["approachSector", ""]) == (_source # 3)}
                && {(_op getOrDefault ["phase", ""]) != "RETURNING"}
                && {(_op getOrDefault ["outcome", ""]) == ""};
        };
    };
    if (!_sourceValid) exitWith {"Defensive assignment or offensive plan ended"};
    if !([_battery, _trp get "position"] call BATTLESPACE_TRP_IN_RANGE) exitWith {"Prepared area outside gun range"};
    ""
};

BATTLESPACE_TRP_SAFE = {
    params ["_battery", "_position", "_aim"];
    private _radius = [_aim, false] call BATTLESPACE_GET_MAX_DISPERSION;
    if ((_battery getVariable ["BSAPieceResource", ""]) == "rocket_artillery") then {_radius = _radius * 1.5};
    _radius = 300 max (_radius + 100);
    (_position nearEntities [["Man", "LandVehicle"], _radius]) findIf {
        alive _x && {side _x == GRLIB_side_enemy}
    } == -1
};

BATTLESPACE_TRP_STATUS = {
    params ["_trp"];
    private _invalid = [_trp] call BATTLESPACE_TRP_INVALID_REASON;
    if (_invalid != "") exitWith {["RETIRED", _invalid]};
    if (CBA_missionTime < (_trp get "readyAt")) exitWith {["PREPARING", "Registering fixed aim point"]};
    private _battery = _trp get "battery";
    private _state = _battery getVariable ["BSAState", []];
    private _status = _state param [0, "NOT READY"];
    if (_status == "IN MISSION" && {(_battery getVariable ["BSATRP", ""]) == (_trp get "id")}) exitWith {["FIRING", "Fixed mission in progress"]};
    if (_status != "READY") exitWith {["REGISTERED", "Battery " + _status]};
    if ((missionNamespace getVariable ["BATTLESPACE_ARTILLERY_NETWORK_ENABLED", true]) isEqualTo false) exitWith {["REGISTERED", "Observer network off"]};
    private _resources = (BATTLESPACE_SECTOR_STATES getOrDefault [_battery getVariable ["BSAFundingSector", ""], createHashMap]) getOrDefault ["resources", createHashMap];
    if ((_resources getOrDefault ["rockets", 0]) <= 0) exitWith {["REGISTERED", "Awaiting paid ammunition"]};
    if !([_battery, _trp get "position", BATTLESPACE_ARTILLERY_TRP_AIM_FLOOR] call BATTLESPACE_TRP_SAFE) exitWith {["REGISTERED", "Friendly troops inside fire area"]};
    ["REGISTERED", "Awaiting fresh observer contact; available next network poll"]
};

BATTLESPACE_TRP_PLAN = {
    if (!isServer || {isRemoteExecuted}) exitWith {};
    if (isNil "BATTLESPACE_STRATEGIC_OPERATIONS" || {isNil "BATTLESPACE_SECTOR_STATES"}
        || {isNil "BATTLESPACE_DEFENSE_GET_FRONT_DEPTH"} || {isNil "blufor_sectors"}) exitWith {};
    if (CBA_missionTime < (localNamespace getVariable ["BSA_TRP_NEXT_PLAN", 0])) exitWith {};
    localNamespace setVariable ["BSA_TRP_NEXT_PLAN", CBA_missionTime + (10 max BATTLESPACE_ARTILLERY_TRP_PLAN_INTERVAL)];
    private _registry = localNamespace getVariable "BSA_TRPS";
    private _sources = call BATTLESPACE_TRP_SOURCES;
    private _history = (localNamespace getVariable "BSA_TRP_RETIRED") select {CBA_missionTime - (_x # 10) < 300};
    {
        private _trp = _registry get _x;
        private _reason = [_trp, _sources] call BATTLESPACE_TRP_INVALID_REASON;
        if (_reason == "") then {continue};
        _history pushBack [_x, _trp get "position", _trp get "radius", "RETIRED", _reason,
            str (_trp get "battery"), _trp get "batteryAnchor", _trp get "kind", _trp get "sector", 0, CBA_missionTime];
        _registry deleteAt _x;
    } forEach keys _registry;
    if (count _history > 12) then {_history deleteRange [0, count _history - 12]};
    localNamespace setVariable ["BSA_TRP_RETIRED", _history];
    private _contacts = localNamespace getVariable "BSA_TRP_CONTACTS";
    {
        private _entry = _contacts get _x;
        if (isNull (_entry # 0) || {CBA_missionTime - (_entry # 2) > 45}) then {_contacts deleteAt _x};
    } forEach keys _contacts;
    if (!BATTLESPACE_ARTILLERY_TRP_ENABLED || {BATTLESPACE_DISABLE_ARTILLERY}) exitWith {};
    _sources = [_sources, [], {str _x}, "ASCEND"] call BIS_fnc_sortBy;
    private _cursor = localNamespace getVariable ["BSA_TRP_SOURCE_CURSOR", 0];
    if (_sources isNotEqualTo []) then {
        _cursor = _cursor mod count _sources;
        _sources = (_sources select [_cursor]) + (_sources select [0, _cursor]);
    };
    private _nominations = 0;
    {
        private _source = _x;
        _source params ["_kind", "_sector", "_operation", "_anchor"];
        if (_nominations >= 2 || {count _registry >= BATTLESPACE_ARTILLERY_TRP_MAX_TOTAL}) exitWith {};
        localNamespace setVariable ["BSA_TRP_SOURCE_CURSOR", _cursor + _forEachIndex + 1];
        if ((values _registry) findIf {(_x get "source") isEqualTo _source} >= 0) then {continue};
        private _center = getMarkerPos _sector;
        if (_center isEqualTo [0,0,0]) then {continue};
        private _toward = getMarkerPos _anchor;
        if (_kind == "DEFENSIVE") then {
            private _front = [blufor_sectors + ["startbase_marker"], [], {_center distance2D getMarkerPos _x}, "ASCEND"] call BIS_fnc_sortBy;
            _toward = getMarkerPos (_front # 0);
        };
        private _distance = (_center distance2D _toward) * 0.4;
        _distance = if (_kind == "DEFENSIVE") then {350 max (_distance min 750)} else {200 max (_distance min 450)};
        private _approach = _center getPos [_distance, _center getDir _toward];
        if (BATTLESPACE_ARTILLERY_SECTIONS findIf {
            [_x, _approach] call BATTLESPACE_TRP_IN_RANGE
        } < 0) then {continue};
        _nominations = _nominations + 1;
        private _candidates = [];
        // At most one small terrain query per nomination; never scan player positions.
        {
            private _position = getPosATL _x;
            _candidates pushBack [count roadsConnectedTo _x, _position];
        } forEach (_approach nearRoads 180);
        _candidates sort false;
        _candidates resize (count _candidates min 4);
        private _positions = _candidates apply {_x # 1};
        {_positions pushBack (_x # 0)} forEach (selectBestPlaces [_approach, 220, "meadow - forest - houses - sea", 70, 4]);
        _positions pushBack _approach;
        private _placed = false;
        {
            private _position = +_x;
            _position set [2, 0];
            if (surfaceIsWater _position || {(surfaceNormal _position) # 2 < 0.92}
                || {_position # 0 < 0} || {_position # 1 < 0} || {_position # 0 > worldSize} || {_position # 1 > worldSize}
                || {_position distance2D getMarkerPos "startbase_marker" < 600}) then {continue};
            if ((values _registry) findIf {(_x get "position") distance2D _position < 350} >= 0) then {continue};
            {
                private _battery = _x;
                if ({(_x get "battery") isEqualTo _battery} count values _registry >= BATTLESPACE_ARTILLERY_TRP_MAX_PER_BATTERY) then {continue};
                if !([_battery, _position] call BATTLESPACE_TRP_IN_RANGE) then {continue};
                private _sequence = 1 + (localNamespace getVariable "BSA_TRP_SEQUENCE");
                localNamespace setVariable ["BSA_TRP_SEQUENCE", _sequence];
                private _id = format ["TRP-%1", _sequence];
                _registry set [_id, createHashMapFromArray [
                    ["id", _id], ["kind", _kind], ["sector", _sector], ["source", +_source],
                    ["ownershipAt", (BATTLESPACE_SECTOR_STATES get _sector) getOrDefault ["lastOwnerChange", 0]],
                    ["battery", _battery], ["batteryAnchor", getPosATL (([_battery] call BATTLESPACE_TRP_PIECES) # 0)],
                    ["pieceAnchors", ([_battery] call BATTLESPACE_TRP_PIECES) apply {[_x, getPosATL _x]}],
                    ["position", +_position], ["radius", BATTLESPACE_ARTILLERY_TRP_RADIUS],
                    ["createdAt", CBA_missionTime], ["readyAt", CBA_missionTime + BATTLESPACE_ARTILLERY_TRP_REGISTRATION_TIME],
                    ["expiresAt", CBA_missionTime + BATTLESPACE_ARTILLERY_TRP_LIFETIME], ["lastFiredAt", -1]
                ]];
                _placed = true;
                if (_placed) exitWith {};
            } forEach BATTLESPACE_ARTILLERY_SECTIONS;
            if (_placed) exitWith {};
        } forEach _positions;
    } forEach _sources;
};

BATTLESPACE_TRP_PREPARE_REQUEST = {
    params ["_battery", "_request"];
    private _copy = +_request;
    _copy resize 6;
    if (!isServer || {isRemoteExecuted} || {!BATTLESPACE_ARTILLERY_TRP_ENABLED}) exitWith {_copy};
    _copy params ["_observer", "_position", "_accuracy", "_system", "_at", "_smoke"];
    if (_system || {_smoke} || {_accuracy <= 0} || {!(_position isEqualType [])}
        || {!(_observer isEqualType objNull)} || {isNull _observer} || {!alive _observer}
        || {side _observer != GRLIB_side_enemy} || {_observer getVariable ["ACE_isUnconscious", false]}
        || {_at > CBA_missionTime} || {CBA_missionTime - _at > 45}) exitWith {_copy};
    private _knownPositions = [];
    if (local _observer) then {
        _knownPositions = ((_observer targets [true, 0, [GRLIB_side_friendly], 45]) select {
            alive _x && {!(_x isKindOf "Air")} && {!(_x getVariable ["ACE_isUnconscious", false])}
        }) apply {getPosATL _x};
    } else {
        private _evidence = (localNamespace getVariable "BSA_TRP_CONTACTS") getOrDefault [str _observer, []];
        if (count _evidence == 4 && {(_evidence # 0) isEqualTo _observer}
            && {(_evidence # 3) == owner _observer} && {CBA_missionTime - (_evidence # 2) <= 45}) then {_knownPositions = _evidence # 1};
    };
    if (_knownPositions findIf {_x distance2D _position < 75} < 0) exitWith {_copy};
    private _matches = (values (localNamespace getVariable "BSA_TRPS")) select {
        (_x get "battery") isEqualTo _battery && {CBA_missionTime >= (_x get "readyAt")}
            && {_position distance2D (_x get "position") <= (_x get "radius")}
            && {([_x] call BATTLESPACE_TRP_INVALID_REASON) == ""}
    };
    _matches = [_matches, [], {_position distance2D (_x get "position")}, "ASCEND"] call BIS_fnc_sortBy;
    if (_matches isEqualTo []) exitWith {_copy};
    private _trp = _matches # 0;
    private _aim = _accuracy max BATTLESPACE_ARTILLERY_TRP_AIM_FLOOR;
    if !([_battery, _trp get "position", _aim] call BATTLESPACE_TRP_SAFE) exitWith {_copy};
    _copy set [1, +(_trp get "position")];
    // Field 2 remains request strength: never let registration purchase extra salvos.
    _copy set [9, [_trp get "id", _aim]];
    _copy
};

BATTLESPACE_TRP_MISSION_VALID = {
    params ["_battery", "_request"];
    private _metadata = _request param [9, []];
    if (_metadata isEqualTo []) exitWith {true};
    private _trp = (localNamespace getVariable "BSA_TRPS") getOrDefault [_metadata # 0, createHashMap];
    count _trp > 0 && {(_trp get "battery") isEqualTo _battery}
        && {(_trp get "position") isEqualTo (_request # 1)}
        && {((_battery getVariable ["BSAState", []]) param [0, ""]) != "SUPPRESSED"}
        && {([_trp] call BATTLESPACE_TRP_INVALID_REASON) == ""}
        && {[_battery, _request # 1, _metadata # 1] call BATTLESPACE_TRP_SAFE}
};

BATTLESPACE_TRP_SNAPSHOT = {
    if (!isServer) exitWith {[]};
    private _rows = [];
    {
        private _trp = _y;
        ([_trp] call BATTLESPACE_TRP_STATUS) params ["_status", "_reason"];
        _rows pushBack [_x, +(_trp get "position"), _trp get "radius", _status, _reason,
            str (_trp get "battery"), +(_trp get "batteryAnchor"), _trp get "kind", _trp get "sector",
            _trp get "readyAt", _trp get "expiresAt", _trp get "lastFiredAt"];
    } forEach (localNamespace getVariable ["BSA_TRPS", createHashMap]);
    _rows append (localNamespace getVariable ["BSA_TRP_RETIRED", []]);
    _rows
};
