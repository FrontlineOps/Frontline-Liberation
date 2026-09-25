/* Pure loadout filter; preserves allowed quantities, ammunition and radio instance IDs. */
params ["_loadout", "_allowedKeys", ["_starter", []]];
private _clean = +_loadout;
private _removed = [];
private _accept = {
    params ["_class"];
    if (_class == "") exitWith {true};
    if (toLower _class in _allowedKeys || {([_class] call KPLIB_fnc_normalizeGearClass) in _allowedKeys}) exitWith {true};
    _removed pushBackUnique _class;
    false
};
private _disposableMagazines = localNamespace getVariable "KPLIB_disposableMagazines";
if (isNil "_disposableMagazines") then {
    _disposableMagazines = createHashMap;
    {
        {
            private _cfg = configFile >> "CfgWeapons" >> _x;
            if (isClass _cfg) then {
                _disposableMagazines set [toLower _x, (getArray (_cfg >> "magazines")) apply {toLower _x}];
            };
        } forEach ([configName _x] + getArray _x);
    } forEach configProperties [configFile >> "CBA_DisposableLaunchers", "isArray _x", true];
    localNamespace setVariable ["KPLIB_disposableMagazines", _disposableMagazines];
};
private _acceptMagazine = {
    params ["_weaponClass", "_magazineClass"];
    private _internal = _disposableMagazines get toLower _weaponClass;
    if (isNil "_internal") then {
        // Non-CBA single-shot launchers (RHS M136/M72/RPG-26, 3CB AT4) accept exactly one
        // magazine: that loaded round is internal ammunition, not a loose magazine.
        private _cfg = configFile >> "CfgWeapons" >> _weaponClass;
        private _magazines = getArray (_cfg >> "magazines");
        _internal = if (getNumber (_cfg >> "type") == 4 && {count _magazines == 1}) then {[toLower (_magazines select 0)]} else {[]};
        _disposableMagazines set [toLower _weaponClass, _internal];
    };
    if (toLower _magazineClass in _internal) exitWith {true};
    [_magazineClass] call _accept
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
        if (_magazine isNotEqualTo [] && {!([_weapon select 0, _magazine select 0] call _acceptMagazine)}) then {
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
            // Internal disposable ammunition is permitted only inside an authorized weapon.
            private _weaponClass = _entry param [0, ""];
            private _valid = ([0, 1, 2, 3, 6] findIf {!([_entry param [_x, ""]] call _accept)}) == -1;
            _valid && {([4, 5] findIf {
                private _magazine = _entry param [_x, []];
                _magazine isNotEqualTo [] && {!([_weaponClass, _magazine select 0] call _acceptMagazine)}
            }) == -1}
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
