OpForStartingUniform = "UK3CB_MEI_B_U_Jeans_Tshirt_08";

Op_StartingItems = [
	"ItemAndroid",
	"ItemMap",
	"ItemCompass",
	"ItemWatch",
	"ACE_Flashlight_XL50",
	"TFAR_anprc148jem"
];

OpforArsenal_DetermineGear = {
	params ["_player"];

	_gearToAdd = [];
	_roleDesc = roleDescription _player;

	if(_roleDesc find "Detachment Commander" > -1) then {
		_gearToAdd = op_DetC;
	};

	if(_roleDesc find "Assistant Detachment Commander" > -1) then {/////unused
		_gearToAdd = op_SLAndTL;
	};

	if(_roleDesc find "Team leader" > -1) then {///////unused
		_gearToAdd = op_TL;
	};

	if(_roleDesc find "Squad Leader" > -1) then {
		_gearToAdd = op_SL;
	};

	if(_roleDesc find "Assistant Team Leader" > -1) then {
		_gearToAdd = op_ASTL;
	};

	if(_roleDesc find "Sergeant" > -1) then {////unused
		_gearToAdd = op_SLAndTL;
	};

	if(_roleDesc find "Medical Specialist" > -1) then {
		_gearToAdd = op_Medic;
	};

	if(_roleDesc find "Rifleman" > -1) then {//////unused
		_gearToAdd = op_Rifleman;
	};

	if(_roleDesc find "Weapons Specialist" > -1) then {/////unused
		_gearToAdd = op_PKP;
	};

	if(_roleDesc find "Machine Gunner" > -1) then {
		_gearToAdd = op_HPKP;
	};

	if(_roleDesc find "Launcher Specialist" > -1) then {
		_gearToAdd = op_RPG;
	};

	if(_roleDesc find "Communications Specialist" > -1) then {
		_gearToAdd = op_COMMGUY;
	};

	if(_roleDesc find "Drone Specialist" > -1) then {
		_gearToAdd = op_EWAR;
	};

	if(_roleDesc find "Demolitions Specialist" > -1) then {
		_gearToAdd = op_Engineer;
	};

	if(_roleDesc find "Engineer Team Leader" > -1) then {
		_gearToAdd = op_Engineer;
	};

	if(_roleDesc find "Engineer-1" > -1) then {
		_gearToAdd = op_Engineer;
	};

	if(_roleDesc find "Engineer-2" > -1) then {
		_gearToAdd = op_Engineer;
	};

	if(_roleDesc find "SNOT Sniper" > -1) then {
		_gearToAdd = op_sniper;
	};

	if(_roleDesc find "SNOT Spotter" > -1) then {
		_gearToAdd = op_Spotter;
	};

	if(_roleDesc find "K11 Marksman" > -1) then {
		_gearToAdd = op_marksm;
	};

	if(_roleDesc find "K12 Marksman" > -1) then {
		_gearToAdd = op_marksm;
	};

	if(_roleDesc find "Weapons Team Leader" > -1) then {
		_gearToAdd = op_Team_Leader;
	};

	if(_roleDesc find "Weapons Gunner" > -1) then {
		_gearToAdd = op_Gunner;
	};

	if(_roleDesc find "Weapons Assistant Gunner" > -1) then {
		_gearToAdd = op_A_G;
	};

	if(_roleDesc find "Terminator 1 Team Leader" > -1) then {
		_gearToAdd = op_MORTORSTUFF + op_SL;
	};

	if(_roleDesc find "Terminator 1 Mortarman" > -1) then {
		_gearToAdd = op_MORTORSTUFF;
	};

	if(_roleDesc find "Terminator 1 Asst. Mortarman" > -1) then {
		_gearToAdd = op_MORTORSTUFF;
	};

	if(_roleDesc find "Flight" > -1) then {
		_gearToAdd = op_pilot;
	};

	_gearToAdd append OPFORArsenalItems;

	_gearToAdd
};

