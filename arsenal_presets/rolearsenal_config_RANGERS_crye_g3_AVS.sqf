// HEY IF YOU NEED TO CHANGE FACTIONS, DO SO HERE:
// KC_Liberation_Master_Framework\arsenal_presets\rolearsenal.sqf

// This gear is selected from when someone respawns in onPlayerRespawn.sqf
RA_StartingHeadwear = [
	// hat
	"H_Cap_usblack"
];
RA_StartingGoggles = [
	// GOGGLES
	"rhs_googles_black"

];
RA_StartingUniforms = [
	// UNIFORMS
	"ARD_MC_Camo_Cyre"
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
	// GLOCK ACC
	"Tier1_SIG_Romeo1",
	"Tier1_MRDS",
	"Tier1_DBALPL"

];
RA_DefaultGear = [
	// WEAPONS
	"Tier1_Glock19_Urban",
	"Tier1_Glock19_WAR",
	// VEST
	"Crye_AVS_1_RG",
	"Crye_AVS_1_1_RG",
	"Crye_AVS_1_2_RG",
	"Crye_AVS_1_3_RG",
	"Crye_AVS_3_RG",
	"Crye_AVS_3_1_RG",
	"Crye_AVS_3_2_RG",
	"Crye_AVS_3_3_RG",
	"Crye_AVS_2_RG",
	//
	"Crye_AVS_1",
	"Crye_AVS_1_1",
	"Crye_AVS_1_2",
	"Crye_AVS_1_3",
	"Crye_AVS_3",
	"Crye_AVS_3_1",
	"Crye_AVS_3_2",
	"Crye_AVS_3_3",
	"Crye_AVS_2",
	// HEADGEAR
	"H_Cap_usblack",
	// UNIFORM
	"ARD_MC_Camo_Cyre",
	"ARD_MC_Camo_Cyre_SS",
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
	// British Stuff
	"V_PlateCarrierL_CTRG",
	"V_PlateCarrierH_CTRG",
	//carrie
	"V_PlateCarrier1_rgr",
	"V_PlateCarrier1_rgr_noflag_F",
	"UK3CB_V_PlateCarrier1_oli",
	"UK3CB_V_PlateCarrier2_oli",
	"V_PlateCarrier2_rgr_noflag_F",
	"V_PlateCarrier2_rgr",
	//
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
	"Crye_AVS_1",
	"Crye_AVS_1_1",
	"Crye_AVS_1_2",
	"Crye_AVS_1_3",
	"Crye_AVS_3",
	"Crye_AVS_3_1",
	"Crye_AVS_3_2",
	"Crye_AVS_3_3",
	"Crye_AVS_2"
	
];
RA_BasicInfVests = [
	// VESTS
	"Crye_AVS_1",
	"Crye_AVS_1_1",
	"Crye_AVS_1_2",
	"Crye_AVS_1_3",
	"Crye_AVS_3",
	"Crye_AVS_3_1",
	"Crye_AVS_3_2",
	"Crye_AVS_3_3",
	"Crye_AVS_2"
	
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
	"B_AssaultPack_cbr",
	"rhsusf_assault_eagleaiii_coy",
	"rhsusf_falconii_coy",
	"B_Kitbag_cbr",
	// backbacks
	"rhsusf_assault_eagleaiii_ocp",
	"UK3CB_CW_US_B_LATE_B_RIF_04",
	"UK3CB_ION_B_B_RIF_OLI_01",
	"UK3CB_ION_B_B_RIF_DES_01",
	"UK3CB_ION_B_B_RIF_BRN_01",
	"B_Kitbag_tan",
	"UK3CB_CW_US_B_LATE_B_RIF_04",
	"rhsusf_falconii",
	"UK3CB_LSM_B_B_CARRYALL_OLI",
	"B_Carryall_green_F",
	"B_Carryall_cbr",
	"UK3CB_ION_B_B_ASS_DES_01",
	"UK3CB_ION_B_B_ASS_OLI_01",
	"UK3CB_LDF_B_B_ASS_OLI",
	"UK3CB_ION_B_B_ASS_BRN_01",
	"B_AssaultPack_khk",
	"UK3CB_ADA_B_B_ASS",
	"UK3CB_ANA_B_B_ASS"

];

