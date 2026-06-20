// HEY IF YOU NEED TO CHANGE FACTIONS, DO SO HERE:
// KC_Liberation_Master_Framework\arsenal_presets\rolearsenal.sqf

// This gear is selected from when someone respawns in onPlayerRespawn.sqf
RA_StartingHeadwear = [
	"H_tweed_ech_OCP"
];
RA_StartingGoggles = [
	// GOGGLES
	"rhs_googles_black",
	"rhs_googles_clear"

];
RA_StartingUniforms = [
	// UNIFORMS
	"U_tweed_acu_summer_ocp"
];

RA_StartingItems = [
	// MISC
	"ItemMap",
	"ItemWatch",
	"TFAR_anprc152",
	"ItemAndroid",
	"ItemCompass"

];
RA_StartingLoadout = RA_StartingHeadwear + RA_StartingGoggles + RA_StartingUniforms + RA_StartingItems;

RA_DefaultGearAmmo = [
	// AMMO
	"rhsusf_mag_17Rnd_9x19_JHP",
	"rhsusf_mag_17Rnd_9x19_FMJ",
	"MPP_15rnd_9MM_147FMJ_G19"
];
RA_DefaultGear = [
	// WEAPONS
	"rhs_weap_m4a1_carryhandle_mstock",
	"MPP_P80_BLK_BLK_9",
	// VEST
	"V_tweed_iotv_mk4_e_2",
	"V_tweed_iotv_mk4_e_1",
	"V_tweed_iotv_mk4_2",
	"V_tweed_iotv_mk4_1",
	"V_tweed_iotv_mk4_cell_2",
	"V_tweed_iotv_mk4_3",
	"V_tweed_iotv_mk4_cell_1",
	"V_tweed_iotv_mk4_240",
	"V_tweed_iotv_mk4_249",
	"V_tweed_iotv_mk4_4cm_2",
	"V_tweed_iotv_mk4_cell_4cm_1",
	"V_tweed_iotv_mk4_4cm_1",
	"V_tweed_iotv_mk4_45_2",
	"V_tweed_iotv_mk4_cell_45_2",
	"V_tweed_iotv_mk4_45_1",
	"V_tweed_iotv_mk4_cell_45_1",
	"V_tweed_msv_mk2_e_1",
	"V_tweed_msv_mk2_2",
	"V_tweed_msv_mk2_cell_1",
	"V_tweed_msv_mk2_3",
	"V_tweed_msv_mk2_cell_2",
	"V_tweed_msv_mk2_1",
	"V_tweed_msv_mk2_240",
	"V_tweed_msv_mk2_249",
	"V_tweed_msv_mk2_4cm_2",
	"V_tweed_msv_mk2_4cm_1",
	"V_tweed_msv_mk2_cell_4cm_1",
	"V_tweed_msv_mk2_45_2",
	"V_tweed_msv_mk2_cell_45_2",
	"V_tweed_msv_mk2_45_1",
	"V_tweed_msv_mk2_cell_45_1",
	// HEADGEAR
	"H_tweed_ech_OCP_licht",
	"H_tweed_ech_OCP",
	"H_tweed_ech_OCP_alt",
	"H_tweed_ech_OCP_b_licht",
	"H_tweed_ech_OCP_b_alt",
	"H_tweed_ech_OCP_b",
	"H_tweed_ech_OCP_b_ESS_2",
	"H_tweed_ech_OCP_ESS_low_b",
	"H_tweed_ech_OCP_b_ESS",
	"H_tweed_ech_OCP_ESS_2",
	"H_tweed_ech_OCP_ESS",
	"H_tweed_ech_OCP_ESS_low",
	"H_tweed_ech_OCP_TASC",
	"H_tweed_ech_OCP_TASC_b",
	"H_tweed_ech_OCP_TASC_b_ESS_2",
	"H_tweed_ech_OCP_TASC_b_ESS",
	"H_tweed_ech_OCP_TASC_b_ESS_3",
	"H_tweed_ech_OCP_TASC_ESS",
	"H_tweed_ech_OCP_TASC_ESS_2",
	"H_tweed_ech_OCP_scrim",
	"H_tweed_ech_OCP_scrim_ess",
	"H_tweed_ech_OCP_scrim_TASC",
	"H_tweed_ech_OCP_scrim_TASC_ESS",
	"H_tweed_ech_nor_OCP_alt",
	"H_tweed_ech_nor_OCP_licht",
	"H_tweed_ech_nor_OCP",
	"H_tweed_ech_nor_OCP_b",
	"H_tweed_ech_nor_OCP_b_licht",
	"H_tweed_ech_nor_OCP_b_alt",
	"H_tweed_ech_nor_OCP_ESS_low_b",
	"H_tweed_ech_nor_OCP_b_ESS_2",
	"H_tweed_ech_nor_OCP_b_ESS",
	"H_tweed_ech_nor_OCP_ESS_low",
	"H_tweed_ech_nor_OCP_ESS_2",
	"H_tweed_ech_nor_OCP_ESS",
	"H_tweed_ech_nor_OCP_TASC",
	"H_tweed_ech_nor_OCP_TASC_b",
	"H_tweed_ech_nor_OCP_TASC_b_ESS",
	"H_tweed_ech_nor_OCP_TASC_b_ESS_3",
	"H_tweed_ech_nor_OCP_TASC_b_ESS_2",
	"H_tweed_ech_nor_OCP_TASC_ESS_2",
	"H_tweed_ech_nor_OCP_TASC_ESS",
	"H_tweed_ech_nor_OCP_scrim",
	"H_tweed_ech_nor_OCP_scrim_ess",
	"H_tweed_ech_nor_OCP_scrim_TASC",
	"H_tweed_ech_nor_OCP_scrim_TASC_ESS",
	"H_tweed_ech_psq_OCP_licht",
	"H_tweed_ech_psq_OCP",
	"H_tweed_ech_psq_OCP_alt",
	"H_tweed_ech_psq_OCP_b_licht",
	"H_tweed_ech_psq_OCP_b_alt",
	"H_tweed_ech_psq_OCP_b",
	"H_tweed_ech_psq_OCP_b_ESS",
	"H_tweed_ech_psq_OCP_ESS_low_b",
	"H_tweed_ech_psq_OCP_b_ESS_2",
	"H_tweed_ech_psq_OCP_ESS",
	"H_tweed_ech_psq_OCP_ESS_low",
	"H_tweed_ech_psq_OCP_ESS_2",
	"H_tweed_ech_psq_OCP_TASC",
	"H_tweed_ech_psq_OCP_TASC_b",
	"H_tweed_ech_psq_OCP_TASC_b_ESS",
	"H_tweed_ech_psq_OCP_TASC_b_ESS_2",
	"H_tweed_ech_psq_OCP_TASC_b_ESS_3",
	"H_tweed_ech_psq_OCP_TASC_ESS_2",
	"H_tweed_ech_psq_OCP_TASC_ESS",
	"H_tweed_ech_psq_OCP_scrim",
	"H_tweed_ech_psq_OCP_scrim_ess",
	"H_tweed_ech_psq_OCP_scrim_TASC",
	"H_tweed_ech_psq_OCP_scrim_TASC_ESS",
	"H_tweed_ihps_bare",
	"H_tweed_ihps_g_bare",
	"H_tweed_ihps_g_tasc_bare",
	"H_tweed_ihps_g_bare_rail",
	"H_tweed_ihps_g_bare_tasc_rail",
	"H_tweed_ihps_1",
	"H_tweed_ihps_g",
	"H_tweed_ihps_g_tasc",
	"H_tweed_ihps_g_tasc_rail",
	"H_tweed_ihps_g_rail",
	"H_tweed_ihps_tasc",
	"H_tweed_ihps_tasc_rail",
	"H_tweed_ihps_rail",
	"H_tweed_ihps_scrim",
	"H_tweed_ihps_scrim_g",
	"H_tweed_ihps_scrim_g_tasc",
	"H_tweed_ihps_tasc_scrim_g_rail",
	"H_tweed_ihps_scrim_g_rail",
	"H_tweed_ihps_scrim_tasc",
	"H_tweed_ihps_tasc_scrim_rail",
	"H_tweed_ihps_scrim_rail",
	"H_tweed_ihps_tasc_bare",
	"H_tweed_ihps_bare_tasc_rail",
	"H_tweed_ihps_bare_rail",
	"H_tweed_Hat_Patrol_ocp",
	// UNIFORM
	"U_tweed_acu_summer_ocp_jedi",
	"U_tweed_acu_summer_ocp",
	"U_tweed_acu_summer_ocp_trop",
	"U_tweed_acu_summer_ocp_g",
	"U_tweed_acu_summer_ocp_jedi_g",
	"U_tweed_acu_summer_ocp_tuck_jedi",
	"U_tweed_acu_summer_ocp_tuck",
	"U_tweed_acu_summer_ocp_tuck_trop",
	"U_tweed_acu_summer_ocp_tuck_unbl_jedi",
	"U_tweed_acu_summer_ocp_tuck_unbl_trop",
	"U_tweed_acu_summer_ocp_tuck_unbl",
	"U_tweed_acu_summer_ocp_unbl_jedi",
	"U_tweed_acu_summer_ocp_unbl",
	"U_tweed_acu_summer_ocp_unbl_trop",
	"U_tweed_acu_summer_ocp_crye",
	"U_tweed_acu_summer_ocp_crye_trop",
	"U_tweed_acu_summer_ocp_crye_jedi",
	"U_tweed_acu_summer_ocp_crye_knee",
	"U_tweed_acu_summer_ocp_crye_knee_trop",
	"U_tweed_acu_summer_ocp_crye_knee_jedi",
	"U_tweed_acu_summer_ocp_blench_crye_jedi",
	"U_tweed_acu_summer_ocp_blench_crye_trop",
	"U_tweed_acu_summer_ocp_blench_crye",
	"U_tweed_acu_summer_ocp_blench_crye_knee_jedi",
	"U_tweed_acu_summer_ocp_blench_crye_knee_trop",
	"U_tweed_acu_summer_ocp_blench_crye_knee",
	// BACKPACK
	"B_simc_US_Molle_sturm_OCP",
	"B_simc_US_Molle_sturm_OCP_thermos_od3",
	"B_simc_US_Molle_sturm_OCP_thermos_OCP",
	"B_simc_US_Molle_sturm_OCP_thermos_od7",
	"B_simc_US_Molle_sturm_OCP_etool",
	"B_simc_US_Molle_sturm_OCP_RTO",
	"B_simc_US_Molle_sturm_OCP_RTO_wasser",
	"B_simc_US_Molle_asspack_OCP",
	"B_simc_US_Molle_asspack_OCP_low",
	"B_simc_US_Molle_asspack_OCP_thermos_od3",
	"B_simc_US_Molle_asspack_OCP_thermos_OCP",
	"B_simc_US_Molle_asspack_OCP_thermos_od7",
	"B_simc_US_Molle_asspack_OCP_wasser",
	"B_tweed_pack_wasser_molle_od3",
	"B_tweed_pack_wasser_molle_od3_alt",
	"B_tweed_pack_wasser_molle_od7",
	"B_tweed_pack_wasser_molle_od7_alt",
	"B_tweed_pack_wasser_molle_ocp",
	"B_tweed_pack_wasser_molle_ocp_alt",
	// MISC
	"ItemTabHCam",
	"ItemGPS",
	"TFAR_microdagr",
	"ItemMicroDAGR",
	"Binocular",
	"rhsusf_bino_m24",
	"rhsusf_bino_m24_ARD",
	// GRENADES
	"rhs_mag_m67",
	"rhs_mag_an_m8hc",
	"rhs_mag_m18_green",
	"rhs_mag_m18_purple",
	"rhs_mag_m18_red",
	"rhs_mag_m18_yellow",
    "ACE_HandFlare_Green",
    "ACE_HandFlare_Red",
    "ACE_HandFlare_White",
    "ACE_HandFlare_Yellow",
    "ACE_Chemlight_IR",
    "ACE_Chemlight_Orange",
    "ACE_Chemlight_White",
    "Chemlight_blue",
    "Chemlight_green",
    "Chemlight_red",
    "Chemlight_yellow",
	// NVGs
	"rhsusf_ANPVS_15",
	// ACE
	"kat_Painkiller",
    "ACE_acc_pointer_green",
	"ACE_Altimeter",
	"ACE_CableTie",
	"ACE_Chemlight_Shield",
	"ACE_DAGR",
	"ACE_EarPlugs",
	"ACE_elasticBandage",
	"ACE_epinephrine",
	"ACE_fieldDressing",
	"ACE_Flashlight_KSF1",
	"ACE_Flashlight_XL50",
	"ACE_IR_Strobe_Item",
	"ACE_MapTools",
	"ACE_microDAGR",
	"ACE_morphine",
	"ACE_packingBandage",
	"ACE_personalAidKit",
	"ACE_plasmaIV_250",
	"ACE_plasmaIV_500",
	"ACE_quikclot",
	"ACE_SpraypaintBlue",
	"ACE_SpraypaintGreen",
	"ACE_SpraypaintRed",
	"ACE_salineIV_250",
	"ACE_salineIV_500",
	"ACE_splint",
	"kat_chestSeal",
	"ACE_tourniquet",
	"ACE_WaterBottle",
	"ACE_WaterBottle_Half",
	"ItemcTabHCam",
	// Rations and MRE
	"ACE_Humanitarian_Ration",
	// GEAR Basic stuff
	"rhs_ess_black",
	"rhs_googles_black",
	"rhs_googles_clear",
	"rhs_googles_orange",
	"rhs_googles_yellow",
	"rhsusf_oakley_goggles_blk",
	"rhsusf_oakley_goggles_clr",
	"rhsusf_oakley_goggles_ylw"
	// GEAR add

] + RA_StartingLoadout + RA_DefaultGearAmmo;

