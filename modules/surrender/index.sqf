/*
    Server-authoritative combat surrender and prisoner escort lifecycle.
    One CBA class casualty event plus three resolved-battle events feed this module.
*/

if (!isServer) exitWith {};

KPLIB_SURRENDER_SERVER_IS_ELIGIBLE = {
    params [["_unit", objNull, [objNull]]];

    !isNull _unit
        && {local _unit}
        && {alive _unit}
        && {!isPlayer _unit}
        && {_unit isKindOf "CAManBase"}
        && {side group _unit == GRLIB_side_enemy}
        && {!(_unit getVariable ["KPLIB_intelligencePrisoner", false])}
        && {!(_unit getVariable ["KPLIB_surrenderInProgress", false])}
};

KPLIB_SURRENDER_SERVER_CONVERT_UNIT = {
    params [
        ["_unit", objNull, [objNull]],
        ["_prisonerGroup", grpNull, [grpNull]]
    ];
    if (isRemoteExecuted || {isNull _prisonerGroup} || {!([_unit] call KPLIB_SURRENDER_SERVER_IS_ELIGIBLE)}) exitWith {[false, false, false]};

    _unit setVariable ["KPLIB_surrenderInProgress", true];
    private _wasMounted = vehicle _unit isNotEqualTo _unit;
    if (_wasMounted) then {
        unassignVehicle _unit;
        moveOut _unit;
    };

    if (!alive _unit || {side group _unit != GRLIB_side_enemy}) exitWith {
        _unit setVariable ["KPLIB_surrenderInProgress", nil];
        [false, _wasMounted, false]
    };

    if (!isNil "KPLIB_INTEL_SERVER_CAPTURE_SOURCE") then {
        [_unit, "", true] call KPLIB_INTEL_SERVER_CAPTURE_SOURCE;
    };
    private _releasedFromTaskForce = false;
    if (!isNil "BATTLESPACE_TASK_FORCE_RELEASE_PERSON") then {
        _releasedFromTaskForce = [_unit] call BATTLESPACE_TASK_FORCE_RELEASE_PERSON;
    };

    _unit setVariable ["KPLIB_intelligencePrisoner", true, true];
    _unit setVariable ["KPLIB_intelligenceEscort", objNull];
    removeAllWeapons _unit;
    if (typeOf _unit != pilot_classname) then {
        removeHeadgear _unit;
    };
    removeBackpack _unit;
    removeVest _unit;
    _unit unassignItem "NVGoggles_OPFOR";
    _unit removeItem "NVGoggles_OPFOR";
    _unit unassignItem "NVGoggles_INDEP";
    _unit removeItem "NVGoggles_INDEP";
    _unit setUnitPos "UP";
    [_unit] joinSilent _prisonerGroup;
    _unit setCaptive true;

    if (KP_liberation_ace) then {
        ["ace_captives_setSurrendered", [_unit, true], _unit] call CBA_fnc_targetEvent;
    } else {
        _unit disableAI "ANIM";
        _unit disableAI "MOVE";
        _unit playMove "AmovPercMstpSnonWnonDnon_AmovPercMstpSsurWnonDnon";
    };

    _unit setVariable ["KPLIB_surrenderInProgress", nil];
    [true, _wasMounted, _releasedFromTaskForce]
};

