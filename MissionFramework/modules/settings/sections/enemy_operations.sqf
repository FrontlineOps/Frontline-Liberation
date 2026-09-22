/* Frontline Enemy Operations. Defaults preserve the prior mission configuration.
   Live policy changes apply on the next consumer check/new operation;
   existing compositions, paid resources and recorded deadlines are retained. */

[
    "BATTLESPACE_AA_PROC_RANGE", "SLIDER",
    "Air defence activation distance (m)",
    "Horizontal distance in metres from players at which virtual air-defence task forces become physical units.",
    ["Frontline - Enemy Operations", "Activation and population"],
    [1, 10000, 2500, 0], true
] call _add;

[
    "BATTLESPACE_AIR_PROC_RANGE", "SLIDER",
    "Aircraft activation distance (m)",
    "Horizontal distance in metres from players at which virtual attack aircraft and airborne transports become physical aircraft.",
    ["Frontline - Enemy Operations", "Activation and population"],
    [1, 12000, 3000, 0], true
] call _add;

[
    "BATTLESPACE_UNIT_PROC_RANGE", "SLIDER",
    "Ground force activation distance (m)",
    "Distance in metres from players at which virtual ground task forces become physical units.",
    ["Frontline - Enemy Operations", "Activation and population"],
    [1, 4700, 1175, 0], true
] call _add;

[
    "BATTLESPACE_MINEFIELD_PROC_RANGE", "SLIDER",
    "Minefield activation distance (m)",
    "Distance in metres from players at which virtual minefields are created as physical mines.",
    ["Frontline - Enemy Operations", "Activation and population"],
    [1, 4500, 1125, 0], true
] call _add;

[
    "BATTLESPACE_UNIT_CAP", "SLIDER",
    "Physical AI unit cap",
    "OPFOR population ceiling used when admitting physical task-force spawns, including reserved capacity for groups being created. Live edits affect new spawn admissions; existing units are not deleted.",
    ["Frontline - Enemy Operations", "Activation and population"],
    [25, 1000, 200, 0], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_CASUALTY_RESPONSE_THRESHOLD", "SLIDER",
    "Casualty response threshold",
    "Accumulated casualty pressure needed before the enemy can dispatch a reserve response to a sector or field incident.",
    ["Frontline - Enemy Operations", "Command and resources"],
    [1, 32, 8, 0], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_DECISION_INTERVAL", "SLIDER",
    "Decision interval (seconds)",
    "Seconds between enemy infrastructure planning passes, before communications disruption delays.",
    ["Frontline - Enemy Operations", "Command and resources"],
    [1, 7200, 1800, 0], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_DEFENSIVE_PATROL_VEHICLE_CHANCE", "SLIDER",
    "Defensive patrol vehicle chance",
    "Chance that a defensive patrol receives one affordable light vehicle. A value of 0.5 gives a 50 percent chance.",
    ["Frontline - Enemy Operations", "Command and resources"],
    [0, 1, 0.2, 0, true], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_ENABLED", "CHECKBOX",
    "Enable strategic enemy operations",
    "Enable enemy resource accounting, resupply and funded strategic formations and infrastructure. Startup-only: strategic accounting and workers need a mission restart.",
    ["Frontline - Enemy Operations", "Command and resources"],
    true, false
] call _add;

[
    "BATTLESPACE_STRATEGIC_GROUND_FORCE_CAP", "SLIDER",
    "Ground force cap",
    "Maximum concurrent enemy ground formations shared by garrisons, field patrols, reserves, offensives and deep reconnaissance.",
    ["Frontline - Enemy Operations", "Command and resources"],
    [1, 384, 96, 0], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_INITIAL_DELAY", "SLIDER",
    "Initial delay (seconds)",
    "Seconds before the first strategic planning pass after initialization. Initial scheduling only; requires a mission restart.",
    ["Frontline - Enemy Operations", "Command and resources"],
    [1, 3600, 300, 0], false
] call _add;

