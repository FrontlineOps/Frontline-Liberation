// base amount of sector lifetime tickets
// if there are no enemies one ticket is removed every SECTOR_TICK_TIME seconds
// 12 * 5 = 60s by default
#define BASE_TICKETS                12
#define SECTOR_TICK_TIME            5
// delay in minutes from which addional time will be added
#define ADDITIONAL_TICKETS_DELAY    1

params ["_sector"];

waitUntil {!isNil "combat_readiness"};
waitUntil {!isNil "sector_to_blufor"};

[format ["Sector %1 (%2) activated - Managed on: %3", (markerText _sector), _sector, debug_source], "SECTORSPAWN"] remoteExecCall ["KPLIB_fnc_log", 2];

private _sectorpos = markerPos _sector;
private _stopit = false;
private _spawncivs = false;
private _building_ai_max = 0;
private _infsquad = "army";
private _building_range = 50;
private _local_capture_size = GRLIB_capture_size;
private _managed_units = [];
private _sector_despawn_tickets = BASE_TICKETS;
private _maximum_additional_tickets = (KP_liberation_delayDespawnMax * 60 / SECTOR_TICK_TIME);

// Don't bother spawning if the sector already has entities in it
if (_sector in active_sectors) exitWith {};

// Sector has populated, mark it active so it doesn't populate again
active_sectors pushBackUnique _sector; publicVariable "active_sectors";

private _opforcount = [] call KPLIB_fnc_getOpforCap;
[_sector, _opforcount] call wait_to_spawn_sector;
private _sectorRange = [_opforcount] call KPLIB_fnc_getSectorRange;

