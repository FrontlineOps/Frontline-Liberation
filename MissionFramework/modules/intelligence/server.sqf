KPLIB_INTEL_LEADS = createHashMap;
KPLIB_INTEL_LAST_FINGERPRINT = "";
KPLIB_INTEL_REVISION = 0;
KPLIB_INTEL_INFORMANT_STATE = createHashMap;
KPLIB_INTEL_INFORMANT_NEXT_AT = -1;

KPLIB_INTEL_SERVER_GET_CALLER = {
    if (!isServer || {!isRemoteExecuted}) exitWith {objNull};
    private _ownerId = remoteExecutedOwner;
    (allPlayers select {isPlayer _x && {owner _x == _ownerId}}) param [0, objNull]
};

KPLIB_INTEL_SERVER_NEAREST_SECTOR = {
    params ["_position", ["_fallback", ""]];
    if !(_position isEqualType [] && {count _position >= 2}) exitWith {_fallback};
    private _sector = [GRLIB_sector_size * 1.5, _position] call KPLIB_fnc_getNearestSector;
    ([_sector, _fallback] select (_sector == ""))
};

KPLIB_INTEL_SERVER_TRIM_ROUTE = {
    params ["_route", "_taskForce"];
    if !(_route isEqualType [] && {_route isNotEqualTo []}) exitWith {[]};
    private _state = _taskForce param [5, ["IDLE", 0, 0]];
    private _routeIndex = if (_state isEqualType []) then {0 max floor (_state param [1, 0])} else {0};
    if (_routeIndex >= count _route) exitWith {[]};
    _route select [_routeIndex]
};

[] call compileFinal preprocessFileLineNumbers "modules\intelligence\reports.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\intelligence\casework.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\intelligence\sourceReports.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\intelligence\leads.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\intelligence\sites.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\intelligence\operations.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\intelligence\custody.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\intelligence\baseRecords.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\intelligence\persistence.sqf";

KPLIB_INTEL_SERVER_REJECT = {
    params ["_player", "_message"];
    if (!isNull _player) then {
        ["REJECTED", 0, _message] remoteExecCall ["KPLIB_INTEL_CLIENT_NOTIFY", _player];
    };
};

KPLIB_INTEL_SERVER_REGISTER_PRISONER_ESCORT = {
    params [["_unit", objNull, [objNull]]];
    private _caller = call KPLIB_INTEL_SERVER_GET_CALLER;
    if (isNull _caller) exitWith {};
    private _owner = remoteExecutedOwner;
    [{
        params ["_caller", "_owner", "_unit"];
        if (isNull _caller || {owner _caller != _owner}) exitWith {};
        if !([_caller, _unit, KPLIB_intelligence_interaction_distance] call KPLIB_INTEL_SERVER_ACTOR_VALID) exitWith {};
        if (isPlayer _unit || {!(_unit getVariable ["KPLIB_intelligencePrisoner", false])} || {_unit getVariable ["KPLIB_intelligenceDelivered", false]}) exitWith {};
        if ([_unit, _caller, "escort action"] call KPLIB_INTEL_SERVER_COMMIT_PRISONER) exitWith {};
        [_unit, _caller] call KPLIB_SURRENDER_SERVER_BEGIN_ESCORT;
    }, [_caller, _owner, _unit]] call CBA_fnc_execNextFrame;
};

KPLIB_INTEL_SERVER_COLLECT_DOCUMENT = {
    params [["_object", objNull, [objNull]]];
    private _caller = call KPLIB_INTEL_SERVER_GET_CALLER;
    if (isNull _caller) exitWith {};
    private _owner = remoteExecutedOwner;
    [{
        params ["_caller", "_owner", "_object"];
        if (isNull _caller || {owner _caller != _owner}) exitWith {};
        [_caller, _object] call KPLIB_INTEL_SERVER_TAKE_DOCUMENT;
    }, [_caller, _owner, _object]] call CBA_fnc_execNextFrame;
};

