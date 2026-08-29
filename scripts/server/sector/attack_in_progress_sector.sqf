params [ "_sector" ];
private [ "_attacktime", "_ownership", "_grp", "_squad_type" ];


_ownership = [ markerpos _sector ] call KPLIB_fnc_getSectorOwnership;
if ( _ownership != GRLIB_side_enemy ) exitWith {
    sectors_under_attack set [_sector, false];
};

if (!(_sector in blufor_sectors)) exitWith {
    sectors_under_attack set [_sector, false];
};

[_sector, 1] remoteExec ["remote_call_sector"];
_attacktime = GRLIB_vulnerability_timer;



while { _attacktime > 0 && ( _ownership == GRLIB_side_enemy || _ownership == GRLIB_side_resistance ) } do {

    if(!(_sector in blufor_sectors)) exitWith {};
    _ownership = [markerpos _sector] call KPLIB_fnc_getSectorOwnership;
    _attacktime = _attacktime - 1;
    sleep 1;
};

waitUntil {
    sleep 1;
    ([markerpos _sector] call KPLIB_fnc_getSectorOwnership != GRLIB_side_resistance) || !(_sector in blufor_sectors)
};

if ( GRLIB_endgame == 0 && (_sector in blufor_sectors) ) then {
    if ( _attacktime <= 1 && ( [markerpos _sector] call KPLIB_fnc_getSectorOwnership == GRLIB_side_enemy ) ) then {

        blufor_sectors = blufor_sectors - [ _sector ];
        sector_to_blufor = createHashMap;

        {
            sector_to_blufor set [_x, true];
        } forEach blufor_sectors;

        if ( isNil { BATTLESPACE_DEFENDERS_SECTORS_SPAWNED }) then {
            BATTLESPACE_DEFENDERS_SECTORS_SPAWNED = createHashMap;
        };

        BATTLESPACE_DEFENDERS_SECTORS_SPAWNED set [_sector, false];
        

        if(isNil { blufor_sectors_cap_times }) then {
            blufor_sectors_cap_times = createHashMap;
        };

        blufor_sectors_cap_times set [_sector, CBA_missionTime];

        last_blufor_sector_change = CBA_missionTime;

        if (_sector in sectors_military) then {
            blufor_military_sectors = blufor_military_sectors - [ _sector ];
            publicVariable "blufor_military_sectors";
        };
        publicVariable "blufor_sectors";
        [_sector, 2] remoteExec ["remote_call_sector"];
        [] spawn KPLIB_fnc_doSave;
        stats_sectors_lost = stats_sectors_lost + 1;
        {
            if (_sector in _x) exitWith {
                if ((count (_x select 3)) == 3) then {
                    {
                        detach _x;
                        deleteVehicle _x;
                    } forEach (attachedObjects ((nearestObjects [((_x select 3) select 0), [KP_liberation_small_storage_building], 10]) select 0));

                    deleteVehicle ((nearestObjects [((_x select 3) select 0), [KP_liberation_small_storage_building], 10]) select 0);
                };
                KP_liberation_production = KP_liberation_production - [_x];
            };
        } forEach KP_liberation_production;
    } else {
        [_sector, 3] remoteExec ["remote_call_sector"];
        {[_x] spawn prisonner_ai;} foreach (((markerpos _sector) nearEntities ["Man", GRLIB_capture_size * 0.8]) select {side group _x == GRLIB_side_enemy});
    };
};
sectors_under_attack set [_sector, false];