[
    "BATTLESPACE_STRATEGIC_INITIAL_STOCK_RATIO", "SLIDER",
    "Initial stock ratio",
    "Fraction of storage capacity filled when a new enemy strategic stock record is created. Initialization policy; existing strategic stocks are not refilled.",
    ["Frontline - Enemy Operations", "Command and resources"],
    [0, 1, 0.75, 0, true], false
] call _add;

[
    "BATTLESPACE_STRATEGIC_LOGISTICS_DECISION_INTERVAL", "SLIDER",
    "Logistics decision interval (seconds)",
    "Seconds between enemy resupply and evacuation planning passes, before communications disruption delays.",
    ["Frontline - Enemy Operations", "Command and resources"],
    [1, 3600, 60, 0], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_RETREAT_STRENGTH_RATIO", "SLIDER",
    "Retreat strength ratio",
    "Surviving fraction of original strength below which air responses and deep reconnaissance begin returning.",
    ["Frontline - Enemy Operations", "Command and resources"],
    [0, 1, 0.35, 0, true], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_FRONT_STOCK_CAPACITY_MULTIPLIERS_1", "SLIDER",
    "Stock capacity: depth 1",
    "Multiply enemy sector storage capacity one network step behind the frontline. Lower values reduce the reserves that sector can hold.",
    ["Frontline - Enemy Operations", "Command and resources"],
    [0, 1, 0.5, 0, true], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_FRONT_STOCK_CAPACITY_MULTIPLIERS_2", "SLIDER",
    "Stock capacity: depth 2",
    "Multiply enemy sector storage capacity two network steps behind the frontline.",
    ["Frontline - Enemy Operations", "Command and resources"],
    [0, 1, 0.75, 0, true], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_FRONT_STOCK_CAPACITY_MULTIPLIERS_3", "SLIDER",
    "Stock capacity: depth 3+",
    "Multiply enemy sector storage capacity three or more network steps behind the frontline.",
    ["Frontline - Enemy Operations", "Command and resources"],
    [0, 1, 1.0, 0, true], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_FRONT_STOCK_CAPACITY_MULTIPLIERS_0", "SLIDER",
    "Stock capacity: frontline",
    "Multiply enemy sector storage capacity directly on the frontline.",
    ["Frontline - Enemy Operations", "Command and resources"],
    [0, 1, 0.25, 0, true], true
] call _add;

[
    "BATTLESPACE_TASK_FORCES_PERSISTENT", "CHECKBOX",
    "Task forces persistent",
    "Save and restore enemy task forces with the campaign so their surviving forces and operational state persist across restarts. Save/load policy; requires a mission restart.",
    ["Frontline - Enemy Operations", "Command and resources"],
    true, false
] call _add;

[
    "BATTLESPACE_STRATEGIC_DEFENDER_DECISION_INTERVAL", "SLIDER",
    "Defender decision interval (seconds)",
    "Seconds between enemy ground allocation passes for defence, reserves, offensives and reconnaissance.",
    ["Frontline - Enemy Operations", "Defence"],
    [1, 3600, 600, 0], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_DEFENDER_QUIET_TIME", "SLIDER",
    "Defender quiet time (seconds)",
    "Seconds without casualties or an ownership change before a sector qualifies as quiet for defender allocation.",
    ["Frontline - Enemy Operations", "Defence"],
    [1, 3600, 300, 0], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_DEFENDER_RETREAT_MANPOWER", "SLIDER",
    "Defender retreat manpower",
    "Remaining troop count below which a defensive group withdraws and a field assignment is considered under strength.",
    ["Frontline - Enemy Operations", "Defence"],
    [1, 20, 3, 0], true
] call _add;

[
    "BATTLESPACE_FIELD_COVERAGE_RADIUS", "SLIDER",
    "Field coverage radius (m)",
    "Radius in metres within which a field squad operates around its assigned patrol centre.",
    ["Frontline - Enemy Operations", "Defence"],
    [1, 1400, 350, 0], true
] call _add;

