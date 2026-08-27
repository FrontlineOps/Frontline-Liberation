/*
 * Author: joko (Jonas)
 * Adapted from LAMBS Danger.fsm.
 * Source: addons/main/functions/fnc_checkMagazineAiUsageFlags.sqf
 * Upstream commit: 63122df5d9403a52f10bf50198ac75a49f0a3d6b
 * Adapted 2026-08-27 for the KPLIB namespace.
 * License: see NOTICE.md and LICENSE.LAMBS in this directory.
 */

if (isNil "KPLIB_lambs_aiUsageFlagCache") then {
    KPLIB_lambs_aiUsageFlagCache = createHashMap;
};

params [
    ["_magazine", "", [""]],
    ["_flags", 0, [0]]
];

KPLIB_lambs_aiUsageFlagCache getOrDefaultCall [
    _magazine + str _flags,
    {
        private _ammo = getText (configFile >> "CfgMagazines" >> _magazine >> "ammo");
        private _aiAmmoUsage = getNumber (configFile >> "CfgAmmo" >> _ammo >> "aiAmmoUsageFlags");
        [_aiAmmoUsage, _flags] call BIS_fnc_bitflagsCheck
    },
    true
]