RA_InfHelmets = [
	// HEADGEAR add this to dertime role so everone gets helmets you want
	// Headgear
	//
	// Helmets
	"TFV_headgear_opscore_cover_mc_peltor_camera",
	"TFV_headgear_opscore_cover_mc_peltor_nsw",
	"TFV_headgear_opscore_cover_mc_peltor"

];
RA_InfGear = [
	// UNIFORMS
	"ARD_MC_Camo_Cyre",
	"ARD_MC_Camo_Cyre_SS"

] + RA_InfHelmets;

RA_InfWeapsAttachments = [
	// SILENCER
	"rhsusf_acc_SFMB556",
	"rhsusf_acc_nt4_black",
	"rhsusf_acc_nt4_tan",
	"Tier1_SOCOM556_2_Mini_DE",
	"Tier1_SOCOM556_2_Mini_Black",
	// GRIPS
	"rhsusf_acc_SF3P556",
	"Tier1_KAC_762_DSR",
	"Tier1_KAC_556_QDC_CQB_Tan",
	"Tier1_KAC_556_QDC_CQB_Black",
	// LASERS AND light
	"rhsusf_acc_wmx",
	"rhsusf_acc_wmx_bk",
	"rhsusf_acc_M952V",
	"rhsusf_acc_anpeq15",
	"rhsusf_acc_anpeq15_bk",
	"rhsusf_acc_anpeq15_bk_top",
	"rhsusf_acc_anpeq15side_bk",
	"rhsusf_acc_anpeq15_wmx",
	"rhsusf_acc_anpeq16a",
	"rhsusf_acc_anpeq16a_top",
	//
	"ACE_acc_pointer_green",
	"rhsusf_acc_anpeq15_bk",
	"rhsusf_acc_anpeq15_bk_light",
	"rhsusf_acc_anpeq15_bk_top",
	"rhsusf_acc_anpeq15side_bk",
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
	//RIFLE + SAW/AR OPTICS
	
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
	"Tier1_Eotech551_Black",
	"Tier1_Eotech551_Desert",
	"Tier1_Eotech553_Black",
	"Tier1_Eotech553_Tan",
	"Tier1_EXPS3_0_Black",
	"Tier1_EXPS3_0_Desert",
	"Tier1_EXPS3_0_Tano",
	"Tier1_EXPS3_0_G33_Black_Up",
	"Tier1_EXPS3_0_G33_Desert_Up",
	"Tier1_EXPS3_0_G33_Tano_Up",
	"Tier1_MicroT1_Low_Black",
	"Tier1_MicroT1_Low_Desert",
	"Tier1_MicroT2_Black",
	"Tier1_MicroT2_Tan",
	"Tier1_MicroT2_G33_Black_Up",
	"Tier1_MicroT2_G33_Desert_Up",
	"Tier1_MicroT2_G33_Tan_Up",
	"Tier1_MicroT2_Low_Black",
	"Tier1_MicroT2_Low_Tan",
	"Tier1_ATACR18_ADM_Black",
	"Tier1_ATACR18_ADM_Desert",
	"Tier1_ATACR18_Geissele_Black",
	"Tier1_ATACR18_Geissele_Desert",
	"Tier1_Razor_Gen2_16",
	"Tier1_Razor_Gen2_16_ADM",
	"Tier1_Razor_Gen2_16_Geissele"
];

RA_InfWeapsAmmo = [
    // AMMO
	"rhs_mag_30Rnd_556x45_M855A1_PMAG",
	"rhs_mag_30Rnd_556x45_M855A1_PMAG_Tracer_Red"

];

RA_InfWeaps = [
	//WEAPONS
	"rhs_weap_mk18_urgi_kac",
	"rhs_weap_mk18_urgi",
	"rhs_weap_m4_urgi_kac",
	"rhs_weap_m4_urgi",
	//"rhs_weap_m4a1",
	//"rhs_weap_m4a1_d",
	//"rhs_weap_m4a1_d_mstock",
	//"rhs_weap_m4a1_mstock",
	// block and mk18
	"rhs_weap_m4a1_blockII_bk",
	"rhs_weap_m4a1_blockII_KAC_bk",
	"rhs_weap_m4a1_blockII_d",
	"rhs_weap_m4a1_blockII_KAC_d",
	"rhs_weap_m4a1_blockII_KAC",
	//
	"rhs_weap_mk18",
	"rhs_weap_mk18_bk",
	"rhs_weap_mk18_KAC_bk",
	"rhs_weap_mk18_d",
	"rhs_weap_mk18_KAC_d",
	"rhs_weap_mk18_KAC"

] + RA_InfWeapsAmmo;

