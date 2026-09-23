/* Frontline AI. Defaults preserve the prior mission configuration. */

[
    "KPLIB_vehicleCombat_enabled", "CHECKBOX",
    "Enable armored vehicle combat",
    "Let AI tank, APC and IFV crews engage known visible ground targets at extended range and select suitable ammunition from their turret inventory. Applies to all combat sides; vehicles with player crews retain manual control.",
    ["Frontline - AI", "Vehicle combat"],
    true, true
] call _add;

[
    "KPLIB_vehicleCombat_rangeMultiplier", "SLIDER",
    "Vehicle engagement range multiplier",
    "Multiply each weapon's configured AI engagement range. Gun and machine-gun distance caps, projectile lifetime and missile control limits still bound each available round.",
    ["Frontline - AI", "Vehicle combat"],
    [1, 3, 2, 1], true
] call _add;

[
    "KPLIB_vehicleCombat_gunRange", "SLIDER",
    "Cannon and missile range cap (m)",
    "Farthest distance for deliberate cannon and anti-tank missile engagements. Crews need a known hostile target, clear sight and a loaded weapon capable of reaching it.",
    ["Frontline - AI", "Vehicle combat"],
    [1000, 6000, 5000, 0], true
] call _add;

[
    "KPLIB_vehicleCombat_mgRange", "SLIDER",
    "Vehicle machine-gun range cap (m)",
    "Farthest distance for deliberate vehicle machine-gun fire. Beyond this, crews can select suitable cannon ammunition if they carry it.",
    ["Frontline - AI", "Vehicle combat"],
    [500, 2500, 1800, 0], true
] call _add;

[
    "KPLIB_vehicleCombat_maxActive", "SLIDER",
    "Concurrent controlled turrets per owner",
    "Maximum simultaneous deliberate vehicle engagements on the server or each headless client. Other turrets continue native combat while waiting for a slot.",
    ["Frontline - AI", "Vehicle combat"],
    [1, 24, 12, 0], true
] call _add;

[
    "KPLIB_vehicleCombat_debug", "CHECKBOX",
    "Log vehicle ammunition decisions",
    "Write controlled vehicle shots, ammunition, target class and engagement distance to the owning server or headless client's RPT.",
    ["Frontline - AI", "Vehicle combat"],
    false, true
] call _add;

[
    "KPLIB_aiCombat_side_west", "CHECKBOX",
    "Apply to BLUFOR",
    "Include BLUFOR AI infantry in Frontline's extended fire-support and gunfire-hearing behavior.",
    ["Frontline - AI", "Infantry combat"],
    false, true
] call _add;

[
    "KPLIB_aiCombat_side_resistance", "CHECKBOX",
    "Apply to Independent",
    "Include Independent AI infantry in Frontline's extended fire-support and gunfire-hearing behavior.",
    ["Frontline - AI", "Infantry combat"],
    true, true
] call _add;

[
    "KPLIB_aiCombat_side_east", "CHECKBOX",
    "Apply to OPFOR",
    "Include OPFOR AI infantry in Frontline's extended fire-support and gunfire-hearing behavior.",
    ["Frontline - AI", "Infantry combat"],
    true, true
] call _add;

[
    "KPLIB_aiCombat_backblastRange", "SLIDER",
    "Backblast range (m)",
    "Distance in metres checked behind a launcher for obstructions and nearby people before the AI fires.",
    ["Frontline - AI", "Infantry combat"],
    [10.0, 100.0, 20, 0], true
] call _add;

[
    "KPLIB_aiCombat_enabled", "CHECKBOX",
    "Enable Frontline infantry combat",
    "Enable deliberate long-range rifle fire, rocket and grenade-launcher support, carried illumination and gunfire responses for eligible AI infantry.",
    ["Frontline - AI", "Infantry combat"],
    true, true
] call _add;

[
    "KPLIB_aiCombat_hearing", "CHECKBOX",
    "Enable gunfire hearing",
    "Let AI hear approximate gunfire locations: idle groups and patrols investigate briefly, and sustained fire is reported to the enemy commander as an unconfirmed contact, without identifying the shooter. Other missions are not replaced. Weapons, suppressors and obstructions affect hearing.",
    ["Frontline - AI", "Infantry combat"],
    true, true
] call _add;

