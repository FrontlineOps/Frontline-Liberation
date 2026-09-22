/* Frontline Intelligence & Civilians. Defaults preserve the prior mission configuration. */

[
    "KP_liberation_cr_building_penalty", "SLIDER",
    "Civilian building damage penalty",
    "Reputation lost per qualifying civilian building damaged or destroyed, assessed when the sector is captured.",
    ["Frontline - Intelligence & Civilians", "Civilian reputation"],
    [0, 60, 15, 0], true
] call _add;

[
    "KP_liberation_cr_kill_penalty", "SLIDER",
    "Civilian kill penalty",
    "Reputation lost when friendly forces kill a civilian.",
    ["Frontline - Intelligence & Civilians", "Civilian reputation"],
    [0, 100, 25, 0], true
] call _add;

[
    "KP_liberation_cr_vehicle_penalty", "SLIDER",
    "Civilian vehicle theft penalty",
    "Reputation lost when a civilian vehicle is seized.",
    ["Frontline - Intelligence & Civilians", "Civilian reputation"],
    [0, 28, 7, 0], true
] call _add;

[
    "KP_liberation_cr_resistance_penalty", "SLIDER",
    "Friendly resistance kill penalty",
    "Reputation lost when friendly forces kill an allied resistance fighter.",
    ["Frontline - Intelligence & Civilians", "Civilian reputation"],
    [0, 60, 15, 0], true
] call _add;

[
    "KP_liberation_cr_param_buildings", "CHECKBOX",
    "Penalize building damage before destruction",
    "Count damaged civilian buildings toward the capture penalty. When disabled, only destroyed buildings count.",
    ["Frontline - Intelligence & Civilians", "Civilian reputation"],
    false, false
] call _add;

[
    "KP_liberation_cr_wounded_gain", "SLIDER",
    "Reputation gained for healing civilians",
    "Reputation awarded for successfully treating a wounded civilian.",
    ["Frontline - Intelligence & Civilians", "Civilian reputation"],
    [0, 20, 3, 0], true
] call _add;

[
    "KP_liberation_cr_sector_gain", "SLIDER",
    "Reputation gained per captured sector",
    "Base reputation awarded for a captured sector, before building penalties. Large towns award twice this amount.",
    ["Frontline - Intelligence & Civilians", "Civilian reputation"],
    [0, 20, 5, 0], true
] call _add;

[
    "KP_liberation_cr_wounded_chance", "SLIDER",
    "Wounded civilian chance (%)",
    "Percentage chance of wounded civilians appearing after a sector capture. The first captured sector always triggers the opportunity.",
    ["Frontline - Intelligence & Civilians", "Civilian reputation"],
    [0, 100, 15, 0], true
] call _add;

[
    "KPLIB_intelligence_archive_duration", "SLIDER",
    "Archive duration (seconds)",
    "Seconds a completed or closed intelligence case remains in the case archive.",
    ["Frontline - Intelligence & Civilians", "Intelligence"],
    [1, 7200, 1800, 0], true
] call _add;

[
    "KPLIB_intelligence_delivery_distance", "SLIDER",
    "Delivery distance (m)",
    "Maximum distance in metres between the escort and a prisoner being delivered at an intelligence terminal.",
    ["Frontline - Intelligence & Civilians", "Intelligence"],
    [1, 1000, 40, 0], true
] call _add;

[
    "KPLIB_intelligence_disruption_duration", "SLIDER",
    "Disruption duration (seconds)",
    "Seconds a successful command or fire-support operation blocks the affected sector's new formations or fire missions.",
    ["Frontline - Intelligence & Civilians", "Intelligence"],
    [1, 4800, 1200, 0], true
] call _add;

[
    "KPLIB_intelligence_enabled", "CHECKBOX",
    "Enable intelligence operations",
    "Enable recovered intelligence, informants, prisoner interrogation and linked operations against enemy support networks.",
    ["Frontline - Intelligence & Civilians", "Intelligence"],
    true, false
] call _add;

[
    "KPLIB_intelligence_informant_chance", "SLIDER",
    "Informant chance (%)",
    "Percentage chance of creating an informant contact when the scheduled attempt meets territory and reputation requirements.",
    ["Frontline - Intelligence & Civilians", "Intelligence"],
    [0, 100, 75, 0], true
] call _add;

[
    "KPLIB_intelligence_informant_lifetime", "SLIDER",
    "Informant lifetime (seconds)",
    "Seconds an unattended informant remains available. The countdown pauses while friendly players are nearby.",
    ["Frontline - Intelligence & Civilians", "Intelligence"],
    [1, 4800, 1200, 0], true
] call _add;

