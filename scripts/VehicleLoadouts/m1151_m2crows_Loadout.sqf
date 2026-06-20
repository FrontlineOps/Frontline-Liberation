params ["_vehicle"];

// Set ACE Re-Arm to use loadout instead of vehicle config.
_vehicle setVariable ["ace_rearm_scriptedLoadout", true, true];

// Removes the existing loadout
{
    private _mag = _x select 0;
    private _turret = _x select 1;
    _vehicle removeMagazineTurret [_mag, _turret];
} foreach (magazinesAllTurrets _vehicle);

_vehicle addMagazineTurret ["rhsusf_mag_duke",[-1]];
_vehicle addMagazineTurret ["rhs_mag_400rnd_127x99_SLAP_mag_Tracer_Red",[0]];
_vehicle addMagazineTurret ["rhs_mag_400rnd_127x99_SLAP_mag_Tracer_Red",[0]];
_vehicle addMagazineTurret ["rhs_mag_400rnd_127x99_SLAP_mag_Tracer_Red",[0]];
_vehicle addMagazineTurret ["rhs_mag_400rnd_127x99_SLAP_mag_Tracer_Red",[0]];
