KPLIB_INTEL_COVERAGE = createHashMap;
KPLIB_INTEL_OBSERVATIONS = createHashMap;
KPLIB_INTEL_LOST_CONTACTS = createHashMap;
KPLIB_INTEL_LEADS = createHashMap;
KPLIB_INTEL_ELIGIBLE_REGIONS = [];
KPLIB_INTEL_REGION_OWNERSHIP_KEY = "";
KPLIB_INTEL_LAST_FINGERPRINT = "";
KPLIB_INTEL_REVISION = 0;
KPLIB_INTEL_INFORMANT_STATE = createHashMap;
KPLIB_INTEL_INFORMANT_NEXT_AT = -1;

KPLIB_INTEL_SERVER_GET_CALLER = {
    if (!isServer || {!isRemoteExecuted}) exitWith {objNull};
    private _ownerId = remoteExecutedOwner;
    (allPlayers select {isPlayer _x && {owner _x == _ownerId}}) param [0, objNull]
};

KPLIB_INTEL_SERVER_IS_NEAR_TERMINAL = {
    params ["_player"];
    if (isNull _player) exitWith {false};

    private _distance = missionNamespace getVariable ["KPLIB_intelligence_terminal_distance", 75];
    private _nearTerminal = (_player distance2D (getMarkerPos "startbase_marker")) <= _distance;
    if (!_nearTerminal) then {
        {
            if ((_player distance2D _x) <= _distance) exitWith {_nearTerminal = true};
        } forEach (missionNamespace getVariable ["GRLIB_all_fobs", []]);
    };
    _nearTerminal
};

KPLIB_INTEL_SERVER_RANDOM_YIELD = {
    params ["_range"];
    private _minimum = 0 max floor (_range param [0, 0]);
    private _maximum = _minimum max floor (_range param [1, _minimum]);
    _minimum + floor random ((_maximum - _minimum) + 1)
};

KPLIB_INTEL_SERVER_GET_REGION_SECTORS = {
    params ["_region"];
    private _maximumHops = 0 max floor (missionNamespace getVariable ["KPLIB_intelligence_region_hops", 1]);
    private _queue = [[_region, 0]];
    private _seen = createHashMap;

    while {_queue isNotEqualTo []} do {
        private _entry = _queue deleteAt 0;
        _entry params ["_sector", "_depth"];
        if (_seen getOrDefault [_sector, false]) then {continue};
        _seen set [_sector, true];
        if (_depth >= _maximumHops) then {continue};

        private _sectorData = NETWORKED_SECTORS get _sector;
        if (isNil "_sectorData") then {continue};
        {
            if !(_seen getOrDefault [_x, false]) then {
                _queue pushBack [_x, _depth + 1];
            };
        } forEach (_sectorData getOrDefault ["Links", []]);
    };

    keys _seen
};

