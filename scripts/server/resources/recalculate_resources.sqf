waitUntil {!isNil "save_is_loaded"};
waitUntil {save_is_loaded};

KP_liberation_fob_resources = [];
KP_liberation_supplies_global = 0;
KP_liberation_ammo_global = 0;
KP_liberation_fuel_global = 0;
KP_liberation_heli_slots = 0;
KP_liberation_plane_slots = 0;
infantry_cap = 50 * GRLIB_resources_multiplier;

please_recalculate = true;

waitUntil {time > 1};

while {true} do {
    waitUntil {sleep 0.5; please_recalculate};
    please_recalculate = false;

    private _local_fob_resources = [];
    private _local_supplies_global = 0;
    private _local_ammo_global = 0;
    private _local_fuel_global = 0;
    private _local_heli_slots = 0;
    private _local_plane_slots = 0;
    private _local_infantry_cap = 50 * GRLIB_resources_multiplier;

    {
        private _fob_buildings = _x nearobjects GRLIB_fob_range;
        private _storage_areas = [];
        private _heliSlots = 0;
        private _planeSlots = 0;
        private _hasAirBuilding = false;
        private _hasRecBuilding = false;

        // Classify each FOB object once instead of filtering the same array repeatedly.
        {
            private _className = typeOf _x;
            if ((_x getVariable ["KP_liberation_storage_type", -1]) == 0) then {
                _storage_areas pushBack _x;
            };
            if (_className isEqualTo KP_liberation_heli_slot_building) then {
                _heliSlots = _heliSlots + 1;
            };
            if (_className isEqualTo KP_liberation_plane_slot_building) then {
                _planeSlots = _planeSlots + 1;
            };
            if (_className isEqualTo KP_liberation_air_vehicle_building) then {
                _hasAirBuilding = true;
            };
            if (_className isEqualTo KP_liberation_recycle_building) then {
                _hasRecBuilding = true;
            };
        } forEach _fob_buildings;

        private _supplyValue = 0;
        private _ammoValue = 0;
        private _fuelValue = 0;

        {
            {
                switch ((typeOf _x)) do {
                    case KP_liberation_supply_crate: {_supplyValue = _supplyValue + (_x getVariable ["KP_liberation_crate_value",0]);};
                    case KP_liberation_ammo_crate: {_ammoValue = _ammoValue + (_x getVariable ["KP_liberation_crate_value",0]);};
                    case KP_liberation_fuel_crate: {_fuelValue = _fuelValue + (_x getVariable ["KP_liberation_crate_value",0]);};
                    default {[format ["Invalid object (%1) at storage area", (typeOf _x)], "ERROR"] call KPLIB_fnc_log;};
                };
            } forEach (attachedObjects _x);
        } forEach _storage_areas;

        _local_fob_resources pushBack [_x, _supplyValue, _ammoValue, _fuelValue, _hasAirBuilding, _hasRecBuilding];
        _local_supplies_global = _local_supplies_global + _supplyValue;
        _local_ammo_global = _local_ammo_global + _ammoValue;
        _local_fuel_global = _local_fuel_global + _fuelValue;
        _local_heli_slots = _local_heli_slots + _heliSlots;
        _local_plane_slots = _local_plane_slots + _planeSlots;
    } forEach (GRLIB_all_fobs + [getMarkerPos "startbase_marker"]);

    {
        if ( _x in sectors_capture ) then {
            _local_infantry_cap = _local_infantry_cap + (10 * GRLIB_resources_multiplier);
        };
    } foreach blufor_sectors;

    KP_liberation_fob_resources = _local_fob_resources;
    KP_liberation_supplies_global = _local_supplies_global;
    KP_liberation_ammo_global = _local_ammo_global;
    KP_liberation_fuel_global = _local_fuel_global;
    KP_liberation_heli_slots = _local_heli_slots;
    KP_liberation_plane_slots = _local_plane_slots;
    infantry_cap = _local_infantry_cap;

};
