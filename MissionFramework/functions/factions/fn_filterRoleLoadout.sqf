/* Pure loadout filter; preserves allowed quantities, ammunition and radio instance IDs. */
params ["_loadout", "_allowed", ["_starter", []]];
private _clean = parseSimpleArray str _loadout;
private _removed = [];
private _allowedKeys = createHashMapFromArray (_allowed apply {[[ _x ] call KPLIB_fnc_normalizeGearClass, true]});
private _accept = {
    params ["_class"];
    if (_class == "") exitWith {true};
    if (([_class] call KPLIB_fnc_normalizeGearClass) in _allowedKeys) exitWith {true};
    _removed pushBackUnique _class;
    false
};
{
    private _weapon = _clean param [_x, []];
    if (_weapon isEqualTo []) then {continue};
    if !([_weapon param [0, ""]] call _accept) then {
        _clean set [_x, []];
        continue;
    };
    {
        if !([_weapon param [_x, ""]] call _accept) then {_weapon set [_x, ""]};
    } forEach [1, 2, 3, 6];
    {
        private _magazine = _weapon param [_x, []];
        if (_magazine isNotEqualTo [] && {!([_magazine select 0] call _accept)}) then {
            _weapon set [_x, []];
        };
    } forEach [4, 5];
} forEach [0, 1, 2, 8];
{
    private _container = _clean param [_x, []];
    if (_container isEqualTo []) then {continue};
    private _cargo = (_container param [1, []]) select {
        private _entry = _x select 0;
        if (_entry isEqualType []) then {
            // Packed weapons are checked with their attachments and loaded magazines too.
            private _packed = _entry select {_x isEqualType "" || {_x isEqualType []}};
            private _classes = flatten _packed select {_x isEqualType ""};
            (_classes findIf {!([_x] call _accept)}) == -1
        } else {
            [_entry] call _accept
        }
    };
    if !([_container select 0] call _accept) then {
        private _replacement = (_starter param [_x, []]) param [0, ""];
        if (_replacement != "" && {[_replacement] call _accept}) then {
            _clean set [_x, [_replacement, _cargo]];
        } else {
            _clean set [_x, []];
        };
    } else {
        _container set [1, _cargo];
    };
} forEach [3, 4, 5];
{
    if !([_clean param [_x, ""]] call _accept) then {_clean set [_x, ""]};
} forEach [6, 7];
private _assigned = _clean param [9, []];
{
    if !([_x] call _accept) then {_assigned set [_forEachIndex, ""]};
} forEach _assigned;
[_clean, _removed]
