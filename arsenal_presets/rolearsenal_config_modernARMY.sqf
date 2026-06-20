// HEY IF YOU NEED TO CHANGE FACTIONS, DO SO HERE:
// KC_Liberation_Master_Framework\arsenal_presets\rolearsenal.sqf

// This gear is selected from when someone respawns in onPlayerRespawn.sqf
RA_StartingHeadwear = [
	// hat
	"H_Cap_tan_specops_US"
];
RA_StartingGoggles = [
	// GOGGLES
	"rhs_googles_black",
	"rhs_googles_clear"

];
RA_StartingUniforms = [
	// UNIFORMS
	"rhs_uniform_cu_ocp"
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
	"rhsusf_mag_15Rnd_9x19_FMJ"

];
RA_DefaultGear = [
	// WEAPONS
	"rhsusf_weap_m9",
	// VEST
	"rhsusf_iotv_ocp",
	"rhsusf_iotv_ocp_Rifleman",
	"rhsusf_spcs_ocp",
	// HEADGEAR
	"H_Cap_tan_specops_US",
	// UNIFORM
	"rhs_uniform_cu_ocp_1stcav",
	"rhs_uniform_cu_ocp",
	"rhs_uniform_acu_ocp",
	// BACKPACK
    "B_Parachute",
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
	"rhsusf_ANPVS_14",
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

RA_ShemaghMasks = [// is in Determine Role
	// MASKS
	"UK3CB_G_Ballistic_Shemagh_Tan_Gloves_Tan",
	"rhsusf_shemagh_od",
	"rhsusf_shemagh2_od",
	"rhsusf_shemagh_tan",
	"rhsusf_shemagh2_tan",
	"rhsusf_shemagh_white",
	"rhsusf_shemagh2_white",
	"rhsusf_shemagh_gogg_od",
	"rhsusf_shemagh2_gogg_od",
	"rhsusf_shemagh_gogg_tan",
	"rhsusf_shemagh2_gogg_tan",
	"rhsusf_shemagh_gogg_white",
	"rhsusf_shemagh2_gogg_white",
	"UK3CB_G_Tactical_Black_Shemagh_Tan_Gloves_Tan",
	"UK3CB_G_Tactical_Gloves_Green_Shemagh_Tan_Headset",
	"UK3CB_G_Tactical_Gloves_Green_Shemagh_White_Headset",
	"UK3CB_G_Tactical_Gloves_Tan_Shemagh_Tan_Headset",
	"UK3CB_G_Tactical_Clear_Shemagh_Tan_Tactical_Gloves_Tan",
	"UK3CB_G_Tactical_Clear_Shemagh_Tan_Tactical_Gloves_Green",
	"UK3CB_G_Tactical_Clear_Shemagh_Tan_Headset",
	"UK3CB_G_Balaclava2_DES"
];
RA_Drip = [// Drip is in Determine Role
	"G_Bandanna_blk",
	"G_Bandanna_khk",
	"G_Bandanna_oli",
	"G_Bandanna_tan",
	"UK3CB_G_Balaclava2_DES",
	"UK3CB_G_Gloves_Black_Shemagh_Tan",
	"UK3CB_G_Gloves_Green_Shemagh_Tan",
	"UK3CB_G_Gloves_Tan_Shemagh_Green",
	"UK3CB_G_Gloves_Tan_Shemagh_Tan",
	"UK3CB_G_KLR_Oli",
	"UK3CB_G_KLR_TAN",
	"UK3CB_G_KL_Oli",
	"UK3CB_G_KL_TAN",
	"UK3CB_G_Neck_Shemag_Tan",
	"UK3CB_G_KR_Oli",
	"UK3CB_G_Neck_Shemag_KR_tan",
	"UK3CB_G_Neck_Shemag_KL_tan",
	"UK3CB_G_Neck_Shemag_KLR_tan",
	"UK3CB_G_KR_TAN",
	"UK3CB_G_Tactical_Black",
	"UK3CB_G_Tactical_Black_Gloves_Green",
	"UK3CB_G_Tactical_Black_Gloves_Tan",
	"UK3CB_G_Tactical_Black_Gloves_Black",
	"UK3CB_G_Tactical_Clear_Gloves_Black",
	"UK3CB_G_Tactical_Clear_Gloves_Green",
	"UK3CB_G_Tactical_Clear_Gloves_Tan",
	"UK3CB_G_Tactical_Black_Shemagh_Green",
	"UK3CB_G_Tactical_Black_Shemagh_Tan",
	"UK3CB_G_Tactical_Clear_Shemagh_Green",
	"UK3CB_G_Tactical_Clear_Shemagh_Tan",
	"UK3CB_G_Tactical_Black_Shemagh_Green_Gloves_Black",
	"UK3CB_G_Tactical_Black_Shemagh_Green_Gloves_Green",
	"UK3CB_G_Tactical_Black_Shemagh_Green_Gloves_Tan",
	"UK3CB_G_Tactical_Black_Shemagh_Tan_Gloves_Black",
	"UK3CB_G_Tactical_Black_Shemagh_Tan_Gloves_Green",
	"UK3CB_G_Tactical_Black_Shemagh_Tan_Gloves_Tan",
	"UK3CB_G_Tactical_Black_Shemagh_White_Gloves_Black",
	"UK3CB_G_Tactical_Clear_Shemagh_Green_Gloves_Black",
	"UK3CB_G_Tactical_Clear_Shemagh_Green_Gloves_Green",
	"UK3CB_G_Tactical_Clear_Shemagh_Green_Gloves_Tan",
	"UK3CB_G_Tactical_Clear_Shemagh_Tan_Gloves_Black",
	"UK3CB_G_Tactical_Clear_Shemagh_Tan_Gloves_Green",
	"UK3CB_G_Tactical_Clear_Shemagh_Tan_Gloves_Tan",
	"UK3CB_G_Tactical_Black_Shemagh_Green_Tactical_Gloves_Black",
	"UK3CB_G_Tactical_Black_Shemagh_Green_Tactical_Gloves_Green",
	"UK3CB_G_Tactical_Black_Shemagh_Green_Tactical_Gloves_Tan",
	"UK3CB_G_Tactical_Black_Shemagh_Tan_Tactical_Gloves_Black",
	"UK3CB_G_Tactical_Black_Shemagh_Tan_Tactical_Gloves_Green",
	"UK3CB_G_Tactical_Black_Shemagh_Tan_Tactical_Gloves_Tan",
	"UK3CB_G_Tactical_Clear_Shemagh_Green_Tactical_Gloves_Black",
	"UK3CB_G_Tactical_Clear_Shemagh_Green_Tactical_Gloves_Green",
	"UK3CB_G_Tactical_Clear_Shemagh_Green_Tactical_Gloves_Tan",
	"UK3CB_G_Tactical_Clear_Shemagh_Tan_Tactical_Gloves_Black",
	"UK3CB_G_Tactical_Clear_Shemagh_Tan_Tactical_Gloves_Green",
	"UK3CB_G_Tactical_Clear_Shemagh_Tan_Tactical_Gloves_Tan",
	"UK3CB_G_Tactical_Black_Tactical_Gloves_Green",
	"UK3CB_G_Tactical_Black_Tactical_Gloves_Tan",
	"UK3CB_G_Tactical_Black_Tactical_Gloves_Black",
	"UK3CB_G_Tactical_Clear_Tactical_Gloves_Green",
	"UK3CB_G_Tactical_Clear_Tactical_Gloves_Tan",
	"UK3CB_G_Tactical_Clear_Tactical_Gloves_Black",
	"UK3CB_G_Tactical_Gloves_Black",
	"UK3CB_G_Tactical_Gloves_Green",
	"UK3CB_G_Tactical_Gloves_Tan",
	"UK3CB_G_Tactical_Gloves_Black_Shemagh_Green",
	"UK3CB_G_Tactical_Gloves_Black_Shemagh_Tan",
	"UK3CB_G_Tactical_Gloves_Green_Shemagh_Green",
	"UK3CB_G_Tactical_Gloves_Green_Shemagh_Tan",
	"UK3CB_G_Tactical_Gloves_Tan_Shemagh_Green",
	"UK3CB_G_Tactical_Gloves_Tan_Shemagh_Tan",
	"UK3CB_G_Tactical_Clear",
	"rhs_googles_black",
	"rhs_googles_clear",
	"rhs_googles_yellow",
	"rhs_ess_black",
	"rhsusf_shemagh_od",
	"rhsusf_shemagh2_od",
	"rhsusf_shemagh_tan",
	"rhsusf_shemagh2_tan",
	"rhsusf_shemagh_gogg_od",
	"rhsusf_shemagh2_gogg_od",
	"rhsusf_shemagh_gogg_tan",
	"rhsusf_shemagh2_gogg_tan",
	"rhsusf_oakley_goggles_blk",
	"rhsusf_oakley_goggles_clr",
	"rhsusf_oakley_goggles_ylw"
];
RA_TierStuff = [
	""
];
RA_Baseballcaps = [// is in Determine Role
	"H_Cap_tan_specops_US"
];
RA_Boonies = [// is in Determine Role
	"rhs_Booniehat_ocp"
];
RA_TeamLeaderVests = [
	// VESTS
	"rhsusf_spcs_ocp_squadleader",
	"rhsusf_spcs_ocp_teamleader_alt",
	"rhsusf_spcs_ocp_teamleader"
	
];
RA_BasicInfVests = [
	// VESTS
	"rhsusf_spcs_ocp_rifleman_alt",
	"rhsusf_spcs_ocp_rifleman",
	"rhsusf_iotv_ocp",
	"rhsusf_iotv_ocp_Rifleman",
	"rhsusf_spcs_ocp"
	
];
RA_LongRangeBackpacks = [
	// BACKPACKS
	"tfw_ilbe_whip_mc",
	"tfw_ilbe_DD_mc",
	"tfw_ilbe_blade_mc"

];
RA_InfBackpacks = [
	// BACKPACKS
	"rhsusf_assault_eagleaiii_ocp",
	"rhsusf_falconii_mc",
	"B_AssaultPack_cbr",
	"UK3CB_GAF_B_B_ASS_MULTICAM_01",
	"rhsusf_assault_eagleaiii_coy",
	"rhsusf_falconii_coy",
	"B_Kitbag_cbr"

];

RA_InfHelmets = [
	// HEADGEAR add this to dertime role so everone gets helmets you want
	"rhsusf_ach_helmet_ocp",
	"rhsusf_ach_helmet_ESS_ocp",
	"rhsusf_ach_helmet_ESS_ocp_alt",
	"rhsusf_ach_helmet_ocp_alt",
	"rhsusf_ach_helmet_headset_ocp",
	"rhsusf_ach_helmet_headset_ocp_alt",
	"rhsusf_ach_helmet_headset_ess_ocp",
	"rhsusf_ach_helmet_headset_ess_ocp_alt",
	"rhsusf_ach_helmet_camo_ocp",
	"rhsusf_ach_helmet_ocp_norotos",
	"rhsusf_opscore_mc_cover_pelt_cam",
	"rhsusf_opscore_mc_cover_pelt_nsw"

];
RA_InfGear = [
	// UNIFORMS
	"rhs_uniform_cu_ocp_1stcav",
	"rhs_uniform_cu_ocp",
	"rhs_uniform_acu_ocp"

] + RA_InfHelmets;

RA_InfWeapsAttachments = [
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
	"rhsusf_acc_harris_bipod"

];

RA_InfWeapsSites = [
	"rhsusf_acc_acog",
	"rhsusf_acc_acog2",
	"rhsusf_acc_acog3",
	"rhsusf_acc_acog_rmr",
	"rhsusf_acc_acog_d",
	"rhsusf_acc_compm4",
	"rhsusf_acc_eotech_552",
	"rhsusf_acc_eotech_552_d",
	"rhsusf_acc_ACOG",
	"rhsusf_acc_ACOG2",
	"rhsusf_acc_compm4"
];

RA_InfWeapsAmmo = [
    // AMMO
	"rhs_mag_30Rnd_556x45_M855A1_PMAG",
	"rhs_mag_30Rnd_556x45_M855A1_PMAG_Tracer_Red"

];

RA_InfWeaps = [
	//WEAPONS
	"rhs_weap_m4_carryhandle",
	"rhs_weap_m4_carryhandle",
	"rhs_weap_m4_mstock",
	"rhs_weap_m4a1_carryhandle_mstock",
	"rhs_weap_m4a1",
	"rhs_weap_m4a1_d",
	"rhs_weap_m4a1_d_mstock",
	"rhs_weap_m4a1_mstock",
	"rhs_weap_m4",
	"rhs_weap_m4a1_carryhandle",
	"rhs_weap_m16a4",
	"rhs_weap_m16a4_imod",
	"rhs_weap_m16a4_carryhandle"

] + RA_InfWeapsAmmo;
// --------------------------------- Goblin ---------------------------------
RA_Goblin = [
	// uniforms
	// Vests
	"V_EOD_olive_F",
	// HEADGEAR
	"rhsusf_ach_bare_headset",
	"rhsusf_ach_bare_headset_ess",
	"rhsusf_ach_bare_tan_headset",
	"rhsusf_ach_bare_tan_headset_ess",
	// EYEWEAR
	// AMMO
	"rhs_mag_30Rnd_556x45_M855A1_PMAG",
	"rhs_mag_30Rnd_556x45_M855A1_PMAG_Tracer_Red",
	// WEAPON ATTACHMENTS 
	"rhsusf_acc_anpeq15_bk",
	"rhsusf_acc_anpeq15_bk_light",
	"rhsusf_acc_anpeq15_bk_top",
	"rhsusf_acc_anpeq15side_bk",
	"rhsusf_acc_wmx_bk",
	// EOD
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
];

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
	"rhs_mag_30Rnd_556x45_M855A1_PMAG",
	"rhs_mag_30Rnd_556x45_M855A1_PMAG_Tracer_Red"
];
RA_GrenadierWeapons = [
	// WEAPONS
	"rhs_weap_m16a4_carryhandle_M203",
	"rhs_weap_m16a4_imod_M203",
	"rhs_weap_m4_carryhandle_m203",
	"rhs_weap_m4a1_carryhandle_m203",
	// 40mm Launcher
	"rhs_weap_M320"

	// Attachments are shared with RA_InfWeaps via RA_InfWeapsAttachments
] + RA_GrenadierAmmo;
RA_Grenadier = [
	// VESTS
	"rhsusf_spcs_ocp_grenadier",
	"rhsusf_iotv_ocp_Grenadier"
		
] + RA_InfBackpacks + RA_GrenadierWeapons + RA_GrenadierAmmo;

