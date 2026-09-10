KPLIB_INTEL_CLIENT_CLEAR_MARKERS = {
    {deleteMarkerLocal _x} forEach (missionNamespace getVariable ["KPLIB_INTEL_CLIENT_MARKERS", []]);
    KPLIB_INTEL_CLIENT_MARKERS = [];
};

KPLIB_INTEL_CLIENT_CLEAR_INFORMANT_MARKER = {
    private _marker = missionNamespace getVariable ["KPLIB_INTEL_CLIENT_INFORMANT_MARKER", ""];
    if (_marker != "") then {deleteMarkerLocal _marker};
    KPLIB_INTEL_CLIENT_INFORMANT_MARKER = "";
};

KPLIB_INTEL_CLIENT_INFORMANT_EVENT = {
    params ["_event", ["_position", [], [[]]], ["_label", "", [""]]];
    if (!hasInterface || {isRemoteExecuted && {remoteExecutedOwner != 2}}) exitWith {};

    switch (_event) do {
        case "SPAWNED": {
            call KPLIB_INTEL_CLIENT_CLEAR_INFORMANT_MARKER;
            if (_position isEqualType [] && {count _position >= 2}) then {
                private _marker = format ["KPLIB_INTEL_INFORMANT_%1", clientOwner];
                createMarkerLocal [_marker, _position];
                _marker setMarkerColorLocal "ColorCIV";
                _marker setMarkerShapeLocal "ELLIPSE";
                _marker setMarkerBrushLocal "FDiagonal";
                _marker setMarkerSizeLocal [500, 500];
                KPLIB_INTEL_CLIENT_INFORMANT_MARKER = _marker;
            };
            ["lib_civ_informant_start", [_label]] call BIS_fnc_showNotification;
        };
        case "DELIVERED": {
            call KPLIB_INTEL_CLIENT_CLEAR_INFORMANT_MARKER;
            ["lib_civ_informant_success"] call BIS_fnc_showNotification;
        };
        case "EXPIRED": {
            call KPLIB_INTEL_CLIENT_CLEAR_INFORMANT_MARKER;
            ["lib_civ_informant_fail"] call BIS_fnc_showNotification;
        };
        case "KILLED": {
            call KPLIB_INTEL_CLIENT_CLEAR_INFORMANT_MARKER;
            ["lib_civ_informant_death"] call BIS_fnc_showNotification;
        };
    };
};

KPLIB_INTEL_CLIENT_CREATE_MARKER = {
    params ["_position"];
    KPLIB_INTEL_CLIENT_MARKER_INDEX = KPLIB_INTEL_CLIENT_MARKER_INDEX + 1;
    private _name = format ["KPLIB_INTEL_%1", KPLIB_INTEL_CLIENT_MARKER_INDEX];
    createMarkerLocal [_name, _position];
    KPLIB_INTEL_CLIENT_MARKERS pushBack _name;
    _name
};

