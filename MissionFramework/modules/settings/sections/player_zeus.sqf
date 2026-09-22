/* Frontline Player & Zeus. Defaults preserve the prior mission configuration. */

[
    "KP_liberation_mobilearsenal", "CHECKBOX",
    "Mobile arsenal",
    "Allow arsenal crates to provide arsenal access away from FOBs.",
    ["Frontline - Player & Zeus", "Player experience"],
    false, true
] call _add;

[
    "KP_liberation_mobilerespawn", "CHECKBOX",
    "Mobile respawn",
    "Offer eligible mobile respawn vehicles as deployment destinations.",
    ["Frontline - Player & Zeus", "Player experience"],
    false, false
] call _add;

[
    "KP_liberation_respawn_cooldown", "LIST",
    "Mobile respawn cooldown (minutes)",
    "Minutes a player must wait after using mobile respawn before using it again. Disabled removes this cooldown.",
    ["Frontline - Player & Zeus", "Player experience"],
    [[0, 300, 600, 900, 1200, 1800, 3600], ["STR_PARAMS_DISABLED", "5", "10", "15", "20", "30", "60"], 2], true
] call _add;

[
    "GRLIB_fatigue", "CHECKBOX",
    "Player fatigue",
    "Enable normal player stamina. Disabling this removes the mission's stamina restriction on movement.",
    ["Frontline - Player & Zeus", "Player experience"],
    true, false
] call _add;

[
    "KP_liberation_mapmarkers", "CHECKBOX",
    "Player map markers",
    "Show friendly group icons, empty-vehicle markers and the transport helicopter marker on the map.",
    ["Frontline - Player & Zeus", "Player experience"],
    true, false
] call _add;

[
    "KPLIB_respawnOnAttackedSectors", "CHECKBOX",
    "Respawn at attacked sectors",
    "Allow deployment to friendly sectors while they are under attack.",
    ["Frontline - Player & Zeus", "Player experience"],
    false, true
] call _add;

[
    "GRLIB_deployment_cinematic", "CHECKBOX",
    "Show deployment cinematic",
    "Play the moving camera sequence when deploying to a selected location.",
    ["Frontline - Player & Zeus", "Player experience"],
    false, true
] call _add;

[
    "GRLIB_introduction", "CHECKBOX",
    "Show introduction",
    "Show the mission introduction after joining.",
    ["Frontline - Player & Zeus", "Player experience"],
    false, true
] call _add;

[
    "KPLIB_sway", "CHECKBOX",
    "Weapon sway",
    "Use normal player weapon sway. Disabling this reduces the player's aiming coefficient to 0.1.",
    ["Frontline - Player & Zeus", "Player experience"],
    true, false
] call _add;

[
    "KP_liberation_enemies_zeus", "CHECKBOX",
    "Add enemies to Zeus",
    "Add non-civilian enemy units and enemy-catalog vehicles to the commander's editable Zeus objects.",
    ["Frontline - Player & Zeus", "Zeus access"],
    true, false
] call _add;

[
    "KP_liberation_commander_zeus", "CHECKBOX",
    "Commander Zeus access",
    "Give the commander role access to the mission's Zeus interface.",
    ["Frontline - Player & Zeus", "Zeus access"],
    false, false
] call _add;

[
    "KP_liberation_limited_zeus", "CHECKBOX",
    "Limited commander Zeus",
    "Use the restricted commander Zeus mode, limiting what the commander can edit and place.",
    ["Frontline - Player & Zeus", "Zeus access"],
    false, false
] call _add;