// ---------------------------------- COMPANY HQ ----------------------------------
RA_CO = [
	// UNIFORM
	"rhs_uniform_g3_mc",
	// VESTS
	"rhsusf_spcs_ocp_squadleader",
	"rhsusf_spcs_ocp_teamleader_alt",
	"rhsusf_spcs_ocp_teamleader",
	"rhsusf_iotv_ocp",
	"rhsusf_spcs_ocp",
	// HATS
	// MISC
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

];

RA_XO = [
	// UNIFORM
	"rhs_uniform_g3_mc",
	// VESTS
	"rhsusf_spcs_ocp_squadleader",
	"rhsusf_spcs_ocp_teamleader_alt",
	"rhsusf_spcs_ocp_teamleader",
	"rhsusf_iotv_ocp",
	"rhsusf_spcs_ocp",
	// ranger
	"Worm_IZLIDB",
	// MISC
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

];

RA_Shadow = [
	// HATS
	// ACCESSORIES
	"B_UavTerminal"

] + RA_TeamLeaderVests;

RA_JFO = [
	// UNIFORM
	"rhs_uniform_g3_mc",
	// HEADGEAR, in determin role
	// VESTS
	"rhsusf_spcs_ocp_squadleader",
	"rhsusf_spcs_ocp_teamleader_alt",
	"rhsusf_spcs_ocp_teamleader",
	"rhsusf_iotv_ocp",
	"rhsusf_spcs_ocp",
	// NVGS
	"rhsusf_ANPVS_15",
	// BACKPACKS
	// ranger
	"Worm_IZLIDB",
    // GRENADES
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
	// WEAPONS
	"rhsusf_weap_m9",
	// AMMO
	"rhsusf_mag_15Rnd_9x19_FMJ",
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
	"kat_AED",
	"kat_lidocaine",
	"kat_phenylephrine",
	"kat_TXA",
	"kat_IO_FAST",
	// SIGHTS
	"rhsusf_acc_compm4",
	
	// ATTACHMENTS
	"rhsusf_acc_grip1",
	"rhsusf_acc_grip2",
	"rhsusf_acc_grip3",
	"rhsusf_acc_grip4",
	"rhsusf_acc_kac_grip",
	"rhsusf_acc_rvg_blk",
	"rhsusf_acc_rvg_de",
	"rhsusf_acc_wmx_bk",
	"rhsusf_acc_wmx",
	// RAILS
	"rhsusf_acc_anpeq15_bk_light",
	"rhsusf_acc_anpeq15_bk_top",
	"rhsusf_acc_anpeq15_bk",
	"rhsusf_acc_anpeq15side_bk",
	// UNIFORMS
	"rhs_uniform_cu_ocp_1stcav",
	"rhs_uniform_cu_ocp",
	"rhs_uniform_acu_ocp",
	// HEADGEAR in determin role
	// MEDIC BACKPACK
	"UK3CB_KRG_B_B_FieldPack_SF_MED",
	"UK3CB_ION_B_B_RIF_MED_BRN",
	// VESTS
	"rhsusf_spcs_ocp_medic",
	"rhsusf_spcs_ocp_rifleman_alt",
	"rhsusf_iotv_ocp_Medic",
	//MISC
	"ACE_Vector",
	"ItemcTab",
	"ItemAndroid"

];