[
    "KPLIB_intelligence_informant_min_reputation", "SLIDER",
    "Informant min reputation",
    "Minimum civilian reputation needed for informants to offer contact. Lower values allow contact at worse reputation.",
    ["Frontline - Intelligence & Civilians", "Intelligence"],
    [-100, 0, 0, 2], true
] call _add;

[
    "KPLIB_intelligence_informant_pause_distance", "SLIDER",
    "Informant pause distance (m)",
    "Distance in metres within which a living friendly player pauses an informant's expiry countdown.",
    ["Frontline - Intelligence & Civilians", "Intelligence"],
    [1, 1000, 150, 0], true
] call _add;

[
    "KPLIB_intelligence_interaction_distance", "SLIDER",
    "Interaction distance (m)",
    "Maximum distance in metres for interacting with intelligence sources and interrogating prisoners.",
    ["Frontline - Intelligence & Civilians", "Intelligence"],
    [1, 1000, 4, 0], true
] call _add;

[
    "KPLIB_intelligence_interrogation_duration", "SLIDER",
    "Interrogation duration (seconds)",
    "Seconds the player must remain with an eligible prisoner to complete interrogation.",
    ["Frontline - Intelligence & Civilians", "Intelligence"],
    [1, 3600, 60, 0], true
] call _add;

[
    "KPLIB_intelligence_lead_duration", "SLIDER",
    "Lead duration (seconds)",
    "Seconds recovered source information remains available as an intelligence lead.",
    ["Frontline - Intelligence & Civilians", "Intelligence"],
    [1, 14400, 3600, 0], true
] call _add;

[
    "KPLIB_intelligence_max_active_cases", "SLIDER",
    "Max active cases",
    "Maximum intelligence cases with a populated operation site at the same time. Other accepted cases wait for a slot.",
    ["Frontline - Intelligence & Civilians", "Intelligence"],
    [1, 20, 2, 0], true
] call _add;

[
    "KPLIB_intelligence_max_archived_reports", "SLIDER",
    "Max archived reports",
    "Maximum recovered reports retained in the intelligence archive. The oldest are removed when this limit is exceeded.",
    ["Frontline - Intelligence & Civilians", "Intelligence"],
    [1, 160, 40, 0], true
] call _add;

[
    "KPLIB_intelligence_max_cases", "SLIDER",
    "Max cases",
    "Maximum accepted intelligence cases, counting both active and queued operations.",
    ["Frontline - Intelligence & Civilians", "Intelligence"],
    [1, 24, 6, 0], true
] call _add;

[
    "KPLIB_intelligence_max_detainees", "SLIDER",
    "Max detainees",
    "Maximum delivered prisoners held by the intelligence custody system at once.",
    ["Frontline - Intelligence & Civilians", "Intelligence"],
    [1, 48, 12, 0], true
] call _add;

[
    "KPLIB_intelligence_max_reports", "SLIDER",
    "Max reports",
    "Unused by the current briefing. The Maximum archived reports setting controls how many recovered reports are retained.",
    ["Frontline - Intelligence & Civilians", "Intelligence"],
    [1, 160, 40, 0], false
] call _add;

[
    "KPLIB_intelligence_informant_interval_1", "SLIDER",
    "Maximum informant interval (seconds)",
    "Upper end of the random delay, in seconds, between eligible informant contact attempts.",
    ["Frontline - Intelligence & Civilians", "Intelligence"],
    [60, 86400, 10800, 0], true
] call _add;

[
    "KPLIB_intelligence_informant_interval_0", "SLIDER",
    "Minimum informant interval (seconds)",
    "Lower end of the random delay, in seconds, between eligible informant contact attempts.",
    ["Frontline - Intelligence & Civilians", "Intelligence"],
    [60, 86400, 5400, 0], true
] call _add;

[
    "KPLIB_intelligence_site_radius", "SLIDER",
    "Site radius (m)",
    "Radius in metres around the source objective searched for buildings suitable for an intelligence operation site.",
    ["Frontline - Intelligence & Civilians", "Intelligence"],
    [1, 3600, 900, 0], true
] call _add;

[
    "KPLIB_intelligence_site_statics", "SLIDER",
    "Site statics",
    "Number of crewed static weapons assigned to a new intelligence site, using the current enemy faction's equipment.",
    ["Frontline - Intelligence & Civilians", "Intelligence"],
    [1, 20, 2, 0], true
] call _add;

