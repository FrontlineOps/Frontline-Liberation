params [["_from", [], [[]]], ["_to", [], [[]]], ["_ignoreA", objNull, [objNull]], ["_ignoreB", objNull, [objNull]]];
if (count _from != 3 || {count _to != 3} || {(_from + _to) findIf {!(_x isEqualType 0) || {!finite _x}} >= 0}) exitWith {false};
if (terrainIntersectASL [_from, _to]) exitWith {false};
private _length = _from vectorDistance _to;
if (_length > 20000) exitWith {false};
// Retain the intact native ray: splitting alone can miss otherwise visible geometry.
// Native range is limited, so long clear rays additionally check bounded sections.
private _visible = (lineIntersectsSurfaces [_from, _to, _ignoreA, _ignoreB, true, 1, "VIEW", "GEOM"]) isEqualTo [];
if (_visible && {_length > 4500}) then {
    private _segments = ceil (_length / 4500);
    private _step = (_to vectorDiff _from) vectorMultiply (1 / _segments);
    private _start = +_from;
    for "_i" from 1 to _segments do {
        private _end = if (_i == _segments) then {_to} else {_from vectorAdd (_step vectorMultiply _i)};
        if ((lineIntersectsSurfaces [_start, _end, _ignoreA, _ignoreB, true, 1, "VIEW", "GEOM"]) isNotEqualTo []) exitWith {_visible = false};
        _start = _end;
    };
};
private _metrics = localNamespace getVariable ["KPLIB_guidanceMetrics", createHashMap];
_metrics set ["sightChecks", (_metrics getOrDefault ["sightChecks", 0]) + 1];
_visible
