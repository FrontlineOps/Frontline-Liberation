/* Returns a deterministic Liberation build price for a generated asset. */

params [
    ["_class", "", [""]],
    ["_category", "light", [""]]
];

private _defaults = missionNamespace getVariable ["KP_liberation_autoFaction_priceDefaults", createHashMap];
private _base = +(_defaults getOrDefault [_category, [100, 0, 50]]);
if (_class isEqualTo "" || {count _base < 3}) exitWith {_base};

private _cfg = configFile >> "CfgVehicles" >> _class;
if !(isClass _cfg) exitWith {_base};

if (_class isKindOf "LandVehicle" || {_class isKindOf "Air"} || {_class isKindOf "Ship"}) exitWith {
    private _profile = [_class] call KPLIB_fnc_getVehicleResourceProfile;
    private _fuel = 0;
    if !(_class isKindOf "StaticWeapon") then {
        if (_profile get "hasFuelConfig") then {
            _fuel = 50 * ((_profile get "fuelCapacity") / 100) ^ 0.65;
        } else {
            _fuel = _base select 2;
        };
    };
    private _prices = [_profile get "supplies", _profile get "ammunition", _fuel];
    private _factors = missionNamespace getVariable ["KP_liberation_autoFaction_vehiclePriceMultipliers", [1, 1, 1]];
    private _limits = [3000, 3000, 2000];
    {
        private _value = (_x * ((_factors param [_forEachIndex, 1]) max 0)) min (_limits select _forEachIndex);
        _prices set [_forEachIndex, if (_value <= 0) then {0} else {25 * ((round (_value / 25)) max 1)}];
    } forEach +_prices;
    _prices
};

// Infantry and non-vehicle entries retain their category pricing.
private _engineCost = (getNumber (_cfg >> "cost")) max 1;
private _costFactor = (((ln _engineCost) - (ln 1000)) / ((ln 1000000) - (ln 1000))) max 0 min 1;
private _threat = getArray (_cfg >> "threat");
private _threatFactor = 0;
if (_threat isNotEqualTo []) then {
    _threatFactor = ((selectMax _threat) max 0) min 1;
};

private _multiplier = (0.75 + (0.5 * _costFactor) + (0.25 * _threatFactor)) max 0.75 min 1.5;

_base apply {
    if (_x <= 0) then {0} else {((round ((_x * _multiplier) / 25)) max 1) * 25}
}
