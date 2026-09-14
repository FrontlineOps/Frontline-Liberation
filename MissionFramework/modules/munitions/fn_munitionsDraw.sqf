if (!hasInterface || {isNull curatorCamera} || {isNull getAssignedCuratorLogic player}) exitWith {};
if (!(uiNamespace getVariable ["KPLIB_munitionsDebug", false])) exitWith {
    ["KPLIB_traceHud", "", 0.75, 0.14] call KPLIB_fnc_munitionsHud;
    ["KPLIB_gasHud", "", 0.06, 0.22] call KPLIB_fnc_munitionsHud;
};
private _refresh = diag_tickTime >= (uiNamespace getVariable ["KPLIB_munitionsPickAt", -1]);
if (_refresh) then {uiNamespace setVariable ["KPLIB_munitionsPickAt", diag_tickTime + 0.1]};
private _lines = uiNamespace getVariable ["KPLIB_munitionsLines", []];
private _tags = uiNamespace getVariable ["KPLIB_munitionsTags", []];
private _colors = [[0,1,1,1],[1,0.2,1,1],[1,1,0,1],[0.1,1,0.2,1]];
private _best = 0.0016;
private _label = "Hover a path or probe for details. Full diagnostics: RPT [FL MUNITIONS].";
private _mouse = getMousePosition;
// Cache coordinate/color conversion; completed flight history is static.
private _input = [_lines, _tags];
private _render = uiNamespace getVariable ["KPLIB_munitionsRenderCache", []];
if (_input isNotEqualTo (uiNamespace getVariable ["KPLIB_munitionsRenderInput", []])) then {
    _render = [];
    {
        private _tag = if (_forEachIndex < count _tags) then {_tags select _forEachIndex} else {["UNKNOWN","Unclassified observation"]};
        _tag params ["_kind", "_name"];
        private _index = ["PROJECTILE","CHILD","FRAGMENT","GEOMETRY"] find _kind;
        private _color = if (_index < 0) then {[1,1,1,1]} else {_colors select _index};
        private _a = ASLToAGL (_x select 0);
        private _b = ASLToAGL (_x select 1);
        private _shadow = if (_kind == "FRAGMENT") then {[]} else {[_a,_b,[0,0,0,0.9],7]};
        _render pushBack [[_a,_b,_color,4], _shadow, _name];
    } forEach _lines;
    uiNamespace setVariable ["KPLIB_munitionsRenderInput", _input];
    uiNamespace setVariable ["KPLIB_munitionsRenderCache", _render];
};
{
    _x params ["_stroke", "_shadow", "_name"];
    if (_shadow isNotEqualTo []) then {drawLine3D _shadow};
    drawLine3D _stroke;
    if (_refresh) then {
        private _screen = worldToScreen (_stroke select 1);
        if (count _screen == 2) then {
            private _distance = ((_screen select 0) - (_mouse select 0))^2 + ((_screen select 1) - (_mouse select 1))^2;
            if (_distance < _best) then {
                _best = _distance;
                _label = _name + " | observed trajectory samples";
            };
        };
    };
} forEach _render;
// Owner-local tips follow actual visual positions each frame, with no forecast.
{
    _x params ["_projectile", "_from", "_kind"];
    if (!isNull _projectile && {local _projectile}) then {
        private _index = (["PROJECTILE","CHILD","FRAGMENT"] find _kind) max 0;
        private _to = ASLToAGL getPosASLVisual _projectile;
        drawLine3D [ASLToAGL _from, _to, [0,0,0,0.9], 7];
        drawLine3D [ASLToAGL _from, _to, _colors select _index, 4];
    };
} forEach (uiNamespace getVariable ["KPLIB_munitionsLiveHeads", []]);
private _fields = uiNamespace getVariable ["KPLIB_munitionsLiveFields", []];
private _hover = "";
{
    _x params ["_field", "_first", "_updated"];
    private _text = [_field, diag_tickTime - _updated, _refresh] call KPLIB_fnc_gasDraw;
    if (_text != "") then {_hover = _text};
} forEach _fields;
if (_refresh) then {
    private _stats = uiNamespace getVariable ["KPLIB_munitionsStats", [0,0,0,0,0,0,0,0,0,0,0,0,0]];
    private _omitted = (_stats select 12) + (uiNamespace getVariable ["KPLIB_munitionsClientOmitted", 0]);
    private _captured = (_stats select 5) + (_stats select 6) + (_stats select 7);
    private _displayed = uiNamespace getVariable ["KPLIB_munitionsDisplayedPaths", 0];
    private _text = [
        format ["VISUAL DEBUG ON | %1 paths | %2 recent explosions | cyan projectile / magenta child / yellow fragment", _displayed, count _fields],
        format ["Captured %1 | not displayed %2 | unrecorded %3 | simplified/omitted segments %4", _captured, (_captured - _displayed) max 0, (_stats select 2) + (_stats select 3), _omitted],
        "Paths: observed start to latest/end, sampled detail. 20 s history, eight bursts/owner. Dots: red +pressure / blue -pressure / orange heat / gray ambient.",
        _label
    ] joinString toString [10];
    ["KPLIB_traceHud", _text, 0.77, 0.16] call KPLIB_fnc_munitionsHud;
    ["KPLIB_gasHud", _hover, 0.06, 0.16] call KPLIB_fnc_munitionsHud;
};
