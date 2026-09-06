KPLIB_CIVREP_LOSE_SECTOR = {
	params ["_sector"];
	if (!isServer || {isRemoteExecuted} || {!(_sector in blufor_sectors)}) exitWith {};
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
		};
		last_blufor_sector_change = CBA_missionTime;
		publicVariable "last_blufor_sector_change";
		publicVariable "blufor_sectors";
		[] spawn KPLIB_fnc_doSave;
	};
};