[
    "KPLIB_aiCombat_explosiveCooldown", "SLIDER",
    "Explosive cooldown (seconds)",
    "Minimum seconds between a soldier's Frontline-controlled rocket or grenade-launcher shots.",
    ["Frontline - AI", "Infantry combat"],
    [5.0, 600.0, 25, 0], true
] call _add;

[
    "KPLIB_aiCombat_flareCooldown", "SLIDER",
    "Flare cooldown (seconds)",
    "Minimum seconds between illumination shots by the same AI group.",
    ["Frontline - AI", "Infantry combat"],
    [30.0, 600.0, 90, 0], true
] call _add;

[
    "KPLIB_aiCombat_flareRadius", "SLIDER",
    "Flare radius (m)",
    "Radius in metres treated as illuminated by a tracked flare. Nearby groups avoid firing overlapping illumination within this radius.",
    ["Frontline - AI", "Infantry combat"],
    [100.0, 600.0, 350, 0], true
] call _add;

[
    "KPLIB_aiCombat_blastMargin", "SLIDER",
    "Friendly explosive clearance (m)",
    "Extra clearance in metres added to the ammunition's blast radius when checking for friendly units and civilians before an explosive shot.",
    ["Frontline - AI", "Infantry combat"],
    [5.0, 100.0, 12, 0], true
] call _add;

[
    "KPLIB_aiCombat_grenadeRange", "SLIDER",
    "Grenade launcher range ceiling (m)",
    "Maximum distance in metres for deliberate grenade-launcher shots, also constrained by the selected weapon and ammunition.",
    ["Frontline - AI", "Infantry combat"],
    [50.0, 800.0, 450, 0], true
] call _add;

[
    "KPLIB_aiCombat_groupExplosiveCooldown", "SLIDER",
    "Group explosive cooldown (seconds)",
    "Minimum seconds between Frontline-controlled explosive shots across all soldiers in the same group.",
    ["Frontline - AI", "Infantry combat"],
    [2.0, 120.0, 8, 0], true
] call _add;

[
    "KPLIB_aiCombat_hearingRange", "SLIDER",
    "Hearing range (m)",
    "Reference gunfire hearing distance in metres. The weapon's audible report and suppressor change the effective range, with further obstruction checks at the listener.",
    ["Frontline - AI", "Infantry combat"],
    [100.0, 3000.0, 1200, 0], true
] call _add;

[
    "KPLIB_aiCombat_maxActive", "SLIDER",
    "Maximum simultaneous fire-support actions",
    "Maximum soldiers simultaneously performing a Frontline aiming or fire-support action on the server.",
    ["Frontline - AI", "Infantry combat"],
    [1.0, 32.0, 12, 0], true
] call _add;

[
    "KPLIB_aiCombat_minRifleRange", "SLIDER",
    "Minimum extended rifle engagement distance (m)",
    "Distance in metres beyond which Frontline can request deliberate extended-range rifle shots.",
    ["Frontline - AI", "Infantry combat"],
    [50.0, 2000.0, 300, 0], true
] call _add;

[
    "KPLIB_aiCombat_rangeMultiplier", "SLIDER",
    "Native engagement range multiplier",
    "Multiply the weapon's configured engagement distance before applying the rifle, rocket or grenade-launcher ceiling.",
    ["Frontline - AI", "Infantry combat"],
    [1.0, 4.0, 2, 2], true
] call _add;

[
    "KPLIB_aiCombat_rifleRange", "SLIDER",
    "Rifle range ceiling (m)",
    "Maximum distance in metres for extended rifle engagements and infantry target searches.",
    ["Frontline - AI", "Infantry combat"],
    [100.0, 2000.0, 1200, 0], true
] call _add;

[
    "KPLIB_aiCombat_launcherRange", "SLIDER",
    "Rocket launcher range ceiling (m)",
    "Maximum distance in metres for deliberate rocket-launcher shots, also constrained by the selected weapon and ammunition.",
    ["Frontline - AI", "Infantry combat"],
    [50.0, 1500.0, 700, 0], true
] call _add;

[
    "KPLIB_aiCombat_soundMemory", "SLIDER",
    "Sound memory (seconds)",
    "Seconds a gunfire report remains available for AI hearing responses.",
    ["Frontline - AI", "Infantry combat"],
    [5.0, 60.0, 20, 0], true
] call _add;

