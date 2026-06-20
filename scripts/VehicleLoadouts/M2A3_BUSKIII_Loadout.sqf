params ["_vehicle"];

// Set ACE Re-Arm to use loadout instead of vehicle config.
_vehicle setVariable ["ace_rearm_scriptedLoadout", true, true];

// Removes the existing loadout
{
    private _mag = _x select 0;
    private _turret = _x select 1;
    _vehicle removeMagazineTurret [_mag, _turret];
} foreach (magazinesAllTurrets _vehicle);

// Adds the new loadout
_vehicle addMagazineTurret ["rhs_mag_smokegen",[-1]];
_vehicle addMagazineTurret ["rhs_mag_2Rnd_TOW2B_AERO",[0]];
_vehicle addMagazineTurret ["rhs_mag_2Rnd_TOW2B_AERO",[0]];
_vehicle addMagazineTurret ["rhs_LaserFCSMag",[0]]; 
_vehicle addMagazineTurret ["rhs_mag_70Rnd_25mm_M242_APFSDS",[0]]; 
_vehicle addMagazineTurret ["rhs_mag_70Rnd_25mm_M242_APFSDS",[0]];
_vehicle addMagazineTurret ["rhs_mag_70Rnd_25mm_M242_APFSDS",[0]];
_vehicle addMagazineTurret ["rhs_mag_70Rnd_25mm_M242_APFSDS",[0]];
_vehicle addMagazineTurret ["rhs_mag_70Rnd_25mm_M242_APFSDS",[0]]; 
_vehicle addMagazineTurret ["rhs_mag_230Rnd_25mm_M242_HEI",[0]];
_vehicle addMagazineTurret ["rhs_mag_230Rnd_25mm_M242_HEI",[0]];
_vehicle addMagazineTurret ["rhs_mag_230Rnd_25mm_M242_HEI",[0]];
_vehicle addMagazineTurret ["rhs_mag_762x51_M240_1200",[0]];
_vehicle addMagazineTurret ["rhs_mag_762x51_M240_1200",[0]];
_vehicle addMagazineTurret ["rhs_mag_762x51_M240_1200",[0]];
_vehicle addMagazineTurret ["rhs_mag_762x51_M240_1200",[0]];
_vehicle addMagazineTurret ["rhs_mag_762x51_M240_1200",[0]];
_vehicle addMagazineTurret ["rhs_mag_2Rnd_TOW2B",[0]];
_vehicle addMagazineTurret ["rhs_mag_2Rnd_TOW2B",[0]];
_vehicle addMagazineTurret ["rhs_mag_2Rnd_TOW2BB",[0]];
_vehicle addMagazineTurret ["rhs_mag_2Rnd_TOW2BB",[0]];
_vehicle addMagazineTurret ["rhs_mag_2Rnd_TOW2BB",[0]];
_vehicle addMagazineTurret ["rhsusf_mag_L8A3_8",[0,0]];
_vehicle addMagazineTurret ["rhsusf_mag_L8A3_8",[0,0]];
_vehicle addMagazineTurret ["rhsusf_mag_L8A3_8",[0,0]];
_vehicle addMagazineTurret ["rhsusf_mag_L8A3_8",[0,0]];
_vehicle addMagazineTurret ["rhsusf_mag_L8A3_8",[0,0]];