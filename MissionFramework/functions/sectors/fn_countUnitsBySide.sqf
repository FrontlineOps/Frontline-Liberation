/*
    File: fn_countUnitsBySide.sqf
    Author: Frontline Liberation Team
    Date: 2026-08-30
    License: MIT License - http://www.opensource.org/licenses/MIT

    Description:
        Counts units of one side from an already fetched nearby-entity set.
        Vehicle crew are counted separately because nearEntities does not return
        units while they are inside vehicles.

    Parameter(s):
        _entities   - Nearby men and supported vehicles [ARRAY, defaults to []]
        _side       - Side to count [SIDE, defaults to GRLIB_side_friendly]
        _includeAir - Count crew inside air vehicles [BOOL, defaults to true]

    Returns:
        Amount of units [NUMBER]
*/

params [
    ["_entities", [], [[]]],
    ["_side", GRLIB_side_friendly, [sideEmpty]],
    ["_includeAir", true, [true]]
];

private _amount = _side countSide (_entities select {
    _x isKindOf "Man"
    && {!(captive _x)}
    && {!(side _x == GRLIB_side_enemy && (isPlayer _x))}
    && {((getPos _x) select 2) < 500}
});

{
    if (
        !(_x isKindOf "Man")
        && {_includeAir || {!(_x isKindOf "Air")}}
        && {((getPos _x) select 2) < 500}
    ) then {
        {
            if (_x isKindOf "Man" && {(side _x) == _side}) then {
                _amount = _amount + 1;
            };
        } forEach (crew _x);
    };
} forEach _entities;

_amount
