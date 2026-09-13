/* Frontline Enemy Support. Defaults preserve the prior mission configuration. */

[
    "BATTLESPACE_AIR_BOMB_HEIGHT", "SLIDER",
    "Air bomb height (m)",
    "Planned bombing-run height in metres above the highest terrain along the attack path. Also sets the minimum acceptable release height as a fraction of this value.",
    ["Frontline - Enemy Support", "Air support"],
    [1, 6000, 1500, 0], false
] call _add;

[
    "BATTLESPACE_AIR_ENGAGEMENT_KEEP_RANGE", "SLIDER",
    "Air engagement keep range (m)",
    "Distance in metres within which an attacking aircraft can remain physically active around its target during engagement and egress.",
    ["Frontline - Enemy Support", "Air support"],
    [1, 32000, 8000, 0], false
] call _add;

[
    "BATTLESPACE_AIR_HELI_ATTACK_HEIGHT", "SLIDER",
    "Air heli attack height (m)",
    "Planned helicopter attack height in metres above terrain or the target elevation, including standoff positions.",
    ["Frontline - Enemy Support", "Air support"],
    [1, 1000, 180, 0], false
] call _add;

[
    "BATTLESPACE_AIR_INFANTRY_ATTACK_MEMORY", "SLIDER",
    "Air infantry attack memory (seconds)",
    "Seconds an aircraft may use its last observed infantry target position after losing direct sight.",
    ["Frontline - Enemy Support", "Air support"],
    [1, 3600, 60, 0], false
] call _add;

[
    "BATTLESPACE_AIR_INFANTRY_CLUSTER_RADIUS", "SLIDER",
    "Air infantry cluster radius (m)",
    "Radius in metres used to group reported infantry into one target cluster for an air-support request.",
    ["Frontline - Enemy Support", "Air support"],
    [1, 1000, 150, 0], false
] call _add;

[
    "BATTLESPACE_AIR_INFANTRY_CONTACT_MAX_AGE", "SLIDER",
    "Air infantry contact max age (seconds)",
    "Maximum age in seconds of infantry reports used to request and maintain an air response.",
    ["Frontline - Enemy Support", "Air support"],
    [1, 3600, 60, 0], false
] call _add;

[
    "BATTLESPACE_AIR_INFANTRY_MIN_COUNT", "SLIDER",
    "Air infantry min count",
    "Minimum number of recently reported infantry in one cluster required to request air support against an assault.",
    ["Frontline - Enemy Support", "Air support"],
    [1, 20, 3, 0], false
] call _add;

[
    "BATTLESPACE_AIR_INFANTRY_OBJECTIVE_RADIUS", "SLIDER",
    "Air infantry objective radius (m)",
    "Maximum distance in metres from an enemy-held objective at which an infantry cluster can trigger defensive air support.",
    ["Frontline - Enemy Support", "Air support"],
    [1, 3200, 800, 0], false
] call _add;

[
    "BATTLESPACE_AIR_INFANTRY_PRESSURE_DURATION", "SLIDER",
    "Air infantry pressure duration (seconds)",
    "Seconds a reported infantry assault must persist near an objective before it qualifies for an air response.",
    ["Frontline - Enemy Support", "Air support"],
    [1, 3600, 90, 0], false
] call _add;

[
    "BATTLESPACE_AIR_JET_ATTACK_HEIGHT", "SLIDER",
    "Air jet attack height (m)",
    "Planned jet attack height in metres above the terrain along non-bombing attack runs.",
    ["Frontline - Enemy Support", "Air support"],
    [1, 1800, 450, 0], false
] call _add;

[
    "BATTLESPACE_STRATEGIC_AIR_RESPONSE_CONTACT_GRACE", "SLIDER",
    "Air response contact grace",
    "Seconds an air response waits for contact to return before abandoning a lost target.",
    ["Frontline - Enemy Support", "Air support"],
    [1, 480, 120, 0], false
] call _add;

[
    "BATTLESPACE_STRATEGIC_AIR_RESPONSE_COOLDOWN", "SLIDER",
    "Air response cooldown (seconds)",
    "Base seconds before the same source sector may launch another air response, lengthened by communications disruption.",
    ["Frontline - Enemy Support", "Air support"],
    [1, 7200, 1800, 0], false
] call _add;

