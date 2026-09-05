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
    if (!hasInterface) exitWith {};

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
    {
        private _marker = [markerPos (_x # 0)] call KPLIB_INTEL_CLIENT_CREATE_MARKER;
        _marker setMarkerTypeLocal "mil_dot";
        _marker setMarkerColorLocal "ColorBLUFOR";
        _marker setMarkerTextLocal format ["INTEL COVERAGE T%1", _x # 1];
    } forEach KPLIB_INTEL_CLIENT_COVERAGE;
    {
        _x params ["_id", "_kind", "_phase", "_region", "_position", "_uncertainty", "_observedAt", "_destinationSector", "_destinationPosition", "_strength", "_route", "_tier", "_meta"];
        private _status = _meta get "status";
        private _current = _status == "CURRENT";
        private _color = if (_current) then {"ColorOPFOR"} else {"ColorOrange"};
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
            default {"o_unknown"};
        };
        _icon setMarkerTypeLocal _type;
        _icon setMarkerColorLocal _color;
        _icon setMarkerTextLocal format ["%1 | %2 | %3", _kind, [_status, _phase] select _current, _strength];
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
    } forEach KPLIB_INTEL_CLIENT_REPORTS;
};

KPLIB_INTEL_CLIENT_NOTIFY = {
    params ["_type", ["_value", 0], ["_detail", ""]];
    if (!hasInterface) exitWith {};
    switch (_type) do {
        case "EARNED": {
            ["lib_admin_notification", ["INTELLIGENCE RECOVERED", format ["+%1 shared intelligence from %2.", _value, toUpper _detail], "res\notif\ui_notif_int.paa"]] call BIS_fnc_showNotification;
        };
        case "ACTIVATED": {
            ["lib_admin_notification", ["INTELLIGENCE COVERAGE", format ["%1 is now covered at analysis tier %2.", _detail, _value], "res\notif\ui_notif_int.paa"]] call BIS_fnc_showNotification;
        };
        case "REPORTS": {
            ["lib_admin_notification", ["SITREP UPDATED", format ["%1 new Battlespace observations are available on the map.", _value], "res\notif\ui_notif_int.paa"]] call BIS_fnc_showNotification;
        };
        case "REJECTED": {
            hint _detail;
            if (!isNull (uiNamespace getVariable ["KPLIB_INTEL_CLIENT_DISPLAY", displayNull])) then {[] call KPLIB_INTEL_CLIENT_DIALOG_REFRESH};
        };
    };
};

KPLIB_INTEL_CLIENT_RECEIVE_SNAPSHOT = {
    params [["_snapshot", [], [[]]]];
    if (!hasInterface || {count _snapshot < 6} || {(_snapshot # 5) != 2}) exitWith {};
    if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {};
    if ((_snapshot # 0) < KPLIB_INTEL_CLIENT_REVISION) exitWith {};
    _snapshot params ["_revision", "_reserve", "_coverage", "_reports", "_regions"];

    private _oldIds = KPLIB_INTEL_CLIENT_REPORTS apply {_x # 0};
    private _newReportCount = 0;
    if (KPLIB_INTEL_CLIENT_HAS_SNAPSHOT) then {
        {_newReportCount = _newReportCount + ([0, 1] select !((_x # 0) in _oldIds))} forEach _reports;
    };

    KPLIB_INTEL_CLIENT_REVISION = _revision;
    KPLIB_INTEL_CLIENT_COVERAGE = _coverage;
    KPLIB_INTEL_CLIENT_REPORTS = _reports;
    KPLIB_INTEL_CLIENT_REGIONS = _regions;
    KPLIB_INTEL_CLIENT_HAS_SNAPSHOT = true;
    resources_intel = _reserve;
    call KPLIB_INTEL_CLIENT_RENDER_MARKERS;

    if (_newReportCount > 0) then {["REPORTS", _newReportCount] call KPLIB_INTEL_CLIENT_NOTIFY};
    if (!isNull (uiNamespace getVariable ["KPLIB_INTEL_CLIENT_DISPLAY", displayNull])) then {[uiNamespace getVariable "KPLIB_INTEL_CLIENT_DISPLAY"] call KPLIB_INTEL_CLIENT_DIALOG_LOAD};
};

[] call compileFinal preprocessFileLineNumbers "modules\intelligence\dialog.sqf";

KPLIB_INTEL_CLIENT_ACTIVATE_SELECTED = {
    private _display = uiNamespace getVariable ["KPLIB_INTEL_CLIENT_DISPLAY", displayNull];
    if (isNull _display) exitWith {};
    private _regionList = _display displayCtrl 101;
    private _tierList = _display displayCtrl 108;
    private _regionIndex = lbCurSel _regionList;
    private _tierIndex = lbCurSel _tierList;
    if (_regionIndex < 0 || {_tierIndex < 0}) exitWith {};
    private _region = _regionList lbData _regionIndex;
    private _tier = parseNumber (_tierList lbData _tierIndex);
    (_display displayCtrl 103) ctrlEnable false;
    [_region, _tier] remoteExecCall ["KPLIB_INTEL_SERVER_ACTIVATE_COVERAGE", 2];
};

KPLIB_INTEL_CLIENT_UPDATE_HUD = {
    params ["_display", "_visibleMap"];
    if (isNull _display) exitWith {};
    private _textControl = _display displayCtrl 516;
    private _background = _display displayCtrl 517;
    private _activeCoverage = KPLIB_INTEL_CLIENT_COVERAGE select {(_x # 2) > CBA_missionTime};
    private _show = _visibleMap && {_activeCoverage isNotEqualTo []};
    private _hudKey = str [KPLIB_INTEL_CLIENT_REVISION, _show, floor (CBA_missionTime / 60)];
    if (_hudKey == KPLIB_INTEL_CLIENT_HUD_KEY && {_display isEqualTo (uiNamespace getVariable ["KPLIB_INTEL_CLIENT_HUD_DISPLAY", displayNull])}) exitWith {};
    uiNamespace setVariable ["KPLIB_INTEL_CLIENT_HUD_DISPLAY", _display];
    KPLIB_INTEL_CLIENT_HUD_KEY = _hudKey;
    _background ctrlShow _show;
    _textControl ctrlShow _show;
    if (!_show) exitWith {_textControl ctrlSetStructuredText parseText ""};

    private _minimumMinutes = 999;
    { _minimumMinutes = _minimumMinutes min (ceil ((((_x # 2) - CBA_missionTime) / 60) max 0)) } forEach _activeCoverage;
    _textControl ctrlSetStructuredText parseText format [
        "<t align='right' color='#7fc9ff'>INTELLIGENCE NETWORK</t><br/><t align='right'>%1 regions | %2 reports | next expiry %3m</t>",
        count _activeCoverage,
        count KPLIB_INTEL_CLIENT_REPORTS,
        _minimumMinutes
    ];
};

KPLIB_INTEL_CLIENT_INIT = {
    if (!hasInterface || {missionNamespace getVariable ["KPLIB_INTEL_CLIENT_INITIALIZED", false]}) exitWith {};
    KPLIB_INTEL_CLIENT_INITIALIZED = true;
    KPLIB_INTEL_CLIENT_REVISION = -1;
    KPLIB_INTEL_CLIENT_COVERAGE = [];
    KPLIB_INTEL_CLIENT_REPORTS = [];
    KPLIB_INTEL_CLIENT_REGIONS = [];
    KPLIB_INTEL_CLIENT_MARKERS = [];
    KPLIB_INTEL_CLIENT_MARKER_INDEX = 0;
    KPLIB_INTEL_CLIENT_SELECTED_REPORT = "";
    KPLIB_INTEL_CLIENT_INFORMANT_MARKER = "";
    KPLIB_INTEL_CLIENT_HAS_SNAPSHOT = false;
    KPLIB_INTEL_CLIENT_HUD_KEY = "";
    uiNamespace setVariable ["KPLIB_INTEL_CLIENT_DISPLAY", displayNull];

    if (missionNamespace getVariable ["KPLIB_intelligence_enabled", true]) then {
        private _escortAction = [
            "KPLIB_INTEL_ESCORT",
            "Escort for debrief",
            "",
            {
                params ["_target", "_player"];
                if (_target getVariable ["KPLIB_intelligencePrisoner", false]) then {
                    [_target] remoteExecCall ["KPLIB_INTEL_SERVER_REGISTER_PRISONER_ESCORT", 2];
                } else {
                    [_target] remoteExecCall ["KPLIB_INTEL_SERVER_BEGIN_INFORMANT_ESCORT", 2];
                };
            },
            {
                params ["_target", "_player"];
                alive _target
                    && {_target isNotEqualTo _player}
                    && {!isPlayer _target}
                    && {side group _player == GRLIB_side_friendly}
                    && {vehicle _player isEqualTo _player}
                    && {_target distance _player <= (missionNamespace getVariable ["KPLIB_intelligence_interaction_distance", 4])}
                    && {
                        _target getVariable ["KPLIB_intelligencePrisoner", false]
                        || {_target getVariable ["KPLIB_intelligenceInformant", false]}
                    }
                    && {side group _target != GRLIB_side_friendly}
            }
        ] call ace_interact_menu_fnc_createAction;
        ["CAManBase", 0, ["ACE_MainActions"], _escortAction, true] call ace_interact_menu_fnc_addActionToClass;

        {
            private _collectAction = [
                format ["KPLIB_INTEL_COLLECT_%1", _forEachIndex],
                "Collect intelligence",
                "res\notif\ui_notif_int.paa",
                {params ["_target"]; [_target] remoteExecCall ["KPLIB_INTEL_SERVER_COLLECT_DOCUMENT", 2]},
                {
                    params ["_target", "_player"];
                    !(_target getVariable ["KPLIB_intelligenceCollected", false])
                        && {side group _player == GRLIB_side_friendly}
                        && {vehicle _player isEqualTo _player}
                        && {_target distance _player <= (missionNamespace getVariable ["KPLIB_intelligence_interaction_distance", 4])}
                }
            ] call ace_interact_menu_fnc_createAction;
            [_x, 0, [], _collectAction, true] call ace_interact_menu_fnc_addActionToClass;
        } forEach KPLIB_intelObjectClasses;

        [] remoteExecCall ["KPLIB_INTEL_SERVER_REQUEST_SYNC", 2];
    };
};