KPLIB_INTEL_CLIENT_RENDER_MARKERS = {
    call KPLIB_INTEL_CLIENT_CLEAR_MARKERS;
    KPLIB_INTEL_CLIENT_MARKER_INDEX = 0;
    KPLIB_INTEL_CLIENT_MAP_REPORTS = +KPLIB_INTEL_CLIENT_REPORTS;
    // Native task markers are disabled in description.ext. Keep active stages
    // visible on the ordinary map after retiring the case-files display.
    {
        _x params ["_id", "_title", "_stage", "_status", "_pos", "_brief", "_effect", "_history", "_deadline"];
        if (_status != "ACTIVE" || {count _pos < 2}) then {continue};
        private _meta = createHashMapFromArray [["title", _title], ["status", "OPERATION"], ["operation", true],
            ["deadline", _deadline], ["details", [_brief, _effect] + _history]];
        KPLIB_INTEL_CLIENT_MAP_REPORTS pushBack ["CASE_" + _id, "OPERATION", ["Recover documents", "Retrieve HVT", "Disrupt support"] # _stage,
            "", _pos, 0, CBA_missionTime, "", [], _title, [], 3, _meta];
    } forEach (missionNamespace getVariable ["KPLIB_INTEL_CLIENT_CASES", []]);
    {
        _x params ["_id", "_kind", "_phase", "_region", "_position", "_uncertainty", "_observedAt", "_destinationSector", "_destinationPosition", "_strength", "_route", "_tier", "_meta"];
        private _status = _meta get "status";
        private _current = _status == "CURRENT";
        private _color = if (_kind == "OPERATION") then {"ColorWEST"} else {["ColorOrange", "ColorOPFOR"] select _current};
        private _selected = _id == KPLIB_INTEL_CLIENT_SELECTED_REPORT;
        private _zone = [_position] call KPLIB_INTEL_CLIENT_CREATE_MARKER;
        _zone setMarkerShapeLocal "ELLIPSE";
        _zone setMarkerBrushLocal "FDiagonal";
        _zone setMarkerColorLocal _color;
        _zone setMarkerSizeLocal [_uncertainty, _uncertainty];
        _zone setMarkerAlphaLocal ([0.12, 0.3] select _selected);
        private _icon = [_position] call KPLIB_INTEL_CLIENT_CREATE_MARKER;
        private _type = switch (_kind) do {
            case "CONVOY": {"o_motor_inf"};
            case "GROUND OFFENSIVE": {"o_mech_inf"};
            case "ARTILLERY": {"o_art"};
            case "ARTILLERY TRP": {"mil_destroy"};
            case "SAM": {"o_antiair"};
            case "SECTOR ASSESSMENT": {"mil_unknown"};
            case "OBJECTIVE STOCK": {"mil_box"};
            case "FORCE-WIDE STOCK": {"mil_box"};
            case "OPERATION": {"mil_objective"};
            default {"o_unknown"};
        };
        _icon setMarkerTypeLocal _type;
        _icon setMarkerColorLocal _color;
        private _age = floor (((CBA_missionTime - _observedAt) max 0) / 60);
        _icon setMarkerTextLocal (if (_kind == "OPERATION") then {format ["%1: %2", _phase, _strength]} else {format ["%1 | %2 min ago | %3", _kind, _age, _strength]});
        if (_selected) then {
            if (count _destinationPosition >= 2) then {
                private _destination = [_destinationPosition] call KPLIB_INTEL_CLIENT_CREATE_MARKER;
                _destination setMarkerTypeLocal "mil_end";
                _destination setMarkerColorLocal _color;
                _destination setMarkerTextLocal (["LAST REPORTED LEG", "REPORTED CURRENT LEG"] select _current);
            };
            // An uncertain corridor around consecutive actual path segments. Never shift the road.
            for "_index" from 1 to (count _route - 1) do {
                private _from = _route # (_index - 1);
                private _to = _route # _index;
                private _midpoint = [((_from # 0) + (_to # 0)) / 2, ((_from # 1) + (_to # 1)) / 2, 0];
                private _corridor = [_midpoint] call KPLIB_INTEL_CLIENT_CREATE_MARKER;
                _corridor setMarkerShapeLocal "RECTANGLE";
                _corridor setMarkerBrushLocal "FDiagonal";
                _corridor setMarkerColorLocal _color;
                _corridor setMarkerDirLocal (_from getDir _to);
                _corridor setMarkerSizeLocal [_uncertainty / 2, (_from distance2D _to) / 2];
                _corridor setMarkerAlphaLocal 0.25;
            };
        };
    } forEach KPLIB_INTEL_CLIENT_MAP_REPORTS;
};


KPLIB_INTEL_CLIENT_NOTIFY = {
    params ["_type", ["_value", 0], ["_detail", ""]];
    if (!hasInterface || {isRemoteExecuted && {remoteExecutedOwner != 2}}) exitWith {};
    // Ordinary reports and stage changes are visible on the map and task list.
    if (_type in ["REPORTS", "INFO"]) exitWith {};
    ["lib_admin_notification", ["INTELLIGENCE", _detail, "res\notif\ui_notif_int.paa"]] call BIS_fnc_showNotification;
};

KPLIB_INTEL_CLIENT_UPDATE_TASKS = {
    if (isNull player) exitWith {};
    if (player isNotEqualTo (missionNamespace getVariable ["KPLIB_INTEL_CLIENT_TASK_OWNER", objNull])) then {
        KPLIB_INTEL_CLIENT_TASKS = createHashMap;
        KPLIB_INTEL_CLIENT_TASK_OWNER = player;
    };
    private _seen = [];
    {
        _x params ["_id", "_title", "_stage", "_status", "_pos", "_brief", "_effect", "_history", "_deadline"];
        _seen pushBack _id;
        private _entry = KPLIB_INTEL_CLIENT_TASKS getOrDefault [_id, []];
        private _newStage = _entry isEqualTo [] || {(_entry # 1) != _stage};
        if (_newStage && {_entry isNotEqualTo []}) then {
            player removeSimpleTask (_entry # 0);
            _entry = [];
        };
        private _task = if (_entry isEqualTo []) then {
            player createSimpleTask [format ["%1: %2", _title, ["Recover documents", "Retrieve HVT", "Disrupt support"] # _stage]]
        } else {_entry # 0};
        private _description = ([_brief] call KPLIB_INTEL_CLIENT_ESCAPE) + "<br/><br/>" + ([_effect] call KPLIB_INTEL_CLIENT_ESCAPE)
            + "<br/><br/>" + ((_history apply {[_x] call KPLIB_INTEL_CLIENT_ESCAPE}) joinString "<br/>");
        if (_status == "QUEUED") then {_description = "Awaiting a confirmed target location.<br/><br/>" + _description};
        _task setSimpleTaskDescription [_description, _title, ["Documents", "HVT", "Support site"] # _stage];
        if (_status == "ACTIVE") then {_task setSimpleTaskDestination _pos};
        private _taskState = switch (_status) do {
            case "ACTIVE": {"ASSIGNED"};
            case "QUEUED": {"CREATED"};
            default {_status};
        };
        _task setTaskState _taskState;
        if (_status == "ACTIVE" && {_newStage || {(_entry param [2, ""]) == "QUEUED"}}) then {
            player setCurrentTask _task;
            if (KPLIB_INTEL_CLIENT_HAS_SNAPSHOT) then {
                ["INFO", 0, format ["New task: %1 - %2", _title, ["recover documents", "retrieve the HVT alive", "disrupt enemy support"] # _stage]] call KPLIB_INTEL_CLIENT_NOTIFY;
            };
        };
        KPLIB_INTEL_CLIENT_TASKS set [_id, [_task, _stage, _status]];
    } forEach KPLIB_INTEL_CLIENT_CASES;
    {
        if !(_x in _seen) then {
            player removeSimpleTask ((KPLIB_INTEL_CLIENT_TASKS get _x) # 0);
            KPLIB_INTEL_CLIENT_TASKS deleteAt _x;
        };
    } forEach keys KPLIB_INTEL_CLIENT_TASKS;
};

KPLIB_INTEL_CLIENT_RECEIVE_SNAPSHOT = {
    params [["_snapshot", [], [[]]]];
    if (!hasInterface || {count _snapshot != 5} || {(_snapshot # 4) != 3}) exitWith {};
    if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {};
    if (!(missionNamespace getVariable ["KPLIB_INTEL_CLIENT_INITIALIZED", false])) exitWith {};
    if ((_snapshot # 0) < KPLIB_INTEL_CLIENT_REVISION) exitWith {};
    _snapshot params ["_revision", "_reports", "_cases", "_detainees"];
    private _oldIds = KPLIB_INTEL_CLIENT_REPORTS apply {_x # 0};
    private _newReports = _reports findIf {!((_x # 0) in _oldIds)} >= 0;
    KPLIB_INTEL_CLIENT_REVISION = _revision;
    KPLIB_INTEL_CLIENT_REPORTS = _reports;
    KPLIB_INTEL_CLIENT_CASES = _cases;
    KPLIB_INTEL_CLIENT_DETAINEES = _detainees;
    call KPLIB_INTEL_CLIENT_RENDER_MARKERS;
    call KPLIB_INTEL_CLIENT_UPDATE_TASKS;
    if (_newReports && {KPLIB_INTEL_CLIENT_HAS_SNAPSHOT}) then {["REPORTS"] call KPLIB_INTEL_CLIENT_NOTIFY};
    KPLIB_INTEL_CLIENT_HAS_SNAPSHOT = true;
};

KPLIB_INTEL_CLIENT_INTERROGATE = {
    params ["_unit", "_duration"];
    if (!hasInterface || {!isRemoteExecuted} || {remoteExecutedOwner != 2}) exitWith {};
    [_duration, [_unit], {}, {
        params ["_args"];
        [_args # 0, "CANCEL"] remoteExecCall ["KPLIB_INTEL_SERVER_REQUEST_ACTION", 2];
    }, "Interrogating prisoner", {
        params ["_args", "_elapsed"];
        private _unit = _args # 0;
        alive player && {alive _unit} && {player distance _unit <= KPLIB_intelligence_interaction_distance}
            && {vehicle player isEqualTo player} && {!(_unit getVariable ["ACE_isUnconscious", false])}
            && {_elapsed < 2 || {_unit getVariable ["KPLIB_intelligenceInterrogating", false]}}
    }] call ace_common_fnc_progressBar;
};

[] call compileFinal preprocessFileLineNumbers "modules\intelligence\map.sqf";

KPLIB_INTEL_CLIENT_INIT = {
    if (!hasInterface || {missionNamespace getVariable ["KPLIB_INTEL_CLIENT_INITIALIZED", false]}) exitWith {};
    KPLIB_INTEL_CLIENT_INITIALIZED = true;
    KPLIB_INTEL_CLIENT_REVISION = -1;
    KPLIB_INTEL_CLIENT_REPORTS = [];
    KPLIB_INTEL_CLIENT_CASES = [];
    KPLIB_INTEL_CLIENT_DETAINEES = 0;
    KPLIB_INTEL_CLIENT_TASKS = createHashMap;
    KPLIB_INTEL_CLIENT_MARKERS = [];
    KPLIB_INTEL_CLIENT_MARKER_INDEX = 0;
    KPLIB_INTEL_CLIENT_SELECTED_REPORT = "";
    KPLIB_INTEL_CLIENT_INFORMANT_MARKER = "";
    KPLIB_INTEL_CLIENT_HAS_SNAPSHOT = false;
    if (!KPLIB_intelligence_enabled) exitWith {};
    [KPLIB_INTEL_CLIENT_MAP_TICK, 0.2] call CBA_fnc_addPerFrameHandler;
    KPLIB_INTEL_CLIENT_CAN_INTERACT = {
        params ["_target", "_actor"];
        alive _target && {alive _actor} && {side group _actor == GRLIB_side_friendly}
            && {vehicle _actor isEqualTo _actor} && {_actor distance _target <= KPLIB_intelligence_interaction_distance}
            && {!(_actor getVariable ["ACE_isUnconscious", false])}
    };
    private _escort = ["KPLIB_INTEL_ESCORT", "Escort to FOB / patrol base", "", {
        params ["_target"];
        [_target] remoteExecCall [["KPLIB_INTEL_SERVER_BEGIN_INFORMANT_ESCORT", "KPLIB_INTEL_SERVER_REGISTER_PRISONER_ESCORT"] select (_target getVariable ["KPLIB_intelligencePrisoner", false]), 2];
    }, {
        params ["_target", "_player"];
        [_target, _player] call KPLIB_INTEL_CLIENT_CAN_INTERACT && {!isPlayer _target}
            && {!(_target getVariable ["KPLIB_intelligenceDelivered", false])}
            && {_target getVariable ["KPLIB_intelligencePrisoner", false] || {_target getVariable ["KPLIB_intelligenceInformant", false]}}
            && {isNull (_target getVariable ["KPLIB_intelligenceEscort", objNull])}
    }] call ace_interact_menu_fnc_createAction;
    ["CAManBase", 0, ["ACE_MainActions"], _escort, true] call ace_interact_menu_fnc_addActionToClass;
    {
        _x params ["_id", "_label", "_condition"];
        private _action = [_id, _label, "", {
            params ["_target", "_player", "_actionId"];
            [_target, _actionId] remoteExecCall ["KPLIB_INTEL_SERVER_REQUEST_ACTION", 2];
        }, _condition, {}, _id] call ace_interact_menu_fnc_createAction;
        ["CAManBase", 0, ["ACE_MainActions"], _action, true] call ace_interact_menu_fnc_addActionToClass;
    } forEach [
        ["INTERROGATE", "Interrogate prisoner", {
            params ["_target", "_player"];
            [_target, _player] call KPLIB_INTEL_CLIENT_CAN_INTERACT
                && {_target getVariable ["KPLIB_intelligenceDetained", false]}
                && {!(_target getVariable ["KPLIB_intelligenceInterrogating", false])}
        }],
        ["HVT", "Detain HVT", {
            params ["_target", "_player"];
            [_target, _player] call KPLIB_INTEL_CLIENT_CAN_INTERACT
                && {(_target getVariable ["KPLIB_intelligenceHVT", ""]) != ""}
                && {!(_target getVariable ["KPLIB_intelligencePrisoner", false])}
        }]
    ];
    {
        private _collect = [format ["KPLIB_INTEL_COLLECT_%1", _forEachIndex], "Collect intelligence", "res\notif\ui_notif_int.paa", {
            params ["_target"];
            [_target] remoteExecCall ["KPLIB_INTEL_SERVER_COLLECT_DOCUMENT", 2];
        }, {
            params ["_target", "_player"];
            [_target, _player] call KPLIB_INTEL_CLIENT_CAN_INTERACT && {!(_target getVariable ["KPLIB_intelligenceCollected", false])}
        }] call ace_interact_menu_fnc_createAction;
        [_x, 0, [], _collect, true] call ace_interact_menu_fnc_addActionToClass;
    } forEach KPLIB_intelObjectClasses;
    private _sabotage = ["KPLIB_INTEL_SABOTAGE", "Sabotage support site", "", {
        params ["_target"];
        [_target, "SABOTAGE"] remoteExecCall ["KPLIB_INTEL_SERVER_REQUEST_ACTION", 2];
    }, {
        params ["_target", "_player"];
        [_target, _player] call KPLIB_INTEL_CLIENT_CAN_INTERACT && {(_target getVariable ["KPLIB_intelligenceObjective", ""]) != ""}
    }] call ace_interact_menu_fnc_createAction;
    ["Land_CargoBox_V1_F", 0, [], _sabotage, true] call ace_interact_menu_fnc_addActionToClass;
    addMissionEventHandler ["EntityRespawned", {
        params ["_unit"];
        if (local _unit && {isPlayer _unit}) then {
            call KPLIB_INTEL_CLIENT_UPDATE_TASKS;
            [] remoteExecCall ["KPLIB_INTEL_SERVER_REQUEST_SYNC", 2];
        };
    }];
    [] remoteExecCall ["KPLIB_INTEL_SERVER_REQUEST_SYNC", 2];
};