KPLIB_SURRENDER_SERVER_TRIGGER_GROUP = {
    params [
        ["_group", grpNull, [grpNull]],
        ["_reason", "GROUP_CASUALTIES", [""]]
    ];
    if (isRemoteExecuted || {isNull _group} || {side _group != GRLIB_side_enemy}) exitWith {0};

    private _survivors = (units _group) select {
        alive _x && {!isPlayer _x} && {_x isKindOf "CAManBase"}
    };
    private _candidates = _survivors select {[_x] call KPLIB_SURRENDER_SERVER_IS_ELIGIBLE};
    if (_candidates isEqualTo []) exitWith {0};

    private _observedStrength = (_group getVariable ["KPLIB_surrenderObservedStrength", count _survivors]) max 1;
    private _survivorRatio = (missionNamespace getVariable ["KPLIB_surrender_group_survivor_ratio", 0.5]) max 0 min 1;
    if (count _survivors > floor (_observedStrength * _survivorRatio)) exitWith {0};

    private _witnessDistance = (missionNamespace getVariable ["KPLIB_surrender_player_witness_distance", 500]) max 0;
    private _anchor = _candidates select 0;
    if ((allPlayers findIf {
        alive _x
            && {side group _x == GRLIB_side_friendly}
            && {_x distance2D _anchor <= _witnessDistance}
    }) < 0) exitWith {0};

    private _chance = (missionNamespace getVariable ["KPLIB_surrender_chance", 60]) max 0 min 100;
    if (random 100 > _chance) exitWith {0};

    private _maximum = floor ((missionNamespace getVariable ["KPLIB_surrender_max_prisoners_per_event", 6]) max 0);
    private _remaining = +_candidates;
    private _prisonerGroup = createGroup [GRLIB_side_civilian, true];
    private _accepted = 0;
    private _dismounted = 0;
    private _releasedFromTaskForces = 0;
    while {_remaining isNotEqualTo [] && {_accepted < _maximum}} do {
        private _unit = _remaining deleteAt (floor random count _remaining);
        private _result = [_unit, _prisonerGroup] call KPLIB_SURRENDER_SERVER_CONVERT_UNIT;
        _result params ["_converted", "_wasMounted", "_releasedFromTaskForce"];
        if (!_converted) then {continue};

        _accepted = _accepted + 1;
        if (_wasMounted) then {_dismounted = _dismounted + 1};
        if (_releasedFromTaskForce) then {_releasedFromTaskForces = _releasedFromTaskForces + 1};
    };
    if (_accepted == 0) then {deleteGroup _prisonerGroup};

    if (_accepted > 0) then {
        [
            format [
                "OPFOR group surrendered after casualties (group=%1, reason=%2, observed=%3, survivors=%4, prisoners=%5, dismounted=%6, taskForceReleased=%7)",
                groupId _group,
                _reason,
                _observedStrength,
                count _survivors,
                _accepted,
                _dismounted,
                _releasedFromTaskForces
            ],
            "SURRENDER"
        ] call KPLIB_fnc_log;
    };
    _accepted
};

KPLIB_SURRENDER_SERVER_TRIGGER_AREA = {
    params [
        ["_center", [], [[]], [2, 3]],
        ["_radius", 0, [0]],
        ["_reason", "UNKNOWN", [""]]
    ];
    if (isRemoteExecuted) exitWith {0};
    if (_center isEqualTo [] || {_radius <= 0}) exitWith {
        [format ["Surrender event %1 rejected because its area is invalid (position=%2, radius=%3)", _reason, _center, _radius], "SURRENDER"] call KPLIB_fnc_log;
        0
    };

    private _candidates = (_center nearEntities ["CAManBase", _radius]) select {
        [_x] call KPLIB_SURRENDER_SERVER_IS_ELIGIBLE
    };
    private _remaining = +_candidates;
    private _chance = (missionNamespace getVariable ["KPLIB_surrender_chance", 60]) max 0 min 100;
    private _maximum = floor ((missionNamespace getVariable ["KPLIB_surrender_max_prisoners_per_event", 6]) max 0);
    private _prisonerGroup = grpNull;
    private _accepted = 0;
    private _dismounted = 0;
    private _releasedFromTaskForces = 0;

    while {_remaining isNotEqualTo [] && {_accepted < _maximum}} do {
        private _candidateIndex = floor random count _remaining;
        private _unit = _remaining deleteAt _candidateIndex;
        if (random 100 > _chance) then {continue};

        if (isNull _prisonerGroup) then {
            _prisonerGroup = createGroup [GRLIB_side_civilian, true];
        };
        private _result = [_unit, _prisonerGroup] call KPLIB_SURRENDER_SERVER_CONVERT_UNIT;
        _result params ["_converted", "_wasMounted", "_releasedFromTaskForce"];
        if (!_converted) then {continue};

        _accepted = _accepted + 1;
        if (_wasMounted) then {_dismounted = _dismounted + 1};
        if (_releasedFromTaskForce) then {_releasedFromTaskForces = _releasedFromTaskForces + 1};
    };

    if (_accepted == 0 && {!isNull _prisonerGroup}) then {
        deleteGroup _prisonerGroup;
    };
    [
        format [
            "Surrender event %1 completed at %2: eligible=%3, prisoners=%4/%5, dismounted=%6, taskForceReleased=%7",
            _reason,
            mapGridPosition _center,
            count _candidates,
            _accepted,
            _maximum,
            _dismounted,
            _releasedFromTaskForces
        ],
        "SURRENDER"
    ] call KPLIB_fnc_log;
    _accepted
};

