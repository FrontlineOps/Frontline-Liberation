params ["_vehicle"];

// Set ACE Re-Arm to use loadout instead of vehicle config.
_vehicle setVariable ["ace_rearm_scriptedLoadout", true, true];
// Removes the existing loadout
{
    private _mag = _x select 0;
    private _turret = _x select 1;
    _vehicle removeMagazineTurret [_mag, _turret];
} foreach (magazinesAllTurrets _vehicle);

_vehicle removeWeaponTurret ["pook_SAM_M2HB",[1]];
_vehicle addWeaponTurret ["pook_SAM_M2HB",[1]];
_vehicle addMagazineTurret ["pook_100Rnd_50cal",[1]];
_vehicle addMagazineTurret ["pook_100Rnd_50cal",[1]];
_vehicle addMagazineTurret ["pook_100Rnd_50cal",[1]];
_vehicle addMagazineTurret ["pook_100Rnd_50cal",[1]];
_vehicle addMagazineTurret ["pook_100Rnd_50cal",[1]];
_vehicle removeWeaponTurret ["pook_NASAMS_launcher",[0]];
_vehicle addWeaponTurret ["pook_MEADS_Launcher",[0]];
_vehicle addMagazineTurret ["pook_MEADSx8",[0]];