[
    "KPLIB_aiCombat_suppressedRange", "SLIDER",
    "Suppressed range (m)",
    "Maximum hearing distance in metres for suppressed gunfire reports.",
    ["Frontline - AI", "Infantry combat"],
    [10.0, 500.0, 180, 0], true
] call _add;

[
    "KPLIB_aiCombat_flares", "CHECKBOX",
    "Use carried illumination rounds",
    "Allow AI carrying compatible illumination rounds to fire them at night when nearby illumination is absent.",
    ["Frontline - AI", "Infantry combat"],
    true, true
] call _add;

[
    "KPLIB_aiSkills_side_west", "CHECKBOX",
    "Apply to BLUFOR",
    "Apply Frontline skill profiles and their terrain, weather and suppression modifiers to eligible BLUFOR AI.",
    ["Frontline - AI", "Skills and suppression"],
    true, true
] call _add;

[
    "KPLIB_aiSkills_side_resistance", "CHECKBOX",
    "Apply to Independent",
    "Apply Frontline skill profiles and their terrain, weather and suppression modifiers to eligible Independent AI.",
    ["Frontline - AI", "Skills and suppression"],
    true, true
] call _add;

[
    "KPLIB_aiSkills_side_east", "CHECKBOX",
    "Apply to OPFOR",
    "Apply Frontline skill profiles and their terrain, weather and suppression modifiers to eligible OPFOR AI.",
    ["Frontline - AI", "Skills and suppression"],
    true, true
] call _add;

[
    "KPLIB_aiSkills_profile_west", "LIST",
    "BLUFOR skill profile",
    "Choose the baseline skill profile for BLUFOR AI before individual variation and situational modifiers.",
    ["Frontline - AI", "Skills and suppression"],
    [["MISSION", "MILITIA", "REGULAR", "VETERAN", "ELITE"], ["Mission original", "Militia", "Regular", "Veteran", "Elite"], 3], true
] call _add;

[
    "KPLIB_aiSkills_boostMinDistance", "SLIDER",
    "Boost min distance (m)",
    "Minimum target distance in metres at which sustained fire can improve the shooter's aiming skills.",
    ["Frontline - AI", "Skills and suppression"],
    [0.0, 5000.0, 150, 0], true
] call _add;

[
    "KPLIB_aiSkills_boostShotInterval", "SLIDER",
    "Boost shot interval (seconds)",
    "Minimum seconds between shots counted toward sustained-fire adaptation. A rapid burst cannot gain multiple steps inside this interval.",
    ["Frontline - AI", "Skills and suppression"],
    [0.25, 60.0, 2, 2], true
] call _add;

[
    "KPLIB_aiSkills_enabled", "CHECKBOX",
    "Enable Frontline AI skills",
    "Apply configured AI skill profiles, individual variation and situational modifiers to eligible soldiers.",
    ["Frontline - AI", "Skills and suppression"],
    true, true
] call _add;

[
    "KPLIB_aiSkills_boostEnabled", "CHECKBOX",
    "Enable sustained-fire adaptation",
    "Gradually improve aiming skills while an AI keeps firing at the same visible hostile target.",
    ["Frontline - AI", "Skills and suppression"],
    true, true
] call _add;

[
    "KPLIB_aiSkills_fogFloor", "SLIDER",
    "Fog floor",
    "Fraction of spotting ability retained at maximum fog before other modifiers. Lower values give fog a stronger spotting penalty.",
    ["Frontline - AI", "Skills and suppression"],
    [0.0, 1.0, 0.65, 0, true], true
] call _add;

[
    "KPLIB_aiSkills_profile_resistance", "LIST",
    "Independent skill profile",
    "Choose the baseline skill profile for Independent AI before individual variation and situational modifiers.",
    ["Frontline - AI", "Skills and suppression"],
    [["MISSION", "MILITIA", "REGULAR", "VETERAN", "ELITE"], ["Mission original", "Militia", "Regular", "Veteran", "Elite"], 1], true
] call _add;

[
    "KPLIB_aiSkills_boostMaximum", "SLIDER",
    "Maximum sustained-fire skill multiplier",
    "Maximum aiming-skill multiplier reached through sustained fire at the same target. A value of 1 adds no improvement.",
    ["Frontline - AI", "Skills and suppression"],
    [1.0, 1.5, 1.1, 2], true
] call _add;