KPLIB_INTEL_SERVER_TAKE_DOCUMENT = {
    params ["_caller", "_object"];
    if (!(call KPLIB_INTEL_SERVER_MUTATION_ALLOWED) || {!KPLIB_intelligence_enabled}) exitWith {false};
    if !([_caller, _object, KPLIB_intelligence_interaction_distance] call KPLIB_INTEL_SERVER_ACTOR_VALID) exitWith {false};
    if !((typeOf _object) in KPLIB_intelObjectClasses) exitWith {false};
    if !([_caller, _object] call KPLIB_INTEL_SERVER_SOURCE_VISIBLE) exitWith {false};
    if ([_object] call KPLIB_INTEL_SERVER_BASE_COLLECT) exitWith {true};
    private _sources = localNamespace getVariable "KPLIB_INTEL_SOURCES";
    private _source = _sources getOrDefault [netId _object, []];
    if (_source isEqualTo [] || {(_source # 0) isNotEqualTo _object}) exitWith {false};
    private _case = createHashMap;
    {
        if ((_y getOrDefault ["target", objNull]) isEqualTo _object && {(_y get "status") == "ACTIVE"} && {(_y get "stage") == 0}) exitWith {_case = _y};
    } forEach (localNamespace getVariable "KPLIB_INTEL_CASES");
    _sources deleteAt (netId _object);
    [_source, count _case == 0] call KPLIB_INTEL_SERVER_REVEAL_SOURCE;
    _object setVariable ["KPLIB_intelligenceCollected", true, true];
    if (count _case > 0) then {[_case, "Dispatch documents identified the network's HVT. Recover them alive."] call KPLIB_INTEL_SERVER_ADVANCE_CASE};
    deleteVehicle _object;
    call KPLIB_INTEL_SERVER_CHANGED;
    true
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
    if !(call KPLIB_INTEL_SERVER_INTERNAL) exitWith {};
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
    if !(call KPLIB_INTEL_SERVER_INTERNAL) exitWith {};
    private _range = missionNamespace getVariable ["KPLIB_intelligence_informant_interval", [5400, 10800]];
    private _minimum = 1 max floor (_range param [0, 5400]);
    private _maximum = _minimum max floor (_range param [1, 10800]);
    KPLIB_INTEL_INFORMANT_NEXT_AT = CBA_missionTime + _minimum + random (_maximum - _minimum);
};

KPLIB_INTEL_SERVER_SET_INFORMANT_WAITING = {
    if !(call KPLIB_INTEL_SERVER_INTERNAL) exitWith {};
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
    if !(call KPLIB_INTEL_SERVER_MUTATION_ALLOWED) exitWith {false};
    params [
        ["_unit", objNull, [objNull]],
        ["_caller", objNull, [objNull]],
        ["_source", "unknown", [""]]
    ];

    if !(call KPLIB_INTEL_SERVER_INTERNAL) exitWith {false};
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
    [_unit, _state get "sector", false] call KPLIB_INTEL_SERVER_CAPTURE_SOURCE;
    [_unit] call (localNamespace getVariable "KPLIB_INTEL_CLAIM_LEAD");
    ["DELIVERED"] call KPLIB_INTEL_SERVER_NOTIFY_INFORMANT;
    [format ["Civilian informant debrief completed (unit=%1, playerOwner=%2, source=%3, information recovered)", netId _unit, owner _caller, _source], "INTELLIGENCE"] call KPLIB_fnc_log;
    [true] call KPLIB_INTEL_SERVER_CLEAR_INFORMANT;
    if (!isNil "F_cr_changeCR") then {[2] spawn F_cr_changeCR};

    true
};

KPLIB_INTEL_SERVER_RELEASE_INFORMANT_ESCORT = {
    if !(call KPLIB_INTEL_SERVER_INTERNAL) exitWith {};
    params [["_unit", objNull, [objNull]], ["_reason", "escort unavailable", [""]]];
    private _state = KPLIB_INTEL_INFORMANT_STATE;
    if (count _state == 0 || {isNull _unit} || {_unit isNotEqualTo (_state getOrDefault ["unit", objNull])} || {!alive _unit}) exitWith {};

    _state set ["escort", objNull];
    _state set ["lastAt", CBA_missionTime];
    [_unit] call KPLIB_INTEL_SERVER_SET_INFORMANT_WAITING;
    [format ["Civilian informant escort released (unit=%1, reason=%2)", netId _unit, _reason], "INTELLIGENCE"] call KPLIB_fnc_log;
};

KPLIB_INTEL_SERVER_MONITOR_INFORMANT_ESCORT = {
    if !(call KPLIB_INTEL_SERVER_INTERNAL) exitWith {};
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
    if (isNull _caller) exitWith {};
    private _owner = remoteExecutedOwner;
    [{
        params ["_unit", "_caller", "_owner"];
        if (!isNull _caller && {owner _caller == _owner}) then {[_unit, _caller] call KPLIB_INTEL_SERVER_START_INFORMANT_ESCORT};
    }, [_unit, _caller, _owner]] call CBA_fnc_execNextFrame;
};

KPLIB_INTEL_SERVER_START_INFORMANT_ESCORT = {
    params ["_unit", "_caller"];
    if !(call KPLIB_INTEL_SERVER_INTERNAL) exitWith {};
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
    if !(call KPLIB_INTEL_SERVER_INTERNAL) exitWith {};
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
    private _caller = call KPLIB_INTEL_SERVER_GET_CALLER;
    if (isNull _caller || {side group _caller != GRLIB_side_friendly} || {!KPLIB_intelligence_enabled}) exitWith {};
    if (CBA_missionTime - (_caller getVariable ["KPLIB_intelligenceLastSync", -10]) < 2) exitWith {};
    _caller setVariable ["KPLIB_intelligenceLastSync", CBA_missionTime];
    [{
        params ["_caller"];
        if (isNull _caller || {side group _caller != GRLIB_side_friendly}) exitWith {};
        [_caller] call KPLIB_INTEL_SERVER_SEND_PAYLOAD;
        private _state = KPLIB_INTEL_INFORMANT_STATE;
        if (!isNull (_state getOrDefault ["unit", objNull])) then {
            ["SPAWNED", _state get "searchPosition", _state get "label"] remoteExecCall ["KPLIB_INTEL_CLIENT_INFORMANT_EVENT", _caller];
        };
    }, [_caller]] call CBA_fnc_execNextFrame;
};

KPLIB_INTEL_SERVER_INIT = {
    if !(call KPLIB_INTEL_SERVER_INTERNAL) exitWith {};
    if (missionNamespace getVariable ["KPLIB_INTEL_SERVER_INITIALIZED", false]) exitWith {};
    if (!(missionNamespace getVariable ["save_is_loaded", false]) || {isNil "NETWORKED_SECTORS"} || {count NETWORKED_SECTORS == 0} || {!(missionNamespace getVariable ["BATTLESPACE_LOGISTICS_READY", false])} || {!(missionNamespace getVariable ["KPLIB_COPS_READY", false])}) exitWith {
        [KPLIB_INTEL_SERVER_INIT, [], 2] call CBA_fnc_waitAndExecute;
    };
    KPLIB_INTEL_SERVER_INITIALIZED = true;
    private _saved = missionNamespace getVariable ["KPLIB_INTEL_PENDING_SAVE", []];
    [_saved] call KPLIB_INTEL_SERVER_IMPORT;
    private _known = _saved isEqualType [] && {_saved isEqualTo [] || {count _saved == 7 && {(_saved # 0) in [1, 2]}} || {count _saved == 8 && {(_saved # 0) == 3} && {(_saved # 7) isEqualType []}}};
    [if (_known && {count _saved == 8}) then {_saved # 7} else {[]}, !_known] call KPLIB_INTEL_SERVER_BASE_IMPORT;
    KPLIB_INTEL_PENDING_SAVE = nil;
    call KPLIB_INTEL_SERVER_SCHEDULE_INFORMANT;
    KPLIB_INTEL_SERVER_PFH = [{[false] call KPLIB_INTEL_SERVER_RECONCILE}, KPLIB_intelligence_reconcile_interval] call CBA_fnc_addPerFrameHandler;
};
