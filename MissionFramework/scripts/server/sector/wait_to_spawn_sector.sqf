params [
    ["_sector", "", [""]],
    ["_opforCount", 0, [0]]
];

private _startedAt = diag_tickTime;
[format ["Sector %1 (%2) - Waiting to spawn sector...", markerText _sector, _sector], "SECTORSPAWN"] call KPLIB_fnc_log;

private _sectorRange = [_opforCount] call KPLIB_fnc_getSectorRange;
{
    private _friendlyCount = [markerPos _sector, _sectorRange, GRLIB_side_friendly] call KPLIB_fnc_getUnitsCount;
    if (_friendlyCount > 0 && {_friendlyCount <= _x}) then {
        sleep 5;
    };
    sleep 0.1;
} forEach [10, 6, 4, 3, 2, 1];

[
    format [
        "Sector %1 (%2) - Waiting done - Time needed: %3 seconds",
        markerText _sector,
        _sector,
        diag_tickTime - _startedAt
    ],
    "SECTORSPAWN"
] call KPLIB_fnc_log;