[
    "BATTLESPACE_FIELD_COVERAGE_SPACING", "SLIDER",
    "Field coverage spacing (m)",
    "Desired spacing in metres between field assignments along exposed sector links. Smaller spacing creates more coverage positions.",
    ["Frontline - Enemy Operations", "Defence"],
    [1, 4800, 1200, 0], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_DEFENDER_MANPOWER_BY_DEPTH_1", "SLIDER",
    "Objective troops: depth 1",
    "Base objective garrison troop target one network step behind the frontline, adjusted by sector type.",
    ["Frontline - Enemy Operations", "Defence"],
    [0, 100, 9, 0], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_DEFENDER_MANPOWER_BY_DEPTH_2", "SLIDER",
    "Objective troops: depth 2",
    "Base objective garrison troop target two network steps behind the frontline, adjusted by sector type.",
    ["Frontline - Enemy Operations", "Defence"],
    [0, 100, 9, 0], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_DEFENDER_MANPOWER_BY_DEPTH_3", "SLIDER",
    "Objective troops: depth 3",
    "Base objective garrison troop target three network steps behind the frontline, adjusted by sector type.",
    ["Frontline - Enemy Operations", "Defence"],
    [0, 100, 9, 0], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_DEFENDER_MANPOWER_BY_DEPTH_0", "SLIDER",
    "Objective troops: frontline",
    "Base objective garrison troop target directly on the frontline, adjusted by sector type.",
    ["Frontline - Enemy Operations", "Defence"],
    [0, 100, 16, 0], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_CONVOY_APC_CHANCE", "SLIDER",
    "Convoy apc chance (%)",
    "Percentage chance of adding an affordable APC escort to an eligible enemy convoy.",
    ["Frontline - Enemy Operations", "Logistics"],
    [0, 100, 25, 0], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_CONVOY_CRATE_VALUE", "SLIDER",
    "Convoy crate value",
    "Base resource units per convoy salvage crate, before the resource multiplier.",
    ["Frontline - Enemy Operations", "Logistics"],
    [1, 400, 100, 0], true
] call _add;

[
    "BATTLESPACE_CONVOY_CRUISE_SPEED", "SLIDER",
    "Convoy cruise speed (km/h)",
    "Convoy cruising speed in km/h, further limited to leave catch-up room below the slowest vehicle's maximum speed.",
    ["Frontline - Enemy Operations", "Logistics"],
    [5, 100, 45, 0], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_CONVOY_MANPOWER", "SLIDER",
    "Convoy manpower",
    "Troops assigned to a new enemy supply convoy's crew and escort composition.",
    ["Frontline - Enemy Operations", "Logistics"],
    [1, 32, 8, 0], true
] call _add;

[
    "BATTLESPACE_CONVOY_SPACING", "SLIDER",
    "Convoy spacing (m)",
    "Desired distance in metres between vehicle centres along the convoy route.",
    ["Frontline - Enemy Operations", "Logistics"],
    [10, 100, 30, 0], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_CONVOY_TRUCKS", "SLIDER",
    "Convoy trucks",
    "Number of cargo trucks requested for a new enemy supply convoy.",
    ["Frontline - Enemy Operations", "Logistics"],
    [1, 20, 2, 0], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_MAX_ACTIVE_CONVOYS", "SLIDER",
    "Max active convoys",
    "Maximum concurrent enemy logistics convoys, including resupply and evacuation operations.",
    ["Frontline - Enemy Operations", "Logistics"],
    [1, 20, 4, 0], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_OFFMAP_REGEN_INTERVAL", "SLIDER",
    "Offmap regen interval (seconds)",
    "Seconds between replenishment ticks for the enemy's off-map resource reserve.",
    ["Frontline - Enemy Operations", "Logistics"],
    [1, 7200, 1800, 0], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_OFFMAP_REGEN_RATIO", "SLIDER",
    "Offmap regen ratio",
    "Fraction of off-map resource capacity regenerated each replenishment tick, up to that resource's capacity.",
    ["Frontline - Enemy Operations", "Logistics"],
    [0, 1, 0.05, 0, true], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_RESUPPLY_COOLDOWN", "SLIDER",
    "Resupply cooldown (seconds)",
    "Base seconds before a sector can receive another resupply dispatch, lengthened by communications disruption.",
    ["Frontline - Enemy Operations", "Logistics"],
    [1, 7200, 1800, 0], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_RESUPPLY_TARGET_RATIO", "SLIDER",
    "Resupply target ratio",
    "Storage fill fraction that resupply deliveries aim to reach after a resource falls below its request threshold.",
    ["Frontline - Enemy Operations", "Logistics"],
    [0, 1, 1, 0, true], true
] call _add;