RA_BansheeTL = [
	// UNIFORM
	"rhs_uniform_g3_mc",
	// MEDS
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

];

RA_BansheePilot = [
	// BACKPACK
	"UK3CB_CHC_C_B_MED",
	// MISC
	"ToolKit",
	"ItemcTab"

];

// ---------------------------------- PLATOON HQ ----------------------------------
RA_PL = [
	// UNIFORM
	"rhs_uniform_g3_mc",
	// VESTS
	"rhsusf_spcs_ocp_squadleader",
	"rhsusf_spcs_ocp_teamleader_alt",
	"rhsusf_spcs_ocp_teamleader",
	// MISC
	"Karma_MosesPoleItem",
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

];

RA_PSgt = [
	// UNIFORM
	"rhs_uniform_g3_mc",
	// VESTS
	"rhsusf_spcs_ocp_squadleader",
	"rhsusf_spcs_ocp_teamleader_alt",
	"rhsusf_spcs_ocp_teamleader",
	"rhsusf_iotv_ocp",
	"rhsusf_spcs_ocp",
	// MISC
	"Karma_MosesPoleItem",
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

];

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
	"ACE_adenosine"

];
RA_PLMedMedications = [
	// MISC
	"kat_AED",
	"kat_X_AED",
	"kat_lidocaine",
	"kat_phenylephrine",
	"kat_TXA",
	"kat_IO_FAST"

] + RA_MedicMeds;