RA_MGandSAWsites = [
	"Tier1_Elcan_156_C1_Black",
	"Tier1_Elcan_156_C1_FDE",
	"Tier1_Elcan_156_C1_FDE_2D",
	"Tier1_Elcan_156_C1_Black_2D",
	"Tier1_Elcan_156_C1_ARD_Black",
	"Tier1_Elcan_156_C1_ARD_FDE",
	"Tier1_Elcan_156_C1_ARD_FDE_2D",
	"Tier1_Elcan_156_C1_ARD_Black_2D",
	"Tier1_Elcan_156_C2_Black",
	"Tier1_Elcan_156_C2_FDE",
	"Tier1_Elcan_156_C2_FDE_2D",
	"Tier1_Elcan_156_C2_Black_2D",
	"Tier1_Elcan_156_C2_ARD_Black",
	"Tier1_Elcan_156_C2_ARD_FDE",
	"Tier1_Elcan_156_C2_ARD_FDE_2D",
	"Tier1_Elcan_156_C2_ARD_Black_2D"
];
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
	"MineDetector",
	// minedetecter
	"ACE_VMH3",
	"ACE_VMM3",
	// GEAR
	"ACE_Fortify",
	"bunwell_axe",
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
	"rhs_weap_m4a1_blockII_M203_bk",
	"rhs_weap_m4a1_blockII_M203_d",
	"rhs_weap_m4a1_blockII_M203",
	"rhs_weap_mk18_m320",
	// 40mm Launcher
	"rhs_weap_M320"

	// Attachments are shared with RA_InfWeaps via RA_InfWeapsAttachments
] + RA_GrenadierAmmo;
RA_Grenadier = [
	"ACE_HuntIR_monitor",
	// VESTS
	"Crye_AVS_1",
	"Crye_AVS_1_1",
	"Crye_AVS_1_2",
	"Crye_AVS_1_3",
	"Crye_AVS_3",
	"Crye_AVS_3_1",
	"Crye_AVS_3_2",
	"Crye_AVS_3_3",
	"Crye_AVS_2"
		
] + RA_InfBackpacks + RA_GrenadierWeapons + RA_GrenadierAmmo;

