if (isRemoteExecuted || {hasInterface && {!isServer}}) exitWith {};
params ["_vehicle"];
if (isNull _vehicle || {!alive _vehicle} || {!(_vehicle isKindOf "Tank" || {_vehicle isKindOf "Wheeled_APC_F"})}) exitWith {};
if (getNumber (configOf _vehicle >> "artilleryScanner") > 0) exitWith {};
private _registry = localNamespace getVariable ["KPLIB_vehicleCombat_registry", createHashMap];
private _key = netId _vehicle;
if (_key == "0:0" || {_key in _registry}) exitWith {};
_registry set [_key, [_vehicle, 0]];
(localNamespace getVariable "KPLIB_vehicleCombat_queue") pushBack _key;
