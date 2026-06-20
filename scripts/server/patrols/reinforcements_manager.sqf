params ["_targetsector"];

if (combat_readiness > 15) then {

    private _init_units_count = (([markerPos _targetsector, GRLIB_capture_size, GRLIB_side_enemy] call KPLIB_fnc_getUnitsCount));

    if !(_targetsector in sectors_bigtown) then {
        while {(_init_units_count * 0.75) <= ([markerPos _targetsector, GRLIB_capture_size, GRLIB_side_enemy] call KPLIB_fnc_getUnitsCount)} do {
            sleep 5;
        };
    };

    if (_targetsector in active_sectors) then {

        private _nearestower = [markerpos _targetsector, GRLIB_side_enemy, GRLIB_radiotower_size] call KPLIB_fnc_getNearestTower;

        if !(isNil "_nearestower") then {
            private _reinforcements_time = (((((markerpos _nearestower) distance (markerpos _targetsector)) / 1000) ^ 1.66 ) * 120) / (GRLIB_difficulty_modifier * GRLIB_csat_aggressivity);
            if (_targetsector in sectors_bigtown) then {
                _reinforcements_time = _reinforcements_time * 0.35;
            };
            private _current_timer = time;

            waitUntil {sleep 1; (_current_timer + _reinforcements_time < time) || (_targetsector in blufor_sectors) || (_nearestower in blufor_sectors)};

            sleep 15;

            if ((_targetsector in active_sectors) && !(_targetsector in blufor_sectors) && !(_nearestower in blufor_sectors) && (!([] call KPLIB_fnc_isBigtownActive) || _targetsector in sectors_bigtown)) then {
                reinforcements_sector_under_attack = _targetsector;
                reinforcements_set = true;
                

                private _shouldSpawn = false;

                if(combat_readiness >= 60) then {

                    private _threshold = 10;

                    if(combat_readiness >= 100) then {
                        _threshold = 20;
                    };

                    if(combat_readiness >= 150) then {
                        _threshold = 35;
                    };

                    _shouldSpawn = (random 100) <= _threshold;
                };
                //// Disabled for IRAQ
                //_shouldSpawn = false;

                if (_shouldSpawn) then {
                    
                    [markerPos _targetsector, 3, 6, true, markerText _targetsector] call send_paratroopers;
                    stats_reinforcements_called = stats_reinforcements_called + 1;
                };
                
            };
        };
    };
};
