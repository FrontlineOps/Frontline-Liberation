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

	if(_roleDesc find "Fireteam leader" > -1) then {
		_gearToAdd = op_TL;
	};

	if(_roleDesc find "Squad Leader" > -1) then {
		_gearToAdd = op_SL;
	};

	if(_roleDesc find "Medical Specialist" > -1) then {
		_gearToAdd = op_Medic;
	};

	if(_roleDesc find "Rifleman" > -1) then {
		_gearToAdd = op_Rifleman;
	};

	if(_roleDesc find "Rifleman GL" > -1) then {
		_gearToAdd = op_Rifleman_GL;
	};

	if(_roleDesc find "Automatic Rifleman" > -1) then {
		_gearToAdd = op_HPKP;
	};
	if(_roleDesc find "Weapons Team Leader" > -1) then {
		_gearToAdd = op_Team_Leader + op_MORTORSTUFF;
	};

	if(_roleDesc find "Weapons Gunner" > -1) then {
		_gearToAdd = op_Gunner + op_MORTORSTUFF;
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
	"PLA_CombatUniform_HM_SWCB",
	"PLA_CombatUniform_SWCB",
	"PLA_Uniform_PLADES2",
	"PLA_Uniform_PLADES3",
	"PLA_Uniform_PLAWOOD2",
	"PLA_Uniform_PLAAF",
	"PLA_Uniform_PLAN",
	"PLA_Uniform_PLANM",
	"PLA_Uniform_PLAFOR",
	"PLA_Uniform_PLAFOR2",
	"PLA_CombatUniform_HM_SW",
	"PLA_CombatUniform_SW",
	"PLA_CombatUniform_HM_SB",
	"PLA_CombatUniform_HM_SBCB",
	"PLA_CombatUniform_SB",
	"PLA_CombatUniform_SBCB",
	"PLA_CombatUniform_HM_SG",
	"PLA_CombatUniform_HM_SGCB",
	"PLA_CombatUniform_SG",
	"PLA_CombatUniform_SGCB",
	// pp2000
	"rhs_weap_pp2000",
	"rhs_acc_okp7_picatinny",
	"rhs_mag_9x19mm_7n31_20",

	// Vests
	"PLAAF_Vest",
	"PLAN_Vest",
	"PLANM_Vest",
	"PLAFOR_Vest",
	"PLAFOR_Vest2",
	"PLA_T15Vest_RF_D",
	"PLA_T15Vest_RF",
	"PLA_T15Vest_RD_D",
	"PLA_T15Vest_RD",
	"PLA_T15Vest",
	"PLA_B04_MG_D",
	"PLA_B04_MG",
	"PLA_B04_RF_D",
	"PLA_B04_RF",
	"PLA_T15Vest_D",
	// HAT
	"VME_Booniehat_PLAAF",
	"VME_Booniehat_DES",
	"VME_Booniehat_PLAN",
	"VME_Booniehat_PLANM",
	"VME_Booniehat_PLARF",
	"VME_Booniehat_PLARF2",
	"VME_Booniehat_PLAAF_Radio",
	"VME_Booniehat_DES_Radio",
	"VME_Booniehat_PLAN_Radio",
	"VME_Booniehat_PLANM_Radio",
	"VME_Booniehat_PLARF_Radio",
	"VME_Booniehat_PLARF2_Radio",
	"VME_Booniehat_WD_Radio",

	// Head Gear
	"VME_PLA_Helmet_D",
	"VME_PLAAF_Helmet",
	"VME_PLAN_Helmet",
	"VME_PLANM_Helmet",
	"VME_PLAFOR2_Helmet",
	"VME_PLAFOR_Helmet",
	"VME_PLA_Helmet_G",
	"VME_PLA_Helmet_D_G",
	"VME_PLA_Helmet_R_O",
	"VME_PLA_Helmet_D_R_O",
	"VME_PLA_Helmet_R",
	"VME_PLA_Helmet_D_R",
	// Facewear
	"PLA_goggle",
	"rhs_googles_black",
	"rhs_googles_orange",
	"UK3CB_G_Ballistic_Black",
	"rhs_googles_clear",
	"rhs_googles_yellow",
	"UK3CB_G_Ballistic_Black_Gloves_Green",
	"UK3CB_G_Ballistic_Black_Gloves_Tan",
	"UK3CB_G_Ballistic_Black_Gloves_Black",
	"UK3CB_G_Tactical_Clear",

	// Backpacks
	"PLADES_CarryAll_Base",
	"PLAAF_CarryAll_Base",
	"PLAN_CarryAll_Base",
	"PLANM_CarryAll_Base",
	"PLADES_FieldPack_Medic",
	"PLAAF_FieldPack_Medic",
	"PLAN_FieldPack_Medic",
	"PLANM_FieldPack_Medic",
	"PLA_AssaultPack_Fix",
	"PLA_AssaultPack_Base",
	"PLADES_QLU11_Pack",
	"PLAFOR_QLU11_Pack",
	"PLANM_QLU11_Pack",
	"PLA_QLU11_Pack",
	"PLAN_QLU11_Pack"
];

// ROLES
	op_SL = [
		// TL same gear
		//UNIFORM
		
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
	op_Rifleman_GL = [
		// Basic gear
		"ItemAndroid",
		"ItemMap",
		"ItemGPS",
		"ItemCompass",
		"ItemWatch",
		// GUN
		"rhs_weap_ak74mr_gp25",
		"rhs_weap_asval_grip",
		// AMMO
		"rhs_20rnd_9x39mm_SP6",
		"rhs_10rnd_9x39mm_SP6",
		"rhs_mag_fold_stock"
];
	op_HPKP = [
		// UNIFORM
		
		//// pkp
		"rhs_weap_pkp",
		"rhs_100Rnd_762x54mmR",
		"rhs_100Rnd_762x54mmR_7N13",
		"rhs_100Rnd_762x54mmR_7N26",
		"rhs_100Rnd_762x54mmR_7BZ3",
		"150Rnd_762x54_Box",
		"rhs_acc_okp7_dovetail"
];
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
	op_MORTORSTUFF = [
	"ACE_RangeTable_82mm",
	"ACE_artilleryTable",
	"itc_land_tablet_fdc",
	"ACE_Kestrel4500"
];
	op_Medic = [
		// The Medic
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