RA_ShemaghMasks = [
	"G_tweed_tacticool",
	"G_tweed_tacticool_comba",
	"G_tweed_tacticool_peltor",
	"G_tweed_tacticool_peltor_comba",
	"G_tweed_tacticool_peltor_nomex",
	"G_tweed_tacticool_peltor_oak",
	"G_tweed_tacticool_nomex",
	"G_tweed_tacticool_oak"
];
RA_Drip = [
	"G_tweed_ESS_Green",
	"G_tweed_ESS_tan",
	"G_LEN_TG1_blauw",
	"G_tweed_tacticool_blauw",
	"G_tweed_tacticool_blauw_comba",
	"G_tweed_tacticool_blauw_peltor",
	"G_tweed_tacticool_blauw_peltor_comba",
	"G_tweed_tacticool_blauw_peltor_nomex",
	"G_tweed_tacticool_blauw_peltor_oak",
	"G_tweed_tacticool_blauw_nomex",
	"G_tweed_tacticool_blauw_oak",
	"G_LEN_TG1_weiss",
	"G_tweed_tacticool_weiss",
	"G_tweed_tacticool_weiss_peltor",
	"G_tweed_tacticool_oranje",
	"G_LEN_TG1_oranje",
	"G_tweed_tacticool_oranje_comba",
	"G_tweed_tacticool_oranje_peltor",
	"G_tweed_tacticool_oranje_peltor_comba",
	"G_tweed_tacticool_oranje_peltor_nomex",
	"G_tweed_tacticool_oranje_nomex",
	"G_tweed_tacticool_oranje_peltor_oak",
	"G_tweed_tacticool_oranje_oak",
	"G_tweed_tacticool_weiss_comba",
	"G_tweed_tacticool_weiss_peltor_comba",
	"G_tweed_tacticool_weiss_peltor_nomex",
	"G_tweed_tacticool_weiss_peltor_oak",
	"G_tweed_tacticool_weiss_nomex",
	"G_tweed_tacticool_weiss_oak",
	"G_LEN_TG1",
	"G_tweed_tacticool",
	"G_tweed_tacticool_comba",
	"G_tweed_tacticool_peltor",
	"G_tweed_tacticool_peltor_comba",
	"G_tweed_tacticool_peltor_nomex",
	"G_tweed_tacticool_peltor_oak",
	"G_tweed_tacticool_nomex",
	"G_tweed_tacticool_oak",
	"G_LEN_Ess_V12",
	"G_Nomex_1_lang",
	"G_Nomex_1_fold",
	"G_Nomex_1",
	"G_Nomex_2_fold",
	"G_Nomex_2",
	"G_Nomex_2_lang",
	"G_Nomex_2_fold_cut",
	"G_Nomex_2_cut",
	"G_Nomex_2_lang_cut",
	"G_Nomex_1_cut",
	"G_Nomex_1_lang_cut",
	"G_Nomex_1_fold_cut",
	"G_Nomex_desu_lang",
	"G_Nomex_desu",
	"G_Nomex_desu_fold",
	"G_Nomex_desu_2",
	"G_Nomex_desu_2_lang",
	"G_Nomex_desu_2_fold",
	"G_Nomex_desu_2_fold_cut",
	"G_Nomex_desu_2_lang_cut",
	"G_Nomex_desu_2_cut",
	"G_Nomex_desu_cut",
	"G_Nomex_desu_lang_cut",
	"G_Nomex_desu_fold_cut",
	"G_tweed_peltor"
];

RA_TierStuff = [
];
RA_Baseballcaps = [
];
RA_Boonies = [
];

