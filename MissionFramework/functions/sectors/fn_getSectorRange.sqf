/*
    File: fn_getSectorRange.sqf
    Author: KP Liberation Dev Team - https://github.com/KillahPotatoes
    Date: 2019-11-25
    Last Update: 2019-12-07
    License: MIT License - http://www.opensource.org/licenses/MIT

    Description:
        Adjusts sector activation distance for the existing OPFOR count.
        The activation threshold is a load guard, not a defender strength target.

    Parameter(s):
        _unitCount - Number of units to take into account [NUMBER, defaults to 0]

    Returns:
        Calculated sector size [NUMBER]
*/

params [
    ["_unitCount", 0, [0]]
];


if (_unitCount < (KPLIB_sector_activation_opfor_threshold / 2)) exitWith {GRLIB_sector_size};
if (_unitCount <= KPLIB_sector_activation_opfor_threshold) exitWith {GRLIB_sector_size - (GRLIB_sector_size * 0.5 * ((_unitCount / KPLIB_sector_activation_opfor_threshold) - 0.5))};
GRLIB_sector_size * 0.75
