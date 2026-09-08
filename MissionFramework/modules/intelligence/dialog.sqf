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

KPLIB_INTEL_CLIENT_SELECT_FILE = {
    private _display = uiNamespace getVariable ["KPLIB_INTEL_CLIENT_DISPLAY", displayNull];
    if (isNull _display || {_display getVariable ["intelUpdating", false]}) exitWith {};
    private _list = _display displayCtrl 101;
    private _index = lbCurSel _list;
    private _rows = _display getVariable ["intelRows", []];
    private _text = format ["Capture enemy prisoners, escort them to a FOB or patrol base, then interrogate them. Sources reveal artillery, troop positions, fortifications and stock figures. Each ordinary source has a 20 percent chance to reveal a difficult operation. Its following stages are assigned automatically.<br/><br/>Capture radio towers intact to receive communications intercepts every %1-%2 minutes. Destroy an enemy-held tower to slow enemy coordination across the map for %3 minutes. Destroyed towers cannot provide intercepts.", round ((KPLIB_radio_intercept_interval # 0) / 60), round ((KPLIB_radio_intercept_interval # 1) / 60), round (KPLIB_radio_disruption_duration / 60)];
    private _position = [];
    KPLIB_INTEL_CLIENT_SELECTED_REPORT = "";
    if (_index >= 0 && {_index < count _rows}) then {
        (_rows # _index) params ["_type", "_row"];
        _display setVariable ["intelSelected", _row # 0];
        if (_type == "CASE") then {
            _row params ["_id", "_title", "_stage", "_status", "_pos", "_brief", "_effect", "_history", "_deadline"];
            _text = format ["<t size='1.2' color='#7fc9ff'>%1</t><br/>Stage %2 of 3 | %3<br/>%4<br/><br/>%5<br/><br/><t color='#e0c36d'>%6</t><br/><br/>%7",
                _title, _stage + 1, _status,
                if (_status in ["ACTIVE", "QUEUED"]) then {format ["Lead expires in %1 minutes", ceil (((_deadline - CBA_missionTime) max 0) / 60)]} else {"Operation closed"},
                [_brief] call KPLIB_INTEL_CLIENT_ESCAPE, [_effect] call KPLIB_INTEL_CLIENT_ESCAPE,
                (_history apply {[_x] call KPLIB_INTEL_CLIENT_ESCAPE}) joinString "<br/><br/>"];
            if (_status == "ACTIVE") then {_position = _pos};
        } else {
            KPLIB_INTEL_CLIENT_SELECTED_REPORT = _row # 0;
            private _meta = _row # 12;
            _text = format ["<t size='1.2' color='#7fc9ff'>%1</t><br/>Source information from %2 minutes ago<br/><br/>%3<br/><br/><t color='#e0c36d'>%4</t>",
                [_meta get "title"] call KPLIB_INTEL_CLIENT_ESCAPE, floor (((CBA_missionTime - (_row # 6)) max 0) / 60),
                ((_meta get "details") apply {[_x] call KPLIB_INTEL_CLIENT_ESCAPE}) joinString "<br/><br/>", [_meta get "window"] call KPLIB_INTEL_CLIENT_ESCAPE];
            if (_meta getOrDefault ["mapVisible", true]) then {_position = _row # 4};
        };
    };
    private _detail = _display displayCtrl 102;
    _detail ctrlSetStructuredText parseText _text;
    _detail ctrlSetPosition [0, 0, 0.53 * safezoneW, (ctrlTextHeight _detail + 0.03 * safezoneH) max (0.28 * safezoneH)];
    _detail ctrlCommit 0;
    if (_position isNotEqualTo []) then {
        private _map = _display displayCtrl 110;
        ctrlMapAnimClear _map;
        _map ctrlMapAnimAdd [0.2, 0.08, _position];
        ctrlMapAnimCommit _map;
    };
    call KPLIB_INTEL_CLIENT_RENDER_MARKERS;
};

KPLIB_INTEL_CLIENT_DIALOG_REFRESH = {
    private _display = uiNamespace getVariable ["KPLIB_INTEL_CLIENT_DISPLAY", displayNull];
    if (isNull _display) exitWith {};
    _display setVariable ["intelUpdating", true];
    private _list = _display displayCtrl 101;
    private _selected = _display getVariable ["intelSelected", ""];
    private _selection = 0;
    private _rows = [];
    lbClear _list;
    {
        private _row = _list lbAdd format ["%1 | %2 | Stage %3", _x # 3, _x # 1, 1 + (_x # 2)];
        _rows pushBack ["CASE", _x];
        if ((_x # 0) == _selected) then {_selection = _row};
    } forEach KPLIB_INTEL_CLIENT_CASES;
    {
        private _row = _list lbAdd format ["REPORT | %1", (_x # 12) get "title"];
        _rows pushBack ["REPORT", _x];
        if ((_x # 0) == _selected) then {_selection = _row};
    } forEach KPLIB_INTEL_CLIENT_REPORTS;
    _display setVariable ["intelRows", _rows];
    _list lbSetCurSel ([-1, _selection] select (_rows isNotEqualTo []));
    (_display displayCtrl 107) ctrlSetText format ["%1 prisoners awaiting interrogation at FOBs / patrol bases", KPLIB_INTEL_CLIENT_DETAINEES];
    _display setVariable ["intelUpdating", false];
    call KPLIB_INTEL_CLIENT_SELECT_FILE;
};
KPLIB_INTEL_CLIENT_DIALOG_LOAD = {call KPLIB_INTEL_CLIENT_DIALOG_REFRESH};

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
        _control ctrlSetText _text;
        _control ctrlCommit 0;
        _control
    };
    private _background = ["RscText", -1, [0.05, 0.06, 0.90, 0.88]] call _create;
    _background ctrlSetBackgroundColor [0.035, 0.05, 0.04, 0.98];
    ["RscText", -1, [0.07, 0.075, 0.79, 0.05], "INTELLIGENCE CASE FILES"] call _create;
    ["RscText", 107, [0.07, 0.13, 0.86, 0.035]] call _create;
    private _list = ["RscListbox", 101, [0.07, 0.18, 0.30, 0.71]] call _create;
    _list ctrlAddEventHandler ["LBSelChanged", {call KPLIB_INTEL_CLIENT_SELECT_FILE}];
    ["RscMapControl", 110, [0.39, 0.18, 0.54, 0.38]] call _create;
    private _scroll = ["RscControlsGroup", 111, [0.39, 0.58, 0.54, 0.31]] call _create;
    private _detail = _display ctrlCreate ["RscStructuredText", 102, _scroll];
    _detail ctrlSetPosition [0, 0, 0.53 * safezoneW, 0.29 * safezoneH];
    _detail ctrlCommit 0;
    private _close = ["RscButton", 104, [0.86, 0.08, 0.07, 0.04], "Close"] call _create;
    _close ctrlAddEventHandler ["ButtonClick", {(ctrlParent (_this # 0)) closeDisplay 2}];
    call KPLIB_INTEL_CLIENT_DIALOG_REFRESH;
    [] remoteExecCall ["KPLIB_INTEL_SERVER_REQUEST_SYNC", 2];
};
