OpForStartingUniform = "rhs_uniform_gorka_r_y","UK3CB_H_Woolhat_KHK";

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
	"rhs_weap_ak74m_npz",
	"rhs_weap_ak74m_camo_npz",
	"rhs_weap_ak74m_desert_npz",
	"rhs_weap_ak74m_zenitco01_b33",
	"rhs_weap_ak105_npz",

	// AMMO
	"rhs_30Rnd_545x39_7N22_AK",
	"rhs_30Rnd_545x39_7N10_AK",

	// PISTOL
	"hgun_Rook40_F",

	// PISTOL AMMO
	"16Rnd_9x21_Mag",

	// Scopes and sights
	"rhs_acc_rakurspm",
	"rhs_acc_1p87",
	"tier1_exps3_0_black",
	"tier1_exps3_0_g33_black_up",
	"tier1_microt2_black",
	"tier1_microt2_g33_black_up",
	"tier1_microt2_low_black",
	"rhsusf_acc_su230",

	// GRIPS
	"rhs_acc_grip_rk2",
	"rhs_acc_grip_rk6",

	// Attachments
	"rhs_acc_perst1ik",
	"rhs_acc_perst1ik_ris",
	"rhs_acc_perst3",
	"rhs_acc_perst3_top",
	"rhs_acc_perst3_2dp_h",
	"rhs_acc_perst3_2dp_light_h",

	// Spressor
	"rhs_acc_tgpa",

	// NVGS
	"rhsusf_ANPVS_15",
	"rhs_1PN138",

	// Radios
	"TFAR_anprc148jem",
	"ItemRadio",

	// Grenades
	"rhs_mag_rgd5",
	"rhs_mag_rgn",
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
	"UK3CB_GAF_B_U_SF_CombatSmock_01_MULTICAM",
	"UK3CB_GAF_B_U_SF_CombatSmock_02_MULTICAM_OLIVE",
	"UK3CB_GAF_B_U_SF_CombatSmock_02_MULTICAM_TAN",
	"UK3CB_GAF_B_U_SF_CombatSmock_02_MULTICAM",
	"UK3CB_LNM_B_U_Crew_CombatSmock_01",
	"UK3CB_LSM_B_U_Crew_CombatSmock_02",
	"UK3CB_LSM_B_U_Crew_CombatSmock_03",
	"UK3CB_LSM_B_U_Crew_CombatSmock_08",
	"UK3CB_GAF_B_U_SF_CombatSmock_05_MULTICAM_OLIVE",
	"UK3CB_GAF_B_U_SF_CombatSmock_05_MULTICAM_TAN",
	"UK3CB_GAF_B_U_SF_CombatSmock_05_MULTICAM",
	"UK3CB_GAF_B_U_SF_CombatSmock_06_MULTICAM_OLIVE",
	"UK3CB_GAF_B_U_SF_CombatSmock_06_MULTICAM_TAN",
	"UK3CB_GAF_B_U_SF_CombatSmock_06_MULTICAM",
	"UK3CB_ION_B_U_CombatSmock_02_URB",
	"UK3CB_ION_B_U_CombatSmock_01_URB",
	"UK3CB_ION_B_U_CombatSmock_01_WIN",
	"UK3CB_CHD_W_B_U_CombatSmock_20",
	"UK3CB_CHD_B_U_CombatSmock_06",
	"UK3CB_CHD_B_U_CombatSmock_05",
	"rhs_uniform_gorka_r_y_gloves",
	"rhs_uniform_gorka_r_y",
	"rhs_uniform_gorka_r_g_gloves",
	"rhs_uniform_gorka_r_g",
	"UK3CB_GAF_B_U_CombatSmock_01_DIGI",
	"UK3CB_GAF_B_U_CombatSmock_02_DIGI",

	// pp2000
	"rhs_weap_pp2000",
	"rhs_acc_okp7_picatinny",
	"rhs_mag_9x19mm_7n31_20",

	// Vests
	"rhsgref_chestrig",
	"UK3CB_V_MBAV_LIGHT_MULTI",
	"UK3CB_V_MBAV_RIFLEMAN_MULTI",

	// HAT
	"UK3CB_H_Cap_DPM_Arid",
	"UK3CB_H_Cap_DPM_SA",
	"rhs_Booniehat_flora",

	// Head Gear
	"UK3CB_TKA_O_H_6b7_1m_bala1_TAN",
	"UK3CB_TKA_O_H_6b7_1m_ess_bala1_TAN",
	"UK3CB_ANP_B_H_6b27m_BLK",
	"UK3CB_ANP_B_H_6b27m_bala_BLK",
	"UK3CB_ANP_B_H_6b27m_ess_BLK",
	"UK3CB_ANP_B_H_6b27m_ess_bala_BLK",
	"UK3CB_TKA_O_H_6b7_1m_bala2_DES",

	// Facewear
	"rhs_balaclava",
	"rhs_6sh117_rifleman",
	"rhs_facewear_6m2_1",
	"rhs_6b45_rifleman",
	"rhs_scarf",

	// add befor napf
	"rhs_acc_rakurspm",

	// Backpacks
	"B_AssaultPack_mcamo",
	"rhs_tortila_emr",
	"rhs_assault_umbts",
	"rhs_rk_sht_30_emr",
	"rhs_rk_sht_30_olive",
	"rhs_rpg_empty",
	"UK3CB_GAF_B_B_ASS_MULTICAM_01",
	"UK3CB_GAF_B_B_ENG_MULTICAM_01"
];