[
    "BATTLESPACE_STRATEGIC_AIR_RESPONSE_DECISION_INTERVAL", "SLIDER",
    "Air response decision interval (seconds)",
    "Seconds between enemy air-response planning passes, before communications disruption delays.",
    ["Frontline - Enemy Support", "Air support"],
    [1, 3600, 60, 0], false
] call _add;

[
    "BATTLESPACE_STRATEGIC_AIR_RESPONSE_INITIAL_DELAY", "SLIDER",
    "Air response initial delay (seconds)",
    "Seconds before enemy air-response planning begins after initialization.",
    ["Frontline - Enemy Support", "Air support"],
    [1, 3600, 600, 0], false
] call _add;

[
    "BATTLESPACE_STRATEGIC_AIR_RESPONSE_MAX_LIFETIME", "SLIDER",
    "Air response max lifetime (seconds)",
    "Maximum seconds from dispatch before an air response starts returning to base.",
    ["Frontline - Enemy Support", "Air support"],
    [1, 7200, 1800, 0], false
] call _add;

[
    "BATTLESPACE_STRATEGIC_AIR_RESPONSE_MAX_RANGE", "SLIDER",
    "Air response max range (m)",
    "Maximum distance in metres from the contact to a sector that can fund the air response.",
    ["Frontline - Enemy Support", "Air support"],
    [1, 72000, 18000, 0], false
] call _add;

[
    "BATTLESPACE_STRATEGIC_AIR_RESPONSE_MIN_AGGRESSIVITY", "SLIDER",
    "Air response min aggressivity",
    "Minimum campaign aggressivity level required before the enemy may dispatch air responses.",
    ["Frontline - Enemy Support", "Air support"],
    [0, 6, 0.9, 2], false
] call _add;

[
    "BATTLESPACE_STRATEGIC_AIR_RESPONSE_MIN_READINESS", "SLIDER",
    "Air response min readiness (%)",
    "Minimum enemy combat readiness percentage required to dispatch air responses.",
    ["Frontline - Enemy Support", "Air support"],
    [0, 100, 70, 0], false
] call _add;

[
    "BATTLESPACE_STRATEGIC_AIR_RESPONSE_MIN_SEPARATION", "SLIDER",
    "Air response min separation (m)",
    "Minimum separation in metres between air-response target areas, preventing multiple responses from covering the same fight.",
    ["Frontline - Enemy Support", "Air support"],
    [1, 12000, 3000, 0], false
] call _add;

[
    "BATTLESPACE_STRATEGIC_AIR_RESPONSE_MIN_WEIGHT", "SLIDER",
    "Air response min weight",
    "Minimum recorded armour or air threat weight needed to enable the corresponding air-response category.",
    ["Frontline - Enemy Support", "Air support"],
    [1, 200, 50, 0], false
] call _add;

[
    "BATTLESPACE_STRATEGIC_AIR_RESPONSE_ON_STATION_DURATION", "SLIDER",
    "Air response on station duration (seconds)",
    "Seconds an air response can remain over its assigned contact area before returning.",
    ["Frontline - Enemy Support", "Air support"],
    [1, 3600, 900, 0], false
] call _add;

[
    "BATTLESPACE_STRATEGIC_AIR_RESPONSE_ORBIT_RADIUS", "SLIDER",
    "Air response orbit radius (m)",
    "Radius in metres of the air response's loiter pattern around its reported contact position.",
    ["Frontline - Enemy Support", "Air support"],
    [1, 4800, 1200, 0], false
] call _add;

[
    "BATTLESPACE_STRATEGIC_AIR_RESPONSE_REACQUIRE_RANGE", "SLIDER",
    "Air response reacquire range (m)",
    "Search radius in metres around the last contact position when an air response selects a replacement contact.",
    ["Frontline - Enemy Support", "Air support"],
    [1, 16000, 4000, 0], false
] call _add;

[
    "BATTLESPACE_STRATEGIC_AIR_RESPONSE_TARGET_COOLDOWN", "SLIDER",
    "Air response target cooldown (seconds)",
    "Seconds before the same target or infantry assault area can receive another air response after an operation ends.",
    ["Frontline - Enemy Support", "Air support"],
    [1, 3600, 600, 0], false
] call _add;

[
    "BATTLESPACE_AIR_STANDOFF_MAX", "SLIDER",
    "Air standoff max (m)",
    "Maximum standoff distance in metres for helicopter weapon employment, also limited by the loaded weapon's range.",
    ["Frontline - Enemy Support", "Air support"],
    [1, 18000, 4500, 0], false
] call _add;