RA_PLMed = [
	// UNIFORM
	"rhs_uniform_g3_mc",
	// VESTS
	"rhsusf_spcs_ocp_medic",
	"rhsusf_spcs_ocp_rifleman_alt",
	"rhsusf_iotv_ocp_Medic",
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

] + RA_PLMedMedications + RA_InfHelmets + RA_ShemaghMasks;

PMed = [
	// UNIFORM
	"rhs_uniform_g3_mc",
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
	// MISC
	"Karma_MosesPoleItem",
	"kat_AED",
	"kat_X_AED",
	"kat_lidocaine",
	"kat_phenylephrine",
	"kat_TXA",
	"kat_IO_FAST",
	// VESTS
	"rhsusf_spcs_ocp_medic",
	"rhsusf_spcs_ocp_rifleman_alt",
	"rhsusf_iotv_ocp_Medic",
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

] + RA_PLMedMedications + RA_InfHelmets + RA_ShemaghMasks;

// ---------------------------------- INFANTRY ----------------------------------
RA_SL = [
	// UNIFORM
	"rhs_uniform_g3_mc",
	// VESTS
	"rhsusf_spcs_ocp_squadleader",
	"rhsusf_spcs_ocp_teamleader_alt",
	"rhsusf_spcs_ocp_teamleader",
	"rhsusf_iotv_ocp",
	"rhsusf_spcs_ocp",
	// AMMO
	"ACE_40mm_Flare_white",
	"ACE_40mm_Flare_green",
	"ACE_40mm_Flare_red",
	"ACE_40mm_Flare_ir",
	"ACE_HuntIR_M203",
	// MISC
	"Karma_MosesPoleItem",
	"ACE_HuntIR_monitor",
	"Binocular",
	"rhsusf_bino_m24",
	"rhsusf_bino_m24_ARD",
	"ACE_MX2A",
	"ACE_Vector",
	"rhsusf_bino_lerca_1200_black",
	"ItemcTab"

];
// SL can also pull ammo for their Autorifleman/Machinegunner, see bottom of this script

RA_TL = [
	// BACKPACK
	"rhs_uniform_g3_mc",
	// VEST
	"rhsusf_spcs_ocp_squadleader",
	"rhsusf_spcs_ocp_teamleader_alt",
	"rhsusf_spcs_ocp_teamleader",
	"rhsusf_iotv_ocp",
	"rhsusf_spcs_ocp",
	// MISC
	"Karma_MosesPoleItem",
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
	"ItemcTab",
	// MEDIC BACKPACK
	"UK3CB_KRG_B_B_FieldPack_SF_MED",
	"UK3CB_ION_B_B_RIF_MED_BRN",
	// VESTS
	"rhsusf_spcs_ocp_medic",
	"rhsusf_spcs_ocp_rifleman_alt",
	"rhsusf_iotv_ocp_Medic"

] + RA_MedicMeds + RA_InfBackpacks;

