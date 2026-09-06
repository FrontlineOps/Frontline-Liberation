// TODO Split this in an added action to the vehicles and add the dorecycle == 1 part in a button action
params ["_vehToRecycle"];

if (_vehToRecycle getVariable ["KP_liberation_preplaced", false]) exitWith {hint localize "STR_PREPLACED_ERROR";};

dorecycle = 0;

if !([player, "RECYCLE"] call KPLIB_fnc_hasPermission) exitWith {hint "Recycling permission is required."};
private _type = typeOf _vehToRecycle;
private _cfg = configFile >> "CfgVehicles";
([_vehToRecycle] call KPLIB_fnc_recycleYield) params ["_price_s", "_price_a", "_price_f"];

createDialog "liberation_recycle";
waitUntil {sleep 0.1; dialog};

ctrlSetText [134, format [localize "STR_RECYCLING_YIELD", getText (_cfg >> _type >> "displayName")]];
ctrlSetText [131, format ["%1", _price_s]];
ctrlSetText [132, format ["%1", _price_a]];
ctrlSetText [133, format ["%1", _price_f]];

waitUntil {sleep 0.1; !dialog || !alive player || dorecycle != 0};

if (dialog) then {closeDialog 0};

if (dorecycle == 1 && !(isnull _vehToRecycle) && alive _vehToRecycle) then {
    if (!(KP_liberation_recycle_building_near) && ((_price_s + _price_a + _price_f) > 0)) exitWith {hint localize "STR_NORECBUILDING_ERROR";};

    private _storage_areas = (([] call KPLIB_fnc_getNearestFob) nearobjects (GRLIB_fob_range * 1.2)) select {(_x getVariable ["KP_liberation_storage_type",-1]) == 0};
    private _crateSum = (ceil (_price_s / 100)) + (ceil (_price_a / 100)) + (ceil (_price_f / 100));
    private _spaceSum = 0;

    {
        if (typeOf _x == KP_liberation_large_storage_building) then {
            _spaceSum = _spaceSum + (count KP_liberation_large_storage_positions) - (count (attachedObjects _x));
        };
        if (typeOf _x == KP_liberation_small_storage_building) then {
            _spaceSum = _spaceSum + (count KP_liberation_small_storage_positions) - (count (attachedObjects _x));
        };
    } forEach _storage_areas;

    if (_spaceSum < _crateSum) then {
        hint localize "STR_CANCEL_ERROR";
    } else {
        [_vehToRecycle] remoteExecCall ["recycle_remote_call", 2];
    };
};