[
    "BATTLESPACE_STRATEGIC_MAX_ACTIVE_AIR_RESPONSES", "SLIDER",
    "Max active air responses",
    "Maximum concurrent funded enemy air-response operations.",
    ["Frontline - Enemy Support", "Air support"],
    [1, 20, 2, 0], false
] call _add;

[
    "BATTLESPACE_AIRLIFT_CHANCE", "SLIDER",
    "Airlift chance",
    "Chance of choosing helicopter deployment for an eligible new offensive or mobile reserve with affordable transport. A value of 0.5 gives a 50 percent chance.",
    ["Frontline - Enemy Support", "Air transport"],
    [0, 1, 0.35, 0, true], false
] call _add;

[
    "BATTLESPACE_AIRLIFT_FLIGHT_HEIGHT", "SLIDER",
    "Airlift flight height (m)",
    "Transport helicopter flight height in metres above terrain during airborne troop deployment.",
    ["Frontline - Enemy Support", "Air transport"],
    [1, 1000, 120, 0], false
] call _add;

[
    "BATTLESPACE_AIRLIFT_LZ_RADIUS", "SLIDER",
    "Airlift lz radius (m)",
    "Radius in metres around the destination searched for a suitable helicopter landing zone.",
    ["Frontline - Enemy Support", "Air transport"],
    [1, 2000, 500, 0], false
] call _add;

[
    "BATTLESPACE_AIRLIFT_MAX_RANGE", "SLIDER",
    "Airlift max range (m)",
    "Maximum horizontal distance in metres allowed for an airborne deployment or reserve transfer.",
    ["Frontline - Enemy Support", "Air transport"],
    [1, 80000, 20000, 0], false
] call _add;

[
    "BATTLESPACE_STRATEGIC_MAX_ACTIVE_AIRBORNE_TRANSPORTS", "SLIDER",
    "Max active airborne transports",
    "Maximum concurrent enemy helicopter transport operations for offensive and reserve formations.",
    ["Frontline - Enemy Support", "Air transport"],
    [1, 20, 2, 0], false
] call _add;

[
    "BATTLESPACE_ARTILLERY_COOLDOWN_PER_SHELL", "SLIDER",
    "Artillery cooldown per shell (seconds)",
    "Seconds of battery cooldown added per planned round per gun, before the minimum, maximum and readiness adjustments.",
    ["Frontline - Enemy Support", "Artillery and air defence"],
    [1, 3600, 15, 0], false
] call _add;

[
    "BATTLESPACE_ARTILLERY_CREW_PER_PIECE", "SLIDER",
    "Artillery crew per piece",
    "Manpower budgeted per artillery piece when paying for a battery.",
    ["Frontline - Enemy Support", "Artillery and air defence"],
    [1, 20, 3, 0], false
] call _add;

[
    "BATTLESPACE_ARTILLERY_MAX_COOLDOWN", "SLIDER",
    "Artillery max cooldown (seconds)",
    "Upper limit in seconds on the battery's base post-mission cooldown, before readiness and communications modifiers.",
    ["Frontline - Enemy Support", "Artillery and air defence"],
    [1, 3600, 60, 0], false
] call _add;

[
    "BATTLESPACE_ARTILLERY_MIN_COOLDOWN", "SLIDER",
    "Artillery min cooldown (seconds)",
    "Minimum base seconds between battery fire missions, before readiness and communications modifiers.",
    ["Frontline - Enemy Support", "Artillery and air defence"],
    [1, 3600, 30, 0], false
] call _add;

[
    "BATTLESPACE_ARTILLERY_SMOKE_CHANCE", "SLIDER",
    "Artillery smoke chance",
    "Chance an observer opens an engagement with smoke. At most one accepted smoke mission is used before switching to HE; 0 disables this opening smoke.",
    ["Frontline - Enemy Support", "Artillery and air defence"],
    [0, 1, 0.15, 0, true], false
] call _add;

[
    "BATTLESPACE_ARTILLERY_TARGET_MOVEMENT_ACCURACY_LOSS_BAND_DISTANCE", "SLIDER",
    "Artillery target movement accuracy loss band distance (m)",
    "Target movement in metres that removes 10 percent of the observer's accumulated aiming accuracy.",
    ["Frontline - Enemy Support", "Artillery and air defence"],
    [1, 1000, 90, 0], false
] call _add;

