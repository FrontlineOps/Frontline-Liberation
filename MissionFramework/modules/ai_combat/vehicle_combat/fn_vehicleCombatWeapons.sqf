params ["_vehicle", "_path"];
private _inventory = (magazinesAllTurrets [_vehicle, true]) select {(_x select 1) isEqualTo _path && {_x select 2 > 0}};
private _mags = [];
{_mags pushBackUnique (_x select 0)} forEach _inventory;
private _out = [];
private _cache = localNamespace getVariable "KPLIB_vehicleCombat_muzzles";
{
    private _weapon = _x;
    private _entries = _cache getOrDefault [_weapon, []];
    if (_entries isEqualTo []) then {
        {
            private _muzzle = if (_x == "this") then {_weapon} else {_x};
            _entries pushBack [_muzzle, compatibleMagazines [_weapon, _x]];
        } forEach getArray (configFile >> "CfgWeapons" >> _weapon >> "muzzles");
        if (count _cache >= 256) then {_cache deleteAt ((keys _cache) select 0)};
        _cache set [_weapon, _entries];
    };
    {
        _x params ["_muzzle", "_compatible"];
        {
            if (!(_x in _compatible)) then {continue};
            private _base = [_weapon, _muzzle, _x] call KPLIB_fnc_vehicleCombatProfile;
            if (count _base == 0 || {_base get "airOnly"}) then {continue};
            private _p = +_base;
            private _cap = if (_p get "kind" == "MG") then {KPLIB_vehicleCombat_mgRange} else {KPLIB_vehicleCombat_gunRange};
            if (_p get "kind" == "HE" && {_p get "speed" < 300}) then {_cap = _cap min 1800};
            _p set ["range", ((_p get "nativeRange") * KPLIB_vehicleCombat_rangeMultiplier) min _cap min (_p get "limit")];
            if (_p get "range" > _p get "minimum") then {_out pushBack _p};
        } forEach _mags;
    } forEach _entries;
} forEach (_vehicle weaponsTurret _path);
_out
