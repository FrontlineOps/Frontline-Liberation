/*
    Funded, persistent Battlespace responses to occupied BLUFOR armor and air.
*/

if (isNil "BATTLESPACE_AIR_RESPONSE_NEXT_CLASS_WARNING") then {
    BATTLESPACE_AIR_RESPONSE_NEXT_CLASS_WARNING = 0;
};

BATTLESPACE_AIR_RESPONSE_APPLY_TARGET_COOLDOWN = {
    params ["_taskForceId", "_operation", "_eventType"];
    private _targetNetId = _operation getOrDefault ["targetNetId", ""];
    if (_targetNetId == "") exitWith {false};

    private _target = objectFromNetId _targetNetId;
    if (isNull _target || {!alive _target}) exitWith {false};

    private _duration = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_AIR_RESPONSE_TARGET_COOLDOWN", 600];
    private _cooldownUntil = (_target getVariable ["BATTLESPACE_AIR_RESPONSE_TARGET_COOLDOWN_UNTIL", 0]) max (CBA_missionTime + _duration);
    private _outcome = _operation getOrDefault ["outcome", ""];
    if (_outcome == "") then {_outcome = _eventType};
    _target setVariable ["BATTLESPACE_AIR_RESPONSE_TARGET_COOLDOWN_UNTIL", _cooldownUntil];
    [format [
        "Air response %1 ended as %2; target %3 (%4) cannot trigger a new response for %5 seconds",
        _taskForceId,
        _outcome,
        typeOf _target,
        _targetNetId,
        round (_cooldownUntil - CBA_missionTime)
    ]] call BATTLESPACE_STRATEGIC_LOG;
    true
};

BATTLESPACE_AIR_RESPONSE_CLASSIFY_CONTACT = {
    params ["_vehicle"];
    if (isNull _vehicle || {!alive _vehicle}) exitWith {""};
    private _hasFriendlyPlayer = (crew _vehicle) findIf {
        isPlayer _x && {alive _x} && {side group _x == GRLIB_side_friendly}
    } >= 0;
    if (!_hasFriendlyPlayer) exitWith {""};
    if (_vehicle isKindOf "Air") exitWith {"AIR"};
    if (_vehicle isKindOf "Tank") exitWith {"ARMOR"};
    ""
};

BATTLESPACE_AIR_RESPONSE_COLLECT_CONTACTS = {
    private _contacts = [];
    private _seen = [];
    {
        if (!alive _x || {side group _x != GRLIB_side_friendly}) then {continue};
        private _vehicle = vehicle _x;
        if (_vehicle isEqualTo _x || {_vehicle in _seen}) then {continue};
        if (CBA_missionTime < (_vehicle getVariable ["BATTLESPACE_AIR_RESPONSE_TARGET_COOLDOWN_UNTIL", 0])) then {continue};
        private _kind = [_vehicle] call BATTLESPACE_AIR_RESPONSE_CLASSIFY_CONTACT;
        if (_kind == "") then {continue};
        _seen pushBack _vehicle;
        private _position = getPosATL _vehicle;
        _position set [2, 0];
        private _score = ([100, 200] select (_kind == "AIR")) + (10 * count ((crew _vehicle) select {isPlayer _x}));
        _contacts pushBack [_score, _kind, _position, netId _vehicle, typeOf _vehicle];
    } forEach allPlayers;
    [_contacts, [], {_x param [0, 0]}, "DESCEND"] call BIS_fnc_sortBy
};

BATTLESPACE_AIR_RESPONSE_IS_COMBAT_AIRCRAFT = {
    params ["_class"];
    private _cfg = configFile >> "CfgVehicles" >> _class;
    if (
        _class == ""
        || {!isClass _cfg}
        || {getNumber (_cfg >> "scope") < 2}
        || {!(_class isKindOf "Air")}
        || {_class isKindOf "ParachuteBase"}
        || {getNumber (_cfg >> "isUav") > 0}
        || {getText (_cfg >> "crew") == ""}
    ) exitWith {false};

    private _weapons = +(getArray (_cfg >> "weapons"));
    {
        _weapons append getArray (_x >> "weapons");
    } forEach ("isClass _x" configClasses (_cfg >> "Turrets"));
    private _utility = ["fakeweapon", "cmflarelauncher", "smokelauncher", "rockets_smoke", "laserdesignator_mounted"];
    private _hasCombatWeapon = _weapons findIf {
        private _weapon = toLower _x;
        !(_weapon in _utility)
        && {(_weapon find "horn") < 0}
        && {(_weapon find "laserdesignator") != 0}
    } >= 0;
    private _hasPylons = count ("isClass _x" configClasses (_cfg >> "Components" >> "TransportPylonsComponent" >> "Pylons")) > 0;
    _hasCombatWeapon || _hasPylons
};

