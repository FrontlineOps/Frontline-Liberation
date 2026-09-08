/* Local presentation only: neither predicts progress nor changes capture state. */
if (!hasInterface) exitWith {};
private _markers = uiNamespace getVariable ["KPLIB_captureStatusMarkers", createHashMap];
private _rows = uiNamespace getVariable ["KPLIB_captureStatusRows", []];
private _stale = diag_tickTime - (uiNamespace getVariable ["KPLIB_captureStatusReceivedAt", diag_tickTime]) > 10;
private _keep = [];
private _ordered = [];
{
    _x params ["_key", "_position", "_label", "_status", "_remaining"];
    private _active = _status in ["CAPTURING", "CONTESTED", "UPDATING"];
    if (_stale && {_active}) then {_status = "UPDATING"};
    private _text = [_status, _remaining] call KPLIB_fnc_captureStatusText;
    private _marker = _markers getOrDefault [_key, ""];
    if (_marker == "" || {!(_marker in allMapMarkers)}) then {
        private _serial = 1 + (uiNamespace getVariable ["KPLIB_captureStatusMarkerSerial", 0]);
        uiNamespace setVariable ["KPLIB_captureStatusMarkerSerial", _serial];
        _marker = createMarkerLocal [format ["KPLIB_capture_%1", _serial], _position];
        _marker setMarkerTypeLocal "mil_objective";
        _markers set [_key, _marker];
    };
    _marker setMarkerPosLocal _position;
    _marker setMarkerColorLocal (switch (_status) do {
        case "CONTESTED": {"ColorYellow"};
        case "UPDATING": {"ColorYellow"};
        case "STOPPED": {"ColorGreen"};
        default {GRLIB_color_enemy_bright};
    });
    _marker setMarkerTextLocal format ["%1: %2", _label, _text];
    _keep pushBack _key;
    _ordered pushBack [[1, 0] select _active, _remaining, _key, _label, _text];
} forEach _rows;
{
    if !(_x in _keep) then {
        deleteMarkerLocal (_markers get _x);
        _markers deleteAt _x;
    };
} forEach (keys _markers);
uiNamespace setVariable ["KPLIB_captureStatusMarkers", _markers];
_ordered sort true;
private _lines = [];
{
    private _label = _x select 3;
    if (count _label > 38) then {_label = (_label select [0, 35]) + "..."};
    _lines pushBack _label;
    _lines pushBack (_x select 4);
} forEach (_ordered select [0, 3]);
if (count _ordered > 3) then {_lines pushBack format ["+%1 more on map", count _ordered - 3]};
uiNamespace setVariable ["KPLIB_captureStatusHud", _lines joinString (toString [10])];