KPLIB_SURRENDER_SERVER_RELEASE_ESCORT = {
    params [
        ["_unit", objNull, [objNull]],
        ["_reason", "escort lost", [""]]
    ];
    if (isRemoteExecuted || {isNull _unit} || {!alive _unit} || {!(_unit getVariable ["KPLIB_intelligencePrisoner", false])}) exitWith {false};

    _unit setVariable ["KPLIB_intelligenceEscort", objNull];
    _unit setVariable ["KPLIB_surrenderEscortActive", nil];
    if (KP_liberation_ace) then {
        ["ace_captives_setSurrendered", [_unit, false], _unit] call CBA_fnc_targetEvent;
    } else {
        _unit enableAI "ANIM";
        _unit enableAI "MOVE";
    };
    _unit setCaptive false;
    _unit setUnitPos "AUTO";

    private _escapeGroup = createGroup [GRLIB_side_enemy, true];
    [_unit] joinSilent _escapeGroup;
    private _destinationSector = [worldSize * 2, getPos _unit] call KPLIB_fnc_getNearestOpforSector;
    if (_destinationSector isNotEqualTo "") then {
        private _waypoint = _escapeGroup addWaypoint [markerPos _destinationSector, 300];
        _waypoint setWaypointType "MOVE";
        _waypoint setWaypointSpeed "FULL";
    };

    [
        format ["Prisoner escort released (unit=%1, reason=%2, destination=%3)", netId _unit, _reason, _destinationSector],
        "SURRENDER"
    ] call KPLIB_fnc_log;
    true
};

KPLIB_SURRENDER_SERVER_MONITOR_ESCORT = {
    params [
        ["_unit", objNull, [objNull]],
        ["_caller", objNull, [objNull]]
    ];

    private _finished = false;
    private _breakDistance = missionNamespace getVariable ["KPLIB_surrender_escort_break_distance", 150];
    while {!_finished} do {
        sleep 3;
        if (isNull _unit || {!alive _unit} || {_unit getVariable ["KPLIB_intelligenceDelivered", false]}) exitWith {
            _finished = true;
        };

        private _currentEscort = _unit getVariable ["KPLIB_intelligenceEscort", objNull];
        if (_currentEscort isNotEqualTo _caller) exitWith {
            _finished = true;
        };
        if (isNull _caller || {!alive _caller} || {!isPlayer _caller} || {_unit distance _caller > _breakDistance}) exitWith {
            [_unit, "escort unavailable or beyond range"] call KPLIB_SURRENDER_SERVER_RELEASE_ESCORT;
            _finished = true;
        };

        if (vehicle _unit isEqualTo _unit && {_unit distance _caller > 3}) then {
            _unit doMove (getPosATL _caller);
        };

        private _deliveryDistance = missionNamespace getVariable ["KPLIB_intelligence_delivery_distance", 40];
        if (
            vehicle _unit isEqualTo _unit
            && {_unit distance _caller <= _deliveryDistance}
            && {!isNil "KPLIB_INTEL_SERVER_IS_NEAR_TERMINAL"}
            && {[_caller] call KPLIB_INTEL_SERVER_IS_NEAR_TERMINAL}
            && {!isNil "KPLIB_INTEL_SERVER_COMMIT_PRISONER"}
        ) then {
            [_unit, _caller, "surrender escort"] call KPLIB_INTEL_SERVER_COMMIT_PRISONER;
            _finished = true;
        };
    };

    if (!isNull _unit && {(_unit getVariable ["KPLIB_intelligenceEscort", objNull]) isEqualTo _caller}) then {
        _unit setVariable ["KPLIB_surrenderEscortActive", nil];
    };
};

