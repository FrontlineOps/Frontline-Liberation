waitUntil { !isNil "GRLIB_all_fobs" };
waitUntil { !isNil "blufor_sectors" };

sleep 5;

attack_in_progress = false;

sectors_under_attack = createHashMap;

while { GRLIB_endgame == 0 } do {

    {
        private _ownership = [markerPos _x] call KPLIB_fnc_getSectorOwnership;
        private _tempTime = time;
        
        if ( _ownership == GRLIB_side_enemy ) then {

            private _set = sectors_under_attack getOrDefault [_x, false];

            while {time <= _tempTime + 120 && _ownership == GRLIB_side_enemy} do {
                _ownership = [markerPos _x] call KPLIB_fnc_getSectorOwnership;
                sleep 5;
            };

            if(!_set && _ownership == GRLIB_side_enemy) then {
                diag_log format ["Spawning sector under attack %1", _x];
                sectors_under_attack set [_x, true];
                [ _x ] call attack_in_progress_sector;
            };
        };
        sleep 0.5;
    } foreach blufor_sectors;

    {
        private _ownership = [_x] call KPLIB_fnc_getSectorOwnership;
        if ( _ownership == GRLIB_side_enemy ) then {
            private _set = sectors_under_attack getOrDefault [_x, false];

            if(!_set) then {
                diag_log format ["Spawning FOB under attack %1", _x];
                sectors_under_attack set [_x, true];
                [ _x ] call attack_in_progress_fob;
            };
        };
        sleep 0.5;
    } foreach GRLIB_all_fobs;

    sleep 1;

};
