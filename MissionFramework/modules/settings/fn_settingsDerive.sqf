/* Rebuild only inexpensive derived configuration. No objects, handlers,
   catalogs or saved campaign records are created or replaced here. */
if (isRemoteExecuted || {isNil "_KPLIB_settingsApplyContext"}) exitWith {};
KP_liberation_autoFaction_vehiclePriceMultipliers = [KP_liberation_autoFaction_vehiclePriceMultipliers_0, KP_liberation_autoFaction_vehiclePriceMultipliers_1, KP_liberation_autoFaction_vehiclePriceMultipliers_2];
KP_liberation_sector_resource_crate_count = [KP_liberation_sector_resource_crate_count_0, KP_liberation_sector_resource_crate_count_1];
KPLIB_radio_intercept_interval = [KPLIB_radio_intercept_interval_0, KPLIB_radio_intercept_interval_1];
KPLIB_intelligence_informant_interval = [KPLIB_intelligence_informant_interval_0, KPLIB_intelligence_informant_interval_1];
BATTLESPACE_STRATEGIC_DEEP_RECON_DURATION = [BATTLESPACE_STRATEGIC_DEEP_RECON_DURATION_0, BATTLESPACE_STRATEGIC_DEEP_RECON_DURATION_1];
BATTLESPACE_OFFENSIVE_RESPONSE_RATIOS = [BATTLESPACE_OFFENSIVE_RESPONSE_RATIOS_0, BATTLESPACE_OFFENSIVE_RESPONSE_RATIOS_1];
BATTLESPACE_OFFENSIVE_RETREAT_RATIO = [BATTLESPACE_OFFENSIVE_RETREAT_RATIO_0, BATTLESPACE_OFFENSIVE_RETREAT_RATIO_1];
BATTLESPACE_STRATEGIC_FRONT_STOCK_CAPACITY_MULTIPLIERS = [BATTLESPACE_STRATEGIC_FRONT_STOCK_CAPACITY_MULTIPLIERS_0, BATTLESPACE_STRATEGIC_FRONT_STOCK_CAPACITY_MULTIPLIERS_1, BATTLESPACE_STRATEGIC_FRONT_STOCK_CAPACITY_MULTIPLIERS_2, BATTLESPACE_STRATEGIC_FRONT_STOCK_CAPACITY_MULTIPLIERS_3];
BATTLESPACE_STRATEGIC_DEFENDER_MANPOWER_BY_DEPTH = [BATTLESPACE_STRATEGIC_DEFENDER_MANPOWER_BY_DEPTH_0, BATTLESPACE_STRATEGIC_DEFENDER_MANPOWER_BY_DEPTH_1, BATTLESPACE_STRATEGIC_DEFENDER_MANPOWER_BY_DEPTH_2, BATTLESPACE_STRATEGIC_DEFENDER_MANPOWER_BY_DEPTH_3];
KPLIB_aiSkills_sides = [];
if (KPLIB_aiSkills_side_west) then {KPLIB_aiSkills_sides pushBack west};
if (KPLIB_aiSkills_side_east) then {KPLIB_aiSkills_sides pushBack east};
if (KPLIB_aiSkills_side_resistance) then {KPLIB_aiSkills_sides pushBack resistance};
KPLIB_aiCombat_sides = [];
if (KPLIB_aiCombat_side_west) then {KPLIB_aiCombat_sides pushBack west};
if (KPLIB_aiCombat_side_east) then {KPLIB_aiCombat_sides pushBack east};
if (KPLIB_aiCombat_side_resistance) then {KPLIB_aiCombat_sides pushBack resistance};
KPLIB_aiSkills_sideProfiles = [[west, KPLIB_aiSkills_profile_west], [east, KPLIB_aiSkills_profile_east], [resistance, KPLIB_aiSkills_profile_resistance]];
KPLIB_sector_activation_opfor_threshold = KPLIB_sector_activation_opfor_base * GRLIB_unitcap;
GREUH_allow_mapmarkers = KP_liberation_mapmarkers;
GREUH_allow_platoonview = KP_liberation_mapmarkers;