RA_TeamLeaderVests = [
	"V_tweed_iotv_mk4_3"
];
RA_BasicInfVests = [
	"V_tweed_iotv_mk4_e_2",
	"V_tweed_iotv_mk4_e_1",
	"V_tweed_iotv_mk4_2",
	"V_tweed_iotv_mk4_1",
	"V_tweed_iotv_mk4_cell_2",
	"V_tweed_iotv_mk4_3",
	"V_tweed_iotv_mk4_cell_1",
	"V_tweed_iotv_mk4_240",
	"V_tweed_iotv_mk4_249",
	"V_tweed_iotv_mk4_4cm_2",
	"V_tweed_iotv_mk4_cell_4cm_1",
	"V_tweed_iotv_mk4_4cm_1",
	"V_tweed_iotv_mk4_45_2",
	"V_tweed_iotv_mk4_cell_45_2",
	"V_tweed_iotv_mk4_45_1",
	"V_tweed_iotv_mk4_cell_45_1"
];
RA_LongRangeBackpacks = [
	// BACKPACKS
	"B_simc_US_Molle_sturm_OCP_RTO"
];
RA_InfBackpacks = [
	// BACKPACKS
	"B_simc_US_Molle_sturm_OCP",
	"B_simc_US_Molle_sturm_OCP_thermos_od3",
	"B_simc_US_Molle_sturm_OCP_thermos_OCP",
	"B_simc_US_Molle_sturm_OCP_thermos_od7",
	"B_simc_US_Molle_sturm_OCP_etool",
	"B_simc_US_Molle_asspack_OCP",
	"B_simc_US_Molle_asspack_OCP_low",
	"B_simc_US_Molle_asspack_OCP_thermos_od3",
	"B_simc_US_Molle_asspack_OCP_thermos_OCP",
	"B_simc_US_Molle_asspack_OCP_thermos_od7",
	"B_simc_US_Molle_asspack_OCP_wasser",
	"B_tweed_pack_wasser_molle_od3",
	"B_tweed_pack_wasser_molle_od3_alt",
	"B_tweed_pack_wasser_molle_od7",
	"B_tweed_pack_wasser_molle_od7_alt",
	"B_tweed_pack_wasser_molle_ocp",
	"B_tweed_pack_wasser_molle_ocp_alt"
];

RA_InfHelmets = [
	// HEADGEAR add this to dertime role so everone gets helmets you want
	// FAST
	"H_tweed_ech_OCP_licht",
	"H_tweed_ech_OCP",
	"H_tweed_ech_OCP_alt",
	"H_tweed_ech_OCP_b_licht",
	"H_tweed_ech_OCP_b_alt",
	"H_tweed_ech_OCP_b",
	"H_tweed_ech_OCP_b_ESS_2",
	"H_tweed_ech_OCP_ESS_low_b",
	"H_tweed_ech_OCP_b_ESS",
	"H_tweed_ech_OCP_ESS_2",
	"H_tweed_ech_OCP_ESS",
	"H_tweed_ech_OCP_ESS_low",
	"H_tweed_ech_OCP_TASC",
	"H_tweed_ech_OCP_TASC_b",
	"H_tweed_ech_OCP_TASC_b_ESS_2",
	"H_tweed_ech_OCP_TASC_b_ESS",
	"H_tweed_ech_OCP_TASC_b_ESS_3",
	"H_tweed_ech_OCP_TASC_ESS",
	"H_tweed_ech_OCP_TASC_ESS_2",
	"H_tweed_ech_OCP_scrim",
	"H_tweed_ech_OCP_scrim_ess",
	"H_tweed_ech_OCP_scrim_TASC",
	"H_tweed_ech_OCP_scrim_TASC_ESS",
	"H_tweed_ech_nor_OCP_alt",
	"H_tweed_ech_nor_OCP_licht",
	"H_tweed_ech_nor_OCP",
	"H_tweed_ech_nor_OCP_b",
	"H_tweed_ech_nor_OCP_b_licht",
	"H_tweed_ech_nor_OCP_b_alt",
	"H_tweed_ech_nor_OCP_ESS_low_b",
	"H_tweed_ech_nor_OCP_b_ESS_2",
	"H_tweed_ech_nor_OCP_b_ESS",
	"H_tweed_ech_nor_OCP_ESS_low",
	"H_tweed_ech_nor_OCP_ESS_2",
	"H_tweed_ech_nor_OCP_ESS",
	"H_tweed_ech_nor_OCP_TASC",
	"H_tweed_ech_nor_OCP_TASC_b",
	"H_tweed_ech_nor_OCP_TASC_b_ESS",
	"H_tweed_ech_nor_OCP_TASC_b_ESS_3",
	"H_tweed_ech_nor_OCP_TASC_b_ESS_2",
	"H_tweed_ech_nor_OCP_TASC_ESS_2",
	"H_tweed_ech_nor_OCP_TASC_ESS",
	"H_tweed_ech_nor_OCP_scrim",
	"H_tweed_ech_nor_OCP_scrim_ess",
	"H_tweed_ech_nor_OCP_scrim_TASC",
	"H_tweed_ech_nor_OCP_scrim_TASC_ESS"
];

RA_InfGear = [
	// UNIFORMS
	"U_tweed_acu_summer_ocp_jedi",
	"U_tweed_acu_summer_ocp",
	"U_tweed_acu_summer_ocp_trop",
	"U_tweed_acu_summer_ocp_g",
	"U_tweed_acu_summer_ocp_jedi_g",
	"U_tweed_acu_summer_ocp_tuck_jedi",
	"U_tweed_acu_summer_ocp_tuck",
	"U_tweed_acu_summer_ocp_tuck_trop",
	"U_tweed_acu_summer_ocp_tuck_unbl_jedi",
	"U_tweed_acu_summer_ocp_tuck_unbl_trop",
	"U_tweed_acu_summer_ocp_tuck_unbl",
	"U_tweed_acu_summer_ocp_unbl_jedi",
	"U_tweed_acu_summer_ocp_unbl",
	"U_tweed_acu_summer_ocp_unbl_trop",
	"U_tweed_acu_summer_ocp_crye",
	"U_tweed_acu_summer_ocp_crye_trop",
	"U_tweed_acu_summer_ocp_crye_jedi",
	"U_tweed_acu_summer_ocp_crye_knee",
	"U_tweed_acu_summer_ocp_crye_knee_trop",
	"U_tweed_acu_summer_ocp_crye_knee_jedi",
	"U_tweed_acu_summer_ocp_blench_crye_jedi",
	"U_tweed_acu_summer_ocp_blench_crye_trop",
	"U_tweed_acu_summer_ocp_blench_crye",
	"U_tweed_acu_summer_ocp_blench_crye_knee_jedi",
	"U_tweed_acu_summer_ocp_blench_crye_knee_trop",
	"U_tweed_acu_summer_ocp_blench_crye_knee"
] + RA_InfHelmets;

RA_InfWeapsAttachments = [
	//
	"ACE_acc_pointer_green",
	"rhsusf_acc_anpeq15_bk",
	"rhsusf_acc_anpeq15_bk_light",
	"rhsusf_acc_anpeq15_bk_top",
	"rhsusf_acc_anpeq15side_bk",
	"rhsusf_acc_wmx_bk",
	"rhsusf_acc_SF3P556",
	"rhsusf_acc_SFMB556",
	"rhsusf_acc_grip1",
	"rhsusf_acc_grip2",
	"rhsusf_acc_grip3",
	"rhsusf_acc_kac_grip",
	"rhsusf_acc_rvg_blk",
	"rhsusf_acc_tdstubby_blk",
	"rhsusf_acc_harris_bipod",
	"rhsusf_acc_nt4_black"

];

RA_InfWeapsSites = [
	"optic_Holosight",
	"optic_Holosight_blk_F",
	"optic_Holosight_khk_F",
	"optic_Holosight_arid_F",
	"optic_Holosight_lush_F",
	"rhsusf_acc_EOTECH",
	"rhsusf_acc_g33_T1",
	"rhsusf_acc_g33_xps3",
	"rhsusf_acc_g33_xps3_tan",
	"rhsusf_acc_eotech_552",
	"rhsusf_acc_eotech_552_d",
	"rhsusf_acc_eotech_552_wd",
	"rhsusf_acc_su230",
	"rhsusf_acc_su230_c",
	"rhsusf_acc_su230a",
	"rhsusf_acc_su230a_c",
	"rhsusf_acc_T1_high",
	"rhsusf_acc_T1_low",
	"rhsusf_acc_eotech_xps3",
	"rhsusf_acc_su230_mrds",
	"rhsusf_acc_acog_rmr",
	"rhsusf_acc_acog2_usmc",
	"rhsusf_acc_acog3_usmc",
	"rhsusf_acc_acog_usmc",
	"rhsusf_acc_compm4"
];

RA_InfWeapsAmmo = [
    // AMMO
	"rhs_mag_30Rnd_556x45_M855A1_Stanag_Pull",
	"grcb_mag_30Rnd_556x45_M855_Stanag_mix",
	"grcb_mag_30Rnd_556x45_Mk318_Stanag_mix",
	"rhsusf_mag_17Rnd_9x19_JHP",
	"grcb_mag_30Rnd_556x45_Mk318_PMAG_mix"
];

