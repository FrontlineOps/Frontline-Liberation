params [["_sector", "", [""]]];
if (!isServer || {_sector == ""}) exitWith {};
private _position = markerPos _sector;
private _getOwnership = {[_sector] call BATTLESPACE_CAPTURE_GET_OWNERSHIP};
private _record = createHashMap;
// Active offensive capture age already persists in the unversioned operation.
{
    if ((_y getOrDefault ["kind", ""]) == "BATTLEGROUP" && {(_y getOrDefault ["targetSector", ""]) == _sector} && {(_y getOrDefault ["phase", ""]) == "ASSAULTING"}) exitWith {_record = _y};
} forEach BATTLESPACE_STRATEGIC_OPERATIONS;
private _clear = {
    sectors_under_attack set [_sector, false];
    _record deleteAt "captureStartedAt";
    _record set ["attackNotified", false];
};
private _started = _record getOrDefault ["captureStartedAt", CBA_missionTime];
// A restored capture age can legitimately put its start before this session's zero.
_record set ["captureStartedAt", _started];
private _owner = call _getOwnership;
while {CBA_missionTime - _started < 120 && {_owner == GRLIB_side_enemy} && {_sector in blufor_sectors} && {GRLIB_endgame == 0}} do {
    sleep 5;
    _owner = call _getOwnership;
};
if (_owner != GRLIB_side_enemy || {!(_sector in blufor_sectors)} || {GRLIB_endgame != 0}) exitWith {
    call _clear;
    [format ["Sector attack monitor cancelled before confirmation for %1", _sector], "SECTOR"] call KPLIB_fnc_log;
};
if !(_record getOrDefault ["attackNotified", false]) then {[_sector, 1] remoteExec ["remote_call_sector", 0]};
_record set ["attackNotified", true];
private _lastUpdate = CBA_missionTime;
private _requiredTime = 120 + GRLIB_vulnerability_timer;
while {_owner in [GRLIB_side_enemy, GRLIB_side_resistance] && {_sector in blufor_sectors} && {GRLIB_endgame == 0}} do {
    if (_owner == GRLIB_side_enemy && {CBA_missionTime - _started >= _requiredTime}) exitWith {};
    sleep 1;
    private _now = CBA_missionTime;
    private _nextOwner = call _getOwnership;
    // Contested time never advances capture; friendly control or empty ground cancels it.
    if (_owner == GRLIB_side_resistance || {_nextOwner == GRLIB_side_resistance}) then {_started = _started + (_now - _lastUpdate)};
    _record set ["captureStartedAt", _started];
    _lastUpdate = _now;
    _owner = _nextOwner;
};
if (GRLIB_endgame == 0 && {_sector in blufor_sectors}) then {
    if (_owner == GRLIB_side_enemy && {CBA_missionTime - _started >= _requiredTime} && {[_sector] call BATTLESPACE_CAPTURE_SECTOR_FOR_OPFOR}) then {
        [format ["Sector attack succeeded at %1", _sector], "SECTOR"] call KPLIB_fnc_log;
    } else {
        [_sector, 3] remoteExec ["remote_call_sector", 0];
        [_position, GRLIB_capture_size * 0.8, "SECTOR_DEFENDED"] call KPLIB_SURRENDER_SERVER_TRIGGER_AREA;
        [format ["Sector attack defeated at %1", _sector], "SECTOR"] call KPLIB_fnc_log;
    };
};
call _clear;
