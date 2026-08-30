KPLIB_INTEL_CLIENT_CLEAR_MARKERS = {
    {deleteMarkerLocal _x} forEach (missionNamespace getVariable ["KPLIB_INTEL_CLIENT_MARKERS", []]);
    KPLIB_INTEL_CLIENT_MARKERS = [];
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

    {
        _x params ["_region", "_tier", "_expiresAt"];
        private _coverageMarker = [getMarkerPos _region] call KPLIB_INTEL_CLIENT_CREATE_MARKER;
        _coverageMarker setMarkerTypeLocal "mil_dot";
        _coverageMarker setMarkerColorLocal "ColorBLUFOR";
        _coverageMarker setMarkerTextLocal format ["INTEL COVERAGE T%1", _tier];
        _coverageMarker setMarkerAlphaLocal 0.8;
    } forEach KPLIB_INTEL_CLIENT_COVERAGE;

    {
        _x params ["_id", "_kind", "_phase", "_region", "_position", "_uncertainty", "_observedAt", "_destinationSector", "_destinationPosition", "_strength", "_route", "_tier"];
        private _zone = [_position] call KPLIB_INTEL_CLIENT_CREATE_MARKER;
        _zone setMarkerShapeLocal "ELLIPSE";
        _zone setMarkerBrushLocal "FDiagonal";
        _zone setMarkerColorLocal "ColorOPFOR";
        _zone setMarkerSizeLocal [_uncertainty, _uncertainty];
        _zone setMarkerAlphaLocal 0.25;

        private _icon = [_position] call KPLIB_INTEL_CLIENT_CREATE_MARKER;
        private _markerType = switch true do {
            case (_kind find "AIR" >= 0): {"o_plane"};
            case (_kind == "CONVOY" || {_kind find "LOGISTICS" >= 0}): {"o_motor_inf"};
            case (_kind == "BATTLEGROUP"): {"o_mech_inf"};
            case (_kind == "ARTILLERY"): {"o_art"};
            case (_kind == "SAM"): {"o_antiair"};
            default {"o_unknown"};
        };
        _icon setMarkerTypeLocal _markerType;
        _icon setMarkerColorLocal "ColorOPFOR";
        _icon setMarkerTextLocal format ["%1 | %2", _kind, _phase];

        if (_destinationPosition isEqualType [] && {count _destinationPosition >= 2}) then {
            private _destination = [_destinationPosition] call KPLIB_INTEL_CLIENT_CREATE_MARKER;
            _destination setMarkerTypeLocal "mil_end";
            _destination setMarkerColorLocal "ColorOPFOR";
            private _destinationLabel = markerText _destinationSector;
            if (_destinationLabel == "") then {_destinationLabel = _destinationSector};
            _destination setMarkerTextLocal format ["ASSESSED DESTINATION: %1", _destinationLabel];
        };

        {
            private _routeMarker = [_x] call KPLIB_INTEL_CLIENT_CREATE_MARKER;
            _routeMarker setMarkerTypeLocal "mil_dot";
            _routeMarker setMarkerColorLocal "ColorOPFOR";
            _routeMarker setMarkerSizeLocal [0.45, 0.45];
            _routeMarker setMarkerAlphaLocal 0.65;
        } forEach _route;
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
    if (!hasInterface || {count _snapshot < 5}) exitWith {};
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
    if (!isNull (uiNamespace getVariable ["KPLIB_INTEL_CLIENT_DISPLAY", displayNull])) then {[] call KPLIB_INTEL_CLIENT_DIALOG_REFRESH};
};

KPLIB_INTEL_CLIENT_DIALOG_LOAD = {
    params [["_display", displayNull, [displayNull]]];
    if (isNull _display) exitWith {};
    private _regionList = _display displayCtrl 101;
    private _tierList = _display displayCtrl 108;
    lbClear _regionList;
    {
        _x params ["_sector", "_label", "_depth"];
        private _active = KPLIB_INTEL_CLIENT_COVERAGE select {(_x # 0) == _sector};
        private _suffix = if (_active isEqualTo []) then {""} else {format ["  [T%1 ACTIVE]", (_active # 0) # 1]};
        private _row = _regionList lbAdd format ["%1  (depth %2)%3", _label, _depth, _suffix];
        _regionList lbSetData [_row, _sector];
    } forEach KPLIB_INTEL_CLIENT_REGIONS;

    lbClear _tierList;
    private _costs = missionNamespace getVariable ["KPLIB_intelligence_tier_costs", [10, 25, 45]];
    {
        private _row = _tierList lbAdd format ["Tier %1 - %2 intel", _forEachIndex + 1, _x];
        _tierList lbSetData [_row, str (_forEachIndex + 1)];
    } forEach _costs;

    _regionList lbSetCurSel ([0, -1] select (lbSize _regionList == 0));
    _tierList lbSetCurSel 0;
    [] call KPLIB_INTEL_CLIENT_DIALOG_REFRESH;
};

KPLIB_INTEL_CLIENT_DIALOG_REFRESH = {
    private _display = uiNamespace getVariable ["KPLIB_INTEL_CLIENT_DISPLAY", displayNull];
    if (isNull _display) exitWith {};
    private _regionList = _display displayCtrl 101;
    private _tierList = _display displayCtrl 108;
    private _briefing = _display displayCtrl 102;
    private _activate = _display displayCtrl 103;
    private _regionIndex = lbCurSel _regionList;
    private _tierIndex = lbCurSel _tierList;
    private _region = if (_regionIndex >= 0) then {_regionList lbData _regionIndex} else {""};
    private _tier = if (_tierIndex >= 0) then {parseNumber (_tierList lbData _tierIndex)} else {0};
    private _costs = missionNamespace getVariable ["KPLIB_intelligence_tier_costs", [10, 25, 45]];
    private _cost = if (_tier >= 1 && {_tier <= count _costs}) then {_costs # (_tier - 1)} else {999999};
    private _activeTier = 0;
    private _activeForRegion = KPLIB_INTEL_CLIENT_COVERAGE select {(_x # 0) == _region};
    if (_activeForRegion isNotEqualTo []) then {_activeTier = (_activeForRegion # 0) # 1};

    (_display displayCtrl 107) ctrlSetText format ["SHARED INTEL RESERVE: %1", missionNamespace getVariable ["resources_intel", 0]];
    private _canActivate = _region != "" && {_tier > 0} && {_tier >= _activeTier} && {(missionNamespace getVariable ["resources_intel", 0]) >= _cost};
    _activate ctrlEnable _canActivate;
    private _tooltip = "Not enough intelligence in the shared reserve.";
    if (_tier < _activeTier) then {_tooltip = "Live coverage cannot be downgraded."};
    if (_canActivate) then {_tooltip = "Activate or renew this coverage tier."};
    _activate ctrlSetTooltip _tooltip;

    if (_region == "") exitWith {
        _briefing ctrlSetStructuredText parseText "<t size='1.2'>No OPFOR frontline regions are currently available for analysis.</t>";
    };

    private _regionData = KPLIB_INTEL_CLIENT_REGIONS select {(_x # 0) == _region};
    private _label = if (_regionData isEqualTo []) then {_region} else {(_regionData # 0) # 1};
    private _coverage = KPLIB_INTEL_CLIENT_COVERAGE select {(_x # 0) == _region};
    private _coverageText = "No active coverage";
    if (_coverage isNotEqualTo []) then {
        private _entry = _coverage # 0;
        private _minutes = ceil ((((_entry # 2) - CBA_missionTime) / 60) max 0);
        _coverageText = format ["Tier %1 active - approximately %2 minutes remaining", _entry # 1, _minutes];
    };

    private _tierText = switch (_tier) do {
        case 1: {"Activity: broad activity class and a large uncertainty area."};
        case 2: {"Tracking: operation type, phase, assessed destination, and strength band."};
        case 3: {"Identification: personnel and vehicle estimate plus sampled real movement route."};
        default {"Select a tier."};
    };
    private _reportText = "";
    private _regionReports = KPLIB_INTEL_CLIENT_REPORTS select {(_x # 3) == _region};
    {
        private _destination = _x # 7;
        if (_destination != "") then {
            private _destinationLabel = markerText _destination;
            if (_destinationLabel == "") then {_destinationLabel = _destination};
            _destination = format [" -> %1", _destinationLabel];
        };
        private _ageMinutes = floor (((CBA_missionTime - (_x # 6)) / 60) max 0);
        _reportText = _reportText + format ["<br/><t color='#ff9d76'>%1</t> | %2%3 | %4 | %5m old", _x # 1, _x # 2, _destination, _x # 9, _ageMinutes];
    } forEach _regionReports;
    if (_reportText == "") then {_reportText = "<br/><t color='#aaaaaa'>No current observations in this region.</t>"};

    _briefing ctrlSetStructuredText parseText format [
        "<t size='1.35' color='#7fc9ff'>%1</t><br/><br/>%2<br/><br/><t color='#e0c36d'>Selected Tier %3 (%4 intel)</t><br/>%5<br/><br/><t size='1.1'>CURRENT SITREP</t>%6",
        _label,
        _coverageText,
        _tier,
        _cost,
        _tierText,
        _reportText
    ];
    private _position = ctrlPosition _briefing;
    _position set [3, (ctrlTextHeight _briefing) max (0.48 * safezoneH)];
    _briefing ctrlSetPosition _position;
    _briefing ctrlCommit 0;
};

KPLIB_INTEL_CLIENT_OPEN_DIALOG = {
    if (!hasInterface || {!(missionNamespace getVariable ["KPLIB_intelligence_enabled", true])}) exitWith {};
    if (!isNull (uiNamespace getVariable ["KPLIB_INTEL_CLIENT_DISPLAY", displayNull])) exitWith {};
    private _parent = findDisplay 46;
    if (isNull _parent) exitWith {};
    private _display = _parent createDisplay "RscDisplayEmpty";
    uiNamespace setVariable ["KPLIB_INTEL_CLIENT_DISPLAY", _display];
    _display displayAddEventHandler ["Unload", {uiNamespace setVariable ["KPLIB_INTEL_CLIENT_DISPLAY", displayNull]}];

    private _background = _display ctrlCreate ["RscText", -1];
    _background ctrlSetPosition [0.14 * safezoneW + safezoneX, 0.14 * safezoneH + safezoneY, 0.72 * safezoneW, 0.72 * safezoneH];
    _background ctrlSetBackgroundColor [0.04, 0.06, 0.04, 0.96];
    _background ctrlCommit 0;

    private _header = _display ctrlCreate ["RscText", -1];
    _header ctrlSetPosition [0.14 * safezoneW + safezoneX, 0.14 * safezoneH + safezoneY, 0.72 * safezoneW, 0.05 * safezoneH];
    _header ctrlSetBackgroundColor [0.28, 0.19, 0.05, 1];
    _header ctrlSetText "INTELLIGENCE ANALYSIS";
    _header ctrlSetFontHeight 0.026 * safezoneH;
    _header ctrlCommit 0;

    private _regionLabel = _display ctrlCreate ["RscText", -1];
    _regionLabel ctrlSetPosition [0.16 * safezoneW + safezoneX, 0.21 * safezoneH + safezoneY, 0.22 * safezoneW, 0.03 * safezoneH];
    _regionLabel ctrlSetText "OPFOR FRONTLINE REGIONS";
    _regionLabel ctrlCommit 0;

    private _regionList = _display ctrlCreate ["RscListbox", 101];
    _regionList ctrlSetPosition [0.16 * safezoneW + safezoneX, 0.245 * safezoneH + safezoneY, 0.22 * safezoneW, 0.33 * safezoneH];
    _regionList ctrlSetBackgroundColor [0.08, 0.12, 0.08, 0.9];
    _regionList ctrlAddEventHandler ["LBSelChanged", {[] call KPLIB_INTEL_CLIENT_DIALOG_REFRESH}];
    _regionList ctrlCommit 0;

    private _tierLabel = _display ctrlCreate ["RscText", -1];
    _tierLabel ctrlSetPosition [0.16 * safezoneW + safezoneX, 0.59 * safezoneH + safezoneY, 0.22 * safezoneW, 0.03 * safezoneH];
    _tierLabel ctrlSetText "ANALYSIS TIER";
    _tierLabel ctrlCommit 0;

    private _tierList = _display ctrlCreate ["RscListbox", 108];
    _tierList ctrlSetPosition [0.16 * safezoneW + safezoneX, 0.625 * safezoneH + safezoneY, 0.22 * safezoneW, 0.13 * safezoneH];
    _tierList ctrlSetBackgroundColor [0.08, 0.12, 0.08, 0.9];
    _tierList ctrlAddEventHandler ["LBSelChanged", {[] call KPLIB_INTEL_CLIENT_DIALOG_REFRESH}];
    _tierList ctrlCommit 0;

    private _reserve = _display ctrlCreate ["RscText", 107];
    _reserve ctrlSetPosition [0.16 * safezoneW + safezoneX, 0.78 * safezoneH + safezoneY, 0.22 * safezoneW, 0.04 * safezoneH];
    _reserve ctrlSetTextColor [0.5, 0.79, 1, 1];
    _reserve ctrlCommit 0;

    private _briefing = _display ctrlCreate ["RscStructuredText", 102];
    _briefing ctrlSetPosition [0.40 * safezoneW + safezoneX, 0.22 * safezoneH + safezoneY, 0.44 * safezoneW, 0.54 * safezoneH];
    _briefing ctrlSetBackgroundColor [0.06, 0.09, 0.06, 0.9];
    _briefing ctrlCommit 0;

    private _activate = _display ctrlCreate ["RscButton", 103];
    _activate ctrlSetPosition [0.50 * safezoneW + safezoneX, 0.79 * safezoneH + safezoneY, 0.14 * safezoneW, 0.045 * safezoneH];
    _activate ctrlSetText "ACTIVATE COVERAGE";
    _activate ctrlAddEventHandler ["ButtonClick", {[] call KPLIB_INTEL_CLIENT_ACTIVATE_SELECTED}];
    _activate ctrlCommit 0;

    private _close = _display ctrlCreate ["RscButton", 104];
    _close ctrlSetPosition [0.65 * safezoneW + safezoneX, 0.79 * safezoneH + safezoneY, 0.10 * safezoneW, 0.045 * safezoneH];
    _close ctrlSetText "CLOSE";
    _close ctrlAddEventHandler ["ButtonClick", {(ctrlParent (_this # 0)) closeDisplay 1}];
    _close ctrlCommit 0;

    [_display] call KPLIB_INTEL_CLIENT_DIALOG_LOAD;
};

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
    if (_hudKey == KPLIB_INTEL_CLIENT_HUD_KEY) exitWith {};
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
    KPLIB_INTEL_CLIENT_HAS_SNAPSHOT = false;
    KPLIB_INTEL_CLIENT_HUD_KEY = "";
    uiNamespace setVariable ["KPLIB_INTEL_CLIENT_DISPLAY", displayNull];

    if (missionNamespace getVariable ["KPLIB_intelligence_enabled", true]) then {
        private _escortAction = [
            "KPLIB_INTEL_ESCORT",
            "Escort for debrief",
            "",
            {params ["_target", "_player"]; [_target] joinSilent group _player},
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
