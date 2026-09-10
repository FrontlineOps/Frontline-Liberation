/* Client-only intelligence presentation on the ordinary map. No separate display.
   Hover reads a dated marker; an unmodified left click selects its recorded route. */
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

KPLIB_INTEL_CLIENT_REPORT_TEXT = {
    params ["_report"];
    private _meta = _report # 12;
    if (_meta getOrDefault ["operation", false]) exitWith {
        private _remaining = ceil (((_meta get "deadline") - CBA_missionTime) max 0) / 60;
        ([_meta get "title", format ["%1 | %2 min remaining", _report # 2, ceil _remaining]]
            + (_meta get "details")) joinString "\n"
    };
    private _age = floor (((CBA_missionTime - (_report # 6)) max 0) / 60);
    private _lines = [_meta getOrDefault ["title", _report # 1], format ["Recorded %1 min ago | %2", _age, _report # 2],
        _meta getOrDefault ["confidence", "Dated source report"]];
    _lines append (_meta getOrDefault ["details", []]);
    _lines pushBack (_meta getOrDefault ["window", "Reconnoitre to confirm current conditions."]);
    if ((_report # 10) isNotEqualTo []) then {_lines pushBack "Click this marker to show its recorded route. Click again to clear."};
    _lines joinString "\n"
};

KPLIB_INTEL_CLIENT_MAP_HITS = {
    params ["_map", "_mouse"];
    private _hits = [];
    {
        private _screen = _map ctrlMapWorldToScreen (_x # 4);
        if (count _screen == 2 && {abs ((_screen # 0) - (_mouse # 0)) <= 18 * pixelW}
            && {abs ((_screen # 1) - (_mouse # 1)) <= 18 * pixelH}) then {
            _hits pushBack _x;
        };
    } forEach (missionNamespace getVariable ["KPLIB_INTEL_CLIENT_MAP_REPORTS", []]);
    _hits
};

KPLIB_INTEL_CLIENT_MAP_TICK = {
    if (!hasInterface || {!visibleMap}) exitWith {};
    private _map = (findDisplay 12) displayCtrl 51;
    if (isNull _map) exitWith {};
    if !(_map getVariable ["KPLIB_intelMapReady", false]) then {
        _map setVariable ["KPLIB_intelMapReady", true];
        _map ctrlSetTooltipMaxWidth (safeZoneW * 0.42);
        _map ctrlAddEventHandler ["MouseButtonDown", {
            params ["_map", "_button", "_x", "_y"];
            if (_button == 0) then {_map setVariable ["KPLIB_intelMouseDown", [_x, _y]]};
            false
        }];
        _map ctrlAddEventHandler ["MouseButtonUp", {
            params ["_map", "_button", "_x", "_y", "_shift", "_ctrl", "_alt"];
            if (_button != 0 || {_shift || {_ctrl || {_alt}}}) exitWith {false};
            private _start = _map getVariable ["KPLIB_intelMouseDown", [_x, _y]];
            if (abs (_x - (_start # 0)) > 4 * pixelW || {abs (_y - (_start # 1)) > 4 * pixelH}) exitWith {false};
            private _hits = [_map, [_x, _y]] call KPLIB_INTEL_CLIENT_MAP_HITS;
            if (_hits isEqualTo []) exitWith {false};
            private _ids = _hits apply {_x # 0};
            private _index = _ids find KPLIB_INTEL_CLIENT_SELECTED_REPORT;
            KPLIB_INTEL_CLIENT_SELECTED_REPORT = _ids param [_index + 1, ""];
            call KPLIB_INTEL_CLIENT_RENDER_MARKERS;
            false
        }];
    };
    private _minute = floor (CBA_missionTime / 60);
    if (_minute != (missionNamespace getVariable ["KPLIB_INTEL_CLIENT_MAP_MINUTE", -1])) then {
        KPLIB_INTEL_CLIENT_MAP_MINUTE = _minute;
        call KPLIB_INTEL_CLIENT_RENDER_MARKERS;
    };
    private _hits = [_map, getMousePosition] call KPLIB_INTEL_CLIENT_MAP_HITS;
    private _text = "";
    if (_hits isNotEqualTo []) then {
        private _selected = _hits findIf {(_x # 0) == KPLIB_INTEL_CLIENT_SELECTED_REPORT};
        _text = [_hits # (_selected max 0)] call KPLIB_INTEL_CLIENT_REPORT_TEXT;
        if (count _hits > 1) then {_text = _text + format ["\n\n%1 reports at this marker. Click to cycle through them.", count _hits]};
    };
    if (_text != (_map getVariable ["KPLIB_intelTooltip", ""])) then {
        _map setVariable ["KPLIB_intelTooltip", _text];
        _map ctrlSetTooltip _text;
    };
};
