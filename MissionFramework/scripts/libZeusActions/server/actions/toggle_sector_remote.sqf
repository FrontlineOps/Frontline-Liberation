toggle_sector_remote = {
	params ["_sector"];
	if (_sector in sectors_allSectors) then {
		if (_sector in blufor_sectors) then {
			blufor_sectors = blufor_sectors - [_sector];

			sector_to_blufor = createHashMap;

			{
				sector_to_blufor set [_x, true];
			} forEach blufor_sectors;
			if (_sector in sectors_military) then {
				blufor_military_sectors = blufor_military_sectors - [ _sector ];
				publicVariable "blufor_military_sectors";
			};
			if (_sector in sectors_factory) then {
				{
        			if (_sector in _x) exitWith {KP_liberation_production = KP_liberation_production - [_x];};
    			} forEach KP_liberation_production;
			}
		} else {
			blufor_sectors = blufor_sectors + [_sector];
			sector_to_blufor = createHashMap;

			{
				sector_to_blufor set [_x, true];
			} forEach blufor_sectors;
			if (_sector in sectors_military) then {
				blufor_military_sectors = blufor_military_sectors + [ _sector ];
				publicVariable "blufor_military_sectors";
			};
			if (_sector in sectors_factory) then {
				{
        			if (_sector in _x) exitWith {KP_liberation_production = KP_liberation_production - [_x];};
    			} forEach KP_liberation_production;
			
    			private _sectorFacilities = (KP_liberation_production_markers select {_sector == (_x select 0)}) select 0;
    			KP_liberation_production pushBack [
    			    markerText _sector,
    			    _sector,
    			    1,
    			    [],
    			    _sectorFacilities select 1,
    			    _sectorFacilities select 2,
    			    _sectorFacilities select 3,
    			    3,
    			    [] call KC_DETERMINE_PRODUCTION_INTERVAL,
    			    0,
    			    0,
    			    0
    			];
			};
		};
		last_blufor_sector_change = CBA_missionTime;
		publicVariable "last_blufor_sector_change";
		publicVariable "blufor_sectors";
		[] spawn KPLIB_fnc_doSave;
	};
};