/* Loose cargo still awaiting recovery from the yard. Loaded or delivered
   cargo is excluded; no enemy strategic stock is exposed. */
if (!isServer || {isRemoteExecuted}) exitWith {[0, 0, 0, 0]};
params ["_sector"];
private _entry = (localNamespace getVariable ["KPLIB_factoryRegistry", createHashMap]) getOrDefault [_sector, [[], [], []]];
private _totals = [0, 0, 0, 0];
if ((_entry select 0) isEqualTo []) exitWith {_totals};
private _position = (_entry select 0) select 0;
private _radius = [40, 180] select (count (_entry select 0) == 4);
private _classes = [KP_liberation_supply_crate, KP_liberation_ammo_crate, KP_liberation_fuel_crate];
{
    if (!alive _x || {!isNull attachedTo _x} || {_x distance2D _position > _radius}) then {continue};
    private _amount = _x getVariable ["KP_liberation_crate_value", 0];
    private _index = _classes find typeOf _x;
    if (_amount <= 0 || {_index < 0}) then {continue};
    _totals set [0, (_totals select 0) + 1];
    _totals set [_index + 1, (_totals select (_index + 1)) + _amount];
} forEach (_entry select 1);
_totals