if ((!(_sector in blufor_sectors)) && (([markerPos _sector, _sectorRange, GRLIB_side_friendly] call KPLIB_fnc_getUnitsCount) > 0)) then {
    // Spawn infantry to the same number of players as on the server.
    // Spawn vehicles based on number of players up to a maximum
    // TODO: Investigate how to spawn garrisoned infantry via stuff like ACE.

    /*
    diag_log "WatergardTestingFlag - enter CBA wait and execute";
    [
        {
            diag_log "WatergardTestingFlag - enter BATTLESPACE_DEFENDERS_SPAWN";
            _this call BATTLESPACE_DEFENDERS_SPAWN;
            diag_log "WatergardTestingFlag - exit BATTLESPACE_DEFENDERS_SPAWN";
        },
        [
            _sector,
            _managed_units
        ],
        5
    ] call CBA_fnc_waitAndExecute;
    diag_log "WatergardTestingFlag - exit CBA wait and execute";
    */

    // CBA_fnc_waitAndExecute for whatever god forsaken reason
    // would spawn multiple threads of BATTLESPACE_DEFENDERS_SPAWN
    // using spawn achieves the same goal, need to contact CBA devs I guess...

    if(isNil { blufor_sectors_cap_times }) then {
        blufor_sectors_cap_times = createHashMap;
    };

    // Handle spawning entities for the player to interact with
    // Use Battlespace activation thresholds but keep the wider range so low pop and server dev situations can be properly handled
    private _count = 0;
    private _req = [] call BATTLESPACE_TASK_FORCE_GET_NEEDED_PLAYERCOUNT_FOR_PROC;
    {
        if((_x distance2D _sectorpos) <= _sectorRange) then {
            _count = _count + 1;
        };

        if(_count >= _req) exitWith {};
    } forEach allPlayers;

    // Still spawn IEDs when there is e.g. a solo driver doing logi
    if(_count > 0) then {
        private _iedcount = 0;
        if (KP_liberation_civ_rep < 0) then {
            _iedcount = round ((ceil (random 3)) * (round ((KP_liberation_civ_rep * -1) / 33)) * GRLIB_difficulty_modifier);
        } else {
            _iedcount = 0;
        };
        if (_iedcount > 8) then {_iedcount = 8};
        [_sector, 400, _iedcount] spawn ied_manager;
    };

    // Check for whether enough players to be able to proc the sector, no point spawning NPCs otherwise
    if(_count >= _req) then {
        // DISABLED - VIRTUALIZED NOW
        // [_sector, _managed_units] spawn BATTLESPACE_DEFENDERS_SPAWN;

        // Populate the sector with some Civilians if the right type
        private _spawncivs = _sector in sectors_bigtown || _sector in sectors_capture || _sector in sectors_factory;
        if (_spawncivs && GRLIB_civilian_activity > 0) then {
            _managed_units = _managed_units + ([_sector] call KPLIB_fnc_spawnCivilians);
        };
        

        // If a sector was just flipped from blufor within the the last time interval, don't spawn more defenders
        private _capTime = blufor_sectors_cap_times getOrDefault [_sector, -1200];
        if((CBA_missionTime - _capTime) >= 600) then {
            if ( isNil { BATTLESPACE_DEFENDERS_SECTORS_SPAWNED }) then {
                BATTLESPACE_DEFENDERS_SECTORS_SPAWNED = createHashMap;
            };

            private _alreadySpawnedTaskForces = BATTLESPACE_DEFENDERS_SECTORS_SPAWNED getOrDefault [_sector, false];
            if(!_alreadySpawnedTaskForces) then {
                [_sector] spawn BATTLESPACE_DEFENDERS_CREATE_TASK_FORCES;
                BATTLESPACE_DEFENDERS_SECTORS_SPAWNED set [_sector, true];
            };
        };

        // Brief wait so the virtual entities can actually spawn in
        sleep 10;

    };

    if (KP_liberation_sectorspawn_debug > 0) then {[format ["Sector %1 (%2) - populating done", (markerText _sector), _sector], "SECTORSPAWN"] remoteExecCall ["KPLIB_fnc_log", 2];};

    private _activationTime = time;
    // sector lifetime loop
    while {!_stopit} do {
        // sector was captured
        if (!(_sector in blufor_sectors) && ([_sectorpos, _local_capture_size] call KPLIB_fnc_getSectorOwnership == GRLIB_side_friendly) && (GRLIB_endgame == 0)) then {
            if (isServer) then {
                [_sector] spawn sector_liberated_remote_call;
            } else {
                [_sector] remoteExec ["sector_liberated_remote_call",2];
            };

            _stopit = true;
            private _nearbyCount = count ((markerPos _sector) nearEntities [["Man"], _local_capture_size * 1.2]);

            // Spawn some civ prisoners to heal
            if(_nearbyCount < 7) then {
                {
                    [_x] spawn prisonner_ai;
                } forEach ((markerPos _sector) nearEntities [["Man"], _local_capture_size * 1.2]);
            };

            sleep 60;
            active_sectors = active_sectors - [_sector]; publicVariable "active_sectors";
            sleep 600;

            {
                if (_x isKindOf "Man") then {
                    if (side group _x != GRLIB_side_friendly) then {
                        deleteVehicle _x;
                    };
                } else {
                    if (!isNull _x) then {
                        [_x] call KPLIB_fnc_cleanOpforVehicle;
                    };
                };
            } forEach _managed_units;
        } else {
            if (([_sectorpos, (_sectorRange + 300), GRLIB_side_friendly] call KPLIB_fnc_getUnitsCount) == 0) then {
                _sector_despawn_tickets = _sector_despawn_tickets - 1;
            } else {
                // start counting running minutes after ADDITIONAL_TICKETS_DELAY
                private _runningMinutes = (floor ((time - _activationTime) / 60)) - ADDITIONAL_TICKETS_DELAY;
                private _additionalTickets = (_runningMinutes * BASE_TICKETS);

                // clamp from 0 to "_maximum_additional_tickets"
                _additionalTickets = (_additionalTickets max 0) min _maximum_additional_tickets;

                _sector_despawn_tickets = BASE_TICKETS + _additionalTickets;
            };

            if (_sector_despawn_tickets <= 0) then {
                {
                    if (_x isKindOf "Man") then {
                        deleteVehicle _x;
                    } else {
                        if (!isNull _x) then {
                            [_x] call KPLIB_fnc_cleanOpforVehicle;
                        };
                    };
                } forEach _managed_units;

                _stopit = true;
                active_sectors = active_sectors - [_sector]; publicVariable "active_sectors";
            };
        };
        sleep SECTOR_TICK_TIME;
    };
} else {
    sleep 40;
    active_sectors = active_sectors - [_sector]; publicVariable "active_sectors";
};

[format ["Sector %1 (%2) deactivated - Was managed on: %3", (markerText _sector), _sector, debug_source], "SECTORSPAWN"] remoteExecCall ["KPLIB_fnc_log", 2];