BATTLESPACE_AIR_RESPONSE_SELECT_CLASS = {
    params ["_targetKind"];
    private _catalogs = missionNamespace getVariable ["KPLIB_autoFactionCatalogs", createHashMap];
    private _opfor = _catalogs getOrDefault ["opfor", createHashMap];
    private _resourcePool = BATTLESPACE_RESOURCE_CLASS_POOLS getOrDefault ["aircraft", []];
    private _primary = if (_targetKind == "AIR") then {
        +(_opfor getOrDefault ["fixedWing", []])
    } else {
        +(_opfor getOrDefault ["rotaryCas", []])
    };
    private _secondary = if (_targetKind == "AIR") then {
        +(_opfor getOrDefault ["rotaryCas", []])
    } else {
        +(_opfor getOrDefault ["fixedWing", []])
    };
    private _valid = [];
    {
        if (_x in _resourcePool && {[_x] call BATTLESPACE_AIR_RESPONSE_IS_COMBAT_AIRCRAFT}) then {
            _valid pushBackUnique _x;
        };
    } forEach _primary;
    if (_valid isEqualTo []) then {
        {
            if (_x in _resourcePool && {[_x] call BATTLESPACE_AIR_RESPONSE_IS_COMBAT_AIRCRAFT}) then {
                _valid pushBackUnique _x;
            };
        } forEach _secondary;
    };
    if (_valid isEqualTo []) then {
        {
            if ([_x] call BATTLESPACE_AIR_RESPONSE_IS_COMBAT_AIRCRAFT) then {_valid pushBackUnique _x};
        } forEach _resourcePool;
    };
    if (_valid isEqualTo []) then {""} else {selectRandom _valid}
};

BATTLESPACE_AIR_RESPONSE_FIND_SOURCE = {
    params ["_targetPosition"];
    private _bestSector = "";
    private _bestDistance = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_AIR_RESPONSE_MAX_RANGE", 18000];
    {
        private _state = _y;
        if ((_state getOrDefault ["owner", ""]) != "OPFOR") then {continue};
        if (CBA_missionTime < (_state getOrDefault ["nextAirResponseAt", 0])) then {continue};
        if (((_state getOrDefault ["resources", createHashMap]) getOrDefault ["aircraft", 0]) < 1) then {continue};
        private _distance = _targetPosition distance2D (getMarkerPos _x);
        if (_distance <= _bestDistance) then {
            _bestDistance = _distance;
            _bestSector = _x;
        };
    } forEach BATTLESPACE_SECTOR_STATES;
    _bestSector
};

BATTLESPACE_AIR_RESPONSE_CONTACT_IS_COVERED = {
    params ["_position", "_netId", ["_excludeTaskForceId", ""]];
    private _separation = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_AIR_RESPONSE_MIN_SEPARATION", 3000];
    private _covered = false;
    {
        if (_x == _excludeTaskForceId) then {continue};
        if (
            (_y getOrDefault ["kind", ""]) == "AIR_RESPONSE"
            && {(_y getOrDefault ["phase", ""]) != "RETURNING"}
            && {
                (_netId != "" && {(_y getOrDefault ["targetNetId", ""]) == _netId})
                || {(_y getOrDefault ["contactPosition", [1e9, 1e9, 0]]) distance2D _position <= _separation}
            }
        ) exitWith {_covered = true};
    } forEach BATTLESPACE_STRATEGIC_OPERATIONS;
    _covered
};

BATTLESPACE_AIR_RESPONSE_SET_DESTINATION = {
    params ["_taskForceId", "_taskForce", "_operation", "_phase", "_destination"];
    if !(
        _destination isEqualType []
        && {(count _destination) in [2, 3]}
        && {_destination findIf {!(_x isEqualType 0)} < 0}
    ) exitWith {false};
    private _normalized = +_destination;
    if (count _normalized == 2) then {_normalized pushBack 0};
    _normalized set [2, 0];
    _operation set ["phase", _phase];
    _taskForce set [2, _normalized];
    BATTLESPACE_TASK_FORCE_PATHS deleteAt _taskForceId;
    BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceId, _operation];
    BATTLESPACE_TASK_FORCES set [_taskForceId, _taskForce];
    [_taskForceId, _taskForce param [1, []], _normalized] call QUEUE_PATHFIND_REQUEST;
    true
};