RA_ARiflemanAmmo = [
	// AMMO
    "rhsusf_200Rnd_556x45_soft_pouch",
	"rhsusf_200Rnd_556x45_mixed_soft_pouch",
	"rhsusf_200Rnd_556x45_box",
	"rhsusf_200rnd_556x45_mixed_box",
	"rhsusf_100Rnd_556x45_soft_pouch",
	"rhsusf_100Rnd_556x45_mixed_soft_pouch",
    "rhs_mag_30Rnd_556x45_M855A1_PMAG",
	"rhs_mag_30Rnd_556x45_M855A1_PMAG_Tracer_Red",
	// MISC
	"ACE_SpareBarrel"

];

RA_ARifleman = [
	// Uniform
	"rhs_uniform_cu_ocp_1stcav",
	"rhs_uniform_cu_ocp",
	"rhs_uniform_acu_ocp",
	// BACKPACKS
	"B_Carryall_cbr",
	// VESTS
	"rhsusf_spcs_ocp_machinegunner",
	"rhsusf_spcs_ocp_rifleman_alt",
	"rhsusf_spcs_ocp_saw",
	// GUNS
	"rhs_weap_m249_pip_S",
	"rhs_weap_m249_pip_L",
	"rhs_weap_m249_pip_ris",
	"rhs_weap_m249_pip",
	// GRIPS AND BIPODS
	"rhsusf_acc_grip4",
	"rhsusf_acc_grip1",
	"rhsusf_acc_kac_grip",
	"rhsusf_acc_grip4_bipod",
	"rhsusf_acc_saw_bipod",
	// ATTACHMENTS
	"rhsusf_acc_SF3P556",
	"rhsusf_acc_SFMB556",
	"rhs_acc_2dpZenit_ris",
	"rhs_acc_perst3",
	"rhsusf_acc_wmx_bk",
	"rhsusf_acc_anpeq15side_bk",
	"ACE_acc_pointer_green",
	// SCOPES
	"rhsusf_acc_su230",
	"rhsusf_acc_su230_c",
	"rhsusf_acc_su230_mrds",
	"rhsusf_acc_su230_mrds_c",
	"rhsusf_acc_acog",
	"rhsusf_acc_acog2",
	"rhsusf_acc_acog3",
	"rhsusf_acc_acog_rmr",
	"rhsusf_acc_acog_d",
	"rhsusf_acc_compm4",
	"rhsusf_acc_eotech_55"

] + RA_InfBackpacks + RA_ARiflemanAmmo;

RA_RiflemanAmmo = [
	// AMMO
	//"rhs_mag_20Rnd_SCAR_762x51_m80a1_epr_bk",
	//"rhs_mag_20Rnd_SCAR_762x51_m80a1_epr",
	//"rhs_mag_fold_stock",
	//"rhs_mag_20Rnd_SCAR_762x51_m61_ap",
	//"rhs_mag_20Rnd_SCAR_762x51_m61_ap_bk"
	//"rhsusf_5Rnd_00Buck",
	//"rhsusf_5Rnd_Slug",
	//"rhsusf_8Rnd_00Buck",
	//"rhsusf_8Rnd_Slug"// Will also get ammo from RA_InfWeaps

];

RA_Rifleman = [
	// Scar Standerd
	//"rhs_weap_SCARH_STD",
	//"rhs_weap_SCARH_FDE_STD",
	// Scar Short
	//"rhs_weap_SCARH_FDE_CQC",
	//"rhs_weap_SCARH_CQC",
	// GRIPS AND ATTACHMENTS
	//"rhs_acc_grip_ffg2",
	// VESTS
	"rhsusf_spcs_ocp_rifleman_alt",
	"rhsusf_spcs_ocp_rifleman",
	"rhsusf_iotv_ocp",
	"rhsusf_iotv_ocp_Rifleman",
	"rhsusf_spcs_ocp",
	// BACKPACKS
	// Sites
	"rhsusf_acc_acog",
	"rhsusf_acc_acog2",
	"rhsusf_acc_acog3",
	"rhsusf_acc_acog_rmr",
	"rhsusf_acc_acog_d",
	"rhsusf_acc_compm4",
	"rhsusf_acc_eotech_552",
	"rhsusf_acc_eotech_552_d",
	"rhsgref_hidf_alicepack"

] + RA_InfBackpacks + RA_BasicInfVests + RA_RiflemanAmmo;

RA_ESpecialistAmmo = [
	// AMMO
	//"rhsusf_5Rnd_00Buck",
	//"rhsusf_5Rnd_Slug",
	//"rhsusf_8Rnd_00Buck",
	//"rhsusf_8Rnd_Slug"// Will also get ammo from RA_InfWeaps

];

RA_ESpecialist = [
	// WEAPONS
    //"rhs_weap_M590_5RD",
    //"rhs_weap_M590_8RD",
	// MISC
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
	//
	"Tier1_100Rnd_762x51_Belt_M61_AP",
	"Tier1_100Rnd_762x51_Belt_M80",
	"Tier1_100Rnd_762x51_Belt_M62_Tracer",
	// MISC
	"ACE_SpareBarrel"

];
RA_MGunner = [
	// VESTS
	"rhsusf_spcs_ocp_machinegunner",
	"rhsusf_spcs_ocp_rifleman_alt",
	"rhsusf_spcs_ocp_saw",
	// WEAPONS
    "rhs_weap_m240B",
	// SCOPES
	"rhsusf_acc_ACOG_MDO",
	"rhsusf_acc_su230a",
	"rhsusf_acc_su230a_c",
	"rhsusf_acc_su230a_mrds",
	"rhsusf_acc_su230a_mrds_c",
	"rhsusf_acc_elcan",
	"rhsusf_acc_elcan_ard",
	"rhsusf_acc_compm4",
	"rhsusf_acc_eotech_552",
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

] + RA_InfBackpacks + RA_MGunnerAmmo;