// ---------------------------------- COMPANY HQ ----------------------------------
RA_CO = [
	// UNIFORM
	"ARD_MC_Camo_Cyre_SS",
	//
	//"ARD_MC_OD_Camo_Cyre_SS",
	//"ARD_MC_OD_Camo_Cyre",
	// VESTS
	"Crye_AVS_1",
	"Crye_AVS_1_1",
	"Crye_AVS_1_2",
	"Crye_AVS_1_3",
	"Crye_AVS_3",
	"Crye_AVS_3_1",
	"Crye_AVS_3_2",
	"Crye_AVS_3_3",
	"Crye_AVS_2",
	//
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
	"ARD_MC_Camo_Cyre_SS",
	//
	//"ARD_MC_OD_Camo_Cyre_SS",
	//"ARD_MC_OD_Camo_Cyre",
	// VESTS
	"Crye_AVS_1",
	"Crye_AVS_1_1",
	"Crye_AVS_1_2",
	"Crye_AVS_1_3",
	"Crye_AVS_3",
	"Crye_AVS_3_1",
	"Crye_AVS_3_2",
	"Crye_AVS_3_3",
	"Crye_AVS_2",
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
	"ARD_MC_Camo_Cyre_SS",
	//
	//"ARD_MC_OD_Camo_Cyre_SS",
	//"ARD_MC_OD_Camo_Cyre",
	// HEADGEAR, in determin role
	// VESTS
	"Crye_AVS_1",
	"Crye_AVS_1_1",
	"Crye_AVS_1_2",
	"Crye_AVS_1_3",
	"Crye_AVS_3",
	"Crye_AVS_3_1",
	"Crye_AVS_3_2",
	"Crye_AVS_3_3",
	"Crye_AVS_2",
	//
	// NVGS
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
RA_MEDICBACKPACK = [
	// medic bags
	"UK3CB_B_TacticalPack_Med_Oli",
	"UK3CB_ION_B_B_RIF_MED_OLI",
	"UK3CB_ION_B_B_RIF_MED_OLI",
	"UK3CB_ION_B_B_RIF_MED_DES",
	"UK3CB_ION_B_B_RIF_MED_BRN",
	"UK3CB_ION_B_B_RIF_MED_BLK",
	"UK3CB_KRG_B_B_FieldPack_SF_MED",
	"UK3CB_CHC_C_B_MED"
];
RA_BansheeM = [
	// WEAPONS
	"Tier1_Glock19_Urban",
	"Tier1_Glock19_WAR",
	// AMMO
	"rhsusf_mag_17Rnd_9x19_JHP",
	"rhsusf_mag_17Rnd_9x19_FMJ",
	// GLOCK ACC
	"Tier1_SIG_Romeo1",
	"Tier1_MRDS",
	"Tier1_TLR1",
	"Tier1_DBALPL",
	"Tier1_DBALPL_FL",
	"acc_flashlight_pistol",
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
	"ARD_MC_Camo_Cyre",
	"ARD_MC_Camo_Cyre_SS",
	// HEADGEAR in determin role
	// MEDIC BACKPACK
	"UK3CB_KRG_B_B_FieldPack_SF_MED",
	"UK3CB_ION_B_B_RIF_MED_BRN",
	// VESTS
	"Crye_AVS_1",
	"Crye_AVS_1_1",
	"Crye_AVS_1_2",
	"Crye_AVS_1_3",
	"Crye_AVS_3",
	"Crye_AVS_3_1",
	"Crye_AVS_3_2",
	"Crye_AVS_3_3",
	"Crye_AVS_2",
	//MISC
	"ACE_Vector",
	"ItemcTab",
	"ItemAndroid"

];

RA_BansheeTL = [
	// UNIFORM
	"ARD_MC_Camo_Cyre_SS",
	//
	//"ARD_MC_OD_Camo_Cyre_SS",
	//"ARD_MC_OD_Camo_Cyre",
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
	"ARD_MC_Camo_Cyre_SS",
	//
	//"ARD_MC_OD_Camo_Cyre_SS",
	//"ARD_MC_OD_Camo_Cyre",
	// MK 17
	"rhs_weap_mk17_STD",
	"rhs_weap_mk17_CQC",
	"rhs_mag_fold_stock",
	//
	"rhs_mag_20Rnd_SCAR_762x51_m61_ap",
	"rhs_mag_20Rnd_SCAR_762x51_m62_tracer",
	"rhs_mag_20Rnd_SCAR_762x51_m80a1_epr",
	//
	"rhsusf_acc_su230a",
	"rhsusf_acc_su230a_c",
	// VESTS
	"Crye_AVS_1",
	"Crye_AVS_1_1",
	"Crye_AVS_1_2",
	"Crye_AVS_1_3",
	"Crye_AVS_3",
	"Crye_AVS_3_1",
	"Crye_AVS_3_2",
	"Crye_AVS_3_3",
	"Crye_AVS_2",
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
	"ARD_MC_Camo_Cyre_SS",
	//
	//"ARD_MC_OD_Camo_Cyre_SS",
	//"ARD_MC_OD_Camo_Cyre",
	// MK 17
	"rhs_weap_mk17_STD",
	"rhs_weap_mk17_CQC",
	"rhs_mag_fold_stock",
	//
	"rhs_mag_20Rnd_SCAR_762x51_m61_ap",
	"rhs_mag_20Rnd_SCAR_762x51_m62_tracer",
	"rhs_mag_20Rnd_SCAR_762x51_m80a1_epr",
	//
	"rhsusf_acc_su230a",
	"rhsusf_acc_su230a_c",
	// VESTS
	"Crye_AVS_1",
	"Crye_AVS_1_1",
	"Crye_AVS_1_2",
	"Crye_AVS_1_3",
	"Crye_AVS_3",
	"Crye_AVS_3_1",
	"Crye_AVS_3_2",
	"Crye_AVS_3_3",
	"Crye_AVS_2",
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
	"ARD_MC_Camo_Cyre_SS",
	//
	//"ARD_MC_OD_Camo_Cyre_SS",
	//"ARD_MC_OD_Camo_Cyre",
	// VESTS
	"Crye_AVS_1",
	"Crye_AVS_1_1",
	"Crye_AVS_1_2",
	"Crye_AVS_1_3",
	"Crye_AVS_3",
	"Crye_AVS_3_1",
	"Crye_AVS_3_2",
	"Crye_AVS_3_3",
	"Crye_AVS_2",
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
	"ARD_MC_Camo_Cyre_SS",
	//
	//"ARD_MC_OD_Camo_Cyre_SS",
	//"ARD_MC_OD_Camo_Cyre",
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
	"Crye_AVS_1",
	"Crye_AVS_1_1",
	"Crye_AVS_1_2",
	"Crye_AVS_1_3",
	"Crye_AVS_3",
	"Crye_AVS_3_1",
	"Crye_AVS_3_2",
	"Crye_AVS_3_3",
	"Crye_AVS_2",
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
	"ARD_MC_Camo_Cyre_SS",
	//
	//"ARD_MC_OD_Camo_Cyre_SS",
	//"ARD_MC_OD_Camo_Cyre",
	// VESTS
	"Crye_AVS_1",
	"Crye_AVS_1_1",
	"Crye_AVS_1_2",
	"Crye_AVS_1_3",
	"Crye_AVS_3",
	"Crye_AVS_3_1",
	"Crye_AVS_3_2",
	"Crye_AVS_3_3",
	"Crye_AVS_2",
	// MK 17
	"rhs_weap_mk17_STD",
	"rhs_weap_mk17_CQC",
	"rhs_mag_fold_stock",
	//
	"rhs_mag_20Rnd_SCAR_762x51_m61_ap",
	"rhs_mag_20Rnd_SCAR_762x51_m62_tracer",
	"rhs_mag_20Rnd_SCAR_762x51_m80a1_epr",
	//
	"rhsusf_acc_su230a",
	"rhsusf_acc_su230a_c",
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
	"ARD_MC_Camo_Cyre_SS",
	// MK 17
	"rhs_weap_mk17_STD",
	"rhs_weap_mk17_CQC",
	"rhs_mag_fold_stock",
	//
	"rhs_mag_20Rnd_SCAR_762x51_m61_ap",
	"rhs_mag_20Rnd_SCAR_762x51_m62_tracer",
	"rhs_mag_20Rnd_SCAR_762x51_m80a1_epr",
	//
	"rhsusf_acc_su230a",
	"rhsusf_acc_su230a_c",
	// VEST
	"Crye_AVS_1",
	"Crye_AVS_1_1",
	"Crye_AVS_1_2",
	"Crye_AVS_1_3",
	"Crye_AVS_3",
	"Crye_AVS_3_1",
	"Crye_AVS_3_2",
	"Crye_AVS_3_3",
	"Crye_AVS_2",
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
	"Crye_AVS_1",
	"Crye_AVS_1_1",
	"Crye_AVS_1_2",
	"Crye_AVS_1_3",
	"Crye_AVS_3",
	"Crye_AVS_3_1",
	"Crye_AVS_3_2",
	"Crye_AVS_3_3",
	"Crye_AVS_2"

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
	// MK 48 AMMO
	"Tier1_100Rnd_762x51_Belt_M80",
	"Tier1_100Rnd_762x51_Belt_M61_AP",
	"Tier1_100Rnd_762x51_Belt_M62_Tracer",
	"Tier1_100Rnd_762x51_Belt_M80A1_EPR",
	//
	"rhsusf_50Rnd_762x51_m80a1epr",
    "rhsusf_50Rnd_762x51_m62_tracer",
    "rhsusf_50Rnd_762x51_m61_ap",
	// MISC
	"ACE_SpareBarrel"

];

RA_ARifleman = [
	// Uniform
	"ARD_MC_Camo_Cyre",
	"ARD_MC_Camo_Cyre_SS",
	// BACKPACKS
	"B_Carryall_cbr",
	// VESTS
	"Crye_AVS_1",
	"Crye_AVS_1_1",
	"Crye_AVS_1_2",
	"Crye_AVS_1_3",
	"Crye_AVS_3",
	"Crye_AVS_3_1",
	"Crye_AVS_3_2",
	"Crye_AVS_3_3",
	"Crye_AVS_2",
	// MK 46
	"Tier1_MK46_Mod0",
	"Tier1_MK46_Mod0_Desert",
	"Tier1_MK46_Mod1_Savit",
	"Tier1_MK46_Mod1_Savit_Desert",
	// mk 48
	"Tier1_MK48_Mod0",
	"Tier1_MK48_Mod0_Desert",
	"Tier1_MK48_Mod1",
	"Tier1_MK48_Mod1_Desert",
	//
	"rhsusf_acc_grip1",
	"Tier1_GripPod_Black",
	"rhsusf_acc_kac_grip_saw_bipod",
	"Tier1_SAW_Bipod_DD",
	"Tier1_SAW_Bipod_DD_Desert",
	"Tier1_SAW_Bipod_KAC",
	"Tier1_SAW_Bipod_KAC_Desert",
	"Tier1_SAW_Bipod_2_KAC",
	"Tier1_SAW_Bipod_2_KAC_Desert",
	"Tier1_GripPod_Tan",
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
	"rhsusf_acc_compm4",
	"rhsusf_acc_eotech_55"

] + RA_MGandSAWsites + RA_InfBackpacks + RA_ARiflemanAmmo;

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
	// BACKPACKS
	// Sites

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
	"Crye_AVS_1",
	"Crye_AVS_1_1",
	"Crye_AVS_1_2",
	"Crye_AVS_1_3",
	"Crye_AVS_3",
	"Crye_AVS_3_1",
	"Crye_AVS_3_2",
	"Crye_AVS_3_3",
	"Crye_AVS_2",
	// WEAPONS
    "rhs_weap_m240B",
	// SCOPES
	//"rhsusf_acc_ACOG_MDO",
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

] + RA_MGandSAWsites + RA_InfBackpacks + RA_MGunnerAmmo;