[
    "BATTLESPACE_CONTACT_MEMORY_MAX_AGE", "SLIDER",
    "Contact memory max age (seconds)",
    "Maximum age in seconds of shared enemy sightings before they are removed from contact memory.",
    ["Frontline - Enemy Operations", "Offensives and reports"],
    [1, 3600, 180, 0], true
] call _add;

[
    "BATTLESPACE_OFFENSIVE_CONTACT_MAX_AGE", "SLIDER",
    "Offensive contact max age (seconds)",
    "Maximum age in seconds of sightings used to select and size an enemy ground offensive.",
    ["Frontline - Enemy Operations", "Offensives and reports"],
    [1, 3600, 180, 0], true
] call _add;

[
    "BATTLESPACE_OFFENSIVE_CONTACT_RADIUS", "SLIDER",
    "Offensive contact radius (m)",
    "Radius in metres for combining reported contacts and already committed forces into one offensive response area.",
    ["Frontline - Enemy Operations", "Offensives and reports"],
    [1, 4800, 1200, 0], true
] call _add;

[
    "BATTLESPACE_OFFENSIVE_MIN_RESPONSE_MANPOWER", "SLIDER",
    "Offensive min response manpower",
    "Minimum response strength used when sizing a ground offensive and deciding whether another formation can be committed.",
    ["Frontline - Enemy Operations", "Offensives and reports"],
    [1, 20, 4, 0], true
] call _add;

[
    "BATTLESPACE_OFFENSIVE_QUIET_ATTACK_DELAY", "SLIDER",
    "Offensive quiet attack delay (seconds)",
    "Seconds without a recorded player sighting before enemy offensives may use the quiet-front attack behavior.",
    ["Frontline - Enemy Operations", "Offensives and reports"],
    [1, 7200, 1800, 0], true
] call _add;

[
    "BATTLESPACE_OFFENSIVE_RETARGET_DISTANCE", "SLIDER",
    "Offensive retarget distance (m)",
    "Movement in metres of the reported target position needed before an offensive updates its manoeuvre destination.",
    ["Frontline - Enemy Operations", "Offensives and reports"],
    [1, 1000, 150, 0], true
] call _add;

[
    "BATTLESPACE_OFFENSIVE_SECURE_DURATION", "SLIDER",
    "Offensive secure duration (seconds)",
    "Seconds an offensive holds a secured objective before its next phase.",
    ["Frontline - Enemy Operations", "Offensives and reports"],
    [1, 3600, 600, 0], true
] call _add;

[
    "BATTLESPACE_OFFENSIVE_TARGET_STANDOFF", "SLIDER",
    "Offensive target standoff (m)",
    "Minimum staging distance in metres from the objective when forming an offensive, also kept outside its capture area.",
    ["Frontline - Enemy Operations", "Offensives and reports"],
    [1, 1800, 450, 0], true
] call _add;

[
    "BATTLESPACE_OFFENSIVE_RESPONSE_RATIOS_1", "SLIDER",
    "Response strength at high stock",
    "Desired offensive strength relative to observed opposition when the source sector has high stock. Nearby committed forces count toward this total.",
    ["Frontline - Enemy Operations", "Offensives and reports"],
    [0.25, 4, 1.5, 2], true
] call _add;

[
    "BATTLESPACE_OFFENSIVE_RESPONSE_RATIOS_0", "SLIDER",
    "Response strength at low stock",
    "Desired offensive strength relative to observed opposition when the source sector has low stock. Nearby committed forces count toward this total.",
    ["Frontline - Enemy Operations", "Offensives and reports"],
    [0.25, 4, 1.0, 2], true
] call _add;