BATTLESPACE_AIR_RESPONSE_BEGIN_RETURN = {
    params ["_taskForceId", "_taskForce", "_operation"];
    private _originSector = _operation getOrDefault ["originSector", ""];
    private _originState = BATTLESPACE_SECTOR_STATES get _originSector;
    if (isNil "_originState" || {(_originState getOrDefault ["owner", ""]) != "OPFOR"}) then {
        _originSector = [(_taskForce param [1, [0, 0, 0]])] call BATTLESPACE_STRATEGIC_FIND_NEAREST_OPFOR_SECTOR;
        _operation set ["originSector", _originSector];
    };
    if (_originSector == "") exitWith {
        _operation set ["outcome", "LOST"];
        BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceId, _operation];
        false
    };
    private _started = [_taskForceId, _taskForce, _operation, "RETURNING", getMarkerPos _originSector] call BATTLESPACE_AIR_RESPONSE_SET_DESTINATION;
    if (_started) then {
        [format ["Air response %1 returning to %2", _taskForceId, _originSector]] call BATTLESPACE_STRATEGIC_LOG;
    };
    _started
};

BATTLESPACE_AIR_RESPONSE_FIND_CONTACT = {
    params ["_taskForceId", "_operation"];
    private _targetKind = _operation getOrDefault ["targetKind", ""];
    private _targetNetId = _operation getOrDefault ["targetNetId", ""];
    private _vehicle = if (_targetNetId == "") then {objNull} else {objectFromNetId _targetNetId};
    if (!isNull _vehicle && {([_vehicle] call BATTLESPACE_AIR_RESPONSE_CLASSIFY_CONTACT) == _targetKind}) exitWith {
        private _position = getPosATL _vehicle;
        _position set [2, 0];
        [_vehicle, _position, netId _vehicle]
    };

    private _anchor = _operation getOrDefault ["contactPosition", [0, 0, 0]];
    private _range = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_AIR_RESPONSE_REACQUIRE_RANGE", 4000];
    private _best = [];
    private _bestDistance = _range;
    {
        if ((_x param [1, ""]) != _targetKind) then {continue};
        private _distance = (_x param [2, []]) distance2D _anchor;
        if ([_x param [2, []], _x param [3, ""], _taskForceId] call BATTLESPACE_AIR_RESPONSE_CONTACT_IS_COVERED) then {continue};
        if (_distance <= _bestDistance) then {
            _bestDistance = _distance;
            _best = [objectFromNetId (_x param [3, ""]), _x param [2, []], _x param [3, ""]];
        };
    } forEach ([] call BATTLESPACE_AIR_RESPONSE_COLLECT_CONTACTS);
    _best
};

BATTLESPACE_AIR_RESPONSE_GET_ORBIT_POINT = {
    params ["_taskForceId", "_contactPosition"];
    private _radius = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_AIR_RESPONSE_ORBIT_RADIUS", 1200];
    private _direction = ((parseNumber _taskForceId) * 53 + floor (CBA_missionTime / 10) * 37) mod 360;
    private _position = _contactPosition getPos [_radius, _direction];
    _position set [2, 0];
    _position
};

