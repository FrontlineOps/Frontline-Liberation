/* Frontline Cleanup & Diagnostics. Defaults preserve the prior mission configuration. */

[
    "GRLIB_cleanup_vehicles", "LIST",
    "Abandoned vehicle cleanup",
    "Hours before empty friendly-catalog vehicles outside FOB and starting-base protection are removed. Disabled turns off this cleanup.",
    ["Frontline - Cleanup & Diagnostics", "Cleanup"],
    [[0, 1, 2, 4], ["STR_PARAMS_DISABLED", "STR_CLEANUP_PARAM1", "STR_CLEANUP_PARAM2", "STR_CLEANUP_PARAM3"], 0], true
] call _add;

[
    "GRLIB_cleanup_delay", "SLIDER",
    "Dead-unit hiding delay (seconds)",
    "Seconds after death before a queued body is hidden; deletion follows ten seconds later.",
    ["Frontline - Cleanup & Diagnostics", "Cleanup"],
    [1, 3600, 250, 0], true
] call _add;

[
    "KPLIB_trashCleanup_lifetime", "SLIDER",
    "Dropped-item lifetime (seconds)",
    "Seconds dropped equipment holders remain before the cleanup worker can remove them.",
    ["Frontline - Cleanup & Diagnostics", "Cleanup"],
    [1, 3600, 240, 0], true
] call _add;

[
    "KP_liberation_delayDespawnMax", "LIST",
    "Maximum despawn delay (minutes)",
    "Maximum extra minutes a sector can remain active after players leave, accumulated from the time players spent there.",
    ["Frontline - Cleanup & Diagnostics", "Cleanup"],
    [[0, 5, 10, 15, 20, 25, 30], ["STR_PARAMS_DISABLED", "5", "10", "15", "20", "25", "30"], 1], true
] call _add;

[
    "KPLIB_aiSkills_debug", "CHECKBOX",
    "AI skill RPT logging",
    "Write AI skill profile assignments and restoration of original skills to the RPT log.",
    ["Frontline - Cleanup & Diagnostics", "Logging"],
    false, true
] call _add;

[
    "KP_liberation_asymmetric_debug", "LIST",
    "Asymmetric events RPT logging",
    "Write resistance casualty attribution from asymmetric encounters to the RPT log.",
    ["Frontline - Cleanup & Diagnostics", "Logging"],
    [[0, 1], ["Off", "On"], 0], true
] call _add;

[
    "KP_liberation_savegame_debug", "LIST",
    "Campaign saving RPT logging",
    "Write campaign save completion times to the RPT log.",
    ["Frontline - Cleanup & Diagnostics", "Logging"],
    [[0, 1], ["Off", "On"], 0], true
] call _add;

[
    "KP_liberation_civrep_debug", "LIST",
    "Civilian reputation RPT logging",
    "Write reputation changes, civilian casualties, wounded-civilian events and resistance relationships to the RPT log.",
    ["Frontline - Cleanup & Diagnostics", "Logging"],
    [[0, 1], ["Off", "On"], 0], true
] call _add;

[
    "KPLIB_guidance_debug", "CHECKBOX",
    "Guidance RPT logging",
    "Write guided-projectile starts, ammunition families and retirement reasons to the RPT log.",
    ["Frontline - Cleanup & Diagnostics", "Logging"],
    false, true
] call _add;

[
    "KPLIB_aiCombat_debug", "CHECKBOX",
    "Infantry combat RPT logging",
    "Write infantry fire-support outcomes and cancellation reasons to the RPT log.",
    ["Frontline - Cleanup & Diagnostics", "Logging"],
    false, true
] call _add;

[
    "KP_liberation_kill_debug", "LIST",
    "Kill accounting RPT logging",
    "Write kill attribution, processing locality and ACE killer-lookup results to the RPT log.",
    ["Frontline - Cleanup & Diagnostics", "Logging"],
    [[0, 1], ["Off", "On"], 0], true
] call _add;

[
    "KP_liberation_production_debug", "LIST",
    "Resource production RPT logging",
    "Write resource production cycle starts, sector updates and completion times to the RPT log.",
    ["Frontline - Cleanup & Diagnostics", "Logging"],
    [[0, 1], ["Off", "On"], 0], true
] call _add;

[
    "KP_liberation_runtime_diagnostics", "CHECKBOX",
    "Runtime RPT diagnostics",
    "Enable periodic performance and entity-count reports in the RPT and the server performance map marker.",
    ["Frontline - Cleanup & Diagnostics", "Logging"],
    false, true
] call _add;

[
    "KP_liberation_sectorspawn_debug", "LIST",
    "Sector spawning RPT logging",
    "Write sector population completion messages to the RPT log.",
    ["Frontline - Cleanup & Diagnostics", "Logging"],
    [[0, 1], ["Off", "On"], 0], true
] call _add;
