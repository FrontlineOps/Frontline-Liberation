/* Config-only vehicle economics, cached without spawning preview vehicles. */
params [["_class", "", [""]]];
private _key = toLower _class;
private _cache = localNamespace getVariable ["KPLIB_vehicleResourceCache", createHashMap];
private _cached = _cache get _key;
if (!isNil "_cached") exitWith {_cached};

private _cfg = configFile >> "CfgVehicles" >> _class;
private _magazines = [];
private _walk = {
    params ["_seat"];
    if (getArray (_seat >> "weapons") isNotEqualTo []) then {
        _magazines append getArray (_seat >> "magazines");
    };
    {[_x] call _walk} forEach ("true" configClasses (_seat >> "Turrets"));
};
[_cfg] call _walk;
{
    private _magazine = getText (_x >> "attachment");
    if (_magazine != "") then {_magazines pushBack _magazine};
} forEach ("true" configClasses (_cfg >> "Components" >> "TransportPylonsComponent" >> "Pylons"));

private _ammoValue = 0;
{
    _ammoValue = _ammoValue + (([_x] call KPLIB_fnc_getMagazineResourceValue)
        * (getNumber (configFile >> "CfgMagazines" >> _x >> "count")));
} forEach _magazines;

// mapSize is available before models load. sizeOf can return zero during preset
// initialization and would give different cached prices on different machines.
private _size = (getNumber (_cfg >> "mapSize")) max 1 min 60;
private _armor = (getNumber (_cfg >> "armor")) max 0 min 3000;
private _power = (getNumber (_cfg >> "enginePower")) max 0 min 3000;
private _seats = (getNumber (_cfg >> "transportSoldier")) max 0 min 100;
private _cargo = (getNumber (_cfg >> "maximumLoad")) max 0 min 10000;
private _support = 0;
{
    if (getNumber (_cfg >> _x) > 0) then {_support = _support + 50};
} forEach ["attendant", "transportRepair", "transportAmmo", "transportFuel"];
// A modest armament allowance pays for the mounting/launcher as well as its rounds.
private _supplies = 25 + _size * _size * 0.25 + _armor * 0.35 + _power * 0.08 + _seats * 3 + _cargo * 0.01 + _support + sqrt _ammoValue * 2;
if (_class isKindOf "Air") then {_supplies = _supplies * 2.5};
// ACE declares refuelling capacity in litres; the engine value often only tunes
// endurance (for example, an MBT can have a smaller engine value than a jeep).
private _fuelCapacity = (getNumber (_cfg >> "fuelCapacity")) max 0;
private _aceCapacity = getNumber (_cfg >> "ace_refuel_fuelCapacity");
if (_aceCapacity > 0) then {_fuelCapacity = _aceCapacity};
private _profile = createHashMapFromArray [
    ["supplies", _supplies],
    ["ammunition", _ammoValue],
    ["fuelCapacity", _fuelCapacity],
    ["hasFuelConfig", isNumber (_cfg >> "fuelCapacity") || {_aceCapacity > 0}]
];
_cache set [_key, _profile];
localNamespace setVariable ["KPLIB_vehicleResourceCache", _cache];
_profile
