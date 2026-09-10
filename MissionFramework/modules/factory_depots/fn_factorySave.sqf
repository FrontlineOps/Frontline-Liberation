/* Called inside the same unscheduled snapshot as the FOB storage totals.
   Returns [depot extension, production snapshot, privately owned objects]. Stored cargo is handed to
   exactly one existing aggregate; all other tracked cargo stays in this ledger.
   Cargo rows: [class, value, ATL, direction, vectorUp, damage, carrier, inTransit].
   Carrier: [class, saved world position, model offset], only for saved vehicles. */
if (!isServer || {isRemoteExecuted}) exitWith {[[1, []], [], []]};
params ["_storages", "_savedVehicles", ["_vehicleRows", []]];
private _aggregateOwners = +_storages;
private _production = KP_liberation_production apply {
    private _row = +_x;
    // The production manager's cached total may predate a just-delivered crate.
    // Read the actual storage in this snapshot before excluding its cargo.
    private _near = nearestObjects [markerPos (_row select 1), [KP_liberation_small_storage_building], 100];
    private _index = _near findIf {alive _x && {(_x getVariable ["KP_liberation_storage_type", -1]) == 1}};
    private _totals = [0, 0, 0];
    _row set [3, []];
    if (_index >= 0) then {
        private _storage = _near select _index;
        _aggregateOwners pushBackUnique _storage;
        _row set [3, [getPosATL _storage, getDir _storage, vectorUp _storage]];
        {
            private _kind = [KP_liberation_supply_crate, KP_liberation_ammo_crate, KP_liberation_fuel_crate] find typeOf _x;
            if (alive _x && {_kind >= 0}) then {
                _totals set [_kind, (_totals select _kind) + (_x getVariable ["KP_liberation_crate_value", 0])];
            };
        } forEach attachedObjects _storage;
    };
    {_row set [9 + _forEachIndex, _x]} forEach _totals;
    _row
};
private _opaque = localNamespace getVariable ["KPLIB_factoryOpaqueSave", []];
if !(_opaque isEqualTo []) exitWith {[_opaque, _production, []]};
private _rows = [];
private _owned = [];
private _registry = localNamespace getVariable ["KPLIB_factoryRegistry", createHashMap];
{
    private _sector = _x;
    (_registry get _sector) params ["_layout", "_crates", "_pending"];
    _owned append _crates;
    private _cargo = +_pending;
    {
        private _crate = _x;
        if (!alive _crate) then {continue};
        private _amount = _crate getVariable ["KP_liberation_crate_value", 0];
        if (_amount <= 0) then {continue};
        private _parent = attachedTo _crate;
        if (!isNull _parent && {_parent in _aggregateOwners}) then {continue};
        private _carrier = [];
        if (!isNull _parent && {_parent in _savedVehicles}) then {
            private _savedPosition = (_vehicleRows select (_savedVehicles find _parent)) select 1;
            _carrier = [typeOf _parent, _savedPosition, _parent worldToModel (getPosATL _crate)];
        };
        _cargo pushBack [typeOf _crate, _amount, getPosATL _crate, getDir _crate, vectorUp _crate, damage _crate, _carrier, !isNull _parent];
    } forEach _crates;
    _rows pushBack [_sector, _layout, _cargo];
} forEach keys _registry;
[[1, _rows], _production, _owned]
