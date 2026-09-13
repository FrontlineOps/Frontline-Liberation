/* Frontline Munitions & Guidance. Defaults preserve the prior mission configuration. */

[
    "KPLIB_munitions_blast_max_jobs", "SLIDER",
    "Maximum concurrent blast jobs",
    "Maximum explosions the server can process for pressure and heat at the same time. Further explosions are skipped by this processor while all slots are occupied.",
    ["Frontline - Munitions & Guidance", "Advanced - effect capacity"],
    [1.0, 16.0, 8, 0], false
] call _add;

[
    "KPLIB_munitions_blast_targets", "SLIDER",
    "Maximum infantry recipients per blast",
    "Maximum living soldiers evaluated for pressure and heat from one explosion, selected nearest to the detonation first.",
    ["Frontline - Munitions & Guidance", "Advanced - effect capacity"],
    [1.0, 64.0, 48, 0], false
] call _add;

[
    "KPLIB_munitions_fragment_cap", "SLIDER",
    "Primary fragment limit per explosion",
    "Maximum primary fragment projectiles requested by one explosion. Ammunition properties determine the count up to this ceiling; increasing it allows larger fragment bursts.",
    ["Frontline - Munitions & Guidance", "Advanced - effect capacity"],
    [1.0, 512.0, 384, 0], false
] call _add;

[
    "KPLIB_munitions_gas_asset_limit", "SLIDER",
    "Vehicle and building recipients per type",
    "Maximum nearby vehicles and maximum nearby buildings evaluated by each pressure field. The limit applies separately to each type.",
    ["Frontline - Munitions & Guidance", "Advanced - effect capacity"],
    [1.0, 16.0, 8, 0], false
] call _add;

[
    "KPLIB_munitions_gas_building_gain", "SLIDER",
    "Building pressure damage multiplier",
    "Scale building damage derived from pressure and accumulated impulse. Higher values increase the resulting structural damage; 0 removes this contribution.",
    ["Frontline - Munitions & Guidance", "Effects"],
    [0.0, 4.0, 1, 2], false
] call _add;

[
    "KPLIB_munitions_gas_enabled", "CHECKBOX",
    "Enable native gas refinement",
    "Use the server's gas solver to evolve pressure and heat around terrain and solid surfaces, refining blast exposure over time. Requires the Frontline gas extension on the server.",
    ["Frontline - Munitions & Guidance", "Effects"],
    true, false
] call _add;

[
    "KPLIB_munitions_gas_assets", "CHECKBOX",
    "Enable pressure damage to vehicles and buildings",
    "Apply damage from the gas pressure field to exposed vehicle components and buildings. Requires native gas refinement.",
    ["Frontline - Munitions & Guidance", "Effects"],
    true, false
] call _add;

[
    "KPLIB_munitions_spatial_fragments", "CHECKBOX",
    "Enable spatial fragmentation",
    "Emit fragment projectiles in randomized directions around eligible explosions. Their flight and collisions determine what they strike.",
    ["Frontline - Munitions & Guidance", "Effects"],
    true, false
] call _add;

[
    "KPLIB_munitions_blast_enabled", "CHECKBOX",
    "Enable supplemental blast effects",
    "Enable Frontline's pressure and heat calculations around explosions, including cover checks and pressure damage to eligible vehicles and buildings.",
    ["Frontline - Munitions & Guidance", "Effects"],
    true, false
] call _add;

[
    "KPLIB_munitions_pressure_gain", "SLIDER",
    "Infantry pressure damage multiplier",
    "Scale infantry injury from direct blast exposure and the refined pressure field. Higher values increase pressure wounds; 0 removes this pressure contribution.",
    ["Frontline - Munitions & Guidance", "Effects"],
    [0.0, 20.0, 8, 0], false
] call _add;

[
    "KPLIB_munitions_thermal_labels", "CHECKBOX",
    "Recognize thermobaric ammunition labels",
    "Use thermobaric and fuel-air wording in ammunition magazine or explosion-effect labels to select prolonged heat exposure when no explicit thermobaric flag is provided.",
    ["Frontline - Munitions & Guidance", "Effects"],
    true, false
] call _add;

[
    "KPLIB_munitions_gas_record", "CHECKBOX",
    "Retain pressure fields from empty impacts",
    "Process and retain pressure fields even when an explosion has no nearby recipients and is outside an active debug capture.",
    ["Frontline - Munitions & Guidance", "Effects"],
    true, false
] call _add;

[
    "KPLIB_munitions_gas_vehicle_gain", "SLIDER",
    "Vehicle pressure damage multiplier",
    "Scale damage to exposed vehicle components from pressure and accumulated impulse. Higher values increase component damage; 0 removes this contribution.",
    ["Frontline - Munitions & Guidance", "Effects"],
    [0.0, 4.0, 1, 2], false
] call _add;

[
    "KPLIB_guidance_enabled", "CHECKBOX",
    "Enable Frontline guidance",
    "Use Frontline's seeker, tracking and steering logic for supported guided ammunition, deriving capabilities from the loaded ammunition configuration.",
    ["Frontline - Munitions & Guidance", "Guidance"],
    true, false
] call _add;

[
    "KPLIB_guidance_warnings", "CHECKBOX",
    "Incoming missile warning sound",
    "Play the aircraft's missile-lock warning sound for its crew when a supported incoming radar or radio-guided missile is detected by its warning equipment.",
    ["Frontline - Munitions & Guidance", "Guidance"],
    true, true
] call _add;

[
    "KPLIB_guidance_max_active", "SLIDER",
    "Maximum guided projectiles",
    "Maximum projectiles under Frontline guidance on each machine. Additional projectiles retain their engine guidance while that machine is at capacity.",
    ["Frontline - Munitions & Guidance", "Guidance"],
    [1, 256, 128, 0], false
] call _add;