OPFORArsenalItems = [
	// Weapons
	"rhs_weap_ak74",
	"rhs_weap_ak74_gp25",
	"rhs_weap_akm",
	"rhs_weap_akm_gp25",
	"rhs_30Rnd_762x39mm_bakelite",
	// Radios
	"TFAR_anprc148jem",
	// US Gear
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
	"rhs_weap_m16a4_carryhandle",
	//
	"rhsusf_weap_m9",
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

	// AMMO
	"rhs_30Rnd_545x39_7N22_AK",
	"rhs_30Rnd_545x39_7N10_AK",
	// US Gear
	"rhsusf_mag_15Rnd_9x19_FMJ",
	"rhs_mag_30Rnd_556x45_M855A1_PMAG",
	"rhs_mag_30Rnd_556x45_M855A1_PMAG_Tracer_Red",

	// PISTOL
	"hgun_Rook40_F",

	// PISTOL AMMO
	"16Rnd_9x21_Mag",

	// Scopes and sights
	"rhs_acc_1p87",
	"tier1_exps3_0_black",
	// US Gear
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
	"rhsusf_acc_compm4",

	// GRIPS

	// Attachments
	"rhs_acc_perst1ik_ris",
	"rhs_acc_perst3_top",
	"rhs_acc_perst3_2dp_h",
	"rhs_acc_perst3_2dp_light_h",

	// Spressor

	// NVGS
	"rhs_1PN138",


	// Grenades
	"rhs_mag_rdg2_white",
	"rhs_mag_nspd",

	//Misc
	"ItemAndroid",
	"ItemMap",
	"ItemGPS",
	"ItemCompass",
	"ItemWatch",
	"ACE_bodyBag",
	"ACE_CableTie",
	"ACE_EarPlugs",
	"ACE_IR_Strobe_Item",
	"ACE_Flashlight_XL50",
	"ACE_SpraypaintRed",
	"ACE_SpottingScope",
	"ACE_SpareBarrel_Item",
	"rhsusf_bino_lrf_Vector21",
	"rhs_pdu4",
	"ACE_Vector",
	"ACE_wirecutter",
	//
	"Binocular",
	"rhsusf_bino_m24",
	"rhsusf_bino_m24_ARD",
	"ACE_Vector",
	"rhsusf_bino_lerca_1200_black",
	"Laserdesignator",
	"Laserbatteries",
	"ItemcTab",

	// Medical
	"ACE_plasmaIV",
	"ACE_plasmaIV_250",
	"ACE_plasmaIV_500",
	"ACE_bloodIV",
	"ACE_bloodIV_250",
	"ACE_bloodIV_500",
	"ACE_epinephrine",
	"ACE_morphine",
	"ACE_salineIV",
	"ACE_salineIV_250",
	"ACE_salineIV_500",
	"ACE_splint",
	"ACE_tourniquet",
	"ACE_elasticBandage",
	"ACE_packingBandage",
	"ACE_adenosine",
	"kat_Painkiller",
	"ACE_quikclot",
	"ACE_epinephrine",

	// Uniforms
	"UK3CB_ARD_B_U_CombatUniform_01",
	"UK3CB_ARD_B_U_SF_Uniform_01",
	"UK3CB_MEI_B_U_Jeans_Tshirt_08",
	"UK3CB_MEI_B_U_Jeans_Tshirt_19",
	//
	"UK3CB_ARD_B_U_CombatUniform_01",
	"UK3CB_ARD_B_U_SF_Uniform_01",
	"UK3CB_ADC_C_Hunter_U_10",
	"UK3CB_ADM_B_U_CombatUniform_01_DDPM_WDL",
	"UK3CB_ADM_B_U_CombatUniform_01_WDL_DDPM",
	"UK3CB_ADM_B_U_CombatUniform_01_WDL",
	"UK3CB_ANA_B_U_CombatUniform_Shortsleeve_01_WDL",
	"UK3CB_TKA_B_U_CombatUniform_Shortsleeve_01_WDL",
	"UK3CB_ADM_B_U_CombatUniform_Shortsleeve_01_DDPM_WDL",
	"UK3CB_ADM_B_U_CombatUniform_Shortsleeve_01_WDL_DDPM",
	"UK3CB_ADM_B_U_CombatUniform_Shortsleeve_01_WDL",
	"UK3CB_ADM_B_U_CombatUniform_Shortsleeve_01_WDL_ALT",
	"UK3CB_LNM_B_U_CombatSmock_19",
	"UK3CB_LNM_B_U_CombatSmock_20",
	"UK3CB_LNM_B_U_CombatSmock_21",
	"UK3CB_FIA_B_U_M10_CombatUniform_WDL01_01",
	"UK3CB_FIA_B_U_M10_CombatUniform_WDL02_01",
	"UK3CB_FIA_B_U_M10_CombatUniform_WDL02_02",

	// pp2000
	"rhs_weap_pp2000",
	"rhs_mag_9x19mm_7n31_20",

	// Vests
	"UK3CB_V_MBAV_LIGHT_MULTI",
	"UK3CB_V_MBAV_RIFLEMAN_MULTI",
	"UK3CB_V_PlateCarrier1_brn",
	"UK3CB_V_PlateCarrier1_des",
	"UK3CB_V_PlateCarrier1_khk",
	"UK3CB_V_PlateCarrier2_brn",
	"UK3CB_V_PlateCarrier2_des",
	"UK3CB_V_PlateCarrier2_khk",

	// HAT
	"UK3CB_H_Cap_DPM_Arid",
	"UK3CB_H_Cap_DPM_SA",
	"rhs_Booniehat_flora",
	"UK3CB_LNM_B_H_BoonieHat_MULTICAM",
	"Head gear OPFOR",
	"H_ShemagOpen_tan",
	"H_ShemagOpen_khk",
	"UK3CB_H_Shemag_grey",

	// Robes
	"UK3CB_TKM_I_U_03_B",
	"UK3CB_TKM_I_U_04_C",
	"UK3CB_TKC_C_U_03_B",

	// Head Gear
	"rhsusf_ach_bare_tan_headset_ess",
	"rhsusf_ach_bare_tan_headset",
	"rhsusf_ach_bare_tan_ess",
	"rhsusf_ach_bare_tan",

	// add befor napf
	

	// Backpacks
	"B_Kitbag_cbr",
	"rhsusf_falconii_coy",
	"UK3CB_GAF_B_B_RIF_MED_TAN",
	"UK3CB_GAF_B_B_RIF_TAN",
	"B_Carryall_cbr",
	"B_AssaultPack_cbr",
	"UK3CB_ANA_B_B_ASS",
	"B_Carryall_khk",
	"UK3CB_LNM_B_B_CARRYALL_WDL_02",
	"UK3CB_CW_US_B_LATE_B_RIF_02",
	"UK3CB_B_Backpack_Pocket",
	"UK3CB_B_Backpack_Med",

	// Drip is in Determine Role
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

// ROLES
	op_DetC = [
		// Radios
		"TFAR_anprc148jem",
		// Basic gear
		"ACE_MX2A",
		"ItemAndroid",
		"ItemMap",
		"ItemGPS",
		"ItemCompass",
		"ItemcTab",
		"ItemWatch"
];
	op_SL = [
		// TL same gear
		//UNIFORM
		"UK3CB_V_MBAV_GRENADIER_MULTI",
		// Radios
		"TFAR_anprc148jem",
		// GUN
		//"rhs_weap_ak74mr_gp25",
		"ACE_MX2A",
		//
		"rhs_weap_m16a4_carryhandle_M203",
		"rhs_weap_m16a4_imod_M203",
		"rhs_weap_m4_carryhandle_m203",
		"rhs_weap_m4a1_carryhandle_m203",
		// AMMO
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
		// Basic gear
		"ItemAndroid",
		"ItemMap",
		"ItemGPS",
		"ItemCompass",
		"ItemWatch"
];
op_TL = [
		// Radios
		"TFAR_anprc148jem",
		// TL same gear
		"ACE_MX2A",
		//UNIFORM
		"UK3CB_V_MBAV_GRENADIER_MULTI",
		// GUN
		"rhs_weap_m16a4_carryhandle_M203",
		"rhs_weap_m16a4_imod_M203",
		"rhs_weap_m4_carryhandle_m203",
		"rhs_weap_m4a1_carryhandle_m203",
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
		// Basic gear
		"bunwell_axe",
		"ItemAndroid",
		"ItemMap",
		"ItemGPS",
		"ItemCompass",
		"ItemWatch"
];
	op_ASTL = [
		// Radios
		"TFAR_anprc148jem",
		// TL same gear
		"ACE_MX2A",
		//UNIFORM
		"UK3CB_V_MBAV_GRENADIER_MULTI",
		// GUN
		"rhs_weap_m16a4_carryhandle_M203",
		"rhs_weap_m16a4_imod_M203",
		"rhs_weap_m4_carryhandle_m203",
		"rhs_weap_m4a1_carryhandle_m203",
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
		// Basic gear
		"bunwell_axe",
		"ItemAndroid",
		"ItemMap",
		"ItemGPS",
		"ItemCompass",
		"ItemWatch"
];
	op_RPG = [
		// RPG GUY
		// Basic gear
		"ItemAndroid",
		"ItemMap",
		"ItemGPS",
		"ItemCompass",
		"ItemWatch"
		
];
	op_Rifleman = [
		// Basic gear
		"ItemAndroid",
		"ItemMap",
		"ItemGPS",
		"ItemCompass",
		"ItemWatch",
		// ACC side
		"rhs_acc_2dpZenit_ris",
		"rhs_acc_perst1ik_ris",
		"rhsusf_acc_wmx_bk",
		"rhsusf_acc_M952V",
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
		// GUN
		"rhs_weap_asval_grip",
		// AMMO
		"rhs_20rnd_9x39mm_SP6",
		"rhs_10rnd_9x39mm_SP6",
		"rhs_mag_fold_stock"
];
	op_PKP = [
		// PKP AR GUY
		// UNIFORM
		"UK3CB_V_MBAV_MG_MULTI",
		// AMMO
		"rhsusf_200Rnd_556x45_soft_pouch",
		"rhsusf_200Rnd_556x45_mixed_soft_pouch",
		"rhsusf_200Rnd_556x45_box",
		"rhsusf_200rnd_556x45_mixed_box",
		"rhsusf_100Rnd_556x45_soft_pouch",
		"rhsusf_100Rnd_556x45_mixed_soft_pouch",
		"rhs_mag_30Rnd_556x45_M855A1_PMAG",
		"rhs_mag_30Rnd_556x45_M855A1_PMAG_Tracer_Red",
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
		"rhsusf_acc_eotech_55",
		// MISC
		"ACE_SpareBarrel"
];
	op_HPKP = [
		// UNIFORM
		"UK3CB_V_MBAV_MG_MULTI",
		// AMMO
		"rhsusf_200Rnd_556x45_soft_pouch",
		"rhsusf_200Rnd_556x45_mixed_soft_pouch",
		"rhsusf_200Rnd_556x45_box",
		"rhsusf_200rnd_556x45_mixed_box",
		"rhsusf_100Rnd_556x45_soft_pouch",
		"rhsusf_100Rnd_556x45_mixed_soft_pouch",
		"rhs_mag_30Rnd_556x45_M855A1_PMAG",
		"rhs_mag_30Rnd_556x45_M855A1_PMAG_Tracer_Red",
		// GUNS
		//// pkp
		"rhs_weap_pkp",
		"rhs_100Rnd_762x54mmR",
		"rhs_100Rnd_762x54mmR_7N13",
		"rhs_100Rnd_762x54mmR_7N26",
		"rhs_100Rnd_762x54mmR_7BZ3",
		"150Rnd_762x54_Box",
		"rhs_acc_okp7_dovetail",
		//
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
		"rhsusf_acc_eotech_55",
		// MISC
		"ACE_SpareBarrel"
];
	op_EWAR = [
		// Radios
		"TFAR_anprc148jem",
		// Drone GUY
		"O_UavTerminal",
		"ItemcTab"

];

	op_COMMGUY = [
		// Radios
		"TFAR_anprc148jem",
		// RadioGuy
		"tfw_rf3080Item",
		// Radio Backpacks
		"UK3CB_B_O_Backpack_Radio_Chem",
		"UK3CB_B_O_Backpack_Radio_Chem_OLI"

];

	op_Engineer = [
		// engineer tools
		"ACE_Fortify",
		"ACE_DefusalKit",
		"bunwell_axe",
		"ToolKit",
		"ACE_EntrenchingTool",
		"J3FF_FoxholeTool"
		// Explosives ordinance
	];
	op_pilot = [
		// Helmets
		"UK3CB_H_Pilot_Helmet",
		// Uniforms
		"UK3CB_CW_SOV_O_LATE_U_H_Pilot_Uniform_01_TTSKO",
		// Radio Backpacks
		"TFAR_mr3000_multicam",
		"TFAR_bussole",
		"TFAR_mr3000_rhs",
		// engineer tools
		"ACE_Clacker",
		"ToolKit",
		// Explosives ordinance
		"ClaymoreDirectionalMine_Remote_Mag",
		"SatchelCharge_Remote_Mag",
		"rhsusf_m112x4_mag",
		"rhsusf_m112_mag",
		// AMMO RPK
		"UK3CB_RPK74_60rnd_545x39",
		// AMMO VAL
		"rhs_20rnd_9x39mm_SP6",
		"rhs_10rnd_9x39mm_SP6",
		"rhs_mag_fold_stock",
		// AMMO RPG
		"rhs_rpg7_OG7V_mag",
		"rhs_rpg7_PG7V_mag",
		// 40MM
		"rhs_VOG25"
	];
	op_sniper = [
		// Radios
		"TFAR_anprc148jem",
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
		"rhsusf_acc_wmx_bk",
		"rhsusf_acc_M952V",
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
		"ACE_Vector",
		"ACE_TRIPOD",
		"ACE_RangeCard",
		// ASVAL
		"rhs_weap_asval_grip",
		// AMMO
		"rhs_20rnd_9x39mm_SP6",
		"rhs_10rnd_9x39mm_SP6",
		"rhs_mag_fold_stock",
		// SVD
		"rhs_weap_svds",
		"rhs_weap_svds_npz",
		// AMMO
		"rhs_10Rnd_762x54mmR_7N1",
		"rhs_10Rnd_762x54mmR_7N14",
		// SILENCER
		"rhs_acc_tgpv2",
		// SCOPE
		"rhs_acc_dh520x56",
		"rhs_acc_pso1m21",
		// NIGHTVISON SCOPE
		"rhs_acc_1pn34"
	];
	op_Spotter = [
		// Ghillie
		"U_I_FullGhillie_sard",
		"rhsgref_6b23_khaki_sniper",
		"UK3CB_ANA_B_U_CombatUniform_Ghillie_GCAM",
		// ASVAL
		"rhs_weap_asval_grip",
		// AMMO
		"rhs_20rnd_9x39mm_SP6",
		"rhs_10rnd_9x39mm_SP6",
		"rhs_mag_fold_stock",
		// SVD
		"rhs_weap_svds",
		"rhs_weap_svds_npz",
		// AMMO
		"rhs_10Rnd_762x54mmR_7N1",
		"rhs_10Rnd_762x54mmR_7N14",
		// SILENCER
		"rhs_acc_tgpv2",
		// SCOPE
		"rhs_acc_dh520x56",
		"rhs_acc_pso1m21",
		// NIGHTVISON SCOPE
		"rhs_acc_1pn34",
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
	op_marksm = [
		// ASVAL
		"rhs_weap_asval_grip",
		// AMMO
		"rhs_20rnd_9x39mm_SP6",
		"rhs_10rnd_9x39mm_SP6",
		"rhs_mag_fold_stock",
		// SVD
		"rhs_weap_svds",
		"rhs_weap_svds_npz",
		// AMMO
		"rhs_10Rnd_762x54mmR_7N1",
		"rhs_10Rnd_762x54mmR_7N14",
		// SILENCER
		"rhs_acc_tgpv2",
		// SCOPE
		"rhs_acc_dh520x56",
		"rhs_acc_pso1m21",
		"rhs_acc_1pn93_1",
		// NIGHTVISON SCOPE
		"rhs_acc_1pn34",
		// Misc
		"ACE_RangeCard"
	];

	// Weapons Squad

	op_Team_Leader = [
		// Radios
		"O_UavTerminal",
		"TFAR_anprc148jem",
		"ace_csw_50Rnd_127x108_mag"
	];

	op_Gunner = [
		//// pkp
		"O_UavTerminal",
		"rhs_weap_pkp",
		"rhs_100Rnd_762x54mmR",
		"rhs_100Rnd_762x54mmR_7N13",
		"rhs_100Rnd_762x54mmR_7N26",
		"rhs_100Rnd_762x54mmR_7BZ3",
		"150Rnd_762x54_Box",
		"rhs_acc_okp7_dovetail",
		//
		"Tier1_100Rnd_762x51_Belt_M80",
		"Tier1_100Rnd_762x51_Belt_M80",
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
		"rhsusf_acc_wmx_bk",
		// AMMO
		"Tier1_250Rnd_762x51_Belt_M80A1_EPR",
		"Tier1_250Rnd_762x51_Belt_M80",
		"Tier1_250Rnd_762x51_Belt_M62_Tracer",
		"Tier1_250Rnd_762x51_Belt_M61_AP",
		//
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

	op_A_G = [
		//// pkp
		"rhs_100Rnd_762x54mmR_7BZ3",
		"rhs_100Rnd_762x54mmR",
		"rhs_100Rnd_762x54mmR_7N13",
		"rhs_100Rnd_762x54mmR_7N26",
		"rhs_100Rnd_762x54mmR_7BZ3",
		"150Rnd_762x54_Box",
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

	op_MORTORSTUFF = [
		"ACE_RangeTable_82mm",
		"ACE_artilleryTable",
		"itc_land_tablet_fdc",
		"ACE_Kestrel4500"
	];

	op_Medic = [
		// The Medic
		"UK3CB_V_MBAV_MEDIC_MULTI",
		"kat_IV_16",
		"kat_naloxone",
		"kat_nitroglycerin",
		"kat_norepinephrine",
		"kat_phenylephrine",
		"kat_Carbonate",
		"ACE_personalAidKit",
		"ACE_plasmaIV",
		"ACE_plasmaIV_250",
		"ACE_plasmaIV_500",
		"ACE_bloodIV",
		"ACE_bloodIV_250",
		"ACE_bloodIV_500",
		"ACE_epinephrine",
		"kat_EACA",
		"kat_lidocaine",
		"ACE_morphine",
		"ACE_salineIV",
		"ACE_salineIV_250",
		"ACE_salineIV_500",
		"kat_TXA",
		"ACE_surgicalKit",
		"ACE_splint",
		"ACE_tourniquet",
		"kat_IO_FAST",
		"ACE_elasticBandage",
		"ACE_packingBandage",
		"ACE_adenosine",
		"kat_Painkiller",
		"ACE_quikclot",
		"ACE_epinephrine",
		"kat_X_AED"
];