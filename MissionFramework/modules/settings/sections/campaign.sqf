/* Frontline Campaign. Defaults preserve the prior mission configuration. */

[
    "KP_liberation_save_interval", "SLIDER",
    "Campaign autosave interval (seconds)",
    "Seconds between automatic campaign saves.",
    ["Frontline - Campaign", "Economy"],
    [30, 3600, 60, 0], true
] call _add;

[
    "KP_liberation_clear_cargo", "CHECKBOX",
    "Clear vehicle cargo",
    "Empty the default weapons, magazines, items and backpacks from vehicles processed by the mission's cargo setup.",
    ["Frontline - Campaign", "Economy"],
    true, false
] call _add;

[
    "GRLIB_recycling_percentage", "SLIDER",
    "Depot salvage return",
    "Fraction of a vehicle's resource value returned at a Salvage Depot, adjusted for its condition and remaining ammunition and fuel.",
    ["Frontline - Campaign", "Economy"],
    [0, 1, 0.6, 0, true], true
] call _add;

[
    "KPLIB_salvage_field_enabled", "CHECKBOX",
    "Enable field salvage",
    "Allow vehicles to be salvaged away from a Salvage Depot, producing resource crates at the vehicle.",
    ["Frontline - Campaign", "Economy"],
    true, true
] call _add;

[
    "KPLIB_salvage_enemy_multiplier", "SLIDER",
    "Enemy vehicle salvage multiplier",
    "Multiply salvage payouts for enemy vehicles that are absent from the friendly build catalog. A value of 2 doubles their payout.",
    ["Frontline - Campaign", "Economy"],
    [0, 4, 2, 2], true
] call _add;

[
    "KPLIB_factory_crate_value", "SLIDER",
    "Factory crate value",
    "Resource units in each pallet of a factory's initial cache, before the resource multiplier. Each cache contains 12 supply, 8 ammunition and 4 fuel pallets.",
    ["Frontline - Campaign", "Economy"],
    [1, 400, 100, 0], false
] call _add;

[
    "KPLIB_salvage_field_multiplier", "SLIDER",
    "Field salvage return multiplier",
    "Fraction of the depot payout returned by field salvage. A value of 0.5 gives half; the salvage calculation caps this fraction at 1.",
    ["Frontline - Campaign", "Economy"],
    [0, 4, 0.5, 2], true
] call _add;

[
    "KP_liberation_sector_resource_crate_count_1", "SLIDER",
    "Maximum settlement crates",
    "Upper end of the random crate count placed when a settlement receives resource loot.",
    ["Frontline - Campaign", "Economy"],
    [0, 30, 5, 0], false
] call _add;

[
    "KP_liberation_sector_resource_crate_count_0", "SLIDER",
    "Minimum settlement crates",
    "Lower end of the random crate count placed when a settlement receives resource loot. Successful loot placement creates at least one crate.",
    ["Frontline - Campaign", "Economy"],
    [0, 30, 3, 0], false
] call _add;

[
    "GRLIB_resources_multiplier", "LIST",
    "Resource multiplier",
    "Scale resource quantities in settlement loot, factory caches and convoy salvage crates. A value of 2 doubles their base crate values.",
    ["Frontline - Campaign", "Economy"],
    [[0.25, 0.5, 0.75, 1, 1.25, 1.5, 2, 3], ["0.25x", "0.5x", "0.75x", "1x", "1.25x", "1.5x", "2x", "3x"], 3], false
] call _add;

[
    "KP_liberation_production_interval", "SLIDER",
    "Resource production interval (minutes)",
    "Base minutes between resource production cycles. Negative civilian reputation lengthens the interval.",
    ["Frontline - Campaign", "Economy"],
    [1, 1440, 120, 0], false
] call _add;

[
    "KP_liberation_sector_resource_chance", "SLIDER",
    "Sector resource chance (%)",
    "Percentage chance that an activated settlement receives resource crates.",
    ["Frontline - Campaign", "Economy"],
    [0, 100, 100, 0], false
] call _add;

[
    "KP_liberation_sector_resource_crate_value", "SLIDER",
    "Sector resource crate value",
    "Resource units in each settlement loot crate, before the resource multiplier.",
    ["Frontline - Campaign", "Economy"],
    [1, 400, 100, 0], false
] call _add;

[
    "KPLIB_factory_capture_report", "CHECKBOX",
    "Show factory capture popup",
    "Show the captured factory's resource totals in a popup when it is secured.",
    ["Frontline - Campaign", "Economy"],
    true, true
] call _add;

[
    "KP_liberation_autoFaction_vehiclePriceMultipliers_1", "SLIDER",
    "Vehicle ammunition price multiplier",
    "Scale ammunition costs in the automatically generated vehicle build catalog. A value of 2 doubles that part of the price.",
    ["Frontline - Campaign", "Economy"],
    [0, 4, 1, 2], false
] call _add;

[
    "KP_liberation_autoFaction_vehiclePriceMultipliers_2", "SLIDER",
    "Vehicle fuel price multiplier",
    "Scale fuel costs in the automatically generated vehicle build catalog. A value of 2 doubles that part of the price.",
    ["Frontline - Campaign", "Economy"],
    [0, 4, 1, 2], false
] call _add;

[
    "KP_liberation_autoFaction_vehiclePriceMultipliers_0", "SLIDER",
    "Vehicle supply price multiplier",
    "Scale supply costs in the automatically generated vehicle build catalog. A value of 2 doubles that part of the price.",
    ["Frontline - Campaign", "Economy"],
    [0, 4, 1, 2], false
] call _add;