BATTLESPACE_AIR_RESPONSE_ON_DECISION_TICK = {
    params ["_taskForceId", "_taskForce"];
    private _operation = BATTLESPACE_STRATEGIC_OPERATIONS get _taskForceId;
    if (isNil "_operation") exitWith {true};
    private _phase = _operation getOrDefault ["phase", "INTERCEPT"];
    private _currentLocation = _taskForce param [1, []];

    if (_phase == "RETURNING") exitWith {
        private _originSector = _operation getOrDefault ["originSector", ""];
        private _originState = BATTLESPACE_SECTOR_STATES get _originSector;
        if (isNil "_originState" || {(_originState getOrDefault ["owner", ""]) != "OPFOR"}) then {
            if !([_taskForceId, _taskForce, _operation] call BATTLESPACE_AIR_RESPONSE_BEGIN_RETURN) exitWith {true};
            _operation = BATTLESPACE_STRATEGIC_OPERATIONS get _taskForceId;
            _originSector = _operation getOrDefault ["originSector", ""];
        };
        if (_originSector != "" && {_currentLocation distance2D (getMarkerPos _originSector) <= 250}) then {
            _operation set ["outcome", "RETURNED"];
            BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceId, _operation];
            true
        } else {
            false
        }
    };

    private _originState = BATTLESPACE_SECTOR_STATES get (_operation getOrDefault ["originSector", ""]);
    private _mustReturn = isNil "_originState"
        || {(_originState getOrDefault ["owner", ""]) != "OPFOR"}
        || {CBA_missionTime >= (_operation getOrDefault ["expiresAt", CBA_missionTime])}
        || {([_taskForce, _operation] call BATTLESPACE_STRATEGIC_GET_SURVIVAL_RATIO) < (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_RETREAT_STRENGTH_RATIO", 0.35])};
    if (_mustReturn) exitWith {
        !([_taskForceId, _taskForce, _operation] call BATTLESPACE_AIR_RESPONSE_BEGIN_RETURN)
    };

    private _contact = [_taskForceId, _operation] call BATTLESPACE_AIR_RESPONSE_FIND_CONTACT;
    if (_contact isEqualTo []) exitWith {
        private _graceUntil = _operation getOrDefault ["contactGraceUntil", -1];
        if (_graceUntil < 0) then {
            _graceUntil = CBA_missionTime + (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_AIR_RESPONSE_CONTACT_GRACE", 120]);
            _operation set ["contactGraceUntil", _graceUntil];
            BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceId, _operation];
        };
        if (CBA_missionTime >= _graceUntil) then {
            !([_taskForceId, _taskForce, _operation] call BATTLESPACE_AIR_RESPONSE_BEGIN_RETURN)
        } else {
            false
        }
    };

    _contact params ["_vehicle", "_contactPosition", "_contactNetId"];
    _operation set ["targetNetId", _contactNetId];
    _operation set ["contactPosition", _contactPosition];
    _operation deleteAt "contactGraceUntil";
    {
        if (!isNull _x && {local _x}) then {
            _x reveal [_vehicle, 4];
            _x setCombatMode "RED";
            _x setBehaviourStrong "COMBAT";
            (units _x) doTarget _vehicle;
        };
    } forEach (_taskForce param [4, []]);

    if (_phase == "INTERCEPT") then {
        private _arrivalRadius = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_AIR_RESPONSE_ARRIVAL_RADIUS", 600];
        if (_currentLocation distance2D _contactPosition <= _arrivalRadius) then {
            _operation set ["loiterUntil", CBA_missionTime + (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_AIR_RESPONSE_ON_STATION_DURATION", 900])];
            private _orbitPoint = [_taskForceId, _contactPosition] call BATTLESPACE_AIR_RESPONSE_GET_ORBIT_POINT;
            [_taskForceId, _taskForce, _operation, "ON_STATION", _orbitPoint] call BATTLESPACE_AIR_RESPONSE_SET_DESTINATION;
        } else {
            private _retargetDistance = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_AIR_RESPONSE_RETARGET_DISTANCE", 500];
            if ((_taskForce param [2, []]) distance2D _contactPosition >= _retargetDistance) then {
                [_taskForceId, _taskForce, _operation, "INTERCEPT", _contactPosition] call BATTLESPACE_AIR_RESPONSE_SET_DESTINATION;
            } else {
                BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceId, _operation];
            };
        };
        false
    } else {
        if (_phase == "ON_STATION") then {
            if (CBA_missionTime >= (_operation getOrDefault ["loiterUntil", CBA_missionTime])) exitWith {
                !([_taskForceId, _taskForce, _operation] call BATTLESPACE_AIR_RESPONSE_BEGIN_RETURN)
            };
            private _orbitRadius = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_AIR_RESPONSE_ORBIT_RADIUS", 1200];
            private _destination = _taskForce param [2, []];
            if (_currentLocation distance2D _destination <= 400 || {_destination distance2D _contactPosition > (2 * _orbitRadius)}) then {
                private _orbitPoint = [_taskForceId, _contactPosition] call BATTLESPACE_AIR_RESPONSE_GET_ORBIT_POINT;
                [_taskForceId, _taskForce, _operation, "ON_STATION", _orbitPoint] call BATTLESPACE_AIR_RESPONSE_SET_DESTINATION;
            } else {
                BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceId, _operation];
            };
            false
        } else {
            _operation set ["outcome", "LOST"];
            BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceId, _operation];
            true
        };
    }
};

BATTLESPACE_AIR_RESPONSE_DISPATCH = {
    params ["_contact"];
    if !([] call BATTLESPACE_STRATEGIC_SERVER_CALL_ALLOWED) exitWith {false};
    _contact params ["_score", "_targetKind", "_targetPosition", "_targetNetId", "_targetClass"];
    private _aircraftClass = [_targetKind] call BATTLESPACE_AIR_RESPONSE_SELECT_CLASS;
    if (_aircraftClass == "") exitWith {
        if (CBA_missionTime >= BATTLESPACE_AIR_RESPONSE_NEXT_CLASS_WARNING) then {
            [format ["No armed generated-faction aircraft can answer %1 contact %2", _targetKind, _targetClass], "WARNING"] call BATTLESPACE_STRATEGIC_LOG;
            BATTLESPACE_AIR_RESPONSE_NEXT_CLASS_WARNING = CBA_missionTime + 300;
        };
        false
    };
    private _originSector = [_targetPosition] call BATTLESPACE_AIR_RESPONSE_FIND_SOURCE;
    if (_originSector == "") exitWith {false};

    private _targetSector = [sectors_allSectors, _targetPosition] call BIS_fnc_nearestPosition;
    private _composition = createHashMapFromArray [
        ["manpower", 0],
        ["vehicles", [_aircraftClass]],
        ["structures", []]
    ];
    private _metadata = createHashMapFromArray [
        ["phase", "INTERCEPT"],
        ["originSector", _originSector],
        ["targetSector", _targetSector],
        ["targetKind", _targetKind],
        ["targetNetId", _targetNetId],
        ["targetClass", _targetClass],
        ["contactPosition", +_targetPosition],
        ["expiresAt", CBA_missionTime + (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_AIR_RESPONSE_MAX_LIFETIME", 1800])],
        ["outcome", ""]
    ];
    private _taskForceId = [
        "Air Response", _composition, getMarkerPos _originSector, _targetPosition, getMarkerPos _originSector,
        _originSector, "AIR_RESPONSE", _metadata
    ] call BATTLESPACE_STRATEGIC_CREATE_FUNDED_TASK_FORCE;
    if (_taskForceId == "") exitWith {false};

    private _state = BATTLESPACE_SECTOR_STATES get _originSector;
    _state set ["nextAirResponseAt", CBA_missionTime + (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_AIR_RESPONSE_COOLDOWN", 1800])];
    BATTLESPACE_SECTOR_STATES set [_originSector, _state];
    [] call BATTLESPACE_LOGISTICS_SAVE;
    [format ["Dispatched air response %1 (%2) from %3 against %4 %5", _taskForceId, _aircraftClass, _originSector, _targetKind, _targetClass]] call BATTLESPACE_STRATEGIC_LOG;
    true
};

BATTLESPACE_AIR_RESPONSE_DECISION_TICK = {
    if !([] call BATTLESPACE_STRATEGIC_SERVER_CALL_ALLOWED) exitWith {};
    if (GRLIB_endgame != 0) exitWith {};
    if ((missionNamespace getVariable ["GRLIB_csat_aggressivity", 0]) < (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_AIR_RESPONSE_MIN_AGGRESSIVITY", 0.9])) exitWith {};
    if ((missionNamespace getVariable ["combat_readiness", 0]) < (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_AIR_RESPONSE_MIN_READINESS", 70])) exitWith {};

    private _activeLimit = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_ACTIVE_AIR_RESPONSES", 2];
    private _remaining = (_activeLimit - (["AIR_RESPONSE"] call BATTLESPACE_STRATEGIC_COUNT_OPERATIONS)) min
        (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_AIR_RESPONSES_PER_TICK", 1]);
    if (_remaining <= 0) exitWith {};
    private _weightThreshold = missionNamespace getVariable ["BATTLESPACE_STRATEGIC_AIR_RESPONSE_MIN_WEIGHT", 50];
    private _armorAllowed = (missionNamespace getVariable ["armor_weight", 0]) >= _weightThreshold;
    private _airAllowed = (missionNamespace getVariable ["air_weight", 0]) >= _weightThreshold;
    if (!_armorAllowed && {!_airAllowed}) exitWith {};

    {
        if (_remaining <= 0) exitWith {};
        private _kind = _x param [1, ""];
        private _position = _x param [2, []];
        private _targetNetId = _x param [3, ""];
        if ((_kind == "ARMOR" && {!_armorAllowed}) || {(_kind == "AIR" && {!_airAllowed})}) then {continue};
        if ([_position, _targetNetId] call BATTLESPACE_AIR_RESPONSE_CONTACT_IS_COVERED) then {continue};
        if ([_x] call BATTLESPACE_AIR_RESPONSE_DISPATCH) then {_remaining = _remaining - 1};
    } forEach ([] call BATTLESPACE_AIR_RESPONSE_COLLECT_CONTACTS);
};
