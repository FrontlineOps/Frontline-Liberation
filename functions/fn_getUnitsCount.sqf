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

    Returns:
        Amount of units [NUMBER]
*/

params [
    ["_pos", [0, 0, 0], [[]], [2, 3]],
    ["_radius", 100, [0]],
    ["_side", GRLIB_side_friendly, [sideEmpty]],
    ["_includeAir", true]
];

private _vehicleKinds =  ["Car", "Tank", "Boat"];

if(_includeAir) then {
    _vehicleKinds pushBack "Air";
};
private _amount = _side countSide ((_pos nearEntities ["Man", _radius]) select {!(captive _x) && !(side _x == GRLIB_side_enemy && (isPlayer _x)) && ((getpos _x) select 2 < 500)});
{
    {
        if(_x isKindOf "Man" && (side _x) == _side) then {
            _amount = _amount + 1;
        };
    } forEach (crew _x);
} forEach ((_pos nearEntities [_vehicleKinds, _radius]) select {((getpos _x) select 2 < 500) && count (crew _x) > 0});

_amount
 
