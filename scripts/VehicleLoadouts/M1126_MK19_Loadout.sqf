params ["_vehicle"];

// Set ACE Re-Arm to use loadout instead of vehicle config.
_vehicle setVariable ["ace_rearm_scriptedLoadout", true, true];

// Removes the existing loadout
{
    private _mag = _x select 0;
    private _turret = _x select 1;
    _vehicle removeMagazineTurret [_mag, _turret];
} foreach (magazinesAllTurrets _vehicle);

_vehicle addMagazineTurret ["rhsusf_mag_L8A3_16",[0]];
_vehicle addMagazineTurret ["rhsusf_mag_L8A3_16",[0]];
_vehicle addMagazineTurret ["rhsusf_mag_L8A3_16",[0]];
_vehicle addMagazineTurret ["RHS_96Rnd_40mm_MK19_M430A1",[0]];
_vehicle addMagazineTurret ["RHS_96Rnd_40mm_MK19_M430A1",[0]];
_vehicle addMagazineTurret ["RHS_96Rnd_40mm_MK19_M430A1",[0]];
_vehicle addMagazineTurret ["RHS_96Rnd_40mm_MK19_M430A1",[0]];
_vehicle addMagazineTurret ["RHS_96Rnd_40mm_MK19_M430A1",[0]];