// ROLES
	op_DetC = [
		// Basic gear
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
		// GUN
		"rhs_weap_ak74mr_gp25",
		// Basic gear
		"ItemAndroid",
		"ItemMap",
		"ItemGPS",
		"ItemCompass",
		"ItemWatch"
];
op_TL = [
		// TL same gear
		//UNIFORM
		"UK3CB_V_MBAV_GRENADIER_MULTI",
		// GUN
		"rhs_weap_ak74mr_gp25",
		// Basic gear
		"bunwell_axe",
		"ItemAndroid",
		"ItemMap",
		"ItemGPS",
		"ItemCompass",
		"ItemWatch"
];
	op_ASTL = [
		// TL same gear
		//UNIFORM
		"UK3CB_V_MBAV_GRENADIER_MULTI",
		// GUN
		"rhs_weap_ak74mr_gp25",
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
		//// pkp
		"rhs_weap_pkp",
		"rhs_100Rnd_762x54mmR",
		"rhs_100Rnd_762x54mmR_7N13",
		"rhs_100Rnd_762x54mmR_7N26",
		"rhs_100Rnd_762x54mmR_7BZ3",
		"150Rnd_762x54_Box",
		"rhs_acc_okp7_dovetail"
];
	op_HPKP = [
		// UNIFORM
		"UK3CB_V_MBAV_MG_MULTI",
		//// pkp
		"rhs_weap_pkp",
		"rhs_100Rnd_762x54mmR",
		"rhs_100Rnd_762x54mmR_7N13",
		"rhs_100Rnd_762x54mmR_7N26",
		"rhs_100Rnd_762x54mmR_7BZ3",
		"150Rnd_762x54_Box",
		"rhs_acc_okp7_dovetail"
];
	op_EWAR = [
		// Drone GUY
		"ItemcTab"

];

	op_COMMGUY = [
		// RadioGuy
		"tfw_rf3080Item",
		// Radio Backpacks
		"UK3CB_B_I_Backpack_Radio_Chem_OLI",
		"UK3CB_B_I_Backpack_Radio_Chem"

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
		// Radio Backpacks
		"UK3CB_B_I_Backpack_Radio_Chem_OLI",
		"UK3CB_B_I_Backpack_Radio_Chem",
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
		// Misc
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
	op_Spotter = [
		// Ghillie
		"U_I_FullGhillie_sard",
		"rhsgref_6b23_khaki_sniper",
		"UK3CB_ANA_B_U_CombatUniform_Ghillie_GCAM",
		// Misc
		"Binocular",
		"rhsusf_bino_lerca_1200_black",
		"ACE_TRIPOD",
		"ACE_RangeCard"

];

	// Weapons Squad

	op_Team_Leader = [
	"ace_csw_50Rnd_127x108_mag"
];

	op_Gunner = [
	//// pkp
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
	//
	"ace_compat_rhs_afrf3_metis_carry",
	"ace_compat_rhs_afrf3_kord_carry",
	"ace_compat_rhs_afrf3_spg9m_carry",
	"ace_csw_50Rnd_127x108_mag"
];

	op_A_G = [
	//// pkp
	"rhs_100Rnd_762x54mmR_7BZ3",
	"rhs_100Rnd_762x54mmR",
	"rhs_100Rnd_762x54mmR_7N13",
	"rhs_100Rnd_762x54mmR_7N26",
	"rhs_100Rnd_762x54mmR_7BZ3",
	"150Rnd_762x54_Box",
	//
	"ace_csw_kordCarryTripodLow",
	"ace_csw_spg9CarryTripod",
	"ace_csw_50Rnd_127x108_mag",
	"ace_csw_kordCarryTripodLow",
	"ace_csw_spg9CarryTripod",
	// BIPODS
	"ace_csw_kordCarryTripodLow",
	"ace_csw_spg9CarryTripod"
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