RA_ATSpec = [
	// VESTS
	"Crye_AVS_1",
	"Crye_AVS_1_1",
	"Crye_AVS_1_2",
	"Crye_AVS_1_3",
	"Crye_AVS_3",
	"Crye_AVS_3_1",
	"Crye_AVS_3_2",
	"Crye_AVS_3_3",
	"Crye_AVS_2"
	// BACKPACKS

] + RA_InfBackpacks + RA_BasicInfVests;

RA_ATAmmoBearer = [
	// BACKPACKS
	// MISC
] + RA_InfBackpacks + RA_BasicInfVests + RA_MGunnerAmmo + RA_GrenadierAmmo; // Ammo bearer can pull all ammo used in their squad

RA_MGAmmoBearer = [
	// BACKPACKS
	// VESTS
	// MISC
	"ACE_SpareBarrel"

] + RA_InfBackpacks + RA_BasicInfVests + RA_MGunnerAmmo; // Assistant Machine Gunner is focussed on supporting their MGs

// ---------------------------------- PHANTOM ---------------------------------------
RA_Phantom = [
	// M110
	"Tier1_M110k5_65mm",
	"Tier1_M110k5_ACS_65mm",
	"Tier1_Harris_Bipod_RVG_MLOK_Tan",
	"Tier1_Harris_Bipod_RVG_Black",
	"optic_AMS",
	//
	"ACE_acc_pointer_green",
	"acc_pointer_IR",
	"ACE_muzzle_mzls_338",
	"muzzle_snds_338_black",
	"muzzle_snds_H",
	"Tier1_M4BII_NGAL_Side",
	"Tier1_M4BII_NGAL_Top",
	// AMMO
	"Tier1_20Rnd_65x48_Creedmoor_SR25_Mag",
	"20Rnd_762x51_Mag",
	"10Rnd_Mk14_762x51_Mag",
	"rhsusf_20Rnd_762x51_m62_Mag",
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
	//"rhs_weap_SCARH_FDE_LB",
	//"rhs_weap_SCARH_LB",
	//"rhs_mag_20Rnd_SCAR_762x51_m61_ap_bk",
	//"rhs_mag_20Rnd_SCAR_762x51_m80a1_epr_bk",
	//"rhs_mag_20Rnd_SCAR_762x51_m80a1_epr",
	//"rhs_mag_fold_stock",
	//"rhs_mag_20Rnd_SCAR_762x51_m61_ap",
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
	"ARD_MC_Camo_Cyre_SS",
	//
	//"ARD_MC_OD_Camo_Cyre_SS",
	//"ARD_MC_OD_Camo_Cyre",
	// Ghillie suits
	"ARD_MC_Ghillie_Camo_Cyre",
	"U_B_T_FullGhillie_tna_F",
	"U_B_FullGhillie_lsh",
	"U_B_FullGhillie_ard",
	// VEST
	"Crye_AVS_1",
	"Crye_AVS_1_1",
	"Crye_AVS_1_2",
	"Crye_AVS_1_3",
	"Crye_AVS_3",
	"Crye_AVS_3_1",
	"Crye_AVS_3_2",
	"Crye_AVS_3_3",
	"Crye_AVS_2",
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
	// M110
	"Tier1_M110k5_65mm",
	"Tier1_M110k5_ACS_65mm",
	"Tier1_Harris_Bipod_RVG_MLOK_Tan",
	"Tier1_Harris_Bipod_RVG_Black",
	"optic_AMS",
	//
	"ACE_acc_pointer_green",
	"acc_pointer_IR",
	"ACE_muzzle_mzls_338",
	"muzzle_snds_338_black",
	"muzzle_snds_H",
	"Tier1_M4BII_NGAL_Side",
	"Tier1_M4BII_NGAL_Top",
	// AMMO
	"Tier1_20Rnd_65x48_Creedmoor_SR25_Mag",
	"20Rnd_762x51_Mag",
	"10Rnd_Mk14_762x51_Mag",
	"rhsusf_20Rnd_762x51_m62_Mag",
	// UNIFORM
	"ARD_MC_Camo_Cyre_SS",
	//
	//"ARD_MC_OD_Camo_Cyre_SS",
	//"ARD_MC_OD_Camo_Cyre",
	// Ghillie suits
	"ARD_MC_Ghillie_Camo_Cyre",
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
	//"rhs_weap_SCARH_FDE_LB",
	//"rhs_weap_SCARH_LB",
	//"rhs_mag_20Rnd_SCAR_762x51_m61_ap_bk",
	//"rhs_mag_20Rnd_SCAR_762x51_m80a1_epr_bk",
	//"rhs_mag_20Rnd_SCAR_762x51_m80a1_epr",
	//"rhs_mag_fold_stock",
	//"rhs_mag_20Rnd_SCAR_762x51_m61_ap",
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
	"Crye_AVS_1",
	"Crye_AVS_1_1",
	"Crye_AVS_1_2",
	"Crye_AVS_1_3",
	"Crye_AVS_3",
	"Crye_AVS_3_1",
	"Crye_AVS_3_2",
	"Crye_AVS_3_3",
	"Crye_AVS_2",
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
	//
	"rhs_mag_20Rnd_SCAR_762x51_m61_ap",
	"rhs_mag_20Rnd_SCAR_762x51_m62_tracer",
	"rhs_mag_20Rnd_SCAR_762x51_m80a1_epr",
	//
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
	"Crye_AVS_1",
	"Crye_AVS_1_1",
	"Crye_AVS_1_2",
	"Crye_AVS_1_3",
	"Crye_AVS_3",
	"Crye_AVS_3_1",
	"Crye_AVS_3_2",
	"Crye_AVS_3_3",
	"Crye_AVS_2",
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
	"ARD_MC_Camo_Cyre_SS",
	//
	//"ARD_MC_OD_Camo_Cyre_SS",
	//"ARD_MC_OD_Camo_Cyre",
	// VESTS
	"Crye_AVS_1",
	"Crye_AVS_1_1",
	"Crye_AVS_1_2",
	"Crye_AVS_1_3",
	"Crye_AVS_3",
	"Crye_AVS_3_1",
	"Crye_AVS_3_2",
	"Crye_AVS_3_3",
	"Crye_AVS_2",
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
	"Crye_AVS_1",
	"Crye_AVS_1_1",
	"Crye_AVS_1_2",
	"Crye_AVS_1_3",
	"Crye_AVS_3",
	"Crye_AVS_3_1",
	"Crye_AVS_3_2",
	"Crye_AVS_3_3",
	"Crye_AVS_2",
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
	"rhs_weap_m4a1",
	"rhs_weap_m4a1_d",
	"rhs_weap_m4a1_d_mstock",
	"rhs_weap_m4a1_mstock"

];
RA_ButcherCommander = [
	// UNIFORM
	"ARD_MC_Camo_Cyre_SS",
	//
	//"ARD_MC_OD_Camo_Cyre_SS",
	//"ARD_MC_OD_Camo_Cyre",
	// HEADGEAR
	"rhsusf_cvc_alt_helmet",
	"rhsusf_cvc_ess",
	"rhsusf_cvc_green_alt_helmet",
	"rhsusf_cvc_green_ess",
	"rhsusf_cvc_green_helmet",
	"rhsusf_cvc_helmet",
	// WEAPONS
	"rhs_weap_m4a1",
	"rhs_weap_m4a1_d",
	"rhs_weap_m4a1_d_mstock",
	"rhs_weap_m4a1_mstock",
	// VESTS
	"Crye_AVS_1",
	"Crye_AVS_1_1",
	"Crye_AVS_1_2",
	"Crye_AVS_1_3",
	"Crye_AVS_3",
	"Crye_AVS_3_1",
	"Crye_AVS_3_2",
	"Crye_AVS_3_3",
	"Crye_AVS_2",
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
	// HEADGEAR
	"rhsusf_cvc_alt_helmet",
	"rhsusf_cvc_ess",
	"rhsusf_cvc_green_alt_helmet",
	"rhsusf_cvc_green_ess",
	"rhsusf_cvc_green_helmet",
	"rhsusf_cvc_helmet",
	// VESTS
	"Crye_AVS_1",
	"Crye_AVS_1_1",
	"Crye_AVS_1_2",
	"Crye_AVS_1_3",
	"Crye_AVS_3",
	"Crye_AVS_3_1",
	"Crye_AVS_3_2",
	"Crye_AVS_3_3",
	"Crye_AVS_2",
	// BACKPACKS
	"rhsusf_assault_eagleaiii_coy",
	"rhsusf_falconii_coy",
	"B_Kitbag_cbr",
	// WEAPONS
	"rhs_weap_m4a1",
	"rhs_weap_m4a1_d",
	"rhs_weap_m4a1_d_mstock",
	"rhs_weap_m4a1_mstock",
    //"rhs_weap_M590_5RD",
	// MISC
	"ItemcTab",
	"ToolKit"

] + RA_ButcherCrewAmmo;

