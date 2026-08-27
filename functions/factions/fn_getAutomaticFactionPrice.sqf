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
