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
_vehicle addMagazineTurret ["rhsusf_mag_L8A3_16",[0]];
_vehicle addMagazineTurret ["rhsusf_mag_L8A3_16",[0]];
_vehicle addMagazineTurret ["rhs_mag_2Rnd_TOW2A",[0]];
_vehicle addMagazineTurret ["rhs_mag_2Rnd_TOW2A",[0]];
_vehicle addMagazineTurret ["rhs_mag_2Rnd_TOW2A",[0]];
_vehicle addMagazineTurret ["rhs_mag_2Rnd_TOW2A",[0]];
_vehicle addMagazineTurret ["rhs_mag_2Rnd_TOW2A",[0]];
_vehicle addMagazineTurret ["rhs_mag_2Rnd_TOW2BB",[0]];
_vehicle addMagazineTurret ["rhs_mag_2Rnd_TOW2BB",[0]];
_vehicle addMagazineTurret ["rhs_mag_1100Rnd_762x51_M240",[2]];
_vehicle addMagazineTurret ["rhs_mag_1100Rnd_762x51_M240",[2]];
_vehicle addMagazineTurret ["rhs_mag_1100Rnd_762x51_M240",[2]];