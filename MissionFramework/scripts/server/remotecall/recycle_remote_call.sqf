if (!isServer || {canSuspend}) exitWith {};
params [["_object_recycled", objNull, [objNull]]];
private _caller = ["RECYCLE"] call KPLIB_fnc_permissionRequest;
if !([_object_recycled, _caller] call KPLIB_fnc_canRecycle) exitWith {};

private _consumed = localNamespace getVariable ["KPLIB_recycleConsumed", createHashMap];
private _identity = netId _object_recycled;
if (_consumed getOrDefault [_identity, false]) exitWith {};
private _vehicle = _object_recycled isKindOf "LandVehicle" || {_object_recycled isKindOf "Air"} || {_object_recycled isKindOf "Ship"};
private _depot = [_object_recycled, _caller] call KPLIB_fnc_getRecycleDepot;
private _field = _vehicle && {_depot isEqualTo []};
if (_field && {!KPLIB_salvage_field_enabled}) exitWith {
    [localize "STR_NORECBUILDING_ERROR"] remoteExecCall ["hint", owner _caller];
};
private _fob = if (_vehicle) then {_depot} else {[_caller] call KPLIB_fnc_buildFobPosition};
if (!_vehicle && {_fob isEqualTo [] || {_object_recycled distance2D _fob >= GRLIB_fob_range}}) exitWith {};
private _prices = [_object_recycled, _field] call KPLIB_fnc_recycleYield;
private _crateCount = 0;
{_crateCount = _crateCount + ceil (_x / 100)} forEach _prices;
if (!_vehicle && {_crateCount > 0} && {_depot isEqualTo []}) exitWith {
    [localize "STR_NORECBUILDING_ERROR"] remoteExecCall ["hint", owner _caller];
};

private _storageAreas = [];
if (!_field) then {
    _storageAreas = ([_fob, GRLIB_fob_range * 1.2] call KPLIB_fnc_buildStorage) - [_object_recycled];
};
private _space = 0;
{
    private _capacity = count (([KP_liberation_small_storage_positions, KP_liberation_large_storage_positions] select (typeOf _x == KP_liberation_large_storage_building)));
    _space = _space + ((_capacity - count attachedObjects _x) max 0);
} forEach _storageAreas;
if (!_field && {_space < _crateCount}) exitWith {
    [localize "STR_CANCEL_ERROR"] remoteExecCall ["hint", owner _caller];
};
private _dropPosition = _caller getPos [4, getDir _caller + 90];
if (_field && {surfaceIsWater _dropPosition}) exitWith {
    ["Stand on dry ground to unload salvage crates."] remoteExecCall ["hint", owner _caller];
};

// Claim before issuing resources. The unscheduled transaction cannot be interleaved
// by another recycle request; deletion itself completes at the end of the frame.
_consumed set [_identity, true];
localNamespace setVariable ["KPLIB_recycleConsumed", _consumed];
private _crates = [];
private _types = [KP_liberation_supply_crate, KP_liberation_ammo_crate, KP_liberation_fuel_crate];
private _failed = false;
{
    private _remaining = _x;
    private _type = _types select _forEachIndex;
    while {_remaining > 0 && {!_failed}} do {
        private _amount = _remaining min 100;
        private _storage = objNull;
        private _position = _dropPosition;
        if (!_field) then {
            private _index = _storageAreas findIf {
                count attachedObjects _x < count (([_x] call KPLIB_fnc_getStoragePositions) select 0)
            };
            if (_index >= 0) then {
                _storage = _storageAreas select _index;
                _position = getPos _storage;
            } else {
                _failed = true;
            };
        };
        if (_failed) exitWith {};
        private _crate = [_type, _amount, _position] call KPLIB_fnc_createCrate;
        if (isNull _crate) exitWith {_failed = true};
        _crates pushBack _crate;
        if (!_field) then {[_crate, _storage] call KPLIB_fnc_crateToStorage};
        _remaining = _remaining - _amount;
    };
    if (_failed) exitWith {};
} forEach _prices;
if (_failed) exitWith {
    {detach _x; deleteVehicle _x} forEach _crates;
    _consumed deleteAt _identity;
    ["Salvage could not be unloaded. The vehicle has been kept."] remoteExecCall ["hint", owner _caller];
};

private _class = typeOf _object_recycled;
{
    if (typeOf _x == "ace_fire_logic") then {deleteVehicle _x};
} forEach attachedObjects _object_recycled;
{deleteVehicle _x} forEach crew _object_recycled;
deleteVehicle _object_recycled;
[{
    params ["_identity"];
    (localNamespace getVariable ["KPLIB_recycleConsumed", createHashMap]) deleteAt _identity;
}, [_identity], 2] call CBA_fnc_waitAndExecute;
please_recalculate = true;
stats_vehicles_recycled = stats_vehicles_recycled + 1;
[format ["Salvaged %1: %2 (field: %3)", _class, _prices, _field], "RECYCLE"] call KPLIB_fnc_log;
[format ["Recovered %1 supplies, %2 ammunition and %3 fuel. %4", _prices select 0, _prices select 1, _prices select 2,
    ["Resources were placed in FOB storage.", "Collect the resource crates nearby."] select _field]] remoteExecCall ["hint", owner _caller];