[
    "KPLIB_aiSkills_nightFloor", "SLIDER",
    "Night floor",
    "Fraction of spotting ability retained in darkness before other modifiers. Equipped night-vision gear bypasses this darkness modifier.",
    ["Frontline - AI", "Skills and suppression"],
    [0.0, 1.0, 0.6, 0, true], true
] call _add;

[
    "KPLIB_aiSkills_profile_east", "LIST",
    "OPFOR skill profile",
    "Choose the baseline skill profile for OPFOR AI before individual variation and situational modifiers.",
    ["Frontline - AI", "Skills and suppression"],
    [["MISSION", "MILITIA", "REGULAR", "VETERAN", "ELITE"], ["Mission original", "Militia", "Regular", "Veteran", "Elite"], 2], true
] call _add;

[
    "KPLIB_aiSkills_rainFloor", "SLIDER",
    "Rain floor",
    "Fraction of spotting ability retained at maximum rain before other modifiers. Lower values give rain a stronger spotting penalty.",
    ["Frontline - AI", "Skills and suppression"],
    [0.0, 1.0, 0.85, 0, true], true
] call _add;

[
    "KPLIB_aiSkills_boostShots", "SLIDER",
    "Shots needed for sustained-fire adaptation",
    "Number of qualifying shots needed to reach the maximum sustained-fire aiming improvement.",
    ["Frontline - AI", "Skills and suppression"],
    [1.0, 100.0, 5, 0], true
] call _add;

[
    "KPLIB_aiSkills_suppressionEnabled", "CHECKBOX",
    "Suppression enabled",
    "Reduce affected AI skills under incoming fire, then restore them as suppression wears off.",
    ["Frontline - AI", "Skills and suppression"],
    true, true
] call _add;

[
    "KPLIB_aiSkills_suppressionHold", "SLIDER",
    "Suppression hold (seconds)",
    "Seconds after the latest incoming-fire event before accumulated suppression starts to decay.",
    ["Frontline - AI", "Skills and suppression"],
    [0.0, 600.0, 8, 0], true
] call _add;

[
    "KPLIB_aiSkills_suppressionImpact", "SLIDER",
    "Suppression impact",
    "Suppression added by each accepted hostile incoming-fire event, up to a total of 1. Higher values reach strong suppression sooner.",
    ["Frontline - AI", "Skills and suppression"],
    [0.0, 1.0, 0.15, 0, true], true
] call _add;

[
    "KPLIB_aiSkills_suppressionRecovery", "SLIDER",
    "Suppression recovery (seconds)",
    "Seconds needed for full accumulated suppression to decay after the hold period ends.",
    ["Frontline - AI", "Skills and suppression"],
    [0.1, 600.0, 20, 2], true
] call _add;

[
    "KPLIB_aiSkills_boostExpiry", "SLIDER",
    "Sustained-fire adaptation expiry (seconds)",
    "Seconds without a qualifying shot before the accumulated sustained-fire aiming improvement is lost.",
    ["Frontline - AI", "Skills and suppression"],
    [0.25, 600.0, 12, 2], true
] call _add;

[
    "KPLIB_aiSkills_boostTargetMovement", "SLIDER",
    "Target movement that resets adaptation (m)",
    "Target displacement in metres that resets the shooter's accumulated aiming improvement.",
    ["Frontline - AI", "Skills and suppression"],
    [0.0, 500.0, 25, 0], true
] call _add;

[
    "KPLIB_aiSkills_terrainRadius", "SLIDER",
    "Terrain radius (m)",
    "Radius in metres around an AI soldier sampled for trees and bushes when calculating vegetation-related skill modifiers.",
    ["Frontline - AI", "Skills and suppression"],
    [1.0, 100.0, 25, 0], true
] call _add;

[
    "KPLIB_aiSkills_variation", "SLIDER",
    "Variation",
    "Random fraction added to or subtracted from each soldier's configured baseline skills. Each soldier keeps a stable variation; 0 removes it.",
    ["Frontline - AI", "Skills and suppression"],
    [0.0, 1.0, 0.08, 0, true], true
] call _add;

[
    "KPLIB_aiSkills_weatherEnabled", "CHECKBOX",
    "Weather enabled",
    "Adjust spotting skills for darkness, rain and fog using the configured retained-skill fractions.",
    ["Frontline - AI", "Skills and suppression"],
    true, true
] call _add;
