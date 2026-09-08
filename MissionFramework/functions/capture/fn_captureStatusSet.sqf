/* Local server calls only. A sector and a FOB never share a display identity. */
if (!isServer || {isRemoteExecuted}) exitWith {false};
params [
    ["_kind", "", [""]],
    ["_target", "", ["", []]],
    ["_status", "", [""]],
    ["_remaining", 0, [0]]
];
if !(_kind in ["SECTOR", "FOB"] && {_status in ["CAPTURING", "CONTESTED", "STOPPED", "CAPTURED"]}) exitWith {false};
if (_kind == "SECTOR" && {!(_target isEqualType "") || {!(_target in allMapMarkers)}}) exitWith {false};
if (_kind == "FOB" && {!(_target isEqualType []) || {!(count _target in [2, 3])} || {_target findIf {!(_x isEqualType 0)} >= 0}}) exitWith {false};
private _entries = localNamespace getVariable ["KPLIB_captureStatusEntries", createHashMap];
private _key = format ["%1:%2", _kind, _target];
private _old = _entries getOrDefault [_key, []];
private _terminal = _status in ["STOPPED", "CAPTURED"];
// Do not expose cancelled pre-warning attacks or extend a repeated terminal event.
if (_terminal && {_old isEqualTo [] || {(_old select 3) == _status}}) exitWith {false};
private _position = if (_kind == "SECTOR") then {markerPos _target} else {+_target};
private _label = if (_old isNotEqualTo []) then {_old select 2} else {
    if (_kind == "SECTOR") then {markerText _target} else {[_target] call KPLIB_fnc_getFobName}
};
if (_label == "") then {_label = mapGridPosition _position};
if (_kind == "FOB" && {_old isEqualTo []}) then {_label = "FOB " + _label};
_entries set [_key, [
    _key, _position, _label, _status, ceil (_remaining max 0), CBA_missionTime,
    if (_terminal) then {CBA_missionTime + 15} else {-1}
]];
localNamespace setVariable ["KPLIB_captureStatusEntries", _entries];
true
