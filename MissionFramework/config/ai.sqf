/* Frontline authored ai data and internal constants.
   Admin-facing options are registered in modules/settings/sections.
   Original mission configuration: https://github.com/KillahPotatoes/KP-Liberation */

KPLIB_aiSkills_factionProfiles = [];

KPLIB_aiSkills_profiles = [
    ["MISSION", [-1, -1, -1, -1, -1, -1, -1, -1, -1]],
    ["MILITIA", [0.40, 0.18, 0.35, 0.40, 0.45, 0.40, 0.45, 0.45, 0.35]],
    ["REGULAR", [0.60, 0.28, 0.55, 0.60, 0.65, 0.60, 0.65, 0.60, 0.60]],
    ["VETERAN", [0.75, 0.38, 0.70, 0.75, 0.80, 0.75, 0.80, 0.75, 0.75]],
    ["ELITE",   [0.90, 0.48, 0.85, 0.90, 0.90, 0.90, 0.90, 0.85, 0.90]]
];

KPLIB_aiSkills_tickInterval = 0.25;

KPLIB_aiSkills_batchSize = 16;

KPLIB_aiSkills_updateInterval = 2;

KPLIB_aiSkills_terrainSamplesPerTick = 2;

KPLIB_aiSkills_terrainInterval = 15;

KPLIB_aiSkills_terrainSaturation = 30;

KPLIB_aiSkills_terrainFloor = [1, 0.65, 0.80, 0.85, 0.50, 0.65, 1, 1, 1];

KPLIB_aiSkills_suppressionFloor = [1, 0.35, 0.50, 0.65, 0.75, 0.65, 0.60, 0.85, 0.75];

KPLIB_aiCombat_batchSize = 8;
