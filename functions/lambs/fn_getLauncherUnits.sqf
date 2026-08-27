#include "script_component.hpp"
/*
 * Author: ThomasAngel
 * Adapted from LAMBS Danger.fsm.
 * Source: addons/main/functions/fnc_getLauncherUnits.sqf
 * Upstream commit: 63122df5d9403a52f10bf50198ac75a49f0a3d6b
 * Adapted 2026-08-27 for the KPLIB namespace.
 * License: see NOTICE.md and LICENSE.LAMBS in this directory.
 */

params [
    ["_group", [], [grpNull, []]],
    ["_flags", AI_AMMO_USAGE_FLAG_VEHICLE + AI_AMMO_USAGE_FLAG_AIR + AI_AMMO_USAGE_FLAG_ARMOUR, [0]],
    ["_checkSubmunition", false, [false]]
];

if (_group isEqualType grpNull) then {
    _group = units _group;
};

private _suitableUnits = [];
{
    if ((secondaryWeapon _x) isEqualTo "") then {continue};
    private _currentUnit = _x;
    private _unitMagazines = (magazines _currentUnit) + (secondaryWeaponMagazine _currentUnit);

    {
        if ([_x, _flags] call KPLIB_fnc_checkMagazineAiUsageFlags) exitWith {
            _suitableUnits pushBackUnique _currentUnit;
        };
        if (!_checkSubmunition) then {continue};

        private _mainAmmo = getText (configFile >> "CfgMagazines" >> _x >> "ammo");
        private _submunition = getText (configFile >> "CfgAmmo" >> _mainAmmo >> "submunitionAmmo");
        if (_submunition isEqualTo "") then {continue};
        private _submunitionFlags = getNumber (configFile >> "CfgAmmo" >> _submunition >> "aiAmmoUsageFlags");
        if ([_submunitionFlags, _flags] call BIS_fnc_bitflagsCheck) exitWith {
            _suitableUnits pushBackUnique _currentUnit;
        };
    } forEachReversed _unitMagazines;
} forEach _group;

_suitableUnits