RA_ATSpec = [
	// VESTS
	"rhsusf_spcs_ocp_rifleman_alt",
	"rhsusf_spcs_ocp_rifleman",
	"rhsusf_iotv_ocp",
	"rhsusf_iotv_ocp_Rifleman",
	"rhsusf_spcs_ocp",
	// BACKPACKS
	"rhsgref_hidf_alicepack",
	"B_Carryall_cbr",
	"UK3CB_LSM_B_B_CARRYALL_KHK"

] + RA_InfBackpacks + RA_BasicInfVests;

RA_ATAmmoBearer = [
	// BACKPACKS
	// MISC
] + RA_InfBackpacks + RA_BasicInfVests + RA_MGunnerAmmo + RA_GrenadierAmmo; // Ammo bearer can pull all ammo used in their squad

RA_MGAmmoBearer = [
	// BACKPACKS
	"rhsgref_hidf_alicepack",
	// VESTS
	// MISC
	"ACE_SpareBarrel"

] + RA_InfBackpacks + RA_BasicInfVests + RA_MGunnerAmmo; // Assistant Machine Gunner is focussed on supporting their MGs

// ---------------------------------- PHANTOM ---------------------------------------
RA_Phantom = [
	// Sniper 2010
	"rhs_weap_XM2010",
	"rhs_weap_XM2010_wd",
	"rhs_weap_XM2010_d",
	// 2010 SUPRESSER
	"rhsusf_acc_m2010s",
	"rhsusf_acc_m2010s_sa",
	"rhsusf_acc_m2010s_wd",
	"rhsusf_acc_m2010s_d",
	// M107
	"rhs_weap_M107",
	// Ammo 2010
	"rhsusf_5Rnd_300winmag_xm2010",
	// SCOPES
	"rhsusf_acc_nxs_5522x56_md_sun",
	"optic_lrps",
	"rhsusf_acc_premier_low",
	"rhsusf_acc_M8541",
	"rhsusf_acc_M8541_low",
	"rhsusf_acc_premier_anpvs27",
	"rhsusf_acc_premier",
	"tier1_elcan_156_c2_ard_docter_black",
	"tier1_elcan_156_c2_ard_docter_fde",
	"tier1_elcan_156_c2_ard_docter_fde_2d",
	"tier1_elcan_156_c2_ard_docter_black_2d",
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
	"tier1_elcan_156_c2_ard_docter_black",
	"tier1_elcan_156_c2_ard_docter_fde",
	"tier1_elcan_156_c2_ard_docter_fde_2d",
	"tier1_elcan_156_c2_ard_docter_black_2d",
	// Scar LONG BARREL
	"rhs_weap_SCARH_FDE_LB",
	"rhs_weap_SCARH_LB",
	"rhs_mag_20Rnd_SCAR_762x51_m61_ap_bk",
	"rhs_mag_20Rnd_SCAR_762x51_m80a1_epr_bk",
	"rhs_mag_20Rnd_SCAR_762x51_m80a1_epr",
	"rhs_mag_fold_stock",
	"rhs_mag_20Rnd_SCAR_762x51_m61_ap",
	"rhsusf_acc_aac_scarh_silencer",
	"rhsusf_acc_aac_762sd_silencer",
	"rhsusf_acc_aac_762sdn6_silencer",
	"muzzle_snds_B",
	"muzzle_snds_B_snd_F",
	"muzzle_snds_B_arid_F",
	"muzzle_snds_B_lush_F",
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
	// HEADGEAR
	// UNIFORM
	"rhs_uniform_g3_mc",
	// Ghillie suits
	"U_B_T_FullGhillie_tna_F",
	"U_B_FullGhillie_lsh",
	"U_B_FullGhillie_ard",
	// VEST
	"rhsusf_spcs_ocp_sniper",
	"rhsusf_spcs_ocp_squadleader",
	"rhsusf_spcs_ocp_teamleader_alt",
	"rhsusf_spcs_ocp_teamleader",
	// MISC
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

];

RA_PhantomSpotter = [
	// UNIFORM
	"rhs_uniform_g3_mc",
	// Ghillie suits
	"U_B_T_FullGhillie_tna_F",
	"U_B_FullGhillie_lsh",
	"U_B_FullGhillie_ard",
	// SUPRESSER
	"rhsusf_acc_nt4_black",
	"rhsusf_acc_aac_scarh_silencer",
	// Ammo
	"rhsusf_5Rnd_300winmag_xm2010",
	// Scopes for sniper
	"tier1_elcan_156_c2_ard_docter_black",
	"tier1_elcan_156_c2_ard_docter_fde",
	"tier1_elcan_156_c2_ard_docter_fde_2d",
	"tier1_elcan_156_c2_ard_docter_black_2d",
	// Scar LONG BARREL
	"rhs_weap_SCARH_FDE_LB",
	"rhs_weap_SCARH_LB",
	"rhs_mag_20Rnd_SCAR_762x51_m61_ap_bk",
	"rhs_mag_20Rnd_SCAR_762x51_m80a1_epr_bk",
	"rhs_mag_20Rnd_SCAR_762x51_m80a1_epr",
	"rhs_mag_fold_stock",
	"rhs_mag_20Rnd_SCAR_762x51_m61_ap",
	"rhsusf_acc_aac_scarh_silencer",
	"rhsusf_acc_aac_762sd_silencer",
	"rhsusf_acc_aac_762sdn6_silencer",
	"muzzle_snds_B",
	"muzzle_snds_B_snd_F",
	"muzzle_snds_B_arid_F",
	"muzzle_snds_B_lush_F",
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
	// VEST
	"rhsusf_spcs_ocp_sniper",
	"rhsusf_spcs_ocp_squadleader",
	"rhsusf_spcs_ocp_teamleader_alt",
	"rhsusf_spcs_ocp_teamleader",
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

];

