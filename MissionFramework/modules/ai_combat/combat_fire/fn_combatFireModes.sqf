/* Inherited mode metadata, shared by infantry and vehicle profiles. */
params ["_weapon", "_muzzle"];
private _cache = localNamespace getVariable "KPLIB_combatFire_modes";
private _key = str _this;
if (_key in _cache) exitWith {_cache get _key};
private _w = configFile >> "CfgWeapons" >> _weapon;
private _m = if (_weapon == _muzzle) then {_w} else {_w >> _muzzle};
private _names = getArray (_m >> "modes");
if (_names isEqualTo []) then {_names = ["this"]};
private _out = [];
{
    private _c = if (_x == "this") then {_m} else {_m >> _x};
    private _reload = getNumber (_c >> "reloadTime");
    if (_reload <= 0) then {continue};
    _out pushBack [
        if (_x == "this") then {_muzzle} else {_x},
        getNumber (_c >> "autoFire") > 0,
        1 max getNumber (_c >> "burst"), getNumber (_c >> "burstRangeMax"),
        _reload, getNumber (_c >> "showToPlayer") > 0 || {_x == "this"},
        getNumber (_c >> "minRange"), getNumber (_c >> "midRange"), getNumber (_c >> "maxRange"),
        getNumber (_c >> "aiRateOfFire")
    ];
} forEach (_names select [0, 32]);
if (count _cache >= 512) then {_cache deleteAt ((keys _cache) select 0)};
_cache set [_key, _out];
_out
