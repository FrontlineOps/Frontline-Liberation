/*
    File: fn_getUnitsCount.sqf
    Author: KP Liberation Dev Team - https://github.com/KillahPotatoes
    Date: 2019-12-03
    Last Update: 2020-05-08
    License: MIT License - http://www.opensource.org/licenses/MIT

    Description:
        Gets the amount of units of given side inside given radius of given position.

    Parameter(s):
        _pos - Description [POSITION, defaults to [0, 0, 0]
        _radius - Description [NUMBER, defaults to 100]
        _side - Description [SIDE, defaults to GRLIB_side_friendly]
        _includeAir - Count crew inside air vehicles [BOOL, defaults to true]

    Returns:
        Amount of units [NUMBER]
*/

params [
    ["_pos", [0, 0, 0], [[]], [2, 3]],
    ["_radius", 100, [0]],
    ["_side", GRLIB_side_friendly, [sideEmpty]],
    ["_includeAir", true]
];

private _entityKinds = ["Man", "Car", "Tank", "Boat"];

if (_includeAir) then {
    _entityKinds pushBack "Air";
};

private _nearbyEntities = _pos nearEntities [_entityKinds, _radius];

[_nearbyEntities, _side, _includeAir] call KPLIB_fnc_countUnitsBySide
 