[
    "BATTLESPACE_OFFENSIVE_RETREAT_RATIO_1", "SLIDER",
    "Maximum offensive retreat strength",
    "Upper end of the randomly chosen surviving-strength fraction that makes a new offensive withdraw. Higher fractions cause earlier withdrawal.",
    ["Frontline - Enemy Operations", "Offensives and reports"],
    [0, 1, 0.6, 0, true], true
] call _add;

[
    "BATTLESPACE_OFFENSIVE_RETREAT_RATIO_0", "SLIDER",
    "Minimum offensive retreat strength",
    "Lower end of the randomly chosen surviving-strength fraction that makes a new offensive withdraw. Lower fractions allow heavier losses before withdrawal.",
    ["Frontline - Enemy Operations", "Offensives and reports"],
    [0, 1, 0.45, 0, true], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_DEEP_RECON_ARC_HALF_ANGLE", "SLIDER",
    "Deep recon arc half angle",
    "Degrees to either side of the approach direction available when selecting an observation position around the target.",
    ["Frontline - Enemy Operations", "Reconnaissance"],
    [1, 180, 75, 0], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_DEEP_RECON_COOLDOWN", "SLIDER",
    "Deep recon cooldown (seconds)",
    "Base seconds before a source sector can send another deep reconnaissance patrol.",
    ["Frontline - Enemy Operations", "Reconnaissance"],
    [1, 3600, 600, 0], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_DEEP_RECON_MANPOWER", "SLIDER",
    "Deep recon manpower",
    "Troops assigned to a new deep reconnaissance patrol, paid from its source sector.",
    ["Frontline - Enemy Operations", "Reconnaissance"],
    [1, 28, 7, 0], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_DEEP_RECON_MAX_STANDOFF", "SLIDER",
    "Deep recon max standoff (m)",
    "Maximum distance in metres from the objective for a deep reconnaissance observation position.",
    ["Frontline - Enemy Operations", "Reconnaissance"],
    [1, 3000, 750, 0], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_DEEP_RECON_MIN_SEPARATION", "SLIDER",
    "Deep recon min separation (m)",
    "Minimum spacing in metres between deep reconnaissance observation positions.",
    ["Frontline - Enemy Operations", "Reconnaissance"],
    [1, 1800, 450, 0], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_DEEP_RECON_RETURN_FIRE_DURATION", "SLIDER",
    "Deep recon return fire duration (seconds)",
    "Seconds after incoming fire during which a reconnaissance group may return fire before resuming silent observation.",
    ["Frontline - Enemy Operations", "Reconnaissance"],
    [1, 3600, 120, 0], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_DEEP_RECON_TARGET", "SLIDER",
    "Deep recon target",
    "Desired number of concurrent deep reconnaissance patrols within the shared ground-formation allowance.",
    ["Frontline - Enemy Operations", "Reconnaissance"],
    [1, 48, 12, 0], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_DEEP_RECON_TARGET_STANDOFF", "SLIDER",
    "Deep recon target standoff (m)",
    "Minimum distance in metres from the objective for an observation position, also kept outside its capture area.",
    ["Frontline - Enemy Operations", "Reconnaissance"],
    [1, 1400, 350, 0], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_DEEP_RECON_DURATION_1", "SLIDER",
    "Maximum reconnaissance duration (seconds)",
    "Upper end of the random observation duration in seconds before a reconnaissance patrol returns.",
    ["Frontline - Enemy Operations", "Reconnaissance"],
    [60, 21600, 3600, 0], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_DEEP_RECON_DURATION_0", "SLIDER",
    "Minimum reconnaissance duration (seconds)",
    "Lower end of the random observation duration in seconds before a reconnaissance patrol returns.",
    ["Frontline - Enemy Operations", "Reconnaissance"],
    [60, 21600, 2400, 0], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_DEFENDER_SOURCE_RESERVE_RATIO", "SLIDER",
    "Defender source reserve ratio",
    "Fraction of a source sector's capacity that must remain in stock after funding defenders or their patrol vehicle.",
    ["Frontline - Enemy Operations", "Reserves"],
    [0, 1, 0.4, 0, true], true
] call _add;