RA_InfWeaps = [
	//WEAPONS
	"rhs_weap_m4a1_carryhandle_mstock",
	"rhsusf_weap_glock17g4",
	"rhs_weap_M136"

] + RA_InfWeapsAmmo;
// --------------------------------- Goblin ---------------------------------
RA_Goblin = [
	// uniforms
	"V_EOD_olive_F",

	"U_tweed_acu_summer_ocp_jedi",
	"U_tweed_acu_summer_ocp",
	"U_tweed_acu_summer_ocp_trop",
	"U_tweed_acu_summer_ocp_g",
	"U_tweed_acu_summer_ocp_jedi_g",
	"U_tweed_acu_summer_ocp_tuck_jedi",
	"U_tweed_acu_summer_ocp_tuck",
	"U_tweed_acu_summer_ocp_tuck_trop",
	"U_tweed_acu_summer_ocp_tuck_unbl_jedi",
	"U_tweed_acu_summer_ocp_tuck_unbl_trop",
	"U_tweed_acu_summer_ocp_tuck_unbl",
	"U_tweed_acu_summer_ocp_unbl_jedi",
	"U_tweed_acu_summer_ocp_unbl",
	"U_tweed_acu_summer_ocp_unbl_trop",
	"U_tweed_acu_summer_ocp_crye",
	"U_tweed_acu_summer_ocp_crye_trop",
	"U_tweed_acu_summer_ocp_crye_jedi",
	"U_tweed_acu_summer_ocp_crye_knee",
	"U_tweed_acu_summer_ocp_crye_knee_trop",
	"U_tweed_acu_summer_ocp_crye_knee_jedi",
	"U_tweed_acu_summer_ocp_blench_crye_jedi",
	"U_tweed_acu_summer_ocp_blench_crye_trop",
	"U_tweed_acu_summer_ocp_blench_crye",
	"U_tweed_acu_summer_ocp_blench_crye_knee_jedi",
	"U_tweed_acu_summer_ocp_blench_crye_knee_trop",
	"U_tweed_acu_summer_ocp_blench_crye_knee",

	"ACE_Clacker",
	"ACE_DefusalKit",
	"ACE_M26_Clacker",
	"ACE_MX2A",
	"MineDetector",
	// minedetecter
	"ACE_VMH3",
	"ACE_VMM3",
	// GEAR
	"ACE_Fortify",
	"bunwell_axe",
	"ACE_MX2A",
	"ACE_wirecutter",
	"ToolKit",
	"ACE_EntrenchingTool",
	"J3FF_FoxholeTool",
	"UK3CB_LFR_B_B_Tacticalpack_Eng_Tan",
	"Binocular",
	"rhsusf_bino_m24",
	"rhsusf_bino_m24_ARD"
] + RA_BasicInfVests + RA_InfBackpacks;

// Grenadier weapons/ammo are used in a few other roles so define them first
RA_GrenadierAmmo = [
	// AMMO
	"rhs_mag_M441_HE",
	"rhs_mag_M433_HEDP",
	"rhs_mag_M397_HET",
	"rhs_mag_M583A1_white",
	"rhs_mag_m661_green",
	"rhs_mag_m662_red",
	"rhs_mag_m713_Red",
	"rhs_mag_m714_White",
	"rhs_mag_m715_Green",
	"rhs_mag_m716_yellow",
	"ACE_40mm_Flare_white",
	"ACE_40mm_Flare_green",
	"ACE_40mm_Flare_red",
	"ACE_40mm_Flare_ir",
	"ACE_HuntIR_M203",
	"rhs_mag_30Rnd_556x45_M855A1_Stanag_Pull",
	"grcb_mag_30Rnd_556x45_M855_Stanag_mix",
	"grcb_mag_30Rnd_556x45_Mk318_Stanag_mix",
	"grcb_mag_30Rnd_556x45_Mk318_PMAG_mix"
];
RA_GrenadierWeapons = [
	"rhs_weap_m4a1_m320",
	"rhs_weap_M320"
] + RA_GrenadierAmmo;
RA_Grenadier = [	
] + RA_BasicInfVests + RA_InfBackpacks + RA_GrenadierWeapons;

// ---------------------------------- COMPANY HQ ----------------------------------
RA_CO = [
    "ACE_Chemlight_HiBlue",
    "ACE_Chemlight_HiGreen",
    "ACE_Chemlight_HiRed",
    "ACE_Chemlight_HiWhite",
    "ACE_Chemlight_HiYellow",
    "ACE_Chemlight_UltraHiOrange",
	"Binocular",
	"rhsusf_bino_m24",
	"rhsusf_bino_m24_ARD",
	"ACE_Vector",
	"ACE_MX2A",
	"rhsusf_bino_lerca_1200_black",
	"ItemcTab"
] + RA_TeamLeaderVests;

RA_XO = [
    "ACE_Chemlight_HiBlue",
    "ACE_Chemlight_HiGreen",
    "ACE_Chemlight_HiRed",
    "ACE_Chemlight_HiWhite",
    "ACE_Chemlight_HiYellow",
    "ACE_Chemlight_UltraHiOrange",
	"Binocular",
	"rhsusf_bino_m24",
	"rhsusf_bino_m24_ARD",
	"ACE_Vector",
	"ACE_MX2A",
	"rhsusf_bino_lerca_1200_black",
    "B_UavTerminal",
	"ItemcTab"

] + RA_TeamLeaderVests;

RA_Shadow = [
	"B_UavTerminal"
] + RA_TeamLeaderVests;

RA_JFO = [
	"rhsusf_ANPVS_15",
    "ACE_Chemlight_HiBlue",
    "ACE_Chemlight_HiGreen",
    "ACE_Chemlight_HiRed",
    "ACE_Chemlight_HiWhite",
    "ACE_Chemlight_HiYellow",
    "ACE_Chemlight_UltraHiOrange",
	"B_IR_Grenade",
	"ACE_HuntIR_M203",
	// MISC
    "ACE_SpottingScope",
	"Binocular",
	"rhsusf_bino_m24",
	"rhsusf_bino_m24_ARD",
	"ACE_Vector",
	"ACE_MX2A",
	"rhsusf_bino_lerca_1200_black",
	"Laserdesignator",
	"Laserbatteries",
	"ACE_Vector",
	"B_UavTerminal",
	"itc_land_tablet_rover",
	"ACE_HuntIR_monitor",
	"ItemcTab"

] + RA_TeamLeaderVests + RA_GrenadierWeapons;

// ---------------------------------- BANSHEE ----------------------------------
RA_BansheeM = [
	"kat_IV_16",
	"kat_nitroglycerin",
	"kat_norepinephrine",
	"kat_Carbonate",
	"kat_naloxone",
	"ACE_salineIV",
	"ACE_plasmaIV",
	"ACE_bloodIV",
	"ACE_bloodIV_250",
	"ACE_bloodIV_500",
	"ACE_surgicalKit",
	"ACE_adenosine",
	"kat_AED",
	"kat_lidocaine",
	"kat_phenylephrine",
	"kat_TXA",
	"kat_IO_FAST",
	"ACE_Vector",
	"ItemcTab",
	"ItemAndroid"

] + RA_TeamLeaderVests;

RA_BansheeTL = [
	"kat_X_AED",
	"kat_IV_16",
	"kat_nitroglycerin",
	"kat_norepinephrine",
	"kat_Carbonate",
	"kat_naloxone",
	"ACE_salineIV",
	"ACE_plasmaIV",
	"ACE_bloodIV",
	"ACE_bloodIV_250",
	"ACE_bloodIV_500",
	"ACE_surgicalKit",
	"ACE_adenosine",
	"kat_AED",
	"kat_lidocaine",
	"kat_phenylephrine",
	"kat_TXA",
	"kat_IO_FAST"

] + RA_TeamLeaderVests;

RA_BansheePilot = [
	// BACKPACK
	// MISC
	"ToolKit",
	"ItemcTab"

];

// ---------------------------------- PLATOON HQ ----------------------------------
RA_PL = [
    "ACE_Chemlight_HiBlue",
    "ACE_Chemlight_HiGreen",
    "ACE_Chemlight_HiRed",
    "ACE_Chemlight_HiWhite",
    "ACE_Chemlight_HiYellow",
    "ACE_Chemlight_UltraHiOrange",
	"Binocular",
	"rhsusf_bino_m24",
	"rhsusf_bino_m24_ARD",
	"ACE_Vector",
	"ACE_MX2A",
	"rhsusf_bino_lerca_1200_black",
	"Laserdesignator",
	"Laserbatteries",
	"ItemcTab"

] + RA_TeamLeaderVests + RA_GrenadierWeapons + RA_InfHelmets + RA_ShemaghMasks;

RA_PSgt = [
    "ACE_Chemlight_HiBlue",
    "ACE_Chemlight_HiGreen",
    "ACE_Chemlight_HiRed",
    "ACE_Chemlight_HiWhite",
    "ACE_Chemlight_HiYellow",
    "ACE_Chemlight_UltraHiOrange",
	"Binocular",
	"rhsusf_bino_m24",
	"rhsusf_bino_m24_ARD",
	"ACE_Vector",
	"ACE_MX2A",
	"rhsusf_bino_lerca_1200_black",
	"Laserdesignator",
	"Laserbatteries",
	"ItemcTab"

] + RA_TeamLeaderVests + RA_GrenadierWeapons + RA_InfHelmets + RA_ShemaghMasks;

