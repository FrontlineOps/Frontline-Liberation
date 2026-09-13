/* Progressive solver snapshots, then a labelled two-second visibility replay. */
if (!hasInterface || {isNull curatorCamera} || {isNull getAssignedCuratorLogic player}) exitWith {""};
params ["_field", "_elapsed", ["_refresh", true]];
_field params ["_id", "_ammo", "_thermal", "_radius", "_duration", "_cell", "_nodes", "_truncated", "_backend", "_frames"];
private _complete = _truncated || {(_field select 11) find "Completed" == 0};
private _cache = uiNamespace getVariable ["KPLIB_gasDrawCache", createHashMap];
private _entry = _cache getOrDefault [_id, []];
if (_refresh || {_entry isEqualTo []}) then {
    private _state = if (_complete) then {[_frames, _elapsed, 2] call KPLIB_fnc_gasFrame} else {_frames param [(count _frames - 1) max 0, [0,[]]]};
    _state params ["_time", "_samples"];
    private _draw = [];
    private _selected = -1;
    private _best = 0.001;
    private _mouse = getMousePosition;
    {
        private _position = ASLToAGL (_x select 0);
        private _screen = worldToScreen _position;
        private _index = _forEachIndex;
        if (count _screen == 2 && {((_x select 0) select 2) >= getTerrainHeightASL (_x select 0)}) then {
            private _distance = ((_screen select 0) - (_mouse select 0))^2 + ((_screen select 1) - (_mouse select 1))^2;
            if (_distance < _best) then {_best = _distance; _selected = _index};
            private _sample = _samples param [_index, [0,294.2,0,0]];
            private _color = [_sample,_thermal,true] call KPLIB_fnc_gasColor;
            _draw pushBack [_position, _color, _index];
        };
    } forEach _nodes;
    private _text = "";
    if (_selected >= 0) then {
        private _status = if (_complete) then {"2 s replay"} else {"LIVE solver snapshot"};
        if (_frames isEqualTo []) then {_status = "Waiting for gas samples"};
        if (_backend != "GAS") then {_status = "LEGACY fallback: gas samples unavailable"};
        if (_truncated) then {_status = _status + " / TRUNCATED"};
        private _sample = _samples param [_selected, []];
        private _values = "";
        if (_sample isNotEqualTo []) then {
            _sample params ["_pressure", "_temperature", "_tracer", "_impulse"];
            _values = format ["dP %1 Pa | I+ %2 Pa s | T %3 K | tracer %4", _pressure toFixed 1, _impulse toFixed 2, _temperature toFixed 1, _tracer toFixed 3];
        };
        private _info = _field param [12,[7,2,[]]];
        _text = [
            format ["%1 | %2 | t=%3 s | probe %4", _ammo, _status, _time toFixed 3, _selected],
            _values,
            format ["%1 fixed probes (underground hidden) / %2 cells | spacing %3 m | GAME INPUT | full report in RPT", count _nodes, (_info select 0)^3, _cell toFixed 2]
        ] joinString toString [10];
    };
    _entry = [_draw, _selected, _text];
    _cache set [_id, _entry];
    private _ids = (uiNamespace getVariable ["KPLIB_munitionsLiveFields", []]) apply {(_x select 0) select 0};
    {if !(_x in _ids) then {_cache deleteAt _x}} forEach keys _cache;
    uiNamespace setVariable ["KPLIB_gasDrawCache", _cache];
};
_entry params ["_draw", "_selected", "_text"];
{
    _x params ["_position", "_color", "_index"];
    if (_index == _selected) then {_color = [1,1,1,1]};
    drawIcon3D ["\a3\ui_f\data\map\markers\military\dot_CA.paa", [0,0,0,0.95], _position, 1.05, 1.05, 0, "", 0];
    drawIcon3D ["\a3\ui_f\data\map\markers\military\dot_CA.paa", _color, _position, 0.8, 0.8, 0, "", 0];
} forEach _draw;
_text