[
    "BATTLESPACE_OFFENSIVE_SOURCE_RESERVE_RATIO", "SLIDER",
    "Offensive source reserve ratio",
    "Fraction of source-sector resource capacity held back when paying for a new offensive. Higher values leave more stock at home.",
    ["Frontline - Enemy Operations", "Reserves"],
    [0, 1, 0.5, 0, true], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_RESERVE_FIELD_CONTACT_MAX_AGE", "SLIDER",
    "Reserve field contact max age (seconds)",
    "Maximum age in seconds of a player sighting used to launch or redirect a reserve response to field casualties. Committed reserves retain the last reported area until the hunt ends or withdrawal is required.",
    ["Frontline - Enemy Operations", "Reserves"],
    [1, 3600, 180, 0], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_RESERVE_FIELD_CONTACT_RADIUS", "SLIDER",
    "Reserve field contact radius (m)",
    "Maximum distance in metres from a casualty incident to a reported player contact used for the reserve response.",
    ["Frontline - Enemy Operations", "Reserves"],
    [1, 8000, 2000, 0], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_RESERVE_FIELD_LOSS_WINDOW", "SLIDER",
    "Reserve field loss window",
    "Seconds without further casualties before accumulated field-incident pressure expires.",
    ["Frontline - Enemy Operations", "Reserves"],
    [1, 2400, 600, 0], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_RESERVE_FIELD_RADIUS", "SLIDER",
    "Reserve field radius (m)",
    "Radius in metres for grouping nearby field casualties into one incident and reserve response.",
    ["Frontline - Enemy Operations", "Reserves"],
    [1, 2400, 600, 0], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_RESERVE_HOLD_DURATION", "SLIDER",
    "Reserve hold duration (seconds)",
    "Seconds a deployed reserve holds its response assignment before returning, subject to contact and survival checks.",
    ["Frontline - Enemy Operations", "Reserves"],
    [1, 3600, 900, 0], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_RESERVE_MANPOWER", "SLIDER",
    "Reserve manpower",
    "Troops requested when forming a new mobile reserve from sector stock.",
    ["Frontline - Enemy Operations", "Reserves"],
    [1, 56, 14, 0], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_RESERVE_MAX_FRONT_DEPTH", "SLIDER",
    "Reserve max front depth",
    "Furthest network depth behind the frontline at which mobile reserves may stage.",
    ["Frontline - Enemy Operations", "Reserves"],
    [1, 20, 2, 0], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_RESERVE_MIN_FRONT_DEPTH", "SLIDER",
    "Reserve min front depth",
    "Nearest network depth behind the frontline at which mobile reserves may stage. Reserves stage at least one step behind it.",
    ["Frontline - Enemy Operations", "Reserves"],
    [1, 20, 1, 0], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_RESERVE_MINIMUM_MANPOWER", "SLIDER",
    "Reserve minimum manpower",
    "Minimum surviving troop count required for a mobile reserve to remain available for response.",
    ["Frontline - Enemy Operations", "Reserves"],
    [1, 32, 8, 0], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_RESERVE_RESPONSE_COOLDOWN", "SLIDER",
    "Reserve response cooldown (seconds)",
    "Base seconds between reserve responses to the same sector or field incident, lengthened by communications disruption.",
    ["Frontline - Enemy Operations", "Reserves"],
    [1, 3600, 600, 0], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_RESERVE_RESPONSE_MAX_HOPS", "SLIDER",
    "Reserve response max hops",
    "Maximum sector-network route distance, in hops, for dispatching a reserve to an incident.",
    ["Frontline - Enemy Operations", "Reserves"],
    [1, 20, 5, 0], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_RESERVE_SOURCE_RATIO", "SLIDER",
    "Reserve source ratio",
    "Fraction of the source sector's capacity that must remain in stock after funding a mobile reserve.",
    ["Frontline - Enemy Operations", "Reserves"],
    [0, 1, 0.5, 0, true], true
] call _add;

[
    "BATTLESPACE_STRATEGIC_RESERVE_TARGET", "SLIDER",
    "Reserve target",
    "Desired number of mobile reserve formations maintained within the shared ground-formation allowance.",
    ["Frontline - Enemy Operations", "Reserves"],
    [1, 20, 5, 0], true
] call _add;
