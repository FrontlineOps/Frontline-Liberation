if (!isServer || {canSuspend}) exitWith {};
params [["_object_recycled", objNull, [objNull]]];
private _caller = ["RECYCLE"] call KPLIB_fnc_permissionRequest;
if (isNull _caller || {isNull _object_recycled} || {!alive _object_recycled}) exitWith {};
private _consumed = localNamespace getVariable ["KPLIB_recycleConsumed", createHashMap];
private _identity = netId _object_recycled;
if (_consumed getOrDefault [_identity, false]) exitWith {};
if (_caller distance2D _object_recycled > 10 || {_object_recycled distance2D startbase <= 1000}
    || {_object_recycled getVariable ["KP_liberation_preplaced", false]}
    || {getObjectType _object_recycled < 8} || {!isNull attachedTo _object_recycled}
    || {(attachedObjects _object_recycled) isNotEqualTo []}
    || {({alive _x} count crew _object_recycled) > 0 && {!unitIsUAV _object_recycled}}
    || {!(locked _object_recycled in [-1, 0, 1])}) exitWith {};
private _class = toLower typeOf _object_recycled;
private _eligible = _class in KPLIB_o_allVeh_classes;
{
    if ((_x findIf {(_x select 0) isEqualType "" && {toLower (_x select 0) == _class}}) != -1) exitWith {_eligible = true};
} forEach (KPLIB_buildList select [2, 6]);
if (!_eligible || {_class in KPLIB_storageBuildings && {(_object_recycled getVariable ["KP_liberation_storage_type", -1]) != 0}}) exitWith {};
private _fob = [_caller] call KPLIB_fnc_buildFobPosition;
if (_fob isEqualTo [] || {_object_recycled distance2D _fob >= GRLIB_fob_range}) exitWith {};
([_object_recycled] call KPLIB_fnc_recycleYield) params ["_price_s", "_price_a", "_price_f"];
if ((_price_s + _price_a + _price_f) > 0
    && {(nearestObjects [_fob, [KP_liberation_recycle_building], GRLIB_fob_range]) findIf {alive _x} == -1}) exitWith {
    [localize "STR_NORECBUILDING_ERROR"] remoteExecCall ["hint", owner _caller];
};
private _storage_areas = ([_fob, GRLIB_fob_range * 1.2] call KPLIB_fnc_buildStorage) - [_object_recycled];
private _space = 0;
{
    private _capacity = count (if (typeOf _x == KP_liberation_large_storage_building) then {KP_liberation_large_storage_positions} else {KP_liberation_small_storage_positions});
    _space = _space + ((_capacity - count attachedObjects _x) max 0);
} forEach _storage_areas;
if (_space < ceil (_price_s / 100) + ceil (_price_a / 100) + ceil (_price_f / 100)) exitWith {
    [localize "STR_CANCEL_ERROR"] remoteExecCall ["hint", owner _caller];
};
// Engine deletion completes after this frame. Claim the identity before crediting.
_consumed set [_identity, true];
localNamespace setVariable ["KPLIB_recycleConsumed", _consumed];
[{
    params ["_identity"];
    (localNamespace getVariable ["KPLIB_recycleConsumed", createHashMap]) deleteAt _identity;
}, [_identity], 2] call CBA_fnc_waitAndExecute;
{deleteVehicle _x} forEach crew _object_recycled;
deleteVehicle _object_recycled;
if ((_price_s > 0) || (_price_a > 0) || (_price_f > 0)) then {
    {
        private _space = 0;
        if (typeOf _x == KP_liberation_large_storage_building) then {
            _space = (count KP_liberation_large_storage_positions) - (count (attachedObjects _x));
        };
        if (typeOf _x == KP_liberation_small_storage_building) then {
            _space = (count KP_liberation_small_storage_positions) - (count (attachedObjects _x));
        };

        while {(_space > 0) && (_price_s > 0)} do {
            private _amount = 100;
            if ((_price_s / 100) < 1) then {
                _amount = _price_s;
            };
            _price_s = _price_s - _amount;
            private _crate = [KP_liberation_supply_crate, _amount, getPos _x] call KPLIB_fnc_createCrate;
            [_crate, _x] call KPLIB_fnc_crateToStorage;
            _space = _space - 1;
        };

        while {(_space > 0) && (_price_a > 0)} do {
            private _amount = 100;
            if ((_price_a / 100) < 1) then {
                _amount = _price_a;
            };
            _price_a = _price_a - _amount;
            private _crate = [KP_liberation_ammo_crate, _amount, getPos _x] call KPLIB_fnc_createCrate;
            [_crate, _x] call KPLIB_fnc_crateToStorage;
            _space = _space - 1;
        };

        while {(_space > 0) && (_price_f > 0)} do {
            private _amount = 100;
            if ((_price_f / 100) < 1) then {
                _amount = _price_f;
            };
            _price_f = _price_f - _amount;
            private _crate = [KP_liberation_fuel_crate, _amount, getPos _x] call KPLIB_fnc_createCrate;
            [_crate, _x] call KPLIB_fnc_crateToStorage;
            _space = _space - 1;
        };

        if ((_price_s == 0) && (_price_a == 0) && (_price_f == 0)) exitWith {};
    } forEach _storage_areas;
};
please_recalculate = true;
stats_vehicles_recycled = stats_vehicles_recycled + 1;

[format ["Recycled %1", _class], "RECYCLE"] call KPLIB_fnc_log;
