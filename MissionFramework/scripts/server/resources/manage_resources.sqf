waitUntil {!isNil "save_is_loaded"};
waitUntil {!isNil "KP_liberation_production"};
waitUntil {save_is_loaded};

sectors_recalculating = false;
sectors_timer = false;

["Production management started", "PRODUCTION"] call KPLIB_fnc_log;
private _start = 0;

KC_DETERMINE_PRODUCTION_INTERVAL = {
    KP_liberation_production_interval + (KP_liberation_production_interval * (abs (KP_liberation_civ_rep / 100)))
};
while {GRLIB_endgame == 0} do {

    recalculate_sectors = false;

    if ((([] call KPLIB_fnc_getPlayerCount) > 0) && ((count KP_liberation_production) > 0)) then {
        waitUntil {sleep 0.5; !sectors_recalculating};
        sectors_recalculating = true;

        private _timeUpdate = sectors_timer;
        if (_timeUpdate) then {sectors_timer = false;};

        _start = diag_tickTime;
        if (KP_liberation_production_debug > 0) then {[format ["Production interval started: %1 - _timeUpdate: %2", diag_tickTime, _timeUpdate], "PRODUCTION"] call KPLIB_fnc_log;};

        private _tempProduction = [];
        {
            private _storageArray = [];
            private _supplyValue = 0;
            private _ammoValue = 0;
            private _fuelValue = 0;
            private _time = _x select 8;

            private _storageCandidates = nearestObjects [markerPos (_x select 1), [KP_liberation_small_storage_building], 100];
            private _storageIndex = _storageCandidates findIf {(_x getVariable ["KP_liberation_storage_type", -1]) == 1};
            if (_storageIndex != -1) then {
                private _storage = _storageCandidates select _storageIndex;
                _storageArray = [(getPosATL _storage),(getDir _storage),(vectorUpVisual _storage)];
                private _storedCrates = attachedObjects _storage;

                if (_timeUpdate) then {

                    if ((_time - 1) < 1) then {
                        _time = [] call KC_DETERMINE_PRODUCTION_INTERVAL;

                        if (((count _storedCrates) < 12) && !((_x select 7) == 3)) then {
                            private _crateType = KP_liberation_supply_crate;
                            switch (_x select 7) do {
                                case 1: {_crateType = KP_liberation_ammo_crate; stats_ammo_produced = stats_ammo_produced + 100;};
                                case 2: {_crateType = KP_liberation_fuel_crate; stats_fuel_produced = stats_fuel_produced + 100;};
                                default {_crateType = KP_liberation_supply_crate; stats_supplies_produced = stats_supplies_produced + 100;};
                            };

                            private _crate = [_crateType, 100, getPosATL _storage] call KPLIB_fnc_createCrate;
                            [_crate, _storage] call KPLIB_fnc_crateToStorage;
                            _storedCrates = attachedObjects _storage;
                        };
                    } else {
                        _time = _time - 1;
                    };
                };

                {
                    switch ((typeOf _x)) do {
                        case KP_liberation_supply_crate: {_supplyValue = _supplyValue + (_x getVariable ["KP_liberation_crate_value",0]);};
                        case KP_liberation_ammo_crate: {_ammoValue = _ammoValue + (_x getVariable ["KP_liberation_crate_value",0]);};
                        case KP_liberation_fuel_crate: {_fuelValue = _fuelValue + (_x getVariable ["KP_liberation_crate_value",0]);};
                        default {[format ["Invalid object (%1) at storage area", (typeOf _x)], "ERROR"] call KPLIB_fnc_log;};
                    };
                } forEach _storedCrates;
            };

            _tempProduction pushBack [
                (markerText (_x select 1)),
                (_x select 1),
                (_x select 2),
                _storageArray,
                (_x select 4),
                (_x select 5),
                (_x select 6),
                (_x select 7),
                _time,
                _supplyValue,
                _ammoValue,
                _fuelValue
            ];
            if (KP_liberation_production_debug > 0) then {[format ["Production Update: %1", _tempProduction select _forEachIndex], "PRODUCTION"] call KPLIB_fnc_log;};
        } forEach KP_liberation_production;

        _tempProduction sort true;

        KP_liberation_production = +_tempProduction;
        sectors_recalculating = false;
    };
    if (KP_liberation_production_debug > 0) then {[format ["Production interval finished - Time needed: %1 seconds", diag_tickTime - _start], "PRODUCTION"] call KPLIB_fnc_log;};
    waitUntil {sleep 1; recalculate_sectors};
};
