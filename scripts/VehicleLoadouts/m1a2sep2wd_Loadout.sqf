params ["_vehicle"];

// Set ACE Re-Arm to use loadout instead of vehicle config.
_vehicle setVariable ["ace_rearm_scriptedLoadout", true, true];

// Removes the existing loadout
{
    private _mag = _x select 0;
    private _turret = _x select 1;
    _vehicle removeMagazineTurret [_mag, _turret];
} foreach (magazinesAllTurrets _vehicle);

_vehicle addMagazineTurret ["rhs_mag_smokegen",[-1]];
_vehicle addMagazineTurret ["rhs_LaserFCSMag",[0]];
_vehicle addMagazineTurret ["rhs_LaserFCSMag",[0]];
_vehicle addMagazineTurret ["rhs_mag_M829A4",[0]];
_vehicle addMagazineTurret ["rhs_mag_M830A1",[0]];
_vehicle addMagazineTurret ["rhs_mag_M1147",[0]],
_vehicle addMagazineTurret ["rhs_mag_762x51_M240_1200",[0]];
_vehicle addMagazineTurret ["rhs_mag_762x51_M240_1200",[0]];
_vehicle addMagazineTurret ["rhs_mag_762x51_M240_1200",[0]];
_vehicle addMagazineTurret ["rhs_mag_762x51_M240_1200",[0]];
_vehicle addMagazineTurret ["rhs_mag_762x51_M240_1200",[0]];
_vehicle addMagazineTurret ["rhs_mag_762x51_M240_1200",[0]];
_vehicle addMagazineTurret ["rhs_mag_762x51_M240_1200",[0]];
_vehicle addMagazineTurret ["rhs_mag_762x51_M240_1200",[0]];
_vehicle addMagazineTurret ["rhs_mag_762x51_M240_1200",[0]];
_vehicle addMagazineTurret ["rhs_mag_762x51_M240_1200",[0]];
_vehicle addMagazineTurret ["rhsusf_mag_L8A3_12",[0,0]];
_vehicle addMagazineTurret ["rhsusf_mag_L8A3_12",[0,0]];
_vehicle addMagazineTurret ["rhsusf_mag_L8A3_12",[0,0]];
_vehicle addMagazineTurret ["rhsusf_mag_L8A3_12",[0,0]];
_vehicle addMagazineTurret ["rhsusf_mag_L8A3_12",[0,0]];
_vehicle removeMagazineTurret ["rhsusf_mag_duke",[0,0]];
_vehicle addMagazineTurret ["SmokeLauncherMag",[0,0]];
_vehicle addMagazineTurret ["rhs_mag_400rnd_127x99_mag_Tracer_Red",[0,0]];
_vehicle addMagazineTurret ["rhs_mag_400rnd_127x99_mag_Tracer_Red",[0,0]];
_vehicle addMagazineTurret ["rhs_mag_200rnd_127x99_SLAP_mag_Tracer_Red",[0,0]];
_vehicle addMagazineTurret ["rhs_mag_762x51_M240_200",[0,2]];
_vehicle addMagazineTurret ["rhs_mag_762x51_M240_200",[0,2]];
_vehicle addMagazineTurret ["rhs_mag_762x51_M240_200",[0,2]];
_vehicle addMagazineTurret ["rhs_mag_762x51_M240_200",[0,2]];
_vehicle addMagazineTurret ["rhs_mag_762x51_M240_200",[0,2]];
_vehicle addMagazineTurret ["rhs_mag_762x51_M240_200",[0,2]];

// Extrarounds [0,0]
// ["rhs_mag_400rnd_127x99_SLAP_mag_Tracer_Red",[0,0]];