KPLIB_INTEL_SERVER_REBUILD_REGIONS = {
    private _ownership = +(missionNamespace getVariable ["blufor_sectors", []]);
    _ownership sort true;
    private _ownershipKey = str _ownership;
    if (_ownershipKey == KPLIB_INTEL_REGION_OWNERSHIP_KEY && {KPLIB_INTEL_ELIGIBLE_REGIONS isNotEqualTo []}) exitWith {false};

    private _maximumDepth = 0 max floor (missionNamespace getVariable ["KPLIB_intelligence_max_frontline_depth", 2]);
    private _regions = [];
    {
        private _sector = _x;
        if (_sector == "startbase_marker" || {_sector in _ownership}) then {continue};
        private _depth = [_sector, _ownership + ["startbase_marker"]] call NETWORKED_SECTORS_GET_DISTANCE_FROM_FRONTLINE;
        if (_depth < 0 || {_depth > _maximumDepth}) then {continue};
        private _label = markerText _sector;
        if (_label == "") then {_label = _sector};
        _regions pushBack [_sector, _label, _depth];
    } forEach sectors_allSectors;

    KPLIB_INTEL_ELIGIBLE_REGIONS = [_regions, [], {_x # 2}, "ASCEND"] call BIS_fnc_sortBy;
    KPLIB_INTEL_REGION_OWNERSHIP_KEY = _ownershipKey;
    true
};

KPLIB_INTEL_SERVER_IS_REGION_ELIGIBLE = {
    params ["_region"];
    (KPLIB_INTEL_ELIGIBLE_REGIONS findIf {(_x # 0) == _region}) != -1
};

KPLIB_INTEL_SERVER_NEAREST_SECTOR = {
    params ["_position", ["_fallback", ""]];
    if !(_position isEqualType [] && {count _position >= 2}) exitWith {_fallback};
    private _sector = [GRLIB_sector_size * 1.5, _position] call KPLIB_fnc_getNearestSector;
    if (_sector == "") then {_fallback} else {_sector}
};

KPLIB_INTEL_SERVER_TRIM_ROUTE = {
    params ["_route", "_taskForce"];
    if !(_route isEqualType [] && {_route isNotEqualTo []}) exitWith {[]};
    private _state = _taskForce param [5, ["IDLE", 0, 0]];
    private _routeIndex = if (_state isEqualType []) then {0 max floor (_state param [1, 0])} else {0};
    if (_routeIndex >= count _route) exitWith {[]};
    _route select [_routeIndex]
};

// Separate bounded report construction, coverage history and recovered source context.
[] call compileFinal preprocessFileLineNumbers "modules\intelligence\reports.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\intelligence\coverage.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\intelligence\leads.sqf";

localNamespace setVariable ["KPLIB_INTEL_ADD_RESERVE", {
    params ["_amount", "_source"];
    if (!isServer || {_amount <= 0}) exitWith {};
    resources_intel = (missionNamespace getVariable ["resources_intel", 0]) + floor _amount;
    publicVariable "resources_intel";
    private _targets = allPlayers select {isPlayer _x && {side group _x == GRLIB_side_friendly}};
    if (_targets isNotEqualTo []) then {
        ["EARNED", floor _amount, _source] remoteExecCall ["KPLIB_INTEL_CLIENT_NOTIFY", _targets];
    };
    [{[true] call KPLIB_INTEL_SERVER_RECONCILE}] call CBA_fnc_execNextFrame;
}];

KPLIB_INTEL_SERVER_REJECT = {
    params ["_player", "_message"];
    if (!isNull _player) then {
        ["REJECTED", 0, _message] remoteExecCall ["KPLIB_INTEL_CLIENT_NOTIFY", _player];
    };
};

KPLIB_INTEL_SERVER_COMMIT_PRISONER = {
    params [
        ["_unit", objNull, [objNull]],
        ["_caller", objNull, [objNull]],
        ["_source", "unknown", [""]]
    ];

    if (!isServer) exitWith {false};
    private _unitId = if (isNull _unit) then {"null"} else {netId _unit};
    if (isRemoteExecuted && {remoteExecutedOwner != 2} && {_caller isNotEqualTo (call KPLIB_INTEL_SERVER_GET_CALLER)}) exitWith {false};
    if !(missionNamespace getVariable ["KPLIB_intelligence_enabled", true]) exitWith {
        [format ["Prisoner intelligence delivery rejected (unit=%1, source=%2, reason=disabled)", _unitId, _source], "INTELLIGENCE"] call KPLIB_fnc_log;
        false
    };
    if (isNull _caller || {!alive _caller} || {side group _caller != GRLIB_side_friendly}) exitWith {
        [format ["Prisoner intelligence delivery rejected (unit=%1, source=%2, reason=invalid escort)", _unitId, _source], "INTELLIGENCE"] call KPLIB_fnc_log;
        false
    };
    if (isNull _unit || {!alive _unit} || {!(_unit isKindOf "Man")} || {isPlayer _unit}) exitWith {
        [format ["Prisoner intelligence delivery rejected (unit=%1, source=%2, reason=invalid prisoner)", _unitId, _source], "INTELLIGENCE"] call KPLIB_fnc_log;
        false
    };
    if !(_unit getVariable ["KPLIB_intelligencePrisoner", false]) exitWith {
        [format ["Prisoner intelligence delivery rejected (unit=%1, source=%2, reason=missing prisoner flag)", _unitId, _source], "INTELLIGENCE"] call KPLIB_fnc_log;
        false
    };
    if (_unit getVariable ["KPLIB_intelligenceDelivered", false]) exitWith {true};

    private _deliveryDistance = missionNamespace getVariable ["KPLIB_intelligence_delivery_distance", 40];
    if ((_caller distance _unit) > _deliveryDistance) exitWith {
        [format ["Prisoner intelligence delivery rejected (unit=%1, source=%2, reason=escort beyond %3m)", _unitId, _source, _deliveryDistance], "INTELLIGENCE"] call KPLIB_fnc_log;
        false
    };
    if !([_caller] call KPLIB_INTEL_SERVER_IS_NEAR_TERMINAL) exitWith {
        [format ["Prisoner intelligence delivery rejected (unit=%1, source=%2, reason=escort outside terminal)", _unitId, _source], "INTELLIGENCE"] call KPLIB_fnc_log;
        false
    };

    _unit setVariable ["KPLIB_intelligenceDelivered", true, true];
    [_unit] call (localNamespace getVariable "KPLIB_INTEL_CLAIM_LEAD");
    private _range = if ((typeOf _unit) in militia_squad) then {
        missionNamespace getVariable ["KPLIB_intelligence_prisoner_yield_militia", [3, 6]]
    } else {
        missionNamespace getVariable ["KPLIB_intelligence_prisoner_yield_opfor", [6, 12]]
    };
    private _amount = [_range] call KPLIB_INTEL_SERVER_RANDOM_YIELD;
    stats_prisoners_captured = (missionNamespace getVariable ["stats_prisoners_captured", 0]) + 1;
    [_amount, "prisoner"] call (localNamespace getVariable "KPLIB_INTEL_ADD_RESERVE");
    [format ["Prisoner intelligence delivery committed (unit=%1, source=%2, intel=%3)", _unitId, _source, _amount], "INTELLIGENCE"] call KPLIB_fnc_log;
    [format ["Prisoner intelligence cleanup (unit=%1, class=%2)", _unitId, typeOf _unit], "INTELLIGENCE"] call KPLIB_fnc_log;
    deleteVehicle _unit;
    true
};

KPLIB_INTEL_SERVER_REGISTER_PRISONER_ESCORT = {
    params [["_unit", objNull, [objNull]]];

    private _caller = call KPLIB_INTEL_SERVER_GET_CALLER;
    private _unitId = if (isNull _unit) then {"null"} else {netId _unit};
    if (isNull _caller || {!alive _caller} || {vehicle _caller isNotEqualTo _caller} || {side group _caller != GRLIB_side_friendly}) exitWith {
        [format ["Prisoner intelligence escort registration rejected (unit=%1, reason=invalid player)", _unitId], "INTELLIGENCE"] call KPLIB_fnc_log;
    };
    if (isNull _unit || {!alive _unit} || {!(_unit isKindOf "Man")} || {isPlayer _unit} || {!(_unit getVariable ["KPLIB_intelligencePrisoner", false])}) exitWith {
        [format ["Prisoner intelligence escort registration rejected (unit=%1, reason=invalid prisoner)", _unitId], "INTELLIGENCE"] call KPLIB_fnc_log;
    };
    if (_unit getVariable ["KPLIB_intelligenceDelivered", false]) exitWith {};

    private _interactionDistance = missionNamespace getVariable ["KPLIB_intelligence_interaction_distance", 4];
    if ((_caller distance _unit) > _interactionDistance) exitWith {
        [format ["Prisoner intelligence escort registration rejected (unit=%1, reason=player beyond %2m)", _unitId, _interactionDistance], "INTELLIGENCE"] call KPLIB_fnc_log;
    };

    if ([_caller] call KPLIB_INTEL_SERVER_IS_NEAR_TERMINAL) then {
        _unit setVariable ["KPLIB_intelligenceEscort", _caller];
        [_unit, _caller, "terminal escort action"] call KPLIB_INTEL_SERVER_COMMIT_PRISONER;
    } else {
        if (isNil "KPLIB_SURRENDER_SERVER_BEGIN_ESCORT") exitWith {
            [format ["Prisoner intelligence escort rejected (unit=%1, reason=surrender subsystem unavailable)", _unitId], "INTELLIGENCE"] call KPLIB_fnc_log;
        };
        if !([_unit, _caller] call KPLIB_SURRENDER_SERVER_BEGIN_ESCORT) then {
            [format ["Prisoner intelligence escort rejected (unit=%1, reason=surrender subsystem refused transition)", _unitId], "INTELLIGENCE"] call KPLIB_fnc_log;
        };
    };
};

KPLIB_INTEL_SERVER_ACTIVATE_COVERAGE = {
    if (!isServer || {canSuspend}) exitWith {};
    params [["_region", "", [""]], ["_tier", 0, [0]]];
    if !(missionNamespace getVariable ["KPLIB_intelligence_enabled", true]) exitWith {};
    private _caller = call KPLIB_INTEL_SERVER_GET_CALLER;
    if (isNull _caller || {!alive _caller} || {vehicle _caller isNotEqualTo _caller} || {side group _caller != GRLIB_side_friendly}) exitWith {};
    if !([_caller, "INTELLIGENCE"] call KPLIB_fnc_hasPermission) exitWith {
        [_caller, "Intelligence spending permission is required."] call KPLIB_INTEL_SERVER_REJECT;
    };
    if !([_caller] call KPLIB_INTEL_SERVER_IS_NEAR_TERMINAL) exitWith {[_caller, "Intelligence analysis is only available at the start base or a FOB."] call KPLIB_INTEL_SERVER_REJECT};
    call KPLIB_INTEL_SERVER_REBUILD_REGIONS;
    if !([_region] call KPLIB_INTEL_SERVER_IS_REGION_ELIGIBLE) exitWith {[_caller, "That region is no longer eligible for coverage."] call KPLIB_INTEL_SERVER_REJECT};

    private _costs = missionNamespace getVariable ["KPLIB_intelligence_tier_costs", [10, 25, 45]];
    if (_tier != floor _tier || {_tier < 1} || {_tier > (count _costs min 3)}) exitWith {[_caller, "Invalid intelligence tier."] call KPLIB_INTEL_SERVER_REJECT};
    private _activeCoverage = KPLIB_INTEL_COVERAGE get _region;
    if (!isNil "_activeCoverage" && {(_activeCoverage getOrDefault ["expiresAt", 0]) <= CBA_missionTime}) then {
        KPLIB_INTEL_COVERAGE deleteAt _region;
        _activeCoverage = nil;
    };
    if (!isNil "_activeCoverage" && {_tier < (_activeCoverage getOrDefault ["tier", 1])}) exitWith {[_caller, "Select the active tier or a higher tier; live coverage cannot be downgraded."] call KPLIB_INTEL_SERVER_REJECT};
    if (!isNil "_activeCoverage" && {CBA_missionTime - (_activeCoverage getOrDefault ["purchasedAt", -10]) < 3}) exitWith {
        [_caller, "Coverage was just activated; wait a moment before another purchase."] call KPLIB_INTEL_SERVER_REJECT;
    };
    private _cost = _costs # (_tier - 1);
    if ((missionNamespace getVariable ["resources_intel", 0]) < _cost) exitWith {[_caller, "The shared reserve does not contain enough intelligence."] call KPLIB_INTEL_SERVER_REJECT};

    resources_intel = resources_intel - _cost;
    publicVariable "resources_intel";
    KPLIB_INTEL_COVERAGE set [_region, createHashMapFromArray [
        ["tier", _tier],
        ["purchasedAt", CBA_missionTime],
        ["expiresAt", CBA_missionTime + (missionNamespace getVariable ["KPLIB_intelligence_coverage_duration", 1800])],
        ["sectors", [_region] call KPLIB_INTEL_SERVER_GET_REGION_SECTORS]
    ]];
    private _label = markerText _region;
    if (_label == "") then {_label = _region};
    private _targets = allPlayers select {isPlayer _x && {side group _x == GRLIB_side_friendly}};
    if (_targets isNotEqualTo []) then {
        ["ACTIVATED", _tier, _label] remoteExecCall ["KPLIB_INTEL_CLIENT_NOTIFY", _targets];
    };
    [{[true] call KPLIB_INTEL_SERVER_RECONCILE}] call CBA_fnc_execNextFrame;
};

KPLIB_INTEL_SERVER_COLLECT_DOCUMENT = {
    params [["_object", objNull, [objNull]]];
    if !(missionNamespace getVariable ["KPLIB_intelligence_enabled", true]) exitWith {};
    private _caller = call KPLIB_INTEL_SERVER_GET_CALLER;
    if (isNull _caller || {isNull _object} || {!alive _caller} || {vehicle _caller isNotEqualTo _caller} || {side group _caller != GRLIB_side_friendly}) exitWith {};
    private _distance = missionNamespace getVariable ["KPLIB_intelligence_interaction_distance", 4];
    if ((_caller distance _object) > _distance || {!((typeOf _object) in KPLIB_intelObjectClasses)}) exitWith {};
    if (_object getVariable ["KPLIB_intelligenceCollected", false]) exitWith {};
    _object setVariable ["KPLIB_intelligenceCollected", true, true];
    [_object] call (localNamespace getVariable "KPLIB_INTEL_CLAIM_LEAD");
    deleteVehicle _object;
    [[missionNamespace getVariable ["KPLIB_intelligence_document_yield", [8, 15]]] call KPLIB_INTEL_SERVER_RANDOM_YIELD, "documents"] call (localNamespace getVariable "KPLIB_INTEL_ADD_RESERVE");
};

KPLIB_INTEL_SERVER_INFORMANT_TARGETS = {
    allPlayers select {isPlayer _x && {side group _x == GRLIB_side_friendly}}
};

KPLIB_INTEL_SERVER_NOTIFY_INFORMANT = {
    params ["_event", ["_position", [], [[]]], ["_label", "", [""]]];
    private _targets = call KPLIB_INTEL_SERVER_INFORMANT_TARGETS;
    if (_targets isNotEqualTo []) then {
        [_event, _position, _label] remoteExecCall ["KPLIB_INTEL_CLIENT_INFORMANT_EVENT", _targets];
    };
};

KPLIB_INTEL_SERVER_CLEAR_INFORMANT = {
    params [["_deleteUnit", false, [false]]];
    private _state = KPLIB_INTEL_INFORMANT_STATE;
    if (count _state == 0) exitWith {};

    private _unit = _state getOrDefault ["unit", objNull];
    private _group = _state getOrDefault ["group", grpNull];
    KPLIB_INTEL_INFORMANT_STATE = createHashMap;

    if (_deleteUnit && {!isNull _unit}) then {
        deleteVehicle _unit;
    };
    if (!isNull _group && {units _group isEqualTo []}) then {
        deleteGroup _group;
    };
};

KPLIB_INTEL_SERVER_SCHEDULE_INFORMANT = {
    private _range = missionNamespace getVariable ["KPLIB_intelligence_informant_interval", [5400, 10800]];
    private _minimum = 1 max floor (_range param [0, 5400]);
    private _maximum = _minimum max floor (_range param [1, 10800]);
    KPLIB_INTEL_INFORMANT_NEXT_AT = CBA_missionTime + _minimum + random (_maximum - _minimum);
};

KPLIB_INTEL_SERVER_SET_INFORMANT_WAITING = {
    params [["_unit", objNull, [objNull]]];
    if (isNull _unit || {!alive _unit}) exitWith {};

    _unit setVariable ["KPLIB_intelligenceEscort", objNull];
    _unit setCaptive true;
    _unit setUnitPos "UP";
    doStop _unit;
    if (missionNamespace getVariable ["KP_liberation_ace", false]) then {
        ["ace_captives_setSurrendered", [_unit, true], _unit] call CBA_fnc_targetEvent;
    } else {
        _unit disableAI "ANIM";
        _unit disableAI "MOVE";
        _unit playMoveNow "AmovPercMstpSnonWnonDnon_AmovPercMstpSsurWnonDnon";
    };
};

KPLIB_INTEL_SERVER_COMMIT_INFORMANT = {
    params [
        ["_unit", objNull, [objNull]],
        ["_caller", objNull, [objNull]],
        ["_source", "unknown", [""]]
    ];

    private _state = KPLIB_INTEL_INFORMANT_STATE;
    if (
        !isServer
        || {count _state == 0}
        || {isNull _unit}
        || {!alive _unit}
        || {vehicle _unit isNotEqualTo _unit}
        || {_unit isNotEqualTo (_state getOrDefault ["unit", objNull])}
        || {!(_unit getVariable ["KPLIB_intelligenceInformant", false])}
        || {_unit getVariable ["KPLIB_intelligenceDelivered", false]}
        || {isNull _caller}
        || {!alive _caller}
        || {!isPlayer _caller}
        || {side group _caller != GRLIB_side_friendly}
    ) exitWith {false};

    private _deliveryDistance = missionNamespace getVariable ["KPLIB_intelligence_delivery_distance", 40];
    if ((_unit distance _caller) > _deliveryDistance || {!([_caller] call KPLIB_INTEL_SERVER_IS_NEAR_TERMINAL)}) exitWith {false};

    _unit setVariable ["KPLIB_intelligenceDelivered", true, true];
    private _amount = 1 max floor (missionNamespace getVariable ["KPLIB_intelligence_informant_yield", 15]);
    ["DELIVERED"] call KPLIB_INTEL_SERVER_NOTIFY_INFORMANT;
    [format ["Civilian informant debrief completed (unit=%1, playerOwner=%2, source=%3, intel=%4)", netId _unit, owner _caller, _source, _amount], "INTELLIGENCE"] call KPLIB_fnc_log;
    [true] call KPLIB_INTEL_SERVER_CLEAR_INFORMANT;
    if (!isNil "F_cr_changeCR") then {[2] spawn F_cr_changeCR};
    [_amount, "informant"] call (localNamespace getVariable "KPLIB_INTEL_ADD_RESERVE");
    true
};

KPLIB_INTEL_SERVER_RELEASE_INFORMANT_ESCORT = {
    params [["_unit", objNull, [objNull]], ["_reason", "escort unavailable", [""]]];
    private _state = KPLIB_INTEL_INFORMANT_STATE;
    if (count _state == 0 || {isNull _unit} || {_unit isNotEqualTo (_state getOrDefault ["unit", objNull])} || {!alive _unit}) exitWith {};

    _state set ["escort", objNull];
    _state set ["lastAt", CBA_missionTime];
    [_unit] call KPLIB_INTEL_SERVER_SET_INFORMANT_WAITING;
    [format ["Civilian informant escort released (unit=%1, reason=%2)", netId _unit, _reason], "INTELLIGENCE"] call KPLIB_fnc_log;
};

KPLIB_INTEL_SERVER_MONITOR_INFORMANT_ESCORT = {
    params [["_unit", objNull, [objNull]], ["_caller", objNull, [objNull]]];
    private _state = KPLIB_INTEL_INFORMANT_STATE;
    if (count _state == 0 || {_unit isNotEqualTo (_state getOrDefault ["unit", objNull])}) exitWith {};
    if (isNull _unit || {!alive _unit} || {_unit getVariable ["KPLIB_intelligenceDelivered", false]}) exitWith {};
    if ((_state getOrDefault ["escort", objNull]) isNotEqualTo _caller) exitWith {};

    private _breakDistance = missionNamespace getVariable ["KPLIB_surrender_escort_break_distance", 150];
    if (
        isNull _caller
        || {!alive _caller}
        || {!isPlayer _caller}
        || {side group _caller != GRLIB_side_friendly}
        || {vehicle _caller isNotEqualTo _caller}
        || {_unit distance _caller > _breakDistance}
    ) exitWith {
        [_unit, "player unavailable or beyond escort range"] call KPLIB_INTEL_SERVER_RELEASE_INFORMANT_ESCORT;
    };

    if ([_unit, _caller, "informant escort"] call KPLIB_INTEL_SERVER_COMMIT_INFORMANT) exitWith {};
    if (vehicle _unit isEqualTo _unit && {_unit distance _caller > 3}) then {
        _unit doMove (getPosATL _caller);
    };
    [KPLIB_INTEL_SERVER_MONITOR_INFORMANT_ESCORT, [_unit, _caller], 3] call CBA_fnc_waitAndExecute;
};

KPLIB_INTEL_SERVER_BEGIN_INFORMANT_ESCORT = {
    params [["_unit", objNull, [objNull]]];
    private _caller = call KPLIB_INTEL_SERVER_GET_CALLER;
    private _state = KPLIB_INTEL_INFORMANT_STATE;
    private _interactionDistance = missionNamespace getVariable ["KPLIB_intelligence_interaction_distance", 4];
    if (
        count _state == 0
        || {isNull _caller}
        || {!alive _caller}
        || {vehicle _caller isNotEqualTo _caller}
        || {side group _caller != GRLIB_side_friendly}
        || {isNull _unit}
        || {!local _unit}
        || {!alive _unit}
        || {isPlayer _unit}
        || {_unit isNotEqualTo (_state getOrDefault ["unit", objNull])}
        || {!(_unit getVariable ["KPLIB_intelligenceInformant", false])}
        || {_unit getVariable ["KPLIB_intelligenceDelivered", false]}
        || {_unit distance _caller > _interactionDistance}
    ) exitWith {};

    private _escort = _state getOrDefault ["escort", objNull];
    if (!isNull _escort) exitWith {};
    if ([_unit, _caller, "informant escort action"] call KPLIB_INTEL_SERVER_COMMIT_INFORMANT) exitWith {};

    _state set ["escort", _caller];
    _state set ["lastAt", CBA_missionTime];
    _unit setVariable ["KPLIB_intelligenceEscort", _caller];
    if (missionNamespace getVariable ["KP_liberation_ace", false]) then {
        ["ace_captives_setSurrendered", [_unit, false], _unit] call CBA_fnc_targetEvent;
    } else {
        _unit enableAI "ANIM";
        _unit enableAI "MOVE";
    };
    _unit setCaptive true;
    _unit setUnitPos "AUTO";
    _unit doMove (getPosATL _caller);
    [format ["Civilian informant escort started (unit=%1, playerOwner=%2)", netId _unit, owner _caller], "INTELLIGENCE"] call KPLIB_fnc_log;
    [KPLIB_INTEL_SERVER_MONITOR_INFORMANT_ESCORT, [_unit, _caller], 3] call CBA_fnc_waitAndExecute;
};

KPLIB_INTEL_SERVER_UPDATE_INFORMANT = {
    if (!isServer) exitWith {};
    private _now = CBA_missionTime;
    private _state = KPLIB_INTEL_INFORMANT_STATE;

    if (count _state > 0) exitWith {
        private _unit = _state getOrDefault ["unit", objNull];
        if (isNull _unit) exitWith {
            ["EXPIRED"] call KPLIB_INTEL_SERVER_NOTIFY_INFORMANT;
            ["Civilian informant state cleared because its unit no longer exists", "INTELLIGENCE"] call KPLIB_fnc_log;
            [false] call KPLIB_INTEL_SERVER_CLEAR_INFORMANT;
        };
        if (!alive _unit) exitWith {
            ["KILLED"] call KPLIB_INTEL_SERVER_NOTIFY_INFORMANT;
            [format ["Civilian informant killed before debrief (unit=%1)", netId _unit], "INTELLIGENCE"] call KPLIB_fnc_log;
            [false] call KPLIB_INTEL_SERVER_CLEAR_INFORMANT;
        };
        if (!isNull (_state getOrDefault ["escort", objNull])) exitWith {};

        private _elapsed = 0 max (_now - (_state getOrDefault ["lastAt", _now]));
        _state set ["lastAt", _now];
        private _pauseDistance = missionNamespace getVariable ["KPLIB_intelligence_informant_pause_distance", 150];
        private _playerNearby = (allPlayers findIf {isPlayer _x && {alive _x} && {side group _x == GRLIB_side_friendly} && {_x distance2D _unit <= _pauseDistance}}) != -1;
        if (!_playerNearby) then {
            _state set ["remaining", (_state getOrDefault ["remaining", 0]) - _elapsed];
        };
        if ((_state getOrDefault ["remaining", 0]) <= 0) then {
            ["EXPIRED"] call KPLIB_INTEL_SERVER_NOTIFY_INFORMANT;
            [format ["Civilian informant contact expired (unit=%1, sector=%2)", netId _unit, _state getOrDefault ["sector", ""]], "INTELLIGENCE"] call KPLIB_fnc_log;
            [true] call KPLIB_INTEL_SERVER_CLEAR_INFORMANT;
        };
    };

    if (KPLIB_INTEL_INFORMANT_NEXT_AT < 0) then {call KPLIB_INTEL_SERVER_SCHEDULE_INFORMANT};
    if (_now < KPLIB_INTEL_INFORMANT_NEXT_AT || {(missionNamespace getVariable ["GRLIB_endgame", 0]) != 0}) exitWith {};

    private _eligibleSectors = (missionNamespace getVariable ["blufor_sectors", []]) select {_x in sectors_capture || {_x in sectors_bigtown}};
    private _minimumReputation = missionNamespace getVariable ["KPLIB_intelligence_informant_min_reputation", 0];
    if (_eligibleSectors isEqualTo [] || {(missionNamespace getVariable ["KP_liberation_civ_rep", -100]) < _minimumReputation}) exitWith {};

    call KPLIB_INTEL_SERVER_SCHEDULE_INFORMANT;
    private _chance = 0 max (100 min (missionNamespace getVariable ["KPLIB_intelligence_informant_chance", 75]));
    if (random 100 > _chance) exitWith {};

    private _spawnData = [];
    private _remainingSectors = +_eligibleSectors;
    while {_remainingSectors isNotEqualTo [] && {_spawnData isEqualTo []}} do {
        private _sectorIndex = floor random count _remainingSectors;
        private _sector = _remainingSectors deleteAt _sectorIndex;
        private _positions = [];
        {
            _positions append ((_x buildingPos -1) select {!surfaceIsWater _x});
        } forEach (nearestObjects [getMarkerPos _sector, ["House", "Building"], 200, true]);
        if (_positions isNotEqualTo []) then {
            _spawnData = [_sector, selectRandom _positions];
        };
    };

    if (_spawnData isEqualTo []) exitWith {
        [format ["Civilian informant spawn skipped: no building position in %1 eligible sectors", count _eligibleSectors], "INTELLIGENCE"] call KPLIB_fnc_log;
    };
    private _civilianClasses = missionNamespace getVariable ["civilians", []];
    if (_civilianClasses isEqualTo []) exitWith {
        ["Civilian informant spawn skipped: generated civilian class pool is empty", "INTELLIGENCE"] call KPLIB_fnc_log;
    };

    _spawnData params ["_sector", "_spawnPosition"];
    private _group = createGroup [GRLIB_side_civilian, true];
    if (isNull _group) exitWith {
        [format ["Civilian informant spawn failed in sector %1: civilian group could not be created", _sector], "INTELLIGENCE"] call KPLIB_fnc_log;
    };
    private _unit = [selectRandom _civilianClasses, _spawnPosition, _group] call KPLIB_fnc_createManagedUnit;
    if (isNull _unit) exitWith {
        deleteGroup _group;
        [format ["Civilian informant spawn failed in sector %1", _sector], "INTELLIGENCE"] call KPLIB_fnc_log;
    };

    _unit setPosATL _spawnPosition;
    _unit setDir random 360;
    _unit setVariable ["KPLIB_intelligenceInformant", true, true];
    _unit setVariable ["KPLIB_intelligenceDelivered", false, true];
    [_unit] call KPLIB_INTEL_SERVER_SET_INFORMANT_WAITING;

    private _searchPosition = [
        (_spawnPosition # 0) + 200 - random 400,
        (_spawnPosition # 1) + 200 - random 400,
        0
    ];
    private _label = markerText _sector;
    if (_label == "") then {_label = _sector};
    KPLIB_INTEL_INFORMANT_STATE = createHashMapFromArray [
        ["unit", _unit],
        ["group", _group],
        ["sector", _sector],
        ["label", _label],
        ["searchPosition", _searchPosition],
        ["remaining", missionNamespace getVariable ["KPLIB_intelligence_informant_lifetime", 1200]],
        ["lastAt", _now],
        ["escort", objNull]
    ];
    ["SPAWNED", _searchPosition, _label] call KPLIB_INTEL_SERVER_NOTIFY_INFORMANT;
    [format ["Civilian informant contact spawned (unit=%1, sector=%2)", netId _unit, _sector], "INTELLIGENCE"] call KPLIB_fnc_log;
};

KPLIB_INTEL_SERVER_REQUEST_SYNC = {
    if !(missionNamespace getVariable ["KPLIB_intelligence_enabled", true]) exitWith {};
    private _caller = call KPLIB_INTEL_SERVER_GET_CALLER;
    if (isNull _caller || {side group _caller != GRLIB_side_friendly}) exitWith {};
    private _activeInformant = KPLIB_INTEL_INFORMANT_STATE getOrDefault ["unit", objNull];
    // Coalesce repeated sync requests on this player object; no persistent identity data.
    private _lastSync = _caller getVariable ["KPLIB_intelligenceLastSync", -10];
    if (CBA_missionTime - _lastSync < 2) exitWith {};
    _caller setVariable ["KPLIB_intelligenceLastSync", CBA_missionTime];
    [{
        params ["_caller"];
        [false] call KPLIB_INTEL_SERVER_RECONCILE;
        if (!isNull _caller && {side group _caller == GRLIB_side_friendly}) then {[_caller] call KPLIB_INTEL_SERVER_SEND_PAYLOAD};
    }, [_caller]] call CBA_fnc_execNextFrame;
    private _informant = KPLIB_INTEL_INFORMANT_STATE;
    private _unit = _informant getOrDefault ["unit", objNull];
    if (!isNull _unit && {alive _unit} && {_unit isEqualTo _activeInformant}) then {
        ["SPAWNED", _informant getOrDefault ["searchPosition", getPosATL _unit], _informant getOrDefault ["label", ""]] remoteExecCall ["KPLIB_INTEL_CLIENT_INFORMANT_EVENT", _caller];
    };
};

KPLIB_INTEL_SERVER_INIT = {
    if (missionNamespace getVariable ["KPLIB_INTEL_SERVER_INITIALIZED", false]) exitWith {};
    if (isNil "resources_intel" || {isNil "NETWORKED_SECTORS"} || {count NETWORKED_SECTORS == 0} || {isNil "BATTLESPACE_STRATEGIC_OPERATIONS"}) exitWith {
        [KPLIB_INTEL_SERVER_INIT, [], 2] call CBA_fnc_waitAndExecute;
    };

    KPLIB_INTEL_SERVER_INITIALIZED = true;
    call KPLIB_INTEL_SERVER_SCHEDULE_INFORMANT;
    [{[true] call KPLIB_INTEL_SERVER_RECONCILE}] call CBA_fnc_execNextFrame;
    KPLIB_INTEL_SERVER_PFH = [{[false] call KPLIB_INTEL_SERVER_RECONCILE}, missionNamespace getVariable ["KPLIB_intelligence_reconcile_interval", 15]] call CBA_fnc_addPerFrameHandler;
};