[
    "BATTLESPACE_ARTILLERY_TARGET_MOVEMENT_ACCURACY_LOSS_DISTANCE", "SLIDER",
    "Artillery target movement accuracy loss distance (m)",
    "Target movement in metres that removes 40 percent of the observer's accumulated aiming accuracy.",
    ["Frontline - Enemy Support", "Artillery and air defence"],
    [1, 1000, 175, 0], false
] call _add;

[
    "BATTLESPACE_ARTILLERY_TRP_AIM_FLOOR", "SLIDER",
    "Artillery trp aim floor",
    "Minimum aiming accuracy used for fire at a registered target reference point. Higher values reduce dispersion around that point.",
    ["Frontline - Enemy Support", "Artillery and air defence"],
    [1, 720, 180, 0], false
] call _add;

[
    "BATTLESPACE_ARTILLERY_TRP_ENABLED", "CHECKBOX",
    "Artillery trp enabled",
    "Allow enemy batteries to prepare target reference points covering defended approaches and offensive objectives for later observer-directed fire.",
    ["Frontline - Enemy Support", "Artillery and air defence"],
    true, false
] call _add;

[
    "BATTLESPACE_ARTILLERY_TRP_LIFETIME", "SLIDER",
    "Artillery trp lifetime (seconds)",
    "Seconds a prepared target reference point remains valid after creation.",
    ["Frontline - Enemy Support", "Artillery and air defence"],
    [1, 7200, 1800, 0], false
] call _add;

[
    "BATTLESPACE_ARTILLERY_TRP_MAX_PER_BATTERY", "SLIDER",
    "Artillery trp max per battery",
    "Maximum target reference points assigned to a single enemy battery.",
    ["Frontline - Enemy Support", "Artillery and air defence"],
    [1, 20, 4, 0], false
] call _add;

[
    "BATTLESPACE_ARTILLERY_TRP_MAX_TOTAL", "SLIDER",
    "Artillery trp max total",
    "Maximum active target reference points shared by all enemy batteries.",
    ["Frontline - Enemy Support", "Artillery and air defence"],
    [1, 32, 8, 0], false
] call _add;

[
    "BATTLESPACE_ARTILLERY_TRP_RADIUS", "SLIDER",
    "Artillery trp radius (m)",
    "Distance in metres from a target reference point within which a fresh observer contact can use its prepared fire plan.",
    ["Frontline - Enemy Support", "Artillery and air defence"],
    [1, 1000, 180, 0], false
] call _add;

[
    "BATTLESPACE_ARTILLERY_TRP_REGISTRATION_TIME", "SLIDER",
    "Artillery trp registration time",
    "Seconds needed to register a new target reference point before it can improve a fire mission.",
    ["Frontline - Enemy Support", "Artillery and air defence"],
    [1, 720, 180, 0], false
] call _add;

[
    "BATTLESPACE_SAM_RELOAD_BATCH", "SLIDER",
    "Sam reload batch",
    "Maximum missiles transferred from sector stock into a SAM site's reserve pool per reload request.",
    ["Frontline - Enemy Support", "Artillery and air defence"],
    [1, 20, 4, 0], false
] call _add;

[
    "BATTLESPACE_SAM_STRATEGIC_MISSILES_PER_LAUNCHER", "SLIDER",
    "Sam strategic missiles per launcher",
    "Strategic missile allocation and resource cost per launcher when an enemy SAM site is created.",
    ["Frontline - Enemy Support", "Artillery and air defence"],
    [1, 32, 8, 0], false
] call _add;

[
    "BATTLESPACE_SAM_TACTICAL_MISSILES_PER_LAUNCHER", "SLIDER",
    "Sam tactical missiles per launcher",
    "Tactical missile allocation and resource cost per launcher when an enemy SAM site is created.",
    ["Frontline - Enemy Support", "Artillery and air defence"],
    [1, 20, 4, 0], false
] call _add;

[
    "BATTLESPACE_STRATEGIC_FORTIFICATION_COOLDOWN", "SLIDER",
    "Fortification cooldown (seconds)",
    "Seconds a sector waits after constructing a fortification before it can build another.",
    ["Frontline - Enemy Support", "Fortifications"],
    [1, 7200, 1800, 0], false
] call _add;