// ---------------------------------- OGRE ----------------------------------

RA_OgreEngiBaseAmmo = [
	// AMMO
	//"rhsusf_5Rnd_00Buck",
	//"rhsusf_5Rnd_Slug",
	//"rhsusf_8Rnd_00Buck",
	//"rhsusf_8Rnd_Slug",
    "rhs_mag_30Rnd_556x45_M855A1_PMAG",
    "rhs_mag_30Rnd_556x45_M855A1_PMAG_Tracer_Red",
	// MISC
	"bunwell_axe",
	"ACE_SpareBarrel",
	"Laserbatteries" // To be able to resupply other role's laser designators and to enable crossloading

];
RA_OgreEngiBaseGear = [
	// WEAPONS
    //"rhs_weap_M590_5RD",
    //"rhs_weap_M590_8RD",
	// WEAPON ATTACHMENTS 
	// VEST
	"rhsusf_iotv_ocp",
	"rhsusf_iotv_ocp_Repair",
	"rhsusf_iotv_ocp_Rifleman",
	"rhsusf_spcs_ocp",
	// HATS
	// HEADGEAR
	"G_Spectacles_Tinted",
	// MISC
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
	// UNIFORM
	"rhs_uniform_g3_mc",
	// VESTS
	"rhsusf_spcs_ocp_squadleader",
	"rhsusf_spcs_ocp_teamleader_alt",
	"rhsusf_spcs_ocp_teamleader",
	"rhsusf_iotv_ocp_Repair",
	// GEAR
	"Binocular",
	"rhsusf_bino_m24",
	"rhsusf_bino_m24_ARD"

] + RA_OgreEngiBaseGear + RA_OgreEngiBaseAmmo; // Ogre can pull all other mags as well, added at the end of file

RA_OgreMedicAmmo = [
	// AMMO
	//"rhsusf_5Rnd_00Buck",
	//"rhsusf_5Rnd_Slug",
	//"rhsusf_8Rnd_00Buck",
	//"rhsusf_8Rnd_Slug",
	"rhs_mag_30Rnd_556x45_M855A1_PMAG",
	"rhs_mag_30Rnd_556x45_M855A1_PMAG_Tracer_Red",
	// MISC
	"Laserbatteries" // To be able to resupply other role's laser designators and to enable crossloading

];
RA_OgreMedic = [
	// VESTS
	"rhsusf_spcs_ocp_medic",
	"rhsusf_iotv_ocp_Medic",
	"rhsusf_iotv_ocp_Repair",
	// WEAPONS
    //"rhs_weap_M590_5RD",
    //"rhs_weap_M590_8RD",
	// WEAPON ATTACHMENTS 
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
	// GEAR
	"UK3CB_LFR_B_B_Tacticalpack_Eng_Tan",
	"Binocular",
	"rhsusf_bino_m24",
	"rhsusf_bino_m24_ARD"

] + RA_InfBackpacks + RA_OgreEngiBaseGear + RA_OgreEngiBaseAmmo; // Ogre can pull all other mags as well, added at the end of file

// ---------------------------------- BUTCHER ----------------------------------
RA_ButcherCommanderAmmo = [
	// AMMO
	//"rhsusf_5Rnd_00Buck",
	//"rhsusf_5Rnd_Slug",
	"rhs_mag_30Rnd_556x45_M855A1_PMAG",
	"rhs_mag_30Rnd_556x45_M855A1_PMAG_Tracer_Red",
	"rhs_weap_m4",
	"rhs_weap_m4a1_carryhandle"

];
RA_ButcherCommander = [
	// UNIFORM
	"rhs_uniform_cu_ocp_1stcav",
	"rhs_uniform_g3_mc",
	// HEADGEAR
	"rhsusf_cvc_alt_helmet",
	"rhsusf_cvc_ess",
	"rhsusf_cvc_green_alt_helmet",
	"rhsusf_cvc_green_ess",
	"rhsusf_cvc_green_helmet",
	"rhsusf_cvc_helmet",
	// WEAPONS
	"rhs_weap_m4a1_carryhandle",
	"rhs_weap_m4",
	// VESTS
	"rhsusf_spcs_ocp_crewman",
	"rhsusf_spcs_ocp_teamleader_alt",
	"rhsusf_spcs_ocp_teamleader",
	// MISC
	"ItemcTab",
	"ToolKit",
	"Binocular",
	"rhsusf_bino_m24",
	"rhsusf_bino_m24_ARD",
	"ACE_MX2A",
	"ACE_Vector",
	"rhsusf_bino_lerca_1200_black"

] + RA_ButcherCommanderAmmo;

