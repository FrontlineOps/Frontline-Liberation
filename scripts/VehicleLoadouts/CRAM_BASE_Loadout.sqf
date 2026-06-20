params ["_vehicle"];

// Set ACE Re-Arm to use loadout instead of vehicle config.
_vehicle setVariable ["ace_rearm_scriptedLoadout", true, true];

// Removes the existing loadout
{
    private _mag = _x select 0;
    private _turret = _x select 1;
    _vehicle removeMagazineTurret [_mag, _turret];
} foreach (magazinesAllTurrets _vehicle);

_vehicle removeWeaponTurret ["pook_CRAM_CIWS_20mm",[0]];
_vehicle addWeaponTurret ["itc_land_weapon_cram",[0]];
_vehicle addMagazineTurret ["itc_land_20mm_phalanx_mag",[0]];
_vehicle addWeaponTurret ["pook_SAM_M2HB",[1]];
_vehicle addMagazineTurret ["pook_100Rnd_50cal",[1]];
_vehicle addMagazineTurret ["pook_100Rnd_50cal",[1]];
_vehicle addMagazineTurret ["pook_100Rnd_50cal",[1]];