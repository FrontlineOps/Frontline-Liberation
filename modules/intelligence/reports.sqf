/* Server-only report construction. Raw records never leave the server.
   The snapshot retains the original 12 report fields and appends display metadata.
   Positions and routes are observations, never client-supplied tracking requests. */

KPLIB_INTEL_SERVER_LABEL = {
    params ["_sector"];
    private _label = markerText _sector;
    if (_label == "") then {_sector} else {_label}
};

KPLIB_INTEL_SERVER_STRENGTH = {
    params ["_men", "_vehicles"];
    private _weight = _men + _vehicles * KPLIB_intelligence_vehicle_strength_weight;
    private _bands = KPLIB_intelligence_strength_bands;
    if (_weight >= (_bands # 1)) exitWith {"HEAVY"};
    if (_weight >= (_bands # 0)) exitWith {"MODERATE"};
    if (_weight > 0) then {"LIGHT"} else {"No force confirmed"}
};

KPLIB_INTEL_SERVER_COLLECT_RAW_REPORTS = {
    private _reports = [];
    {
        private _id = if (_x isEqualType "") then {_x} else {str _x};
        private _operation = _y;
        private _kind = toUpper (_operation getOrDefault ["kind", ""]);
        if !(_kind in KPLIB_intelligence_operation_kinds) then {continue};
        if ((_operation getOrDefault ["outcome", ""]) != "") then {continue};
        private _force = BATTLESPACE_TASK_FORCES get _x;
        if (isNil "_force") then {continue};
        private _position = +(_force param [1, []]);
        if (count _position < 2) then {continue};
        private _groups = (_force param [4, []]) select {!isNull _x};
        private _objects = _force param [8, []];
        private _composition = _force param [3, createHashMap];
        private _men = _composition getOrDefault ["manpower", 0];
        private _classes = +(_composition getOrDefault ["vehicles", []]);
        private _physical = _groups isNotEqualTo [] || {_objects isNotEqualTo []};
        if (_physical) then {
            private _people = [];
            {
                {_people pushBackUnique _x} forEach (units _x select {alive _x && {!captive _x}});
            } forEach _groups;
            _men = count _people;
            if (_people isNotEqualTo []) then {_position = getPosATL (_people # 0)};
            _classes = (_objects select {
                alive _x && {!(_x isKindOf "Man")}
                    && {!(_x getVariable ["BATTLESPACE_CONVOY_CARGO_CRATE", false])}
                    && {!(_x getVariable ["KPLIB_captured", false])}
                    && {_x isKindOf "AllVehicles"}
            }) apply {typeOf _x};
        };
        private _phase = toUpper (_operation getOrDefault ["phase", "ACTIVE"]);
        private _leg = +(_force param [2, []]);
        private _objective = _operation getOrDefault ["targetSector", ""];
        if (_phase == "RETURNING") then {
            _objective = _operation getOrDefault ["returnSector", _operation getOrDefault ["sourceSector", _operation getOrDefault ["originSector", ""]]];
        };
        private _route = [];
        if (count _leg >= 2) then {
            _route = [BATTLESPACE_TASK_FORCE_PATHS getOrDefault [_x, []], _force] call KPLIB_INTEL_SERVER_TRIM_ROUTE;
        };
        if (_route isNotEqualTo []) then {
            // A replacement order can precede its pathfinder result. Never attach the old route to it.
            if ((_route # (count _route - 1)) distance2D _leg > 350) then {
                _route = [];
            } else {
                if (_physical) then {
                    // The virtual path index stops advancing while physical groups drive their waypoints.
                    private _nearestIndex = 0;
                    private _nearestDistance = 1e10;
                    {
                        private _distance = _position distance2D _x;
                        if (_distance < _nearestDistance) then {
                            _nearestIndex = _forEachIndex;
                            _nearestDistance = _distance;
                        };
                    } forEach _route;
                    _route = _route select [(_nearestIndex - 1) max 0];
                };
            };
        };
        // Keep consecutive route points. Sampling across bends invents off-road shortcuts.
        private _routeLimit = (KPLIB_intelligence_route_point_limit max 2) min 64;
        private _routePartial = count _route > _routeLimit;
        _route = _route select [0, _routeLimit];
        private _priority = switch (_kind) do {
            case "BATTLEGROUP": {90};
            case "CONVOY": {85};
            case "RESERVE": {75};
            case "AIR_RESPONSE": {90};
            case "FORTIFICATION": {55};
            default {35};
        };
        if (_phase in ["PRESSING", "ASSAULTING", "ENGAGED", "SECURING"]) then {_priority = _priority + 10};
        if (_phase == "RETURNING") then {_priority = _priority - 20};
        private _cargo = createHashMap;
        if (_kind == "CONVOY") then {
            private _crates = _operation getOrDefault ["cargoCrateCount", 0];
            private _lost = _operation getOrDefault ["cargoCratesLost", 0];
            private _ratio = if (_crates > 0) then {0 max (1 - _lost / _crates)} else {
                [_force, _operation] call BATTLESPACE_STRATEGIC_GET_SURVIVAL_RATIO
            };
            {
                private _amount = floor (_y * _ratio);
                if (_amount > 0) then {_cargo set [_x, _amount]};
            } forEach (_operation getOrDefault ["cargo", createHashMap]);
        };
        _reports pushBack createHashMapFromArray [
            ["id", _id], ["kind", _kind], ["phase", _phase], ["position", _position],
            ["sector", [_position] call KPLIB_INTEL_SERVER_NEAREST_SECTOR],
            ["assigned", _operation getOrDefault ["assignedSector", ""]],
            ["funding", _operation getOrDefault ["fundingSector", ""]],
            ["objective", _objective], ["leg", _leg], ["route", _route], ["partial", _routePartial],
            ["men", _men], ["classes", _classes], ["physical", _physical], ["priority", _priority],
            ["role", _operation getOrDefault ["defenseRole", ""]],
            ["purpose", _operation getOrDefault ["convoyPurpose", "RESUPPLY"]], ["cargo", _cargo]
        ];
    } forEach BATTLESPACE_STRATEGIC_OPERATIONS;

    {
        private _group = _x;
        if (isNull _group) then {continue};
        private _vehicles = [];
        {
            private _vehicle = vehicle _x;
            if (alive _x && {_vehicle != _x} && {alive _vehicle} && {!(_vehicle getVariable ["KPLIB_captured", false])}) then {
                _vehicles pushBackUnique _vehicle;
            };
        } forEach units _group;
        if (_vehicles isEqualTo []) then {continue};
        private _position = getPosATL (_vehicles # 0);
        private _state = _group getVariable ["BSAState", "READY"];
        private _phase = if (_state isEqualType []) then {_state param [0, "READY"]} else {_state};
        _reports pushBack createHashMapFromArray [
            ["id", format ["ARTILLERY_%1", _group]], ["kind", "ARTILLERY"], ["phase", toUpper _phase],
            ["position", _position], ["sector", [_position] call KPLIB_INTEL_SERVER_NEAREST_SECTOR],
            ["funding", _group getVariable ["BSAFundingSector", ""]],
            ["men", {alive _x} count units _group], ["classes", _vehicles apply {typeOf _x}],
            ["physical", true], ["priority", 95],
            ["ammunition", (((missionNamespace getVariable ["BATTLESPACE_SECTOR_STATES", createHashMap]) getOrDefault [_group getVariable ["BSAFundingSector", ""], createHashMap]) getOrDefault ["resources", createHashMap]) getOrDefault ["rockets", -1]]
        ];
    } forEach (missionNamespace getVariable ["BATTLESPACE_ARTILLERY_SECTIONS", []]);
    {
        private _vehicles = (_x getOrDefault ["Units", []]) select {alive _x && {!(_x getVariable ["KPLIB_captured", false])}};
        if (_vehicles isEqualTo []) then {continue};
        private _position = getPosATL (_vehicles # 0);
        private _men = 0;
        {_men = _men + ({alive _x} count crew _x)} forEach _vehicles;
        _reports pushBack createHashMapFromArray [
            ["id", format ["SAM_%1", _x getOrDefault ["Id", _forEachIndex]]], ["kind", "SAM"],
            ["phase", "ACTIVE"], ["position", _position],
            ["sector", [_position] call KPLIB_INTEL_SERVER_NEAREST_SECTOR],
            ["funding", _x getOrDefault ["Sector", ""]], ["men", _men],
            ["classes", _vehicles apply {typeOf _x}], ["physical", true], ["priority", 95]
        ];
    } forEach (missionNamespace getVariable ["BATTLESPACE_SAM_EXISTING_SITES", []]);
    _reports
};

KPLIB_INTEL_SERVER_ASSESS_REGION = {
    params ["_region", "_sectors", "_raw"];
    private _details = [];
    private _total = 0;
    private _vehicles = [];
    {
        private _sector = _x;
        if (_sector in blufor_sectors || {_sector == "startbase_marker"}) then {continue};
        private _defenders = _raw select {
            (_x get "kind") == "DEFENDER" && {(_x getOrDefault ["assigned", ""]) == _sector}
                && {(_x get "phase") != "RETURNING"}
        };
        private _stationed = 0;
        private _incoming = 0;
        private _roles = [];
        private _countVehicles = 0;
        {
            if ((_x get "phase") == "DEPLOYING") then {
                _incoming = _incoming + (_x get "men");
            } else {
                _stationed = _stationed + (_x get "men");
            };
            _roles pushBackUnique (_x get "role");
            _countVehicles = _countVehicles + count (_x get "classes");
            _vehicles append (_x get "classes");
        } forEach _defenders;
        _total = _total + _stationed;
        private _range = if (_stationed > 0) then {format ["roughly %1-%2 infantry", (floor (_stationed / 8) * 8) max 1, (floor (_stationed / 8) + 1) * 8]} else {"no stationed defenders confirmed"};
        _details pushBack format ["%1: %2; %3. %4%5", [_sector] call KPLIB_INTEL_SERVER_LABEL, _range,
            ["no vehicles reported", "vehicles reported"] select (_countVehicles > 0),
            _roles joinString ", ", ["", "; reinforcements deploying"] select (_incoming > 0)];
    } forEach _sectors;
    createHashMapFromArray [
        ["id", "ASSESS_" + _region], ["kind", "SECTOR ASSESSMENT"], ["phase", "ASSESSED"],
        ["position", markerPos _region], ["sector", _region], ["men", _total], ["classes", _vehicles],
        ["details", _details], ["priority", 60]
    ]
};

KPLIB_INTEL_SERVER_BUILD_OBSERVATION = {
    params ["_raw", "_tier", "_regions", ["_allRaw", []]];
    private _id = _raw get "id";
    private _kind = _raw get "kind";
    private _phase = _raw get "phase";
    private _position = _raw get "position";
    private _radius = KPLIB_intelligence_uncertainty_radii param [_tier - 1, 1200];
    private _assessment = _kind == "SECTOR ASSESSMENT";
    // Same identity retains the same error direction. Movement reflects movement, not rerolled noise.
    private _seed = 0;
    {_seed = (_seed * 31 + _x) mod 65521} forEach toArray _id;
    private _angle = _seed mod 360;
    private _offset = _radius * (0.25 + (_seed mod 50) / 100);
    private _observed = if (_assessment) then {+_position} else {
        [(_position # 0) + sin _angle * _offset, (_position # 1) + cos _angle * _offset, 0]
    };
    private _classes = _raw get "classes";
    private _men = _raw get "men";
    private _strength = [_men, count _classes] call KPLIB_INTEL_SERVER_STRENGTH;
    private _displayKind = _kind;
    if (_tier == 1 && {!_assessment}) then {
        _displayKind = switch true do {
            case (_kind find "AIR" >= 0): {"AIR ACTIVITY"};
            case (_kind == "CONVOY"): {"LOGISTICS ACTIVITY"};
            case (_kind in ["ARTILLERY", "SAM", "FORTIFICATION"]): {"FIXED DEFENSE"};
            default {"GROUND ACTIVITY"};
        };
    };
    if (_displayKind == "BATTLEGROUP") then {_displayKind = "GROUND OFFENSIVE"};
    private _details = +(_raw getOrDefault ["details", []]);
    private _objective = _raw getOrDefault ["objective", ""];
    private _leg = if (_tier >= 2) then {+(_raw getOrDefault ["leg", []])} else {[]};
    private _route = if (_tier >= 2) then {+(_raw getOrDefault ["route", []])} else {[]};
    private _destination = "";
    if (count _leg >= 2) then {
        _destination = [_leg] call KPLIB_INTEL_SERVER_NEAREST_SECTOR;
        _details pushBack format ["Current movement: toward grid %1, near %2.", mapGridPosition _leg, [_destination] call KPLIB_INTEL_SERVER_LABEL];
    };
    if (_tier >= 2 && {!_assessment}) then {
        if (_objective != "") then {
            _details pushBack format ["%1: %2.", ["Assessed mission objective", "Returning toward"] select (_phase == "RETURNING"), [_objective] call KPLIB_INTEL_SERVER_LABEL];
        };
        if (_leg isEqualTo []) then {_details pushBack "Holding or operating locally; no onward movement confirmed."};
        if (_route isNotEqualTo []) then {
            _details pushBack (["Assessed movement corridor; roads and cross-country legs follow reported orders, not guaranteed travel.", "Partial movement corridor; later legs are not shown."] select (_raw getOrDefault ["partial", false]));
        } else {
            if (_leg isNotEqualTo []) then {_details pushBack "Movement reported; route not yet confirmed."};
        };
        _details pushBack (switch (_kind) do {
            case "CONVOY": {format ["Purpose: %1.", _raw get "purpose"]};
            case "RESERVE": {["Reserve available locally; could respond to fighting.", "Reserve committed away from its staging area."] select (_phase in ["RESPONDING", "DEPLOYING", "HOLDING", "ENGAGED"])};
            case "BATTLEGROUP": {"Offensive force maneuvering against the front. Its phase describes observed orders, not a guaranteed attack."};
            case "DEFENDER": {format ["Defensive role: %1.", _raw get "role"]};
            default {"Confirm disposition by reconnaissance before committing."};
        });
    };
    private _window = "";
    if (_tier >= 3 && {!_assessment}) then {
        _strength = format ["%1 %2 / %3 vehicles", _men, ["infantry (crew extra)", "personnel incl. crew"] select (_raw getOrDefault ["physical", false]), count _classes];
        private _types = createHashMap;
        {
            private _name = getText (configFile >> "CfgVehicles" >> _x >> "displayName");
            if (_name == "") then {_name = _x};
            _types set [_name, 1 + (_types getOrDefault [_name, 0])];
        } forEach _classes;
        private _names = [];
        {_names pushBack format ["%1 x %2", _y, _x]} forEach _types;
        _names sort true;
        if (_names isNotEqualTo []) then {_details pushBack ("Identified vehicles: " + (_names joinString ", "))};
        _window = "MODERATE confidence: opportunity depends on the reported disposition remaining unchanged; confirm locally.";
        switch (_kind) do {
            case "CONVOY": {
                private _cargo = _raw get "cargo";
                private _cargoText = [];
                {
                    private _label = switch (_x) do {
                        case "rockets": {"artillery rounds"};
                        case "manpower": {"reinforcement personnel"};
                        default {(_x splitString "_") joinString " "};
                    };
                    _cargoText pushBack format ["%1 %2", _y, _label];
                } forEach _cargo;
                _cargoText sort true;
                _details pushBack ("Remaining cargo: " + (["none confirmed", _cargoText joinString ", "] select (_cargoText isNotEqualTo [])));
                private _batteries = _allRaw select {(_x get "kind") == "ARTILLERY" && {(_x getOrDefault ["funding", ""]) == _objective}};
                _details pushBack (["Interception before arrival could deny this delivery to the receiving objective.", "Receiving objective funds an observed artillery battery. Denying ammunition could limit subsequent fire; existing reserves may remain."] select (_batteries isNotEqualTo [] && {(_cargo getOrDefault ["rockets", 0]) > 0}));
                if (_cargoText isEqualTo []) then {_details pushBack "No cargo remains confirmed; there may be little supply value in pursuing this convoy."};
                _window = "MODERATE confidence: intercept before arrival; road congestion, combat and new orders can change timing.";
            };
            case "ARTILLERY": {
                _details pushBack "Counter-battery opportunity: disabling these observed guns removes their fire support; other batteries may remain.";
                if ((_raw getOrDefault ["ammunition", -1]) == 0) then {
                    _details pushBack "Supporting ammunition stock reported empty. New fire missions depend on resupply; already reserved salvos may still fire.";
                };
                if (_phase == "COOLDOWN") then {_window = "MODERATE confidence: battery reported between missions. Cooldown is not a guarantee that the position is undefended."};
            };
            case "SAM": {_details pushBack "Air-defense suppression opportunity: disabling the observed site could open a local flight corridor. Other air defenses are not ruled out."};
            case "RESERVE": {_details pushBack "Fix or intercept this reserve to reduce its ability to reinforce another fight. A commitment elsewhere may leave a temporary opening."};
            case "BATTLEGROUP": {_details pushBack (["Disrupt this force's approach or reinforce its assessed objective before it presses.", "Withdrawing force: pursue only after checking for supporting defenders."] select (_phase == "RETURNING"))};
            default {_details pushBack "Use the reported strength and movement to choose an approach, bypass or interception point."};
        };
    };
    private _title = format ["%1 near %2", _displayKind, [_raw get "sector"] call KPLIB_INTEL_SERVER_LABEL];
    if (_assessment) then {_title = "Sector assessment: " + ([_raw get "sector"] call KPLIB_INTEL_SERVER_LABEL)};
    private _meta = createHashMapFromArray [
        ["title", _title], ["details", _details], ["priority", _raw get "priority"],
        ["status", "CURRENT"], ["regions", +_regions], ["window", _window],
        ["confidence", ["LOW - broad assessment", "MODERATE - reported orders", "HIGH identification; MODERATE intent"] # (_tier - 1)]
    ];
    [_id, _displayKind, ["DETECTED", _phase] select (_tier >= 2 || {_assessment}), _regions param [0, ""],
        _observed, _radius, CBA_missionTime, _destination, _leg, _strength, _route, _tier, _meta]
};
