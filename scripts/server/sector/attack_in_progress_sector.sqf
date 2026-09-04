params [["_sector", "", [""]]];
if (_sector isEqualTo "") exitWith {};

private _position = markerPos _sector;
private _clearAttackState = {
    sectors_under_attack set [_sector, false];
};
private _getOwnership = {
    [_position] call KPLIB_fnc_getSectorOwnership
};

private _ownership = call _getOwnership;
private _confirmationEndsAt = time + 120;
while {
    time <= _confirmationEndsAt
    && {_ownership == GRLIB_side_enemy}
    && {_sector in blufor_sectors}
    && {GRLIB_endgame == 0}
} do {
    sleep 5;
    _ownership = call _getOwnership;
};

if (
    time <= _confirmationEndsAt
    || {_ownership != GRLIB_side_enemy}
    || {!(_sector in blufor_sectors)}
    || {GRLIB_endgame != 0}
) exitWith {
    call _clearAttackState;
    [format ["Sector attack monitor cancelled before confirmation for %1", _sector], "SECTOR"] call KPLIB_fnc_log;
};

[_sector, 1] remoteExec ["remote_call_sector"];
private _attackTime = GRLIB_vulnerability_timer;

while {
    _attackTime > 0
    && {_ownership in [GRLIB_side_enemy, GRLIB_side_resistance]}
    && {_sector in blufor_sectors}
    && {GRLIB_endgame == 0}
} do {
    _ownership = call _getOwnership;
    _attackTime = _attackTime - 1;
    sleep 1;
};

waitUntil {
    sleep 1;
    GRLIB_endgame != 0
        || {(call _getOwnership) != GRLIB_side_resistance}
        || {!(_sector in blufor_sectors)}
};

if (GRLIB_endgame == 0 && {_sector in blufor_sectors}) then {
    _ownership = call _getOwnership;
    if (_attackTime <= 1 && {_ownership == GRLIB_side_enemy}) then {
        blufor_sectors = blufor_sectors - [_sector];
        sector_to_blufor = createHashMap;
        {sector_to_blufor set [_x, true]} forEach blufor_sectors;

        if (isNil "BATTLESPACE_CIVILIANS_SECTORS_POPULATED") then {
            BATTLESPACE_CIVILIANS_SECTORS_POPULATED = createHashMap;
        };
        BATTLESPACE_CIVILIANS_SECTORS_POPULATED set [_sector, false];

        if (isNil "blufor_sectors_cap_times") then {
            blufor_sectors_cap_times = createHashMap;
        };
        blufor_sectors_cap_times set [_sector, CBA_missionTime];
        last_blufor_sector_change = CBA_missionTime;

        if (_sector in sectors_military) then {
            blufor_military_sectors = blufor_military_sectors - [_sector];
            publicVariable "blufor_military_sectors";
        };
        publicVariable "blufor_sectors";
        [_sector, 2] remoteExec ["remote_call_sector"];
        stats_sectors_lost = stats_sectors_lost + 1;

        private _productionIndex = KP_liberation_production findIf {_sector in _x};
        if (_productionIndex >= 0) then {
            private _production = KP_liberation_production select _productionIndex;
            private _storageData = _production param [3, []];
            if (count _storageData == 3) then {
                private _storage = (nearestObjects [_storageData select 0, [KP_liberation_small_storage_building], 10]) param [0, objNull];
                if (isNull _storage) then {
                    [format ["Sector %1 lost without its expected production storage object", _sector], "SECTOR"] call KPLIB_fnc_log;
                } else {
                    {
                        detach _x;
                        deleteVehicle _x;
                    } forEach attachedObjects _storage;
                    deleteVehicle _storage;
                };
            };
            KP_liberation_production deleteAt _productionIndex;
        };

        [] spawn KPLIB_fnc_doSave;
        [format ["Sector attack succeeded at %1", _sector], "SECTOR"] call KPLIB_fnc_log;
    } else {
        [_sector, 3] remoteExec ["remote_call_sector"];
        [_position, GRLIB_capture_size * 0.8, "SECTOR_DEFENDED"] call KPLIB_SURRENDER_SERVER_TRIGGER_AREA;
        [format ["Sector attack defeated at %1", _sector], "SECTOR"] call KPLIB_fnc_log;
    };
};

call _clearAttackState;