[
    "KPLIB_salvage_wreck_supply_fraction", "SLIDER",
    "Wreck supply return fraction",
    "Fraction of the supply value retained by a destroyed vehicle before the salvage return multiplier. Wrecks return no ammunition or fuel.",
    ["Frontline - Campaign", "Economy"],
    [0, 1, 0.25, 0, true], true
] call _add;

[
    "GRLIB_difficulty_modifier", "LIST",
    "Campaign difficulty multiplier",
    "Scale the increase in enemy combat readiness when objectives are captured. Higher values make captures raise readiness faster.",
    ["Frontline - Campaign", "General"],
    [[1, 2, 3, 4, 5, 6, 8, 10], ["1x", "2x", "3x", "4x", "5x", "6x", "8x", "10x"], 7], false
] call _add;

[
    "GRLIB_civilian_activity", "LIST",
    "Civilian activity",
    "Scale the number of ambient civilian groups created in settlements, towns and factory sectors.",
    ["Frontline - Campaign", "General"],
    [[0, 0.5, 1, 2], ["0x", "0.5x", "1x", "2x"], 3], false
] call _add;

[
    "GRLIB_csat_aggressivity", "LIST",
    "Enemy aggressivity",
    "Aggressivity level checked against the minimum required for enemy air responses.",
    ["Frontline - Campaign", "General"],
    [[2, 3, 4, 5, 6], ["2", "3", "4", "5", "6"], 4], false
] call _add;

[
    "KP_liberation_restart", "LIST",
    "Scheduled restart (hours)",
    "Hours before the dedicated server issues its scheduled restart command, with advance player notifications. Uses the server's configured restart credentials.",
    ["Frontline - Campaign", "General"],
    [[0, 1, 2, 3, 4, 5, 6, 8], ["STR_PARAMS_DISABLED", "1", "2", "3", "4", "5", "6", "8"], 5], false
] call _add;

[
    "GRLIB_unitcap", "LIST",
    "Unit-cap multiplier",
    "Multiply the OPFOR population threshold used to permit sector activation. Higher values allow activation to continue with more OPFOR already present.",
    ["Frontline - Campaign", "General"],
    [[0.5, 0.75, 1, 1.25, 1.5, 2], ["0.5x", "0.75x", "1x", "1.25x", "1.5x", "2x"], 3], false
] call _add;

[
    "KP_liberation_victoryCondition", "LIST",
    "Victory condition",
    "Choose which objective categories must be captured to win the campaign.",
    ["Frontline - Campaign", "General"],
    [[0, 1, 2, 3, 4], ["STR_PARAMS_VICTORYCONDITION_0", "STR_PARAMS_VICTORYCONDITION_1", "STR_PARAMS_VICTORYCONDITION_2", "STR_PARAMS_VICTORYCONDITION_3", "STR_PARAMS_VICTORYCONDITION_4"], 4], false
] call _add;

[
    "GRLIB_capture_size", "SLIDER",
    "Capture area radius",
    "Radius in metres used to count opposing forces for sector control. Large towns use 1.4 times this radius.",
    ["Frontline - Campaign", "Objectives"],
    [1, 900, 225, 0], false
] call _add;

[
    "GRLIB_vulnerability_timer", "SLIDER",
    "Enemy sector capture time (seconds)",
    "Time enemy forces must hold control to overrun an FOB. Captured sectors add 120 seconds to this value.",
    ["Frontline - Campaign", "Objectives"],
    [1, 3600, 840, 0], false
] call _add;

[
    "GRLIB_radiotower_size", "SLIDER",
    "Radio tower range",
    "Radius in metres around friendly radio towers within which enemy groups can appear on the map.",
    ["Frontline - Campaign", "Objectives"],
    [1, 10000, 2500, 0], false
] call _add;

[
    "GRLIB_sector_size", "SLIDER",
    "Sector activation distance",
    "Maximum player proximity range, in metres, for activating sector defenders. The range contracts as the OPFOR population rises.",
    ["Frontline - Campaign", "Objectives"],
    [500, 10000, 3000, 0], false
] call _add;

[
    "KPLIB_sector_activation_opfor_base", "SLIDER",
    "Sector activation population threshold",
    "OPFOR count at which new sector activation pauses, multiplied by the unit-cap setting. Activation range begins shrinking at half this count.",
    ["Frontline - Campaign", "Objectives"],
    [25, 2000, 480, 0], false
] call _add;

[
    "GRLIB_time_factor", "LIST",
    "Nominal full-day duration (real hours)",
    "Real hours for a complete 24-hour day at the selected time acceleration, before the shorter-nights option.",
    ["Frontline - Campaign", "Time and weather"],
    [[8, 6, 4, 3, 2, 1], ["3", "4", "6", "8", "12", "24"], 1], false
] call _add;

[
    "GRLIB_shorter_nights", "CHECKBOX",
    "Shorter nights",
    "Advance time four times faster between 20:00 and 04:00 than during the day.",
    ["Frontline - Campaign", "Time and weather"],
    true, false
] call _add;

[
    "KP_liberation_fog_param", "CHECKBOX",
    "Vanilla fog",
    "Allow engine-controlled fog. Disabling this makes the mission repeatedly clear fog.",
    ["Frontline - Campaign", "Time and weather"],
    false, false
] call _add;

[
    "GRLIB_weather_param", "LIST",
    "Weather mode",
    "Choose a fixed light-cloud sky, variable clear-to-cloudy weather, or the full weather range including heavy overcast.",
    ["Frontline - Campaign", "Time and weather"],
    [[1, 2, 3], ["STR_WEATHER_PARAM1", "STR_WEATHER_PARAM2", "STR_WEATHER_PARAM3"], 1], false
] call _add;
