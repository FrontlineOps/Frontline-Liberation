waitUntil {sleep 0.1; !isNil "GRLIB_all_fobs" && {!isNil "blufor_sectors"}};
sleep 5;

sectors_under_attack = createHashMap;
private _attackWorker = scriptNull;

while {GRLIB_endgame == 0} do {
    if (scriptDone _attackWorker) then {
        {
            private _sector = _x;
            if (
                scriptDone _attackWorker
                && {([markerPos _sector] call KPLIB_fnc_getSectorOwnership) == GRLIB_side_enemy}
                && {!(sectors_under_attack getOrDefault [_sector, false])}
            ) then {
                sectors_under_attack set [_sector, true];
                [format ["Sector attack monitor dispatched for %1", _sector], "SECTOR"] call KPLIB_fnc_log;
                _attackWorker = [_sector] spawn attack_in_progress_sector;
            };
            sleep 0.5;
        } forEach (+blufor_sectors);

        {
            private _fobPosition = _x;
            if (
                scriptDone _attackWorker
                && {([_fobPosition] call KPLIB_fnc_getSectorOwnership) == GRLIB_side_enemy}
                && {!(sectors_under_attack getOrDefault [_fobPosition, false])}
            ) then {
                sectors_under_attack set [_fobPosition, true];
                [format ["FOB attack monitor dispatched at %1", mapGridPosition _fobPosition], "SECTOR"] call KPLIB_fnc_log;
                _attackWorker = [_fobPosition] spawn attack_in_progress_fob;
            };
            sleep 0.5;
        } forEach (+GRLIB_all_fobs);
    };

    sleep 1;
};