RA_MedicMeds = [
	// MEDS
	"kat_IV_16",
	"kat_nitroglycerin",
	"kat_norepinephrine",
	"kat_Carbonate",
	"kat_naloxone",
	"ACE_salineIV",
	"ACE_plasmaIV",
	"ACE_bloodIV",
	"ACE_bloodIV_250",
	"ACE_bloodIV_500",
	"ACE_surgicalKit",
	"ACE_adenosine",
	"kat_lorazepam",
	"kat_plate",
	"kat_accuvac",
	"kat_retractor",
	"kat_scalpel",
	"kat_etomidate",
	"kat_IO_FAST",
	"kat_X_AED"

];
RA_PLMedMedications = [
	// MISC
	"kat_AED",
	"kat_X_AED",
	"kat_lidocaine",
	"kat_phenylephrine",
	"kat_accuvac",
	"kat_TXA",
	"kat_IO_FAST"

] + RA_MedicMeds;

RA_PLMed = [
    "ACE_Chemlight_HiBlue",
    "ACE_Chemlight_HiGreen",
    "ACE_Chemlight_HiRed",
    "ACE_Chemlight_HiWhite",
    "ACE_Chemlight_HiYellow",
    "ACE_Chemlight_UltraHiOrange",
	// MISC
	"Binocular",
	"rhsusf_bino_m24",
	"rhsusf_bino_m24_ARD",
	"ACE_Vector",
	"rhsusf_bino_lerca_1200_black",
	"ItemcTab"

] + RA_PLMedMedications + RA_TeamLeaderVests + RA_InfHelmets + RA_ShemaghMasks;

PMed = [
	"kat_IV_16",
	"kat_nitroglycerin",
	"kat_norepinephrine",
	"kat_Carbonate",
	"kat_naloxone",
	"ACE_salineIV",
	"ACE_plasmaIV",
	"ACE_bloodIV",
	"ACE_bloodIV_250",
	"ACE_bloodIV_500",
	"ACE_surgicalKit",
	"ACE_adenosine",
	// MISC
	"kat_AED",
	"kat_X_AED",
	"kat_lidocaine",
	"kat_phenylephrine",
	"kat_TXA",
	"kat_IO_FAST",
	// VESTS
	"rhsusf_spc_corpsman",
	// GRENADES
    "ACE_Chemlight_HiBlue",
    "ACE_Chemlight_HiGreen",
    "ACE_Chemlight_HiRed",
    "ACE_Chemlight_HiWhite",
    "ACE_Chemlight_HiYellow",
    "ACE_Chemlight_UltraHiOrange",
	// MISC
	"Binocular",
	"rhsusf_bino_m24",
	"rhsusf_bino_m24_ARD",
	"ACE_Vector",
	"rhsusf_bino_lerca_1200_black",
	"ItemcTab"

] + RA_PLMedMedications + RA_TeamLeaderVests + RA_InfHelmets;

// ---------------------------------- INFANTRY ----------------------------------
RA_SL = [
	"ACE_40mm_Flare_white",
	"ACE_40mm_Flare_green",
	"ACE_40mm_Flare_red",
	"ACE_40mm_Flare_ir",
	"ACE_HuntIR_M203",
	// MISC
	"ACE_HuntIR_monitor",
	"Binocular",
	"rhsusf_bino_m24",
	"rhsusf_bino_m24_ARD",
	"ACE_MX2A",
	"ACE_Vector",
	"rhsusf_bino_lerca_1200_black",
	"ItemcTab"

] + RA_TeamLeaderVests;
// SL can also pull ammo for their Autorifleman/Machinegunner, see bottom of this script

RA_TL = [
	"ACE_HuntIR_monitor",
    "ACE_Chemlight_HiBlue",
    "ACE_Chemlight_HiGreen",
    "ACE_Chemlight_HiRed",
    "ACE_Chemlight_HiWhite",
    "ACE_Chemlight_HiYellow",
    "ACE_Chemlight_UltraHiOrange",
	"Binocular",
	"rhsusf_bino_m24",
	"rhsusf_bino_m24_ARD",
	"ACE_Vector",
	"ACE_MX2A",
	"rhsusf_bino_lerca_1200_black",
	"ItemcTab"

] + RA_InfBackpacks + RA_TeamLeaderVests;
// TL can also pull ammo for their Autorifleman/Machinegunner, see bottom of this script

RA_Medic = [
	"ItemcTab"

] + RA_BasicInfVests + RA_MedicMeds + RA_InfBackpacks;

RA_ARiflemanAmmo = [
	// AMMO
    "rhsusf_200Rnd_556x45_soft_pouch",
	"rhsusf_200Rnd_556x45_mixed_soft_pouch",
	"rhsusf_200Rnd_556x45_box",
	"rhsusf_200rnd_556x45_mixed_box",
	"rhsusf_100Rnd_556x45_soft_pouch",
	"rhsusf_100Rnd_556x45_mixed_soft_pouch",
    "rhs_mag_30Rnd_556x45_M855A1_PMAG_Tan",
	"rhs_mag_30Rnd_556x45_M855A1_PMAG_Tan_Tracer_Red",
	"rhs_mag_30Rnd_556x45_M855A1_PMAG",
	"rhs_mag_30Rnd_556x45_M855A1_PMAG_Tracer_Red",
	// MISC
	"ACE_SpareBarrel"

];

RA_ARifleman = [
	"ACE_EntrenchingTool",
	// GUN
	"rhs_weap_m249_pip",
	"rhs_weap_m249_pip_S",
	"rhs_weap_m249_pip_L",
	"rhs_weap_m249_pip_ris",
	//"rhs_weap_m249_pip",
	// GRIPS AND BIPODS
	"rhsusf_acc_grip4",
	"rhsusf_acc_grip1",
	"rhsusf_acc_kac_grip",
	"rhsusf_acc_grip4_bipod",
	"rhsusf_acc_saw_bipod",
	// ATTACHMENTS
	"ACE_acc_pointer_green",
	"rhsusf_acc_anpeq15_bk",
	"rhsusf_acc_anpeq15_bk_light",
	"rhsusf_acc_anpeq15_bk_top",
	"rhsusf_acc_anpeq15side_bk",
	"rhsusf_acc_wmx_bk",
	"rhsusf_acc_SF3P556",
	"rhsusf_acc_SFMB556",
	// SCOPES
	"rhsusf_acc_su230",
	"rhsusf_acc_su230_c",
	"rhsusf_acc_su230_mrds",
	"rhsusf_acc_su230_mrds_c",
	"rhsusf_acc_acog",
	"rhsusf_acc_acog2_usmc",
	"rhsusf_acc_acog3_usmc",
	"rhsusf_acc_acog_usmc",
	"rhsusf_acc_compm4"

] + RA_BasicInfVests + RA_InfBackpacks + RA_ARiflemanAmmo;

RA_DMarksman = [
	"kt_M110A1_blk02",
	"rhsusf_acc_harris_swivel",
	// M40 ammo
	"rhsusf_5Rnd_762x51_AICS_m118_special_Mag",
	"rhsusf_5Rnd_762x51_AICS_m993_Mag",
	"rhsusf_5Rnd_762x51_AICS_m62_Mag",
	//
	"rhsusf_10Rnd_762x51_m118_special_Mag",
	"rhsusf_10Rnd_762x51_m993_Mag",
	"rhsusf_10Rnd_762x51_m62_Mag",
	//
	"10Rnd_338_Mag",
	"rhsusf_20Rnd_762x51_m80_Mag",
	"rhsusf_20Rnd_762x51_m118_special_Mag",
	"rhsusf_20Rnd_762x51_m62_Mag",
	"rhsusf_20Rnd_762x51_m993_Mag",
	//
	"bipod_01_F_khk",
	"bipod_01_F_blk",
	"bipod_01_F_mtp",
	"rhs_acc_harris_swivel",
	"rhsusf_acc_harris_bipod",
	"bipod_01_F_snd",
	// M14
	"rhs_weap_XM2010_d",
	//
	"UK3CB_M14_20rnd_762x51",
	"rhsusf_20Rnd_762x51_m62_Mag",
	"uk3cb_muzzle_snds_M14",
	"rhsusf_20Rnd_762x51_m993_Mag",
	//
	// SCOPES
	"rhsusf_acc_nxs_5522x56_md_sun",
	"optic_lrps",
	"rhsusf_acc_premier_low",
	"rhsusf_acc_M8541",
	"rhsusf_acc_M8541_low",
	"rhsusf_acc_premier_anpvs27",
	"rhsusf_acc_premier",
	// ACC side
	"rhs_acc_2dpZenit_ris",
	"rhs_acc_perst1ik_ris",
	"rhs_acc_perst3",
	"rhsusf_acc_wmx_bk",
	"rhsusf_acc_M952V",
	"rhsusf_acc_anpeq15A",
	"rhsusf_acc_anpeq15side_bk",
	// muzzle
	"rhsusf_acc_harris_swivel",
	"ACE_acc_pointer_green",
	"rhsusf_acc_harris_bipod",
	"bipod_01_F_blk",
	// Scopes
	"rhsusf_acc_acog2_usmc",
	"rhsusf_acc_acog3_usmc",
	"rhsusf_acc_acog_usmc",
	//
	// AMMO
	"rhs_mag_30Rnd_556x45_M855A1_PMAG_Tan",
	"rhs_mag_30Rnd_556x45_M855A1_PMAG_Tan_Tracer_Red",
	"rhs_mag_30Rnd_556x45_M855A1_PMAG",
	"rhs_mag_30Rnd_556x45_M855A1_PMAG_Tracer_Red",
	//
	"rhsusf_acc_nt4_black",
	//
	"rhsusf_acc_harris_bipod",
	"rhsusf_acc_grip1",
	"rhsusf_acc_grip2",
	"rhsusf_acc_grip2_tan",
	"rhsusf_acc_grip2_wd",
	"rhsusf_acc_rvg_blk",
	"rhsusf_acc_tdstubby_blk",
	"rhsusf_acc_tdstubby_tan",
	"rhsusf_acc_rvg_de",
	"rhs_acc_grip_rk6",
	"rhs_acc_grip_ffg2",
	"optic_dms",
	"ACE_Kestrel4500",
    "ACE_Chemlight_HiBlue",
    "ACE_Chemlight_HiGreen",
    "ACE_Chemlight_HiRed",
    "ACE_Chemlight_HiWhite",
    "ACE_Chemlight_HiYellow",
    "ACE_Chemlight_UltraHiOrange",
	"Binocular",
	"rhsusf_bino_m24",
	"rhsusf_bino_m24_ARD",
	"rhsusf_bino_lerca_1200_black",
	"Laserdesignator",
	"Laserbatteries",
	"ACE_MX2A",
	"ACE_Vector",
	"ACE_TRIPOD",
	"ACE_RangeCard"

] + RA_TeamLeaderVests + RA_InfBackpacks + RA_BasicInfVests;

