KPLIB_INTEL_CLIENT_ESCAPE = {
    params ["_text"];
    private _result = "";
    {
        _result = _result + (switch (_x) do {
            case 38: {"&amp;"};
            case 60: {"&lt;"};
            case 62: {"&gt;"};
            default {toString [_x]};
        });
    } forEach toArray _text;
    _result
};

KPLIB_INTEL_CLIENT_SELECT_REPORT = {
    private _display = uiNamespace getVariable ["KPLIB_INTEL_CLIENT_DISPLAY", displayNull];
    if (isNull _display || {_display getVariable ["intelUpdating", false]}) exitWith {};
    private _list = _display displayCtrl 109;
    private _id = _list lbData (lbCurSel _list);
    private _found = KPLIB_INTEL_CLIENT_REPORTS select {(_x # 0) == _id};
    private _detail = _display displayCtrl 102;
    if (_found isEqualTo []) exitWith {
        KPLIB_INTEL_CLIENT_SELECTED_REPORT = "";
        _detail ctrlSetStructuredText parseText "No reports in this view. Select a frontline region to activate assessment, or recover documents and prisoners for leads.";
        call KPLIB_INTEL_CLIENT_RENDER_MARKERS;
    };
    private _report = _found # 0;
    private _changed = KPLIB_INTEL_CLIENT_SELECTED_REPORT != _id;
    KPLIB_INTEL_CLIENT_SELECTED_REPORT = _id;
    private _meta = _report # 12;
    private _age = floor ((CBA_missionTime - (_report # 6)) max 0);
    private _lines = (_meta get "details") apply {[_x] call KPLIB_INTEL_CLIENT_ESCAPE};
    private _window = [_meta get "window"] call KPLIB_INTEL_CLIENT_ESCAPE;
    _detail ctrlSetStructuredText parseText format [
        "<t size='1.15' color='#7fc9ff'>%1</t><br/>%2 | %3 | %4<br/>Last observed %5m %6s ago | %7<br/><br/>%8<br/><br/><t color='#e0c36d'>%9</t>",
        [_meta get "title"] call KPLIB_INTEL_CLIENT_ESCAPE, _meta get "status", _report # 2, _report # 9,
        floor (_age / 60), _age mod 60, _meta get "confidence", _lines joinString "<br/><br/>", _window
    ];
    private _position = ctrlPosition _detail;
    _position set [3, (ctrlTextHeight _detail + 0.02 * safezoneH) max (0.21 * safezoneH)];
    _detail ctrlSetPosition _position;
    _detail ctrlCommit 0;
    if (_changed) then {
        private _map = _display displayCtrl 110;
        ctrlMapAnimClear _map;
        _map ctrlMapAnimAdd [0.3, 0.12, _report # 4];
        ctrlMapAnimCommit _map;
        call KPLIB_INTEL_CLIENT_RENDER_MARKERS;
    };
};

KPLIB_INTEL_CLIENT_DIALOG_REFRESH = {
    private _display = uiNamespace getVariable ["KPLIB_INTEL_CLIENT_DISPLAY", displayNull];
    if (isNull _display || {_display getVariable ["intelUpdating", false]}) exitWith {};
    _display setVariable ["intelUpdating", true];
    private _regions = _display displayCtrl 101;
    private _region = _regions lbData (lbCurSel _regions);
    private _tiers = _display displayCtrl 108;
    private _tier = (lbCurSel _tiers) + 1;
    private _active = KPLIB_INTEL_CLIENT_COVERAGE select {(_x # 0) == _region};
    private _activeTier = if (_active isEqualTo []) then {0} else {(_active # 0) # 1};
    private _cost = KPLIB_intelligence_tier_costs param [_tier - 1, 99999];
    private _eligible = KPLIB_INTEL_CLIENT_REGIONS findIf {(_x # 0) == _region} >= 0;
    private _permitted = [player, "INTELLIGENCE"] call KPLIB_fnc_hasPermission;
    private _nearTerminal = player distance2D (markerPos "startbase_marker") <= KPLIB_intelligence_terminal_distance
        || {(missionNamespace getVariable ["GRLIB_all_fobs", []]) findIf {player distance2D _x <= KPLIB_intelligence_terminal_distance} >= 0};
    private _button = _display displayCtrl 103;
    _button ctrlEnable (_permitted && {_nearTerminal} && {_eligible} && {_tier >= _activeTier} && {resources_intel >= _cost});
    _button ctrlSetTooltip format ["Spend the displayed full tier cost for %1 minutes; upgrades also charge the full cost.", ceil (KPLIB_intelligence_coverage_duration / 60)];
    if (resources_intel < _cost) then {_button ctrlSetTooltip "Not enough intelligence in the shared reserve."};
    if (_tier < _activeTier) then {_button ctrlSetTooltip "Select the active tier or higher; live coverage cannot be downgraded."};
    if (!_eligible) then {_button ctrlSetTooltip "Select an eligible frontline region to purchase analysis."};
    if (!_nearTerminal) then {_button ctrlSetTooltip "Reports can be read here. Return to the start base or a FOB to purchase analysis."};
    if (!_permitted) then {_button ctrlSetTooltip "An admin must grant intelligence spending permission."};
    (_display displayCtrl 107) ctrlSetText format ["SHARED RESERVE: %1 INTEL", resources_intel];
    private _coverageText = "No active coverage for this selection.";
    if (_active isNotEqualTo []) then {
        _coverageText = format ["T%1 active: %2m remaining.", _activeTier, ceil ((((_active # 0) # 2) - CBA_missionTime) / 60 max 0)];
    };
    private _tierDescription = [
        "Sector strengths, reported vehicles, defensive roles and changes in activity.",
        "Assessment plus moving forces, current legs, likely objectives and movement corridors.",
        "Movement plus vehicle identification, surviving cargo, support links and conditional opportunities."
    ] param [_tier - 1, "Select a tier."];
    (_display displayCtrl 112) ctrlSetStructuredText parseText format ["%1<br/><br/><t color='#e0c36d'>Selected tier %2: %3 intel</t><br/>%4", _coverageText, _tier, _cost, _tierDescription];
    private _reports = KPLIB_INTEL_CLIENT_REPORTS select {
        private _meta = _x # 12;
        _region == "__ALL"
            || {_region == "__LEADS" && {(_meta get "status") == "RECOVERED LEAD"}}
            || {_region in (_meta get "regions")}
    };
    private _list = _display displayCtrl 109;
    lbClear _list;
    private _selection = 0;
    {
        private _meta = _x # 12;
        private _row = _list lbAdd format ["%1 | %2 | %3", _meta get "status", _meta get "title", _x # 9];
        _list lbSetData [_row, _x # 0];
        _list lbSetTooltip [_row, format ["Observed %1m ago. Select to focus the map and read the assessment.", floor (((CBA_missionTime - (_x # 6)) max 0) / 60)]];
        if ((_x # 0) == KPLIB_INTEL_CLIENT_SELECTED_REPORT) then {_selection = _row};
    } forEach _reports;
    _list lbSetCurSel ([ -1, _selection] select (_reports isNotEqualTo []));
    (_display displayCtrl 113) ctrlSetText format ["%1 REPORTS - HIGHEST PRIORITY FIRST", count _reports];
    _display setVariable ["intelUpdating", false];
    call KPLIB_INTEL_CLIENT_SELECT_REPORT;
};

KPLIB_INTEL_CLIENT_DIALOG_LOAD = {
    params ["_display"];
    if (isNull _display) exitWith {};
    _display setVariable ["intelUpdating", true];
    private _list = _display displayCtrl 101;
    private _previous = _list lbData (lbCurSel _list);
    if (_previous == "") then {_previous = "__ALL"};
    lbClear _list;
    private _rows = [["__ALL", "Priority overview", -1], ["__LEADS", "Recovered leads", -1]] + KPLIB_INTEL_CLIENT_REGIONS;
    {
        private _sector = _x # 0;
        if (_rows findIf {(_x # 0) == _sector} < 0) then {_rows pushBack [_sector, markerText _sector, -1]};
    } forEach KPLIB_INTEL_CLIENT_COVERAGE;
    private _selected = 0;
    {
        private _sector = _x # 0;
        private _active = KPLIB_INTEL_CLIENT_COVERAGE select {(_x # 0) == _sector};
        private _suffix = if (_active isEqualTo []) then {""} else {format [" [T%1]", (_active # 0) # 1]};
        private _row = _list lbAdd ((_x # 1) + _suffix);
        _list lbSetData [_row, _sector];
        if (_sector == _previous) then {_selected = _row};
    } forEach _rows;
    _list lbSetCurSel _selected;
    private _tiers = _display displayCtrl 108;
    if (lbSize _tiers == 0) then {
        {
            private _row = _tiers lbAdd format ["T%1 %2 - %3", _forEachIndex + 1, _x, KPLIB_intelligence_tier_costs # _forEachIndex];
            _tiers lbSetData [_row, str (_forEachIndex + 1)];
        } forEach ["Assessment", "Movement", "Opportunities"];
        _tiers lbSetCurSel 0;
    };
    _display setVariable ["intelUpdating", false];
    call KPLIB_INTEL_CLIENT_DIALOG_REFRESH;
};

KPLIB_INTEL_CLIENT_OPEN_DIALOG = {
    if (!hasInterface || {!KPLIB_intelligence_enabled}) exitWith {};
    if (!isNull (uiNamespace getVariable ["KPLIB_INTEL_CLIENT_DISPLAY", displayNull])) exitWith {};
    private _parent = findDisplay 46;
    if (isNull _parent) exitWith {};
    private _display = _parent createDisplay "RscDisplayEmpty";
    uiNamespace setVariable ["KPLIB_INTEL_CLIENT_DISPLAY", _display];
    _display displayAddEventHandler ["Unload", {uiNamespace setVariable ["KPLIB_INTEL_CLIENT_DISPLAY", displayNull]}];
    private _create = {
        params ["_class", "_id", "_position", ["_text", ""]];
        private _control = _display ctrlCreate [_class, _id];
        _position params ["_x", "_y", "_w", "_h"];
        _control ctrlSetPosition [safezoneX + _x * safezoneW, safezoneY + _y * safezoneH, _w * safezoneW, _h * safezoneH];
        if (_text != "") then {_control ctrlSetText _text};
        _control ctrlCommit 0;
        _control
    };
    private _background = ["RscText", -1, [0.05, 0.06, 0.90, 0.88]] call _create;
    _background ctrlSetBackgroundColor [0.035, 0.05, 0.04, 0.98];
    private _header = ["RscText", -1, [0.05, 0.06, 0.90, 0.055], "INTELLIGENCE ANALYSIS"] call _create;
    _header ctrlSetBackgroundColor [0.28, 0.19, 0.05, 1];
    private _regions = ["RscListbox", 101, [0.07, 0.14, 0.23, 0.30]] call _create;
    _regions ctrlAddEventHandler ["LBSelChanged", {
        params ["_control", "_index"];
        private _display = ctrlParent _control;
        if (_display getVariable ["intelUpdating", false]) exitWith {};
        private _region = _control lbData _index;
        private _active = KPLIB_INTEL_CLIENT_COVERAGE select {(_x # 0) == _region};
        if (_active isNotEqualTo []) then {(_display displayCtrl 108) lbSetCurSel (((_active # 0) # 1) - 1)};
        call KPLIB_INTEL_CLIENT_DIALOG_REFRESH;
    }];
    private _tiers = ["RscListbox", 108, [0.07, 0.46, 0.23, 0.13]] call _create;
    _tiers ctrlAddEventHandler ["LBSelChanged", {call KPLIB_INTEL_CLIENT_DIALOG_REFRESH}];
    ["RscStructuredText", 112, [0.07, 0.61, 0.23, 0.24]] call _create;
    ["RscMapControl", 110, [0.32, 0.14, 0.61, 0.27]] call _create;
    ["RscText", 113, [0.32, 0.415, 0.61, 0.025]] call _create;
    private _reports = ["RscListbox", 109, [0.32, 0.445, 0.61, 0.15]] call _create;
    _reports ctrlAddEventHandler ["LBSelChanged", {call KPLIB_INTEL_CLIENT_SELECT_REPORT}];
    private _scroll = ["RscControlsGroupNoHScrollbars", 111, [0.32, 0.615, 0.61, 0.235]] call _create;
    private _detail = _display ctrlCreate ["RscStructuredText", 102, _scroll];
    _detail ctrlSetPosition [0, 0, 0.59 * safezoneW, 0.23 * safezoneH];
    _detail ctrlCommit 0;
    ["RscText", 107, [0.07, 0.87, 0.25, 0.035]] call _create;
    private _activate = ["RscButton", 103, [0.49, 0.87, 0.25, 0.045], "ACTIVATE / RENEW COVERAGE"] call _create;
    _activate ctrlAddEventHandler ["ButtonClick", {call KPLIB_INTEL_CLIENT_ACTIVATE_SELECTED}];
    private _close = ["RscButton", 104, [0.77, 0.87, 0.16, 0.045], "CLOSE"] call _create;
    _close ctrlAddEventHandler ["ButtonClick", {(ctrlParent (_this # 0)) closeDisplay 1}];
    // Reopening should focus even if the selected identity survived the prior display.
    KPLIB_INTEL_CLIENT_SELECTED_REPORT = "";
    [_display] call KPLIB_INTEL_CLIENT_DIALOG_LOAD;
    [{
        params ["_args", "_handle"];
        _args params ["_display"];
        if (isNull _display) exitWith {[_handle] call CBA_fnc_removePerFrameHandler};
        [_display] call KPLIB_INTEL_CLIENT_DIALOG_LOAD;
    }, 10, [_display]] call CBA_fnc_addPerFrameHandler;
};
