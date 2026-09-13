/* Pure schema validation. Values are data, never compiled SQF. The caller
   decides whether invalid author input falls back or rejects a packet. */
params ["_values"];
private _rows = localNamespace getVariable ["KPLIB_settingsCatalog", []];
if (!(_values isEqualType []) || {count _values != count _rows} || {_rows isEqualTo []}) exitWith {[false, [], ["Setting count mismatch"]]};
private _out = +_values;
private _errors = [];
{
    _x params ["_runtime", "_key", "_type", "_data", "_live", "_title", "_category", "_default"];
    private _value = _values select _forEachIndex;
    private _valid = switch (_type) do {
        case "CHECKBOX": {_value isEqualType true};
        case "SLIDER": {
            _value isEqualType 0 && {finite _value} && {_value >= _data select 0} && {_value <= _data select 1}
        };
        case "LIST": {_value in (_data select 0)};
        default {false};
    };
    if (!_valid) then {
        _errors pushBack _title;
        _out set [_forEachIndex, _default];
    } else {
        if (_type == "SLIDER" && {_data select 3 == 0} && {!(_data param [4, false])}) then {
            _out set [_forEachIndex, round _value];
        };
    };
} forEach _rows;
private _lookup = localNamespace getVariable "KPLIB_settingsLookup";
private _ordered = {
    params ["_low", "_high"];
    private _a = _lookup get _low;
    private _b = _lookup get _high;
    if ((_out select _a) > (_out select _b)) then {
        _errors pushBack ((_rows select _a) select 5);
        _out set [_a, (_rows select _a) select 7];
        _out set [_b, (_rows select _b) select 7];
    };
};
{
    [_x + "_0", _x + "_1"] call _ordered;
} forEach ["KP_liberation_sector_resource_crate_count", "KPLIB_radio_intercept_interval",
    "KPLIB_intelligence_informant_interval", "BATTLESPACE_STRATEGIC_DEEP_RECON_DURATION",
    "BATTLESPACE_OFFENSIVE_RESPONSE_RATIOS", "BATTLESPACE_OFFENSIVE_RETREAT_RATIO"];
["BATTLESPACE_ARTILLERY_MIN_COOLDOWN", "BATTLESPACE_ARTILLERY_MAX_COOLDOWN"] call _ordered;
["BATTLESPACE_STRATEGIC_RESERVE_MIN_FRONT_DEPTH", "BATTLESPACE_STRATEGIC_RESERVE_MAX_FRONT_DEPTH"] call _ordered;
[_errors isEqualTo [], _out, _errors]