RA_RiflemanAmmo = [
];

RA_Rifleman = [
	"ACE_EntrenchingTool"
] + RA_InfBackpacks + RA_BasicInfVests + RA_RiflemanAmmo;

RA_ESpecialistAmmo = [
];

RA_ESpecialist = [
    "ACE_wirecutter",
	"ACE_Clacker",
	"ACE_DefusalKit",
	"ACE_M26_Clacker",
	"MineDetector",
	"rhsusf_m112_mag",
	"rhsusf_m112x4_mag",
	"SatchelCharge_Remote_Mag",
	"SLAMDirectionalMine_Wire_Mag"

] + RA_InfBackpacks + RA_BasicInfVests + RA_ESpecialistAmmo;

// ---------------------------------- WEAPONS ----------------------------------
RA_MGunnerAmmo = [
    // AMMO
    "rhsusf_100Rnd_762x51_m80a1epr",
    "rhsusf_100Rnd_762x51_m62_tracer",
    "rhsusf_100Rnd_762x51_m61_ap",
	//
	"rhsusf_50Rnd_762x51_m80a1epr",
    "rhsusf_50Rnd_762x51_m62_tracer",
    "rhsusf_50Rnd_762x51_m61_ap",
	// MISC
	"ACE_SpareBarrel"

];
RA_MGunner = [
    "rhs_weap_m240B",

	"rhsusf_acc_ACOG_MDO",
	"rhsusf_acc_su230a",
	"rhsusf_acc_su230a_c",
	"rhsusf_acc_su230a_mrds",
	"rhsusf_acc_su230a_mrds_c",
	"rhsusf_acc_acog2_usmc",
	"rhsusf_acc_acog3_usmc",
	"rhsusf_acc_acog_usmc",
	// BARREL ATTACHMENT
    "rhsusf_acc_ARDEC_M240",
	// GRIPS AND BIPODS
	"rhsusf_acc_grip4_bipod",         
    "rhsusf_acc_saw_bipod",            
    "rhsusf_acc_saw_lw_bipod",   
    "rhsusf_acc_kac_grip_saw_bipod",
	// RAIL ATTACHMENTS
    "rhsusf_acc_anpeq15_bk_light",     
    "rhsusf_acc_anpeq15_bk_top",       
    "rhsusf_acc_anpeq15_bk",                     
    "rhsusf_acc_anpeq15side_bk",
    "rhsusf_acc_wmx_bk"

] + RA_InfBackpacks + RA_BasicInfVests + RA_MGunnerAmmo;

RA_ATSpec = [
	// AT
	"KTW_mk45",
	// AT Ammo 
	"kt_84mm_HEAT_AT",
	"kt_84mm_HE_airburst",
	// Misc
	"ACE_EntrenchingTool"

] + RA_InfBackpacks + RA_BasicInfVests;

RA_ATAmmoBearer = [
	"kt_84mm_HEAT_AT",
	"kt_84mm_HE_airburst"
	// MISC
] + RA_InfBackpacks + RA_BasicInfVests + RA_MGunnerAmmo + RA_GrenadierAmmo; // Ammo bearer can pull all ammo used in their squad

RA_MGAmmoBearer = [
	// MISC
	"ACE_EntrenchingTool",
	"ACE_SpareBarrel"

] + RA_InfBackpacks + RA_BasicInfVests + RA_MGunnerAmmo; // Assistant Machine Gunner is focussed on supporting their MGs

// ---------------------------------- PHANTOM ---------------------------------------
RA_Phantom = [
	// Sniper M40
	"kt_M110A1_blk02",
	"kt_mk22",
	// M40 acc
	"rhsusf_acc_harris_swivel",
	// M40 ammo
	"rhsusf_5Rnd_762x51_AICS_m118_special_Mag",
	"rhsusf_5Rnd_762x51_AICS_m993_Mag",
	"rhsusf_5Rnd_762x51_AICS_m62_Mag",
	//
	"rhsusf_10Rnd_762x51_m118_special_Mag",
	"rhsusf_10Rnd_762x51_m993_Mag",
	"rhsusf_10Rnd_762x51_m62_Mag",
	//
	"10Rnd_338_Mag",
	"rhsusf_20Rnd_762x51_m80_Mag",
	"rhsusf_20Rnd_762x51_m118_special_Mag",
	"rhsusf_20Rnd_762x51_m62_Mag",
	"rhsusf_20Rnd_762x51_m993_Mag",
	//
	"bipod_01_F_khk",
	"bipod_01_F_blk",
	"bipod_01_F_mtp",
	"rhs_acc_harris_swivel",
	"rhsusf_acc_harris_bipod",
	"bipod_01_F_snd",
	// M14
	"rhs_weap_XM2010_d",
	//
	"UK3CB_M14_20rnd_762x51",
	"rhsusf_20Rnd_762x51_m62_Mag",
	"uk3cb_muzzle_snds_M14",
	"rhsusf_20Rnd_762x51_m993_Mag",
	//
	"rhsusf_acc_m14_flashsuppresor",
	// Thermol scopes
	// SCOPES
	"rhsusf_acc_nxs_5522x56_md_sun",
	"optic_lrps",
	"rhsusf_acc_premier_low",
	"rhsusf_acc_M8541",
	"rhsusf_acc_M8541_low",
	"rhsusf_acc_premier_anpvs27",
	"rhsusf_acc_premier",
	// ACC side
	"rhs_acc_2dpZenit_ris",
	"rhs_acc_perst1ik_ris",
	"rhs_acc_perst3",
	"rhsusf_acc_wmx_bk",
	"rhsusf_acc_M952V",
	"rhsusf_acc_anpeq15A",
	"rhsusf_acc_anpeq15side_bk",
	// muzzle
	"rhsusf_acc_harris_swivel",
	"ACE_acc_pointer_green",
	"rhsusf_acc_m24_muzzlehider_black",
	"muzzle_snds_B",
	"ACE_muzzle_mzls_B",
	"rhsusf_acc_harris_bipod",
	"bipod_01_F_blk",
	// Scopes
	"rhsusf_acc_acog2_usmc",
	"rhsusf_acc_acog3_usmc",
	"rhsusf_acc_acog_usmc",
	//
	// AMMO
	"rhs_mag_30Rnd_556x45_M855A1_PMAG_Tan",
	"rhs_mag_30Rnd_556x45_M855A1_PMAG_Tan_Tracer_Red",
	"rhs_mag_30Rnd_556x45_M855A1_PMAG",
	"rhs_mag_30Rnd_556x45_M855A1_PMAG_Tracer_Red",
	//
	"rhsusf_acc_nt4_black",
	//
	"rhsusf_acc_harris_bipod",
	"rhsusf_acc_grip1",
	"rhsusf_acc_grip2",
	"rhsusf_acc_grip2_tan",
	"rhsusf_acc_grip2_wd",
	"rhsusf_acc_rvg_blk",
	"rhsusf_acc_tdstubby_blk",
	"rhsusf_acc_tdstubby_tan",
	"rhsusf_acc_rvg_de",
	"rhs_acc_grip_rk6",
	"rhs_acc_grip_ffg2",
	"optic_dms",

	"ACE_Kestrel4500",
    "ACE_Chemlight_HiBlue",
    "ACE_Chemlight_HiGreen",
    "ACE_Chemlight_HiRed",
    "ACE_Chemlight_HiWhite",
    "ACE_Chemlight_HiYellow",
    "ACE_Chemlight_UltraHiOrange",
	"Binocular",
	"rhsusf_bino_m24",
	"rhsusf_bino_m24_ARD",
	"rhsusf_bino_lerca_1200_black",
	"Laserdesignator",
	"Laserbatteries",
	"ACE_MX2A",
	"ACE_Vector",
	"ACE_TRIPOD",
	"ACE_RangeCard"

] + RA_TeamLeaderVests + RA_InfBackpacks + RA_BasicInfVests;