[
    "BATTLESPACE_STRATEGIC_FORTIFICATION_GARRISON_RADIUS", "SLIDER",
    "Fortification garrison radius (m)",
    "Radius in metres around the sector centre within which an arrived objective garrison must be present to support fortification construction.",
    ["Frontline - Enemy Support", "Fortifications"],
    [1, 1400, 350, 0], false
] call _add;

[
    "BATTLESPACE_STRATEGIC_FORTIFICATION_MAX_SLOPE", "SLIDER",
    "Fortification max slope",
    "Maximum terrain slope in degrees accepted for fortification earthworks. Weapon positions use their own 15-degree limit.",
    ["Frontline - Enemy Support", "Fortifications"],
    [0, 90, 25, 0], false
] call _add;

[
    "BATTLESPACE_STRATEGIC_MAX_ACTIVE_FORTIFICATIONS", "SLIDER",
    "Max active fortifications",
    "Maximum active enemy fortification sites across the map.",
    ["Frontline - Enemy Support", "Fortifications"],
    [1, 192, 48, 0], false
] call _add;

[
    "BATTLESPACE_STRATEGIC_MAX_FORTIFICATIONS_PER_SECTOR", "SLIDER",
    "Max fortifications per sector",
    "Maximum fortification sites and construction tiers allowed for one enemy sector.",
    ["Frontline - Enemy Support", "Fortifications"],
    [1, 20, 3, 0], false
] call _add;

[
    "BATTLESPACE_STRATEGIC_MAX_ACTIVE_MINEFIELDS", "SLIDER",
    "Max active minefields",
    "Maximum active enemy minefield operations across the map.",
    ["Frontline - Enemy Support", "Minefields"],
    [1, 272, 68, 0], false
] call _add;

[
    "BATTLESPACE_STRATEGIC_MAX_MINEFIELDS_PER_SECTOR", "SLIDER",
    "Max minefields per sector",
    "Maximum active minefields funded by one enemy sector.",
    ["Frontline - Enemy Support", "Minefields"],
    [1, 20, 4, 0], false
] call _add;

[
    "BATTLESPACE_STRATEGIC_MINEFIELD_AT_RATIO", "SLIDER",
    "Minefield at ratio",
    "Fraction of mine positions assigned anti-tank mines, distributed across the field. The remaining positions use anti-personnel mines.",
    ["Frontline - Enemy Support", "Minefields"],
    [0, 1, 0.25, 0, true], false
] call _add;

[
    "BATTLESPACE_STRATEGIC_MINEFIELD_CONSTRUCTION_COST", "SLIDER",
    "Minefield construction cost",
    "Construction-supply units deducted from sector stock to establish one minefield.",
    ["Frontline - Enemy Support", "Minefields"],
    [1, 24, 6, 0], false
] call _add;

[
    "BATTLESPACE_STRATEGIC_MINEFIELD_COOLDOWN", "SLIDER",
    "Minefield cooldown (seconds)",
    "Seconds a sector waits after creating a minefield before it may create another.",
    ["Frontline - Enemy Support", "Minefields"],
    [1, 14400, 3600, 0], false
] call _add;

[
    "BATTLESPACE_STRATEGIC_MINEFIELD_MAX_FRONT_DEPTH", "SLIDER",
    "Minefield max front depth",
    "Furthest sector-network depth behind the frontline at which the enemy can establish minefields. Depth 0 is the frontline.",
    ["Frontline - Enemy Support", "Minefields"],
    [1, 20, 1, 0], false
] call _add;

[
    "BATTLESPACE_STRATEGIC_MINEFIELD_MINE_COUNT", "SLIDER",
    "Minefield mine count",
    "Number of mine positions generated for each new enemy minefield.",
    ["Frontline - Enemy Support", "Minefields"],
    [1, 96, 24, 0], false
] call _add;

[
    "BATTLESPACE_STRATEGIC_MINEFIELD_PLAYER_EXCLUSION_RADIUS", "SLIDER",
    "Minefield player exclusion radius (m)",
    "Distance in metres from the sector centre within which nearby friendly players prevent new minefield construction.",
    ["Frontline - Enemy Support", "Minefields"],
    [1, 10000, 2500, 0], false
] call _add;

[
    "BATTLESPACE_STRATEGIC_MINEFIELD_QUIET_TIME", "SLIDER",
    "Minefield quiet time (seconds)",
    "Seconds without casualties or an ownership change before a sector can construct a minefield.",
    ["Frontline - Enemy Support", "Minefields"],
    [1, 3600, 600, 0], false
] call _add;