KPLIB_SURRENDER_SERVER_BEGIN_ESCORT = {
    params [
        ["_unit", objNull, [objNull]],
        ["_caller", objNull, [objNull]]
    ];
    if (isRemoteExecuted && {remoteExecutedOwner != owner _caller}) exitWith {false};

    private _interactionDistance = missionNamespace getVariable ["KPLIB_intelligence_interaction_distance", 4];
    if (
        isNull _unit
        || {isNull _caller}
        || {!local _unit}
        || {!alive _unit}
        || {!alive _caller}
        || {!isPlayer _caller}
        || {side group _caller != GRLIB_side_friendly}
        || {vehicle _caller isNotEqualTo _caller}
        || {_unit distance _caller > _interactionDistance}
        || {!(_unit getVariable ["KPLIB_intelligencePrisoner", false])}
        || {_unit getVariable ["KPLIB_intelligenceDelivered", false]}
    ) exitWith {false};

    private _currentEscort = _unit getVariable ["KPLIB_intelligenceEscort", objNull];
    if (_currentEscort isEqualTo _caller && {_unit getVariable ["KPLIB_surrenderEscortActive", false]}) exitWith {true};
    if (!isNull _currentEscort && {_unit getVariable ["KPLIB_surrenderEscortActive", false]}) exitWith {false};

    _unit setVariable ["KPLIB_intelligenceEscort", _caller];
    _unit setVariable ["KPLIB_surrenderEscortActive", true];
    if (KP_liberation_ace) then {
        ["ace_captives_setSurrendered", [_unit, false], _unit] call CBA_fnc_targetEvent;
    } else {
        _unit enableAI "ANIM";
        _unit enableAI "MOVE";
    };
    _unit setCaptive true;
    _unit setUnitPos "AUTO";
    private _escortGroup = group _caller;
    [_unit] joinSilent _escortGroup;
    if (group _unit isNotEqualTo _escortGroup) exitWith {
        _unit setVariable ["KPLIB_intelligenceEscort", objNull];
        _unit setVariable ["KPLIB_surrenderEscortActive", nil];
        if (KP_liberation_ace) then {
            ["ace_captives_setSurrendered", [_unit, true], _unit] call CBA_fnc_targetEvent;
        } else {
            _unit disableAI "ANIM";
            _unit disableAI "MOVE";
        };
        [format ["Prisoner escort rejected (unit=%1, reason=failed to join player group)", netId _unit], "SURRENDER"] call KPLIB_fnc_log;
        false
    };
    _unit doMove (getPosATL _caller);

    [format ["Prisoner escort started (unit=%1, playerOwner=%2, group=%3)", netId _unit, owner _caller, groupId _escortGroup], "SURRENDER"] call KPLIB_fnc_log;
    [_unit, _caller] spawn KPLIB_SURRENDER_SERVER_MONITOR_ESCORT;
    true
};

KPLIB_SURRENDER_KILLED_XEH = ["CAManBase", "Killed", {
    params ["_killed"];
    if (
        isNull _killed
        || {isPlayer _killed}
    ) exitWith {};

    private _group = group _killed;
    if (isNull _group || {side _group != GRLIB_side_enemy}) exitWith {};

    private _observedStrength = ({alive _x} count units _group) + 1;
    private _recordedStrength = _group getVariable ["KPLIB_surrenderObservedStrength", 0];
    if (_observedStrength > _recordedStrength) then {
        _group setVariable ["KPLIB_surrenderObservedStrength", _observedStrength];
    };
    if (_group getVariable ["KPLIB_surrenderCasualtyCheckPending", false]) exitWith {};

    _group setVariable ["KPLIB_surrenderCasualtyCheckPending", true];
    [{
        params ["_group"];
        if (isNull _group) exitWith {};
        _group setVariable ["KPLIB_surrenderCasualtyCheckPending", nil];
        [_group] call KPLIB_SURRENDER_SERVER_TRIGGER_GROUP;
    }, [_group], 2] call CBA_fnc_waitAndExecute;
}, true] call CBA_fnc_addClassEventHandler;

[
    format [
        "Surrender subsystem initialized (chance=%1%%, maxPerEvent=%2, groupRatio=%3, witnessDistance=%4m, escortBreakDistance=%5m)",
        missionNamespace getVariable ["KPLIB_surrender_chance", 60],
        missionNamespace getVariable ["KPLIB_surrender_max_prisoners_per_event", 6],
        missionNamespace getVariable ["KPLIB_surrender_group_survivor_ratio", 0.5],
        missionNamespace getVariable ["KPLIB_surrender_player_witness_distance", 500],
        missionNamespace getVariable ["KPLIB_surrender_escort_break_distance", 150]
    ],
    "SURRENDER"
] call KPLIB_fnc_log;