RA_ButcherCrewAmmo = [
	// AMMO
	//"rhsusf_5Rnd_00Buck",
	//"rhsusf_5Rnd_Slug",
	"rhs_mag_30Rnd_556x45_M855A1_PMAG",
	"rhs_mag_30Rnd_556x45_M855A1_PMAG_Tracer_Red"

];
RA_ButcherDriver = [
	// UNIFORM
	"rhs_uniform_cu_ocp_1stcav",
	// HEADGEAR
	"rhsusf_cvc_alt_helmet",
	"rhsusf_cvc_ess",
	"rhsusf_cvc_green_alt_helmet",
	"rhsusf_cvc_green_ess",
	"rhsusf_cvc_green_helmet",
	"rhsusf_cvc_helmet",
	// VESTS
	"rhsusf_spcs_ocp_crewman",
	// BACKPACKS
	"rhsusf_assault_eagleaiii_coy",
	"rhsusf_falconii_coy",
	"B_Kitbag_cbr",
	// WEAPONS
	"rhs_weap_m4a1_carryhandle",
	"rhs_weap_m4",
    //"rhs_weap_M590_5RD",
	// MISC
	"ItemcTab",
	"ToolKit"

] + RA_ButcherCrewAmmo;

RA_ButcherGunner = [
	// UNIFORM
	"rhs_uniform_cu_ocp_1stcav",
	// HEADGEAR
	"rhsusf_cvc_alt_helmet",
	"rhsusf_cvc_ess",
	"rhsusf_cvc_green_alt_helmet",
	"rhsusf_cvc_green_ess",
	"rhsusf_cvc_green_helmet",
	"rhsusf_cvc_helmet",
	// VESTS
	"rhsusf_spcs_ocp_crewman",
	"rhsusf_spcs_ocp_teamleader_alt",
	"rhsusf_spcs_ocp_teamleader",
	// BACKPACKS
	"rhsusf_assault_eagleaiii_coy",
	"rhsusf_falconii_coy",
	"B_Kitbag_cbr",
	// WEAPONS
	"rhs_weap_m4a1_carryhandle",
	"rhs_weap_m4",
    //"rhs_weap_M590_5RD",
	// MISC
	"ItemcTab",
	"ToolKit"

] + RA_ButcherCrewAmmo;
// ---------------------------------- SHADE ----------------------------------
RA_ShadeAmmo = [
    // AMMO GET SAME GEAR NOW IN DETERMINEROLE
	// WEAPON ATTACHMENTS
	"ACE_Kestrel4500",
	"rhsusf_acc_anpeq15_bk",
	"rhsusf_acc_anpeq15_bk_light",
	"rhsusf_acc_anpeq15_bk_top",
	"rhsusf_acc_anpeq15side_bk",
	"rhsusf_acc_wmx_bk"
	// HATS
	// HEADGEAR
	
];
RA_ShadeTL = [
	// VESTS
	"rhsusf_spcs_ocp_squadleader",
	"rhsusf_spcs_ocp_teamleader_alt",
	"rhsusf_spcs_ocp_teamleader",
	"rhsusf_iotv_ocp",
	"rhsusf_spcs_ocp",
	// UNIFORM
	"rhs_uniform_g3_mc",
	// MISC
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
	// VESTS
	"rhsusf_spcs_ocp_rifleman",
	"rhsusf_iotv_ocp",
	"rhsusf_iotv_ocp_Rifleman",
	"rhsusf_spcs_ocp",
    // BACKPACKS
	"UK3CB_LSM_B_B_CARRYALL_KHK",
	// MISC
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
    // AMMO GET SAME GEAR NOW IN DETERMINEROLE
	// WEAPON ATTACHMENTS
	"ACE_Kestrel4500",
	"rhsusf_acc_anpeq15_bk",
	"rhsusf_acc_anpeq15_bk_light",
	"rhsusf_acc_anpeq15_bk_top",
	"rhsusf_acc_anpeq15side_bk",
	"rhsusf_acc_wmx_bk"
	// HATS
	// HEADGEAR
	
];
RA_SavageTL = [
	// VESTS
	"rhsusf_spcs_ocp_squadleader",
	"rhsusf_spcs_ocp_teamleader_alt",
	"rhsusf_spcs_ocp_teamleader",
	"rhsusf_iotv_ocp",
	"rhsusf_spcs_ocp",
	// UNIFORM
	"rhs_uniform_g3_mc",
	// MISC
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
	// VESTS
	"rhsusf_spcs_ocp_rifleman",
	"rhsusf_iotv_ocp",
	"rhsusf_iotv_ocp_Rifleman",
	"rhsusf_spcs_ocp",
    // BACKPACKS
	"UK3CB_LSM_B_B_CARRYALL_KHK",
	// MISC
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
	// VESTS
	"UK3CB_V_Pilot_Vest"

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
	// WEAPONS
	"rhs_weap_m4a1_carryhandle",
	"rhs_weap_m4",
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
	"U_B_HeliPilotCoveralls",
	"USP_G3C_RS_KP_MX_MC",
	// MISC
	"ToolKit",
	"ItemcTab"

] + RA_PilotGear + RA_PilotHelmets + RA_PilotWeapons + RA_PilotAmmo;

// ---------------------------------- DEMON ----------------------------------
RA_Demon = [
	// NVGS
	"rhsusf_ANPVS_15",
	// UNIFORMS
	"U_B_HeliPilotCoveralls",
	// MISC
	"ToolKit",
	"ItemcTab"

] + RA_PilotGear + RA_PilotHelmets + RA_PilotWeapons + RA_PilotAmmo;

// ---------------------------------- REAPER ----------------------------------
RA_Reaper = [
	// HEADGEAR
	"H_PilotHelmetFighter_B",
	// UNIFORMS
	"UK3CB_CW_US_B_LATE_U_J_Pilot_Uniform_01_NATO",
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