RA_ButcherGunner = [
	// UNIFORM
	// HEADGEAR
	"rhsusf_cvc_alt_helmet",
	"rhsusf_cvc_ess",
	"rhsusf_cvc_green_alt_helmet",
	"rhsusf_cvc_green_ess",
	"rhsusf_cvc_green_helmet",
	"rhsusf_cvc_helmet",
	// VESTS
	"Crye_AVS_1",
	"Crye_AVS_1_1",
	"Crye_AVS_1_2",
	"Crye_AVS_1_3",
	"Crye_AVS_3",
	"Crye_AVS_3_1",
	"Crye_AVS_3_2",
	"Crye_AVS_3_3",
	"Crye_AVS_2",
	// BACKPACKS
	"rhsusf_assault_eagleaiii_coy",
	"rhsusf_falconii_coy",
	"B_Kitbag_cbr",
	// WEAPONS
	"rhs_weap_m4a1",
	"rhs_weap_m4a1_d",
	"rhs_weap_m4a1_d_mstock",
	"rhs_weap_m4a1_mstock",
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
	"Crye_AVS_1",
	"Crye_AVS_1_1",
	"Crye_AVS_1_2",
	"Crye_AVS_1_3",
	"Crye_AVS_3",
	"Crye_AVS_3_1",
	"Crye_AVS_3_2",
	"Crye_AVS_3_3",
	"Crye_AVS_2",
	// UNIFORM
	"ARD_MC_Camo_Cyre_SS",
	//
	//"ARD_MC_OD_Camo_Cyre_SS",
	//"ARD_MC_OD_Camo_Cyre",
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
	"Crye_AVS_1",
	"Crye_AVS_1_1",
	"Crye_AVS_1_2",
	"Crye_AVS_1_3",
	"Crye_AVS_3",
	"Crye_AVS_3_1",
	"Crye_AVS_3_2",
	"Crye_AVS_3_3",
	"Crye_AVS_2",
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
	"Crye_AVS_1",
	"Crye_AVS_1_1",
	"Crye_AVS_1_2",
	"Crye_AVS_1_3",
	"Crye_AVS_3",
	"Crye_AVS_3_1",
	"Crye_AVS_3_2",
	"Crye_AVS_3_3",
	"Crye_AVS_2",
	// UNIFORM
	"ARD_MC_Camo_Cyre_SS",
	//
	//"ARD_MC_OD_Camo_Cyre_SS",
	//"ARD_MC_OD_Camo_Cyre",
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
	"Crye_AVS_1",
	"Crye_AVS_1_1",
	"Crye_AVS_1_2",
	"Crye_AVS_1_3",
	"Crye_AVS_3",
	"Crye_AVS_3_1",
	"Crye_AVS_3_2",
	"Crye_AVS_3_3",
	"Crye_AVS_2",
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
	"rhs_weap_m4a1",
	"rhs_weap_m4a1_d",
	"rhs_weap_m4a1_d_mstock",
	"rhs_weap_m4a1_mstock",
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
	// UNIFORMS
	"U_B_HeliPilotCoveralls",
	// MISC
	"ToolKit",
	"ItemcTab"

] + RA_PilotGear + RA_PilotHelmets + RA_PilotWeapons + RA_PilotAmmo;

// ---------------------------------- DEMON ----------------------------------
RA_Demon = [
	// NVGS
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
