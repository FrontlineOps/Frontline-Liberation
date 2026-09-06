// Base sector lifetime is 12 tickets * 5 seconds. Continued player presence
// adds tickets after the first minute, capped by KP_liberation_delayDespawnMax.
#define BASE_TICKETS 12
#define SECTOR_TICK_TIME 5
#define ADDITIONAL_TICKETS_DELAY 1

params [["_sector", "", [""]]];
if (_sector isEqualTo "") exitWith {};

waitUntil {sleep 0.1; !isNil "combat_readiness" && {!isNil "sector_to_blufor"}};
if (_sector in active_sectors) exitWith {};

private _position = markerPos _sector;
private _deactivate = {
    active_sectors = active_sectors - [_sector];
    publicVariable "active_sectors";
};

active_sectors pushBackUnique _sector;
publicVariable "active_sectors";
[format ["Sector %1 (%2) activated - Managed on: %3", markerText _sector, _sector, debug_source], "SECTORSPAWN"] call KPLIB_fnc_log;

private _opforCount = [] call KPLIB_fnc_getOpforCap;
[_sector, _opforCount] call wait_to_spawn_sector;
private _sectorRange = [_opforCount] call KPLIB_fnc_getSectorRange;

if (
    _sector in blufor_sectors
    || {([_position, _sectorRange, GRLIB_side_friendly] call KPLIB_fnc_getUnitsCount) <= 0}
) exitWith {
    sleep 40;
    call _deactivate;
    [format ["Sector %1 (%2) deactivated without population", markerText _sector, _sector], "SECTORSPAWN"] call KPLIB_fnc_log;
};

if (isNil "blufor_sectors_cap_times") then {
    blufor_sectors_cap_times = createHashMap;
};

private _nearbyPlayerCount = 0;
private _requiredPlayerCount = [] call BATTLESPACE_TASK_FORCE_GET_NEEDED_PLAYERCOUNT_FOR_PROC;
{
    if (_x distance2D _position <= _sectorRange) then {
        _nearbyPlayerCount = _nearbyPlayerCount + 1;
    };
    if (_nearbyPlayerCount >= _requiredPlayerCount) exitWith {};
} forEach allPlayers;

if (_nearbyPlayerCount >= _requiredPlayerCount) then {
    private _lastCaptureTime = blufor_sectors_cap_times getOrDefault [_sector, -1200];
    if (CBA_missionTime - _lastCaptureTime >= 600) then {
        if (isNil "BATTLESPACE_CIVILIANS_SECTORS_POPULATED") then {
            BATTLESPACE_CIVILIANS_SECTORS_POPULATED = createHashMap;
        };
        if (!(BATTLESPACE_CIVILIANS_SECTORS_POPULATED getOrDefault [_sector, false])) then {
            BATTLESPACE_CIVILIANS_SECTORS_POPULATED set [_sector, true];
            [_sector] call BATTLESPACE_DEFENDERS_CREATE_AMBIENT_CIVILIANS;
        };
    };

    // Allow newly-created ambient civilians to enter the existing proc queue.
    sleep 10;
};

if (KP_liberation_sectorspawn_debug > 0) then {
    [format ["Sector %1 (%2) - populating done", markerText _sector, _sector], "SECTORSPAWN"] call KPLIB_fnc_log;
};

private _activatedAt = time;
private _despawnTickets = BASE_TICKETS;
private _maximumAdditionalTickets = KP_liberation_delayDespawnMax * 60 / SECTOR_TICK_TIME;
private _running = true;

while {_running} do {
    private _captured = !(_sector in blufor_sectors)
        && {([_position, GRLIB_capture_size] call KPLIB_fnc_getSectorOwnership) == GRLIB_side_friendly}
        && {GRLIB_endgame == 0};

    if (_captured) then {
        [_sector] spawn sector_liberated_remote_call;
        [_position, GRLIB_capture_size * 1.2, "SECTOR_CAPTURE"] call KPLIB_SURRENDER_SERVER_TRIGGER_AREA;
        sleep 60;
        call _deactivate;
        _running = false;
    } else {
        if (([_position, _sectorRange + 300, GRLIB_side_friendly] call KPLIB_fnc_getUnitsCount) == 0) then {
            _despawnTickets = _despawnTickets - 1;
        } else {
            private _runningMinutes = floor ((time - _activatedAt) / 60) - ADDITIONAL_TICKETS_DELAY;
            private _additionalTickets = (_runningMinutes * BASE_TICKETS) max 0 min _maximumAdditionalTickets;
            _despawnTickets = BASE_TICKETS + _additionalTickets;
        };

        if (_despawnTickets <= 0) then {
            call _deactivate;
            _running = false;
        };
    };

    if (_running) then {sleep SECTOR_TICK_TIME};
};

[format ["Sector %1 (%2) deactivated - Was managed on: %3", markerText _sector, _sector, debug_source], "SECTORSPAWN"] call KPLIB_fnc_log;