RA_PhantomSpotter = [
	"rhsusf_acc_nt4_black",
	// M40 ammo
	"rhsusf_5Rnd_762x51_AICS_m118_special_Mag",
	"rhsusf_5Rnd_762x51_AICS_m993_Mag",
	"rhsusf_5Rnd_762x51_AICS_m62_Mag",
	//
	"rhsusf_10Rnd_762x51_m118_special_Mag",
	"rhsusf_10Rnd_762x51_m993_Mag",
	"rhsusf_10Rnd_762x51_m62_Mag",
	//
	"UK3CB_M14_20rnd_762x51",
	"rhsusf_20Rnd_762x51_m62_Mag",
	//
	"rhsusf_20Rnd_762x51_m80_Mag",
	"rhsusf_20Rnd_762x51_m118_special_Mag",
	"rhsusf_20Rnd_762x51_m62_Mag",
	"rhsusf_20Rnd_762x51_m993_Mag",
	//
	"bipod_01_F_khk",
	"bipod_01_F_blk",
	"bipod_01_F_mtp",
	"rhs_acc_harris_swivel",
	"rhsusf_acc_harris_bipod",
	"bipod_01_F_snd",
	//
	"uk3cb_optic_artel_m14",
	"uk3cb_optic_PVS4_M14",
	//
	"UK3CB_M14_20rnd_762x51",
	"rhsusf_20Rnd_762x51_m62_Mag",
	"uk3cb_muzzle_snds_M14",
	"rhsusf_20Rnd_762x51_m993_Mag",
	//
	"rhsusf_acc_m14_flashsuppresor",
	// Scopes for sniper
	"rhsusf_acc_acog2_usmc",
	"rhsusf_acc_acog3_usmc",
	"rhsusf_acc_acog_usmc",
	// BACKPACK GUNS
	// AMMO
	"rhs_mag_30Rnd_556x45_M855A1_PMAG_Tan",
	"rhs_mag_30Rnd_556x45_M855A1_PMAG_Tan_Tracer_Red",
	"rhs_mag_30Rnd_556x45_M855A1_PMAG",
	"rhs_mag_30Rnd_556x45_M855A1_PMAG_Tracer_Red",
	//
	"rhsgref_sdn6_suppressor",
	"rhsusf_acc_harris_bipod",
	"rhsusf_acc_grip1",
	"rhsusf_acc_grip2",
	"rhsusf_acc_grip2_tan",
	"rhsusf_acc_grip2_wd",
	"rhsusf_acc_rvg_blk",
	"rhsusf_acc_tdstubby_blk",
	"rhsusf_acc_tdstubby_tan",
	"rhsusf_acc_rvg_de",
	"rhs_acc_grip_rk6",
	"rhs_acc_grip_ffg2",
	"optic_dms",
	// MISC
    "ACE_Chemlight_HiBlue",
    "ACE_Chemlight_HiGreen",
    "ACE_Chemlight_HiRed",
    "ACE_Chemlight_HiWhite",
    "ACE_Chemlight_HiYellow",
    "ACE_Chemlight_UltraHiOrange",
	"ACE_Kestrel4500",
    "ACE_SpottingScope",
	"Binocular",
	"rhsusf_bino_m24",
	"rhsusf_bino_m24_ARD",
	"rhsusf_bino_lerca_1200_black",
	"Laserdesignator",
	"Laserbatteries",
	"ACE_MX2A",
	"ACE_Vector",
	"ACE_TRIPOD",
	"ACE_RangeCard"

] + RA_TeamLeaderVests;

// ---------------------------------- OGRE ----------------------------------

RA_OgreEngiBaseAmmo = [
    "rhs_mag_30Rnd_556x45_M855A1_PMAG_Tan",
	"rhs_mag_30Rnd_556x45_M855A1_PMAG_Tan_Tracer_Red",
	"rhs_mag_30Rnd_556x45_M855A1_PMAG",
	"rhs_mag_30Rnd_556x45_M855A1_PMAG_Tracer_Red",
	// MISC
	"bunwell_axe",
	"ACE_SpareBarrel",
	"Laserbatteries" // To be able to resupply other role's laser designators and to enable crossloading

];
RA_OgreEngiBaseGear = [
	"ACE_SpareBarrel",
	"ACE_Clacker",
	"ACE_DefusalKit",
	"ACE_M26_Clacker",
	"MineDetector",
	"ItemcTab",
	"ToolKit",
	"rhsusf_m112_mag",
	"rhsusf_m112x4_mag",
	"ATMine_Range_Mag",
	"SatchelCharge_Remote_Mag",
	"ClaymoreDirectionalMine_Remote_Mag",
	"APERSBoundingMine_Range_Mag",
	"SLAMDirectionalMine_Wire_Mag",
	"rhsusf_mine_m14_mag",
	"rhs_mine_M19_mag",
	"rhsusf_mine_m49a1_10m_mag",
	"rhsusf_mine_m49a1_3m_mag",
	"rhsusf_mine_m49a1_6m_mag"
];

RA_OgreTL = [
	"Binocular",
	"rhsusf_bino_m24",
	"rhsusf_bino_m24_ARD"

] + RA_TeamLeaderVests + RA_OgreEngiBaseGear + RA_OgreEngiBaseAmmo; // Ogre can pull all other mags as well, added at the end of file

RA_OgreMedicAmmo = [
	"rhs_mag_30Rnd_556x45_M855A1_PMAG_Tan",
	"rhs_mag_30Rnd_556x45_M855A1_PMAG_Tan_Tracer_Red",
	"rhs_mag_30Rnd_556x45_M855A1_PMAG",
	"rhs_mag_30Rnd_556x45_M855A1_PMAG_Tracer_Red",
	// MISC
	"Laserbatteries" // To be able to resupply other role's laser designators and to enable crossloading

];
RA_OgreMedic = [
	"rhsusf_acc_anpeq15_bk",
	"rhsusf_acc_anpeq15_bk_light",
	"rhsusf_acc_anpeq15_bk_top",
	"rhsusf_acc_anpeq15side_bk",
	"rhsusf_acc_wmx_bk",
	// GEAR
	"G_Spectacles_Tinted",
	"Binocular",
	"rhsusf_bino_m24",
	"rhsusf_bino_m24_ARD"

] + RA_OgreEngiBaseGear + RA_OgreEngiBaseAmmo + RA_PLMedMedications + RA_InfBackpacks + RA_OgreMedicAmmo;
// Ogre Med is also Doctor like PL Med. Ogre can pull all other mags as well, added at the end of file

RA_OgreEngi = [
	"Binocular",
	"rhsusf_bino_m24",
	"rhsusf_bino_m24_ARD"

] + RA_InfBackpacks + RA_OgreEngiBaseGear + RA_OgreEngiBaseAmmo; // Ogre can pull all other mags as well, added at the end of file

// ---------------------------------- BUTCHER ----------------------------------
RA_ButcherCommanderAmmo = [
	"rhs_mag_30Rnd_556x45_M855A1_PMAG_Tan",
	"rhs_mag_30Rnd_556x45_M855A1_PMAG_Tan_Tracer_Red",
	"rhs_mag_30Rnd_556x45_M855A1_PMAG",
	"rhs_mag_30Rnd_556x45_M855A1_PMAG_Tracer_Red",
	"rhs_weap_m27iar"

];
RA_ButcherCommander = [
	"ItemcTab",
	"ToolKit",
	"Binocular",
	"rhsusf_bino_m24",
	"rhsusf_bino_m24_ARD",
	"ACE_MX2A",
	"ACE_Vector",
	"rhsusf_bino_lerca_1200_black"

] + RA_TeamLeaderVests + RA_ButcherCommanderAmmo;

RA_ButcherCrewAmmo = [
	"rhs_mag_30Rnd_556x45_M855A1_PMAG_Tan",
	"rhs_mag_30Rnd_556x45_M855A1_PMAG_Tan_Tracer_Red",
	"rhs_mag_30Rnd_556x45_M855A1_PMAG",
	"rhs_mag_30Rnd_556x45_M855A1_PMAG_Tracer_Red"

];
RA_ButcherDriver = [
	"ItemcTab",
	"ToolKit"

] + RA_ButcherCrewAmmo;

