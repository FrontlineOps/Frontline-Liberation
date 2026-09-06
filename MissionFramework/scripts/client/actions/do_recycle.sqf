params ["_vehToRecycle"];
if !([player, "RECYCLE"] call KPLIB_fnc_hasPermission) exitWith {hint "Recycling permission is required."};
if !([_vehToRecycle, player] call KPLIB_fnc_canRecycle) exitWith {};

private _vehicle = _vehToRecycle isKindOf "LandVehicle" || {_vehToRecycle isKindOf "Air"} || {_vehToRecycle isKindOf "Ship"};
private _depot = [_vehToRecycle, player] call KPLIB_fnc_getRecycleDepot;
private _field = _vehicle && {_depot isEqualTo []};
if (_field && {!KPLIB_salvage_field_enabled}) exitWith {hint localize "STR_NORECBUILDING_ERROR"};
private _prices = [_vehToRecycle, _field] call KPLIB_fnc_recycleYield;

dorecycle = 0;
if !(createDialog "liberation_recycle") exitWith {};
private _name = getText (configFile >> "CfgVehicles" >> typeOf _vehToRecycle >> "displayName");
ctrlSetText [134, format [[localize "STR_RECYCLING_YIELD", "Salvaging this %1 will yield:"] select _vehicle, _name]];
{ctrlSetText [131 + _forEachIndex, str _x]} forEach _prices;
if (_vehicle) then {
    ctrlSetText [125, "Vehicle salvage"];
    ctrlSetText [120, "Salvage"];
    ctrlSetText [135, ["To FOB storage. Vehicle and cargo will be removed.", "Crates nearby. Vehicle and cargo will be removed."] select _field];
};

waitUntil {sleep 0.1; !dialog || {!alive player} || {dorecycle != 0}};
if (dialog) then {closeDialog 0};
if (dorecycle == 1 && {[_vehToRecycle, player] call KPLIB_fnc_canRecycle}) then {
    // Never send prices or a destination: the server rechecks both at commit.
    [_vehToRecycle] remoteExecCall ["recycle_remote_call", 2];
};