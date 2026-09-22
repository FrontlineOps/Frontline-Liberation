/* Frontline Bases & Logistics. Defaults preserve the prior mission configuration. */

[
    "KP_liberation_allow_fixedwing_at_fobs", "CHECKBOX",
    "Allow fixed-wing construction at FOBs",
    "Permit aircraft construction at FOBs when general vehicle construction there is disabled.",
    ["Frontline - Bases & Logistics", "FOBs"],
    false, true
] call _add;

[
    "KP_liberation_allow_fob_vehcile_building", "CHECKBOX",
    "Allow vehicle construction at FOBs",
    "Permit ground vehicles and helicopters to be built at FOBs as well as the starting base.",
    ["Frontline - Bases & Logistics", "FOBs"],
    false, true
] call _add;

[
    "GRLIB_fob_range", "SLIDER",
    "FOB construction radius (m)",
    "Radius in metres used for FOB construction and nearby base services.",
    ["Frontline - Bases & Logistics", "FOBs"],
    [1, 1200, 300, 0], true
] call _add;

[
    "GRLIB_maximum_fobs", "LIST",
    "Maximum FOBs",
    "Maximum number of FOBs that may exist at once.",
    ["Frontline - Bases & Logistics", "FOBs"],
    [[1, 2, 3, 4, 5, 6, 7], ["1", "2", "3", "4", "5", "6", "7"], 1], true
] call _add;

[
    "KPLIB_fieldHospital_actionDuration", "SLIDER",
    "Action duration (seconds)",
    "Seconds needed to deploy or repack a field hospital.",
    ["Frontline - Bases & Logistics", "Field hospital"],
    [1, 3600, 15, 0], true
] call _add;

[
    "KPLIB_fieldHospital_repackDistance", "SLIDER",
    "Repack distance (m)",
    "Maximum distance in metres from a field hospital at which its owner can repack it.",
    ["Frontline - Bases & Logistics", "Field hospital"],
    [1, 1000, 5, 0], true
] call _add;

[
    "KPLIB_COPS_CONTEST_COUNT", "SLIDER",
    "Contest count",
    "Number of nearby hostile units or vehicles needed to block deployment to a patrol base.",
    ["Frontline - Bases & Logistics", "Patrol bases"],
    [1, 20, 3, 0], true
] call _add;

[
    "KPLIB_COPS_CONTEST_RADIUS", "SLIDER",
    "Contest radius (m)",
    "Radius in metres around a patrol base checked for hostiles before offering it as a deployment destination.",
    ["Frontline - Bases & Logistics", "Patrol bases"],
    [1, 1200, 300, 0], true
] call _add;

[
    "KPLIB_COPS_MAX", "SLIDER",
    "Maximum patrol bases",
    "Maximum number of deployed patrol bases shared by BLUFOR.",
    ["Frontline - Bases & Logistics", "Patrol bases"],
    [1, 20, 1, 0], true
] call _add;

[
    "KPLIB_COPS_DISMANTLE_COOLDOWN", "SLIDER",
    "Minimum deployment time before dismantling (seconds)",
    "Seconds a newly placed patrol base must remain deployed before its owner can dismantle it.",
    ["Frontline - Bases & Logistics", "Patrol bases"],
    [1, 10800, 2700, 0], true
] call _add;

[
    "KPLIB_COPS_MIN_FOB_DISTANCE", "SLIDER",
    "Minimum distance from FOBs (m)",
    "Minimum distance in metres from an FOB or the starting base when placing a patrol base.",
    ["Frontline - Bases & Logistics", "Patrol bases"],
    [1, 2000, 500, 0], true
] call _add;

[
    "KPLIB_COPS_MIN_HOSTILE_SECTOR_DISTANCE", "SLIDER",
    "Minimum distance from enemy objectives (m)",
    "Minimum distance in metres from an enemy objective when placing a patrol base.",
    ["Frontline - Bases & Logistics", "Patrol bases"],
    [1, 2000, 500, 0], true
] call _add;

[
    "KPLIB_COPS_REDEPLOY_RADIUS", "SLIDER",
    "Redeploy radius (m)",
    "Distance in metres within which a patrol base offers redeployment and can be dismantled by its owner.",
    ["Frontline - Bases & Logistics", "Patrol bases"],
    [1, 1000, 20, 0], true
] call _add;

[
    "KPLIB_COPS_SECTOR_SEARCH_DISTANCE", "SLIDER",
    "Sector search distance (m)",
    "Search radius in metres for the nearest enemy objective when validating patrol-base placement.",
    ["Frontline - Bases & Logistics", "Patrol bases"],
    [1, 10000, 2500, 0], true
] call _add;

[
    "KP_liberation_fuel_neutral", "SLIDER",
    "Fuel endurance at idle (minutes)",
    "Minutes for a full tank to drain while stationary with the engine running. Higher values reduce fuel consumption.",
    ["Frontline - Bases & Logistics", "Vehicle fuel"],
    [1, 720, 180, 0], true
] call _add;

[
    "KP_liberation_fuel_max", "SLIDER",
    "Fuel endurance at maximum speed (minutes)",
    "Minutes for a full tank to drain at maximum driving speed. Higher values reduce fuel consumption.",
    ["Frontline - Bases & Logistics", "Vehicle fuel"],
    [1, 180, 45, 0], true
] call _add;

[
    "KP_liberation_fuel_normal", "SLIDER",
    "Fuel endurance at normal speed (minutes)",
    "Minutes for a full tank to drain at normal driving speed. Higher values reduce fuel consumption.",
    ["Frontline - Bases & Logistics", "Vehicle fuel"],
    [1, 360, 90, 0], true
] call _add;
