waitUntil {sleep 0.1; !isNil "GRLIB_all_fobs" && {!isNil "blufor_sectors"} && {!isNil "BATTLESPACE_CAPTURE_GET_OWNERSHIP"}};
sleep 5;
sectors_under_attack = createHashMap;
private _workers = createHashMap;
while {GRLIB_endgame == 0} do {
    {if (scriptDone _y) then {_workers deleteAt _x}} forEach _workers;
    {
        private _sector = _x;
        if (!(_sector in _workers) && {! (sectors_under_attack getOrDefault [_sector, false])} && {[_sector] call BATTLESPACE_CAPTURE_GET_OWNERSHIP == GRLIB_side_enemy}) then {
            sectors_under_attack set [_sector, true];
            _workers set [_sector, [_sector] spawn attack_in_progress_sector];
            [format ["Sector attack monitor dispatched for %1", _sector], "SECTOR"] call KPLIB_fnc_log;
        };
        sleep 0.5;
    } forEach (+blufor_sectors);
    {
        private _key = str _x;
        if (!(_key in _workers) && {!(sectors_under_attack getOrDefault [_x, false])} && {[_x] call KPLIB_fnc_getSectorOwnership == GRLIB_side_enemy}) then {
            sectors_under_attack set [_x, true];
            _workers set [_key, [_x] spawn attack_in_progress_fob];
            [format ["FOB attack monitor dispatched at %1", mapGridPosition _x], "SECTOR"] call KPLIB_fnc_log;
        };
        sleep 0.5;
    } forEach (+GRLIB_all_fobs);
    sleep 1;
};