RA_ButcherGunner = [
	"ItemcTab",
	"ToolKit"

] + RA_ButcherCrewAmmo;
// ---------------------------------- SHADE ----------------------------------
RA_ShadeAmmo = [
    // AMMO GET SAME GEAR NOW IN DETERMINEROLE
	// WEAPON ATTACHMENTS
	"ACE_Kestrel4500"
	// HATS
	// HEADGEAR
	
];
RA_ShadeTL = [
	"Binocular",
	"rhsusf_bino_m24",
	"rhsusf_bino_m24_ARD",
	"ACE_Vector",
	"rhsusf_bino_lerca_1200_black",
	"ItemcTab",
	"ACE_RangeTable_82mm",
	"ACE_artilleryTable",
	"itc_land_tablet_fdc"

] + RA_ShadeAmmo + RA_TeamLeaderVests;

RA_ShadeM = [
	"Binocular",
	"rhsusf_bino_m24",
	"rhsusf_bino_m24_ARD",
	"ACE_Vector",
	"ItemcTab",
	"ACE_RangeTable_82mm",
	"ACE_artilleryTable",
	"itc_land_tablet_fdc"

] + RA_ShadeAmmo + RA_BasicInfVests;
// ---------------------------------- SAVAGE ----------------------------------
RA_SavageAmmo = [
	"ACE_Kestrel4500"	
];
RA_SavageTL = [
	"Binocular",
	"rhsusf_bino_m24",
	"rhsusf_bino_m24_ARD",
	"ACE_Vector",
	"rhsusf_bino_lerca_1200_black",
	"Laserdesignator",
	"Laserbatteries",
	"ItemcTab",
	"B_UavTerminal",
	"ACE_RangeTable_82mm",
	"ACE_artilleryTable",
	"itc_land_tablet_fdc"

] + RA_SavageAmmo + RA_TeamLeaderVests;

RA_Savage = [
	"Binocular",
	"rhsusf_bino_m24",
	"rhsusf_bino_m24_ARD",
	"ACE_Vector",
	"ItemcTab",
	"Laserdesignator",
	"Laserbatteries",
	"ACE_RangeTable_82mm",
	"ACE_artilleryTable",
	"itc_land_tablet_fdc"

] + RA_SavageAmmo + RA_BasicInfVests;

// ---------------------------------- STALKER ----------------------------------
RA_PilotGear = [
];
RA_PilotHelmets = [
	// HEADGEAR
	"rhsusf_hgu56p_white",
	"rhsusf_hgu56p_visor_white",
	"rhsusf_hgu56p_black",
	"rhsusf_hgu56p_green",
	"rhsusf_hgu56p_mask_black_skull",
	"rhsusf_hgu56p_mask_black",
	"rhsusf_hgu56p_mask_green_mo",
	"rhsusf_hgu56p_mask_green",
	"rhsusf_hgu56p_mask_mo",
	"rhsusf_hgu56p_mask_saf",
	"rhsusf_hgu56p_mask_skull",
	"rhsusf_hgu56p_mask_tan",
	"rhsusf_hgu56p_mask",
	"rhsusf_hgu56p_saf",
	"rhsusf_hgu56p_tan",
	"rhsusf_hgu56p_visor_black",
	"rhsusf_hgu56p_visor_green",
	"rhsusf_hgu56p_visor_mask_black_skull",
	"rhsusf_hgu56p_visor_mask_black",
	"rhsusf_hgu56p_visor_mask_green_mo",
	"rhsusf_hgu56p_visor_mask_green",
	"rhsusf_hgu56p_visor_mask_mo",
	"rhsusf_hgu56p_visor_mask_saf",
	"rhsusf_hgu56p_visor_mask_skull",
	"rhsusf_hgu56p_visor_mask_tan",
	"rhsusf_hgu56p_visor_mask",
	"rhsusf_hgu56p_visor_saf",
	"rhsusf_hgu56p_visor_tan",
	"rhsusf_hgu56p_visor",
	"rhsusf_hgu56p",
	"rhsusf_hgu56p_visor_mask_pink",
	"rhsusf_hgu56p_visor_pink",
	"rhsusf_hgu56p_usa",
	"rhsusf_hgu56p_visor_mask_saf",
	"rhsusf_hgu56p_visor_saf",
	"H_HeadSet_black_F"

];
RA_PilotWeapons = [
	// SCOPES
	"rhsusf_acc_compm4",
	// ATTACHEMENTS
	"rhsusf_acc_anpeq15_bk",
	"rhsusf_acc_anpeq15_bk_light",
	"rhsusf_acc_SF3P556",
	"rhsusf_acc_SFMB556",
	"rhsusf_acc_tdstubby_blk"
];

RA_PilotAmmo = [
	// AMMO
	"rhs_mag_30Rnd_556x45_M855A1_PMAG",
	"rhs_mag_30Rnd_556x45_M855A1_PMAG_Tracer_Red"
];

RA_Stalker = [
	// NVGS
	"rhsusf_ANPVS_15",
	// UNIFORMS
	"USAF_Overalls_Ranger_FG_1_w",
	"USAF_Overalls_Ranger_FG_2_w",
	"USAF_Overalls_Ranger_FG_3_w",
	"USAF_Overalls_Ranger_FG_4_w",
	// MISC
	"ToolKit",
	"ItemcTab"

] + RA_PilotGear + RA_PilotHelmets + RA_PilotWeapons + RA_PilotAmmo;

// ---------------------------------- DEMON ----------------------------------
RA_Demon = [
	// NVGS
	"rhsusf_ANPVS_15",
	// UNIFORMS
	"USAF_Overalls_Ranger_FG_1_w",
	"USAF_Overalls_Ranger_FG_2_w",
	"USAF_Overalls_Ranger_FG_3_w",
	"USAF_Overalls_Ranger_FG_4_w",
	// MISC
	"ToolKit",
	"ItemcTab"

] + RA_PilotGear + RA_PilotHelmets + RA_PilotWeapons + RA_PilotAmmo;

// ---------------------------------- REAPER ----------------------------------
RA_Reaper = [
	// HEADGEAR
	"H_PilotHelmetFighter_B",
	// UNIFORMS
	"USAF_Overalls_Ranger_FG_1_w",
	"USAF_Overalls_Ranger_FG_2_w",
	"USAF_Overalls_Ranger_FG_3_w",
	"USAF_Overalls_Ranger_FG_4_w",
	// MISC
	"B_UavTerminal",
	"ItemcTab",
	"ToolKit"

] + RA_PilotGear + RA_PilotHelmets + RA_PilotWeapons + RA_PilotAmmo;

// Used for ignoring all magazines/ammo types and allowing them to be crossloaded
RA_AllAmmoTypes = RA_DefaultGearAmmo +
	RA_InfWeapsAmmo +
	RA_GrenadierAmmo +
	RA_ARiflemanAmmo +
	RA_RiflemanAmmo +
	RA_ESpecialistAmmo +
	RA_MGunnerAmmo +
	RA_OgreEngiBaseAmmo +
	RA_OgreMedicAmmo +
	RA_ButcherCommanderAmmo +
	RA_ButcherCrewAmmo +
	RA_SavageAmmo +
	RA_ShadeAmmo +
	RA_Goblin +
	RA_TierStuff +
	RA_PilotAmmo;
RA_AllAmmoTypes = RA_AllAmmoTypes arrayIntersect RA_AllAmmoTypes; // Remove duplicates

// Ogre can pull all ammo types
RA_OgreTL = RA_OgreTL + RA_AllAmmoTypes;
RA_OgreMedic = RA_OgreMedic + RA_AllAmmoTypes;
RA_OgreEngi = RA_OgreEngi + RA_AllAmmoTypes;

// SL/TL can also pull ammo for their Autorifleman/Machinegunner
RA_SL = RA_SL + RA_ARiflemanAmmo + RA_MGunnerAmmo;
RA_TL = RA_TL + RA_ARiflemanAmmo + RA_MGunnerAmmo;

// Used for checking whether something is in our arsenal whitelist system or not
RA_FullArsenal = RA_DefaultGear +
	RA_InfGear +
	RA_InfWeaps +
	RA_Grenadier +
	RA_CO +
	RA_XO +
	RA_JFO +
	RA_Shadow +
	RA_PL +
	RA_PSgt +
	RA_PLMed +
	PMed +
	RA_SL +
	RA_TL +
	RA_Medic +
	RA_ARifleman +
	RA_DMarksman +
	RA_Rifleman +
	RA_ESpecialist +
	RA_MGunner +
	RA_ATSpec +
	RA_ATAmmoBearer +
	RA_MGAmmoBearer +
	RA_Phantom +
	RA_PhantomSpotter +
	RA_OgreTL +
	RA_OgreMedic +
	RA_OgreEngi +
	RA_Baseballcaps +
	RA_BansheeTL +
	RA_BansheeM +
	RA_BansheePilot +
	RA_Boonies +
	RA_ButcherCommander +
	RA_ButcherDriver +
	RA_ButcherGunner +
	RA_SavageTL +
	RA_Savage +
	RA_ShadeTL +
	RA_ShadeM +
	RA_Stalker +
	RA_Demon +
	RA_Reaper;
RA_FullArsenal = RA_FullArsenal arrayIntersect RA_FullArsenal; // Remove duplicates