[
    "KPLIB_intelligence_spawn_clearance", "SLIDER",
    "Spawn clearance",
    "Minimum player clearance in metres before an intelligence operation site can be populated.",
    ["Frontline - Intelligence & Civilians", "Intelligence"],
    [1, 1200, 300, 0], true
] call _add;

[
    "KPLIB_intelligence_stage_duration", "SLIDER",
    "Stage duration (seconds)",
    "Seconds allowed to complete each stage of an intelligence operation.",
    ["Frontline - Intelligence & Civilians", "Intelligence"],
    [1, 14400, 3600, 0], true
] call _add;

[
    "KPLIB_intelligence_stock_loss", "SLIDER",
    "Stock loss",
    "Fraction of remaining manpower, construction supplies, rockets and trucks removed from the source sector by a successful logistics operation.",
    ["Frontline - Intelligence & Civilians", "Intelligence"],
    [0, 1, 0.35, 0, true], true
] call _add;

[
    "KPLIB_intelligence_task_chance", "SLIDER",
    "Task chance",
    "Chance that recovered documents or interrogation information reveal a linked operation. A value of 0.5 gives a 50 percent chance.",
    ["Frontline - Intelligence & Civilians", "Intelligence"],
    [0, 1, 0.2, 0, true], true
] call _add;

[
    "KPLIB_intelligence_terminal_distance", "SLIDER",
    "Terminal distance (m)",
    "Distance in metres from an FOB or patrol base within which intelligence delivery and terminal actions are available.",
    ["Frontline - Intelligence & Civilians", "Intelligence"],
    [1, 1000, 75, 0], true
] call _add;

[
    "KPLIB_radio_disruption_duration", "SLIDER",
    "Disruption duration (seconds)",
    "Seconds enemy command coordination remains disrupted after an enemy-held radio tower is destroyed. Further tower losses refresh the duration.",
    ["Frontline - Intelligence & Civilians", "Radio towers"],
    [1, 14400, 3600, 0], true
] call _add;

[
    "KPLIB_radio_disruption_multiplier", "SLIDER",
    "Disruption multiplier",
    "Multiply enemy command delays while communications are disrupted. A value of 2 makes affected command intervals take twice as long.",
    ["Frontline - Intelligence & Civilians", "Radio towers"],
    [0, 4, 2, 2], true
] call _add;

[
    "KPLIB_radio_intercept_interval_1", "SLIDER",
    "Maximum tower intercept interval (seconds)",
    "Upper end of the random delay, in seconds, between communications intercepts from a captured tower.",
    ["Frontline - Intelligence & Civilians", "Radio towers"],
    [30, 7200, 900, 0], true
] call _add;

[
    "KPLIB_radio_intercept_interval_0", "SLIDER",
    "Minimum tower intercept interval (seconds)",
    "Lower end of the random delay, in seconds, between communications intercepts from a captured tower.",
    ["Frontline - Intelligence & Civilians", "Radio towers"],
    [30, 7200, 600, 0], true
] call _add;

[
    "KPLIB_surrender_chance", "SLIDER",
    "Chance (%)",
    "Percentage chance of surrender when an enemy group breaks or surviving troops are assessed after a battle.",
    ["Frontline - Intelligence & Civilians", "Surrender and prisoners"],
    [0, 100, 40, 0], true
] call _add;

[
    "KPLIB_surrender_escort_break_distance", "SLIDER",
    "Escort break distance (m)",
    "Maximum separation in metres from the escort before an abandoned prisoner can escape.",
    ["Frontline - Intelligence & Civilians", "Surrender and prisoners"],
    [1, 1000, 150, 0], true
] call _add;

[
    "KPLIB_surrender_group_survivor_ratio", "SLIDER",
    "Group survivor ratio",
    "Largest surviving fraction of a group's observed strength that permits a casualty-triggered surrender attempt. A value of 0.5 requires at least half its strength to be lost.",
    ["Frontline - Intelligence & Civilians", "Surrender and prisoners"],
    [0, 1, 0.5, 0, true], true
] call _add;

[
    "KPLIB_surrender_max_prisoners_per_event", "SLIDER",
    "Max prisoners per event",
    "Maximum soldiers who can become prisoners in one surrender event.",
    ["Frontline - Intelligence & Civilians", "Surrender and prisoners"],
    [1, 24, 6, 0], true
] call _add;

[
    "KPLIB_surrender_player_witness_distance", "SLIDER",
    "Player witness distance (m)",
    "Maximum distance in metres from a broken group to a living friendly player for a witnessed surrender attempt.",
    ["Frontline - Intelligence & Civilians", "Surrender and prisoners"],
    [1, 2000, 500, 0], true
] call _add;