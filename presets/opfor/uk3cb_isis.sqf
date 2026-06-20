// Enemy infantry classes
opfor_officer = "UK3CB_MEE_O_COM";                          // Officer 
opfor_squad_leader = "UK3CB_MEE_O_SL";                          	// Sergeant 
opfor_team_leader = "UK3CB_MEE_O_TL";                    	// Junior Sergeant 
opfor_sentry = "UK3CB_MEE_O_TL";                                	// Efreitor 
opfor_rifleman = "UK3CB_MEE_O_RIF_1";                              	// Rifleman 
opfor_rpg = "UK3CB_MEE_O_LAT";                                        	// Rifleman w/ RPG-26 
opfor_grenadier = "UK3CB_MEE_O_GL";                            	// Grenadier w/ GP-25 
opfor_machinegunner = "UK3CB_MEE_O_AR",					  		// Autorifleman (PKP)
opfor_heavygunner = "UK3CB_MEE_O_MG";                      	// Machinegunner 
opfor_marksman = "UK3CB_MEE_O_MK";                              	// Marksman 
opfor_sharpshooter = "UK3CB_MEE_O_SPOT";                          // Sharpshooter 
opfor_sniper = "UK3CB_MEE_O_SNI";                                	// Sniper 
opfor_at = "UK3CB_MEE_O_AT";                                          	// AT Specialist 
opfor_aa = "UK3CB_MEE_O_AA";                                          	// AA Specialist 
opfor_medic = "UK3CB_MEE_O_MD";                                    	// Medic 
opfor_engineer = "UK3CB_MEE_O_ENG";                              	// Engineer 
opfor_paratrooper = "UK3CB_MEE_O_RIF_1";								// Rifleman w/ RShG2 
opfor_rto	= "UK3CB_MEE_O_IED";								// Officer (Armored) EMR

// From exported arsenal
opfor_rto_loadout = [["rhs_weap_akm","rhs_acc_dtkakm","","",["rhs_30Rnd_762x39mm",30],[],""],[],[],["UK3CB_MEE_O_U_04_D",[["ACE_EarPlugs",1],["ACE_fieldDressing",4],["rhs_mag_rdg2_white",1,1],["rhs_mag_rdg2_black",1,1],["rhs_mag_rgd5",2,1],["rhs_30Rnd_762x39mm",6,30]]],["rhs_belt_AK4",[["ACE_fieldDressing",4],["ACE_tourniquet",1],["ACE_splint",1],["ACE_morphine",1],["ACE_epinephrine",1],["ACE_DefusalKit",1],["ACE_Cellphone",1]]],["UK3CB_ION_B_B_RadioBag_BLK",[["rhs_30Rnd_762x39mm",2,30],["IEDUrbanBig_Remote_Mag",1,1],["IEDLandBig_Remote_Mag",1,1]]],"UK3CB_H_Shemag_blk","",[],["ItemMap","","ItemRadio","ItemCompass","ItemWatch",""]],[["ace_arsenal_face","PersianHead_A3_01"]];


// Enemy vehicles used by secondary objectives.
opfor_mrap = "UK3CB_MEE_O_M1025_MK19";                                            // GAZ-233011
opfor_mrap_armed = "UK3CB_MEE_O_M113tank_MK19_90";                                  // GAZ-233014 (Armed)
opfor_transport_helo = "RHS_UH1Y_UNARMED_d";                          // Mi-8MT (Cargo)
opfor_transport_truck = "UK3CB_MEE_O_V3S_Open";                            // KamAZ-5350 (Covered)
opfor_ammobox_transport = "UK3CB_MEE_O_V3S_Recovery";                  // KamAZ-5350 Flatbed
opfor_fuel_truck = "UK3CB_MEE_O_V3S_Refuel";                            // TZ-8-255B1 (Fuel)
opfor_ammo_truck = "UK3CB_MEE_O_V3S_Reammo";                            // KamAZ-5350 (Ammo)
opfor_fuel_container = "B_Slingload_01_Fuel_F";             			// HURON Fuel
opfor_ammo_container = "B_Slingload_01_Ammo_F";             			// HURON Ammo
opfor_flag = "Flag_MEE";                                       // isis Flag


// To force add uniform
opfor_uniforms = [
	"UK3CB_MEE_O_U_01",
	"UK3CB_MEE_O_U_04_D"
];
// Kit to put in uniform if replacing due to invalid ID
opfor_uniform_kit = [
	["ACE_packingBandage",10],
	["ACE_tourniquet",4],
	["ACE_morphine",1]
];
// Force add a backpack
opfor_backpacks = [
	"UK3CB_ION_B_B_RadioBag_BLK"
];
// Force add a vest
opfor_vests = [
	"rhs_belt_AK4",
	"UK3CB_V_Pouch"
];


// TODO: Add actual loadout stuff to force init to?

// Sector defender infantry pool
militia_squad = [
	"UK3CB_MEE_O_SL",												// Sergeant 
	"UK3CB_MEE_O_TL",										// Junior Sergeant 
	"UK3CB_MEE_O_TL",												// Efreitor 
	"UK3CB_MEE_O_RIF_1",												// Rifleman 
	"UK3CB_MEE_O_RIF_1",												// Rifleman 
	"UK3CB_MEE_O_RIF_1",												// Rifleman 
	"UK3CB_MEE_O_RIF_1",												// Rifleman 
	"UK3CB_MEE_O_RIF_1",												// Rifleman 
	"UK3CB_MEE_O_LAT",													// Rifleman w/ RPG-26 
	"UK3CB_MEE_O_LAT",													// Rifleman w/ RPG-26 
	"UK3CB_MEE_O_AT",												// Rifleman w/ RShG2 
	"UK3CB_MEE_O_GL",											// Grenadier w/ GP-25 
	"UK3CB_MEE_O_GL",											// Grenadier w/ GP-25 
	"UK3CB_MEE_O_GL",											// Grenadier w/ GP-25 
	"UK3CB_MEE_O_AR",											// Autorifleman (PKP) 
	"UK3CB_MEE_O_MG",										// Machinegunner 
	"UK3CB_MEE_O_MK",												// Marksman 
	"UK3CB_MEE_O_SPOT",											// Sharpshooter 
	"UK3CB_MEE_O_SNI",												// Sniper 
	"UK3CB_MEE_O_MD",												// Medic 
	"UK3CB_MEE_O_MD",												// Medic 
	"UK3CB_MEE_O_ENG",												// Engineer 
	"UK3CB_MEE_O_ENG",												// Engineer 
	"UK3CB_MEE_O_AT",										// Grenadier w/ RPG-7V2 
	"UK3CB_MEE_O_AT",										// Grenadier w/ RPG-7V2 
	"UK3CB_MEE_O_AT",													// AT Specialist 
	"UK3CB_MEE_O_AA" 													// AA Specialist 
];

// NOTE: Still used for now for Lib config stuff
militia_vehicles = [];
opfor_vehicles = [];
opfor_vehicles_low_intensity = [];
opfor_battlegroup_vehicles_low_intensity = [];
opfor_battlegroup_vehicles = [
	"UK3CB_MEE_O_DSHkM_Mini_TriPod",												// NSV Minitripod
	"UK3CB_MEE_O_KORD",														// KORD Minitripod
	"UK3CB_MEE_O_KORD_high",												// KORD Tripod
	"UK3CB_MEE_O_AGS",												// AGS-30
	"UK3CB_MEE_O_SPG9",													// SPG-9M
	"UK3CB_MEE_O_ZU23",														// ZU-23-2
	"UK3CB_MEE_O_ZU23",
	"UK3CB_MEE_O_D30",											// 9K115-2 Metis-M
	"UK3CB_MEE_O_D30",											// 9M133-2 Kornet-M
	"rhsgref_ins_d30_at",
	"rhsgref_ins_d30_at",
	"UK3CB_MEE_O_2b14_82mm",												// 2B14-1 Podnos
	"UK3CB_MEE_O_Igla_AA_pod",												// 9K38 Djigit
	"UK3CB_MEE_O_Hilux_Open",												// UAZ Open
	"UK3CB_MEE_O_Hilux_Open",                         							// UAZ Covered
	//
	"UK3CB_MEE_O_Hilux_Vulcan_Front",
	"UK3CB_MEE_O_Hilux_Vulcan_Front", 
	"UK3CB_MEE_O_Hilux_Zu23_Front",
	"UK3CB_MEE_O_Hilux_Zu23_Front", 
	"UK3CB_MEE_O_M1025_MK19",
	"UK3CB_MEE_O_M1025_MK19", 
	"UK3CB_MEE_O_M1025_M2",
	"UK3CB_MEE_O_M1025_M2", 
	"UK3CB_MEE_O_M1025_TOW",
	"UK3CB_MEE_O_M1025_TOW",
	//
	"UK3CB_KRG_O_M270_Avenger",
	"UK3CB_KRG_O_M270_Avenger", 
	"UK3CB_MEE_O_MTLB_ZU23",
	"UK3CB_MEE_O_MTLB_ZU23",
	//
	"UK3CB_MEE_O_BTR60",
	"UK3CB_MEE_O_BTR60", 
	"UK3CB_MEE_O_M113tank_MK19_90",
	"UK3CB_MEE_O_M113tank_MK19_90",
	//
	"UK3CB_MEE_O_BMP1",
	"UK3CB_MEE_O_BMP1",  
	"UK3CB_MEE_O_MTLB_BMP",
	"UK3CB_MEE_O_MTLB_BMP", 
	"UK3CB_MEE_O_MTLB_KPVT",
	"UK3CB_MEE_O_MTLB_KPVT", 
	"UK3CB_MEE_O_MTLB_PKT",
	"UK3CB_MEE_O_MTLB_PKT",
	//
	"UK3CB_MEE_O_LR_Closed",                         							// GAZ-233011
	"UK3CB_MEE_O_LR_M2",													// GAZ-233114
	"UK3CB_MEE_O_LR_M2",													// GAZ-233014 (PKM/AGS-30)
	"UK3CB_MEE_O_V3S_Open",                    						// KamAZ-5350 Open
	"UK3CB_MEE_O_V3S_Closed",                    							// KamAZ-5350 Covered
	"UK3CB_ADG_O_Ikarus_ISL",
	"UK3CB_MEE_O_V3S_Reammo",                  							// KamAZ-5350 Ammo
	"UK3CB_MEE_O_V3S_Recovery",                  						// KamAZ-5350 Flatbed
	"UK3CB_MEE_O_V3S_Refuel",                  							// TZ-8-255B1 Fuel
	"UK3CB_MEE_O_V3S_Open",                  							// Ural-4320 Open
	"UK3CB_MEE_O_V3S_Closed",                  								// Ural-4320 Covered
	"UK3CB_MEE_O_V3S_Recovery",                  							// Ural-4320 Repair
	"UK3CB_MEE_O_V3S_Zu23",												// Ural-4320 (ZU-23)
	"UK3CB_MEE_O_Hilux_Rocket_Arty",													// BM-21 Grad
	"UK3CB_MEE_O_BTR60",													// BTR-80
	"UK3CB_MEE_O_Hilux_BMP",													// BTR-80a
	"UK3CB_MEE_O_BMP1",													// BMP-1P
	"UK3CB_MEE_O_BRDM2",													// BMP-2 (1980)
	"UK3CB_MEE_O_BRDM2_ATGM",														// BMP-2 (1986)
	"UK3CB_MEE_O_BRDM2_HQ",                    								// BMP-2D
	"UK3CB_MEE_O_BMP1",													// BMP-2K
	"UK3CB_MEE_O_BMP1",														// BMP-3
	"UK3CB_MEE_O_BMP1",												// BMP-3 (late)
	"UK3CB_MEE_O_BMP1",													// BMP-3M
	"UK3CB_MEE_O_BMP1",													// BMP-3M (Vesna-K/A)
	"UK3CB_MEE_O_BMP1",														// BMD-4
	"UK3CB_MEE_O_BMP1",													// BMD-4M
	"UK3CB_MEE_O_BMP1",													// BMD-4M (A)
	"UK3CB_MEE_O_BMP1",													// 2S25 Sprut
	"UK3CB_MEE_O_Hilux_Vulcan_Front",													// ZSU-23-4V
	"UK3CB_MEE_O_Hilux_Vulcan_Front",													// ZSU-23-4V
	"ZSU-23-4 Shilka",
	"ZSU-23-4 Shilka",
	"UK3CB_MEE_O_T55",														// T-80BV
	"UK3CB_MEE_O_T55",														// T-80BVK
	"UK3CB_MEE_O_T55",														// T-72B3 (2012)
	"UK3CB_MEE_O_T55",														// T-72B3 (2016)
	"UK3CB_MEE_O_T55",															// T-80U
	"UK3CB_MEE_O_T55",														// T-80UK
	"UK3CB_MEE_O_T55",														// T-80UM
	"UK3CB_MEE_O_T55",														// T-90A
	"UK3CB_MEE_O_T55",														// T-90AM
	"UK3CB_KRG_O_M60A3",
	"UK3CB_KRG_O_M60A3",
	"UK3CB_ADA_O_T72BC",
	"UK3CB_ADA_O_T72BC", 
	"UK3CB_ADA_O_T72BB",
	"UK3CB_ADA_O_T72BB", 
	"UK3CB_ADA_O_T72BA",
	"UK3CB_ADA_O_T72BA", 
	"UK3CB_ADA_O_T72BM",
	"UK3CB_ADA_O_T72BM", 
	"UK3CB_ADA_O_T72B",
	"UK3CB_ADA_O_T72B", 
	"UK3CB_ADA_O_T72A",
	"UK3CB_ADA_O_T72A",
	"UK3CB_ADA_O_C130J",
	"UK3CB_ADA_O_C130J",
	"UK3CB_ADA_O_C130J",
	"UK3CB_ADA_O_C130J",
	"UK3CB_ADA_O_UH1H_GUNSHIP",
	"UK3CB_ADA_O_UH1H_GUNSHIP",                                            		// Mi-8T Hip
	"UK3CB_TKA_O_Bell412_Armed",
	"UK3CB_TKA_O_Bell412_Armed",
	"UK3CB_TKA_O_Mi8",                                            		// Mi-8MT Hip
	"UK3CB_TKA_O_Mi8",                                            		// Mi-8AMT Hip
	"UK3CB_TKA_O_Mi8",                                            			// Ka-60 Kasatka
	"UK3CB_TKA_O_Mi8AMTSh",													// Mi-8MTV3 Hip (S-8 x4)
	"UK3CB_TKA_O_Mi8AMTSh",												// Mi-8AMTSh Hip (S-8 x6)
    "UK3CB_TKA_O_Mi_24P",                                                	// Mi-24P Hind
	"UK3CB_TKA_O_Mi_24P",
    "UK3CB_TKA_O_Mi_24V", 	                                                // Mi-24V Hind
	"UK3CB_TKA_O_Mi_24V",													// Mi-28N Havoc
	"UK3CB_TKA_O_Cessna_T41_Armed",
	"UK3CB_TKA_O_Cessna_T41_Armed",													// Su-25SM Frogfoot
	"UK3CB_TKA_O_MIG21_CAS",												// T-50 obr. 2011
	"UK3CB_TKA_O_MIG21_CAS",											// T-50 obr. 2013
	"UK3CB_TKA_O_MIG21_CAS",													// MiG-29S Fulcrum
	"UK3CB_TKA_O_MIG21_CAS",													// MiG-29SM Fulcrum
	"UK3CB_TKA_O_MIG21_CAS",
	"UK3CB_TKA_O_Su25SM_Cluster",
	"UK3CB_TKA_O_Su25SM_Cluster",                                            	// Tu-95 Bear
	"UK3CB_KRG_O_M109",
	"UK3CB_KRG_O_M109",
	"UK3CB_MEE_O_Hilux_Mortar",
	"UK3CB_MEE_O_Hilux_Mortar",
	"rhs_2s3_tv",
	"rhs_2s3_tv",
	"karmakut_9s32",													// 9S32 Radar
	"karmakut_sa6",														// SA-6 Gainful
	"karmakut_sa15",													// SA-15 Gauntlet
	"karmakut_sa20"													// SA-20 Gargoyle

];

// TODO: Utilize these arrays and add to the overall KPLIB config that it needs
// KPLIB_o_allVeh_classes
// KPLIB_allLandVeh_classes
opfor_tanks = [
	[0,
		[
			"UK3CB_MEE_O_T55"															// T-80BV
		]	
	],	
	[40, 	
		[	
			"UK3CB_MEE_O_T55",													// 2S25 Sprut
			"UK3CB_MEE_O_T55",														// T-80BV
			"UK3CB_MEE_O_T55",														// T-80BV
			"UK3CB_MEE_O_T55",														// T-80BVK
			"UK3CB_MEE_O_T55",														// T-80BVK
			"UK3CB_KRG_O_M60A3"														// T-72B3 (2012)
		]	
	],	
	[80,	
		[	
			"UK3CB_MEE_O_T55",													// 2S25 Sprut
			"UK3CB_MEE_O_T55",													// 2S25 Sprut
			"UK3CB_MEE_O_T55",														// T-80BV
			"UK3CB_MEE_O_T55",														// T-80BVK
			"UK3CB_MEE_O_T55",														// T-72B3 (2012)
			"UK3CB_MEE_O_T55",														// T-72B3 (2012)
			"UK3CB_MEE_O_T55",														// T-72B3 (2016)
			"UK3CB_MEE_O_T55",														// T-72B3 (2016)
			"UK3CB_KRG_O_M60A3",															// T-80U
			"UK3CB_KRG_O_M60A3",														// T-80UK
			"UK3CB_KRG_O_M60A3",														// T-80UK
			"UK3CB_KRG_O_M60A3",														// T-80UM
			"UK3CB_KRG_O_M60A3",															// T-80UM
			"UK3CB_ADA_O_T72BC",
			"UK3CB_ADA_O_T72BC", 
			"UK3CB_ADA_O_T72BB",
			"UK3CB_ADA_O_T72BB", 
			"UK3CB_ADA_O_T72BA",
			"UK3CB_ADA_O_T72BA", 
			"UK3CB_ADA_O_T72BM",
			"UK3CB_ADA_O_T72BM", 
			"UK3CB_ADA_O_T72B",
			"UK3CB_ADA_O_T72B", 
			"UK3CB_ADA_O_T72A",
			"UK3CB_ADA_O_T72A"

		]	
	],	
	[120,	
		[	
			"UK3CB_MEE_O_T55",													// 2S25 Sprut
			"UK3CB_MEE_O_T55",													// 2S25 Sprut
			"UK3CB_MEE_O_T55",													// 2S25 Sprut
			"UK3CB_MEE_O_T55",														// T-80BV
			"UK3CB_MEE_O_T55",														// T-80BVK
			"UK3CB_MEE_O_T55",														// T-72B3 (2012)
			"UK3CB_KRG_O_M60A3",														// T-72B3 (2012)
			"UK3CB_KRG_O_M60A3",														// T-72B3 (2016)
			"UK3CB_KRG_O_M60A3",														// T-72B3 (2016)
			"UK3CB_KRG_O_M60A3",															// T-80U
			"UK3CB_KRG_O_M60A3",														// T-80UK
			"UK3CB_KRG_O_M60A3",														// T-80UK
			"UK3CB_KRG_O_M60A3",														// T-80UM
			"UK3CB_KRG_O_M60A3",														// T-80UM
			"UK3CB_ADA_O_T72BC",
			"UK3CB_ADA_O_T72BC", 
			"UK3CB_ADA_O_T72BB",
			"UK3CB_ADA_O_T72BB", 
			"UK3CB_ADA_O_T72BA",
			"UK3CB_ADA_O_T72BA", 
			"UK3CB_ADA_O_T72BM",
			"UK3CB_ADA_O_T72BM", 
			"UK3CB_ADA_O_T72B",
			"UK3CB_ADA_O_T72B", 
			"UK3CB_ADA_O_T72A",
			"UK3CB_ADA_O_T72A"														// T-90A
		]	
	]	
];	
// Vehicles considered Anti-Air (Only high readiness)	
opfor_sams = [	
	[0,	
		[	
			"UK3CB_MEE_O_Hilux_Zu23_Front"												// Ural (ZU-23)
		]	
	],	
	[60, 	
		[	
			"UK3CB_MEE_O_Hilux_Zu23_Front",												// Ural (ZU-23)
			"UK3CB_MEE_O_Hilux_Zu23_Front",												// Ural (ZU-23)
			"UK3CB_KRG_O_M270_Avenger",												// Ural (ZU-23)
			"UK3CB_KRG_O_M270_Avenger",												// Ural (ZU-23)
			"UK3CB_MEE_O_Hilux_Vulcan_Front"														// ZSU-23-4V
		]	
	],	
	[120, 	
		[	
			"UK3CB_MEE_O_Hilux_Zu23_Front",												// Ural (ZU-23)
			"UK3CB_KRG_O_M270_Avenger",												// Ural (ZU-23)
			"UK3CB_KRG_O_M270_Avenger",													// ZSU-23-4V
			"UK3CB_MEE_O_Hilux_Vulcan_Front",													// ZSU-23-4V
			"UK3CB_MEE_O_Hilux_Vulcan_Front"														// ZSU-23-4V
		]
	]
];
// Vehicles considered IFVs (APCs with an autocannon)
opfor_ifvs = [
	[0,
		[
			"UK3CB_MEE_O_BTR60",													// BTR-80a
			"UK3CB_MEE_O_BTR60"													// BTR-80a														// BMP-2 (1980)
		]
	],
	[40,
		[
			"UK3CB_MEE_O_BMP1",
			"UK3CB_MEE_O_BMP1",  
			"UK3CB_MEE_O_MTLB_BMP",
			"UK3CB_MEE_O_MTLB_BMP", 
			"UK3CB_MEE_O_MTLB_KPVT",
			"UK3CB_MEE_O_MTLB_KPVT", 
			"UK3CB_MEE_O_MTLB_PKT",
			"UK3CB_MEE_O_MTLB_PKT"														// BMP-3
		]
	],
	[80,
		[
			"UK3CB_MEE_O_BMP1",
			"UK3CB_MEE_O_BMP1",  
			"UK3CB_MEE_O_MTLB_BMP",
			"UK3CB_MEE_O_MTLB_BMP", 
			"UK3CB_MEE_O_MTLB_KPVT",
			"UK3CB_MEE_O_MTLB_KPVT", 
			"UK3CB_MEE_O_MTLB_PKT",
			"UK3CB_MEE_O_MTLB_PKT"														// BMD-4M
		]
	],
	[120, 
		[
			"UK3CB_MEE_O_BMP1",
			"UK3CB_MEE_O_BMP1",  
			"UK3CB_MEE_O_MTLB_BMP",
			"UK3CB_MEE_O_MTLB_BMP", 
			"UK3CB_MEE_O_MTLB_KPVT",
			"UK3CB_MEE_O_MTLB_KPVT", 
			"UK3CB_MEE_O_MTLB_PKT",
			"UK3CB_MEE_O_MTLB_PKT"													// BMD-4M (A)
		]
	]
];
// Vehicles considered APCs (machineguns)
opfor_apcs = [
	[0,
		[
			"UK3CB_MEE_O_BTR60"														// BTR-80
		]
	]
];
// Vehicles considered pure troop transport
opfor_transports = [
	[0,
		[
			"UK3CB_ADG_O_Ikarus_ISL",
			"UK3CB_MEE_O_V3S_Open",                  							// Ural-4320 Open
			"UK3CB_MEE_O_V3S_Closed"                  									// Ural-4320 Covered
		]
	],
	[75, 
		[
			"UK3CB_ADG_O_Ikarus_ISL",
			"UK3CB_ADG_O_Ikarus_ISL",
			"UK3CB_MEE_O_V3S_Open",                  							// Ural-4320 Open
			"UK3CB_MEE_O_V3S_Closed",                  								// Ural-4320 Covered
			"UK3CB_MEE_O_V3S_Open",                    						// KamAZ-5350 Open
			"UK3CB_MEE_O_V3S_Open",                    						// KamAZ-5350 Open
			"UK3CB_MEE_O_V3S_Open",                    						// KamAZ-5350 Open
			"UK3CB_MEE_O_V3S_Closed",	                    						// KamAZ-5350 Covered
			"UK3CB_MEE_O_V3S_Closed",	                    						// KamAZ-5350 Covered
			"UK3CB_MEE_O_V3S_Closed",	                    						// KamAZ-5350 Covered
			"UK3CB_MEE_O_V3S_Closed"	                    							// KamAZ-5350 Covered
		]
	]
];
// Vehicles considered scout cars
opfor_scout_cars = [
	[0,
		[
			"UK3CB_MEE_O_Hilux_Vulcan_Front",
			"UK3CB_MEE_O_Hilux_Vulcan_Front", 
			"UK3CB_MEE_O_Hilux_Zu23_Front",
			"UK3CB_MEE_O_Hilux_Zu23_Front", 
			"UK3CB_MEE_O_M1025_MK19",
			"UK3CB_MEE_O_M1025_MK19", 
			"UK3CB_MEE_O_M1025_M2",
			"UK3CB_MEE_O_M1025_M2", 
			"UK3CB_MEE_O_M1025_TOW",
			"UK3CB_MEE_O_M1025_TOW"													// GAZ-233114
		]
	],
	[60, 
		[
			"UK3CB_MEE_O_Hilux_Vulcan_Front",
			"UK3CB_MEE_O_Hilux_Vulcan_Front", 
			"UK3CB_MEE_O_Hilux_Zu23_Front",
			"UK3CB_MEE_O_Hilux_Zu23_Front", 
			"UK3CB_MEE_O_M1025_MK19",
			"UK3CB_MEE_O_M1025_MK19", 
			"UK3CB_MEE_O_M1025_M2",
			"UK3CB_MEE_O_M1025_M2", 
			"UK3CB_MEE_O_M1025_TOW",
			"UK3CB_MEE_O_M1025_TOW"													// GAZ-233014 (PKM/AGS-30)
		]
	]
];

opfor_halo_air = [
	[0,
		[
			"UK3CB_ADA_O_C130J",
			"UK3CB_ADA_O_C130J",
			"UK3CB_ADA_O_C130J",
			"UK3CB_ADA_O_C130J",                                            		// Mi-8MT Hip
			"UK3CB_TKA_O_Mi8",                                            		// Mi-8AMT Hip
			"UK3CB_TKA_O_Mi8",                                            			// Ka-60 Kasatka
			"UK3CB_TKA_O_Mi8AMTSh",													// Mi-8MTV3 Hip (S-8 x4)
			"UK3CB_TKA_O_Mi8AMTSh",												// Mi-8AMTSh Hip (S-8 x6)
			"UK3CB_TKA_O_Mi_24P",                                                	// Mi-24P Hind
			"UK3CB_TKA_O_Mi_24P"                                          			// Ka-60 Kasatka
		]
	]
];

// Map from category name to the spawn info
compositionEnumToClassNames = {
	params ["_enum"];

	switch (_enum) do
	{
		case "Tanks": {opfor_tanks};
		case "AA": {opfor_sams};
		case "IFV": {opfor_ifvs};
		case "APC": {opfor_apcs};
		case "Transport": {opfor_transports};
		case "Scouts": {opfor_scout_cars};
	}
};

// These categories will be considered infantry transport and will attempt to fill empty cargo spots with infantry.
compositionEnumIsInfantryTransport = {
	params ["_enum"];
	
	switch (_enum) do
	{
		case "Tanks": {false};
		case "AA": {false};
		case "IFV": {true};
		case "APC": {true};
		case "Transport": {true};
		case "Scouts": {true}; // Scout cars don't hold enough capacity to spawn any crew
		default {false};
	}
};
// These categories will be considered pure transport and the crew will dismount and join with the infantry
compositionEnumWouldDismountTransport = {
	params ["_enum"];

	switch (_enum) do
	{
		case "Tanks": {false};
		case "AA": {false};
		case "IFV": {false};
		case "APC": {false};
		case "Transport": {true};
		case "Scouts": {false};
		default {false};
	}
};
// These categories will prevent from driving around as just a driver without other crew members in the gunner / commander, etc.. seats.
compositionEnumPreventsSingleDriver = {
	params ["_enum"];

	switch (_enum) do
	{
		case "Tanks": {true};
		case "AA": {true};
		case "IFV": {true};
		case "APC": {true};
		case "Transport": {false};
		case "Scouts": {true};
		default {false};
	}
};


// First array is a number that signifies the combat readiness level that must be reached to utilize the composition
// Largest one will be used
// i.e. [10, 20, 30, 40] at alertness 50 will use the composition defined in 40
// The composition should add up to 1 unless you want more stuff to spawn in specific brackets than the calculated battlegroup size or less stuff to spawn
// The numbers inside signify the RATIO of that specific type (rounded)
// It will use the actual battlegroup calculated number * the ratio for what will appear
// This ensures it still follows the scaling amount but the composition will be adjusted properly.
// There's also support for min or max to ensure something will always spawn, or to ensure something doesn't spawn too much
// If min or max is set to 0, it means its ignored and there will be no min or cap for that category.
// Ceil means that the category will ceil up instead of rounding.
opfor_mechanized_battlegroup_compositions = [
	[0, 
		createHashMapFromArray [
			["Tanks", 
				createHashMapFromArray [
					["Ratio", 0.1],
					["Max", 2],
					["Min", 0]
				]
			],
			["AA",
				createHashMapFromArray [
					["Ratio", 0.1],
					["Max", 1],
					["Min", 0]
				]
			],
			["IFV",
				createHashMapFromArray [
					["Ratio", 0.2],
					["Max", 2],
					["Min", 1]
				]
			],
			["APC",
				createHashMapFromArray [
					["Ratio", 0.3],
					["Max", 3],
					["Min", 1]
				]
			],
			["Transport",
				createHashMapFromArray [
					["Ratio", 0.3],
					["Max", 0],
					["Min", 1]
				]
			],
			["Scouts",
				createHashMapFromArray [
					["Ratio", 0.1],
					["Max", 0],
					["Min", 1]
				]
			]
		]
	],
	[40,
		createHashMapFromArray [
			["Tanks", 
				createHashMapFromArray [
					["Ratio", 0.1],
					["Max", 2],
					["Min", 0]
				]
			],
			["AA",
				createHashMapFromArray [
					["Ratio", 0.1],
					["Max", 1],
					["Min", 0]
				]
			],
			["IFV",
				createHashMapFromArray [
					["Ratio", 0.3],
					["Max", 3],
					["Min", 1]
				]
			],
			["APC",
				createHashMapFromArray [
					["Ratio", 0.2],
					["Max", 3],
					["Min", 1]
				]
			],
			["Transport",
				createHashMapFromArray [
					["Ratio", 0.2],
					["Max", 0],
					["Min", 1]
				]
			],
			["Scouts",
				createHashMapFromArray [
					["Ratio", 0.1],
					["Max", 0],
					["Min", 1]
				]
			]
		]
	],
	[80,
		createHashMapFromArray [
			["Tanks", 
				createHashMapFromArray [
					["Ratio", 0.2],
					["Max", 3],
					["Min", 1]
				]
			],
			["AA",
				createHashMapFromArray [
					["Ratio", 0.1],
					["Max", 1],
					["Min", 0]
				]
			],
			["IFV",
				createHashMapFromArray [
					["Ratio", 0.45],
					["Max", 3],
					["Min", 0]
				]
			],
			["APC",
				createHashMapFromArray [
					["Ratio", 0.15],
					["Max", 3],
					["Min", 1]
				]
			],
			["Transport",
				createHashMapFromArray [
					["Ratio", 0.1],
					["Max", 0],
					["Min", 1]
				]
			],
			["Scouts",
				createHashMapFromArray [
					["Ratio", 0.1],
					["Max", 0],
					["Min", 0]
				]
			]
		]
	],
	[120,
		createHashMapFromArray [
			["Tanks", 
				createHashMapFromArray [
					["Ratio", 0.35],
					["Max", 4],
					["Min", 1]
				]
			],
			["AA",
				createHashMapFromArray [
					["Ratio", 0.1],
					["Max", 2],
					["Min", 0]
				]
			],
			["IFV",
				createHashMapFromArray [
					["Ratio", 0.45],
					["Max", 4],
					["Min", 1]
				]
			],
			["APC",
				createHashMapFromArray [
					["Ratio", 0.25],
					["Max", 3],
					["Min", 0]
				]
			],
			["Transport",
				createHashMapFromArray [
					["Ratio", 0],
					["Max", 0],
					["Min", 0]
				]
			],
			["Scouts",
				createHashMapFromArray [
					["Ratio", 0.05],
					["Max", 0],
					["Min", 0]
				]
			]
		]
	]
];

opfor_motorized_battlegroup_compositions = [
	[0, 
		createHashMapFromArray [
			["Tanks", 
				createHashMapFromArray [
					["Ratio", 0],
					["Max", 0],
					["Min", 0]
				]
			],
			["AA",
				createHashMapFromArray [
					["Ratio", 0.1],
					["Max", 1],
					["Min", 0]
				]
			],
			["IFV",
				createHashMapFromArray [
					["Ratio", 0],
					["Max", 0],
					["Min", 0]
				]
			],
			["APC",
				createHashMapFromArray [
					["Ratio", 0.3],
					["Max", 4],
					["Min", 1]
				]
			],
			["Transport",
				createHashMapFromArray [
					["Ratio", 0.4],
					["Max", 0],
					["Min", 1]
				]
			],
			["Scouts",
				createHashMapFromArray [
					["Ratio", 0.3],
					["Max", 0],
					["Min", 1]
				]
			]
		]
	],
	[40,
		createHashMapFromArray [
			["Tanks", 
				createHashMapFromArray [
					["Ratio", 0],
					["Max", 0],
					["Min", 0]
				]
			],
			["AA",
				createHashMapFromArray [
					["Ratio", 0.1],
					["Max", 1],
					["Min", 0]
				]
			],
			["IFV",
				createHashMapFromArray [
					["Ratio", 0],
					["Max", 0],
					["Min", 0]
				]
			],
			["APC",
				createHashMapFromArray [
					["Ratio", 0.3],
					["Max", 4],
					["Min", 1]
				]
			],
			["Transport",
				createHashMapFromArray [
					["Ratio", 0.5],
					["Max", 0],
					["Min", 1]
				]
			],
			["Scouts",
				createHashMapFromArray [
					["Ratio", 0.2],
					["Max", 0],
					["Min", 1]
				]
			]
		]
	],
	[80,
		createHashMapFromArray [
			["Tanks", 
				createHashMapFromArray [
					["Ratio", 0],
					["Max", 0],
					["Min", 0]
				]
			],
			["AA",
				createHashMapFromArray [
					["Ratio", 0.1],
					["Max", 2],
					["Min", 0]
				]
			],
			["IFV",
				createHashMapFromArray [
					["Ratio", 0.1],
					["Max", 2],
					["Min", 0]
				]
			],
			["APC",
				createHashMapFromArray [
					["Ratio", 0.4],
					["Max", 4],
					["Min", 1]
				]
			],
			["Transport",
				createHashMapFromArray [
					["Ratio", 0.5],
					["Max", 0],
					["Min", 1]
				]
			],
			["Scouts",
				createHashMapFromArray [
					["Ratio", 0.1],
					["Max", 0],
					["Min", 0]
				]
			]
		]
	],
	[120,
		createHashMapFromArray [
			["Tanks", 
				createHashMapFromArray [
					["Ratio", 0.05],
					["Max", 1],
					["Min", 0]
				]
			],
			["AA",
				createHashMapFromArray [
					["Ratio", 0.1],
					["Max", 2],
					["Min", 0]
				]
			],
			["IFV",
				createHashMapFromArray [
					["Ratio", 0.25],
					["Max", 3],
					["Min", 1]
				]
			],
			["APC",
				createHashMapFromArray [
					["Ratio", 0.5],
					["Max", 5],
					["Min", 1]
				]
			],
			["Transport",
				createHashMapFromArray [
					["Ratio", 0.35],
					["Max", 0],
					["Min", 0]
				]
			],
			["Scouts",
				createHashMapFromArray [
					["Ratio", 0.05],
					["Max", 0],
					["Min", 0]
				]
			]
		]
	]
];

// Deprecated funtion (?)
opfor_troup_transports = [];

// Enemy rotary-wings that will need to spawn in flight.
opfor_choppers = [
	
];

// Enemy fixed-wings that will need to spawn in the air.
opfor_air = [
	"UK3CB_ADA_O_C130J",
	"UK3CB_ADA_O_C130J",
	"UK3CB_ADA_O_C130J",
	"UK3CB_ADA_O_C130J",                                            		// Mi-8MT Hip
	"UK3CB_TKA_O_Mi8",                                            		// Mi-8AMT Hip
	"UK3CB_TKA_O_Mi8",                                            			// Ka-60 Kasatka
	"UK3CB_TKA_O_Mi8AMTSh",													// Mi-8MTV3 Hip (S-8 x4)
	"UK3CB_TKA_O_Mi8AMTSh",												// Mi-8AMTSh Hip (S-8 x6)
	"UK3CB_TKA_O_Mi_24P",                                                	// Mi-24P Hind
	"UK3CB_TKA_O_Mi_24P"
];

opfor_cap = [
	"UK3CB_TKA_O_MIG21_CAS",												// T-50 obr. 2011
	"UK3CB_TKA_O_Su25SM_Cluster",
	"UK3CB_TKA_O_MIG21_CAS",													// MiG-29S Fulcrum
	"UK3CB_TKA_O_Su25SM_Cluster",
	"UK3CB_TKA_O_MIG21_CAS"													// MiG-29SM Fulcrum
];

// TODO: Move to own file
// There will be one infantry spawning for every X players
// Infantry spawn using the opfor_at, opfor_aa etc.
BATTLESPACE_DEFENDERS_INFANTRY_RATIO = 1 / 2; // Flip to mean X infantry for every one player(s)
// There will be one vehicle for every X players 
BATTLESPACE_DEFENDERS_VEHICLE_RATIO = 18;
// There will be one static for every X players
BATTLESPACE_DEFENDERS_STATICS_RATIO = 10;

BATTLESPACE_DEFENDERS_MECHANIZED_PATROL_DEFS = [
	[
		["UK3CB_MEE_O_M1025_MK19"],
		BATTLESPACE_SQUAD_SIZE
	],
	[
		["UK3CB_MEE_O_M1025_MK19","UK3CB_MEE_O_M1025_MK19"],
		BATTLESPACE_SQUAD_SIZE
	],
	[
		["UK3CB_MEE_O_M1025_M2","UK3CB_MEE_O_M1025_MK19"],
		BATTLESPACE_SQUAD_SIZE
	],
	[
		["UK3CB_MEE_O_M1025_MK19","UK3CB_MEE_O_M1025_M2"],
		BATTLESPACE_SQUAD_SIZE
	],
	[
		["UK3CB_MEE_O_M1025_MK19"],
		BATTLESPACE_SQUAD_SIZE * 2
	],
	[
		["UK3CB_MEE_O_M1025_M2"],
		BATTLESPACE_SQUAD_SIZE
	],
	[
		["UK3CB_MEE_O_M1025_M2","UK3CB_MEE_O_M1025_M2"],
		BATTLESPACE_SQUAD_SIZE
	],
	[
		["UK3CB_MEE_O_M1025_M2"],
		BATTLESPACE_SQUAD_SIZE * 2
	],
	[
		["ZSU-23-4 Shilka"],
		BATTLESPACE_SQUAD_SIZE
	],
	[
		["ZSU-23-4 Shilka","ZSU-23-4 Shilka"],
		BATTLESPACE_SQUAD_SIZE
	],
	[
		["ZSU-23-4 Shilka"],
		BATTLESPACE_SQUAD_SIZE * 2
	],
	[
		["UK3CB_MEE_O_BMP1"],
		BATTLESPACE_SQUAD_SIZE
	],
	[
		["UK3CB_MEE_O_BMP1","UK3CB_MEE_O_BMP1"],
		BATTLESPACE_SQUAD_SIZE
	],
	[
		["UK3CB_MEE_O_BMP1"],
		BATTLESPACE_SQUAD_SIZE * 2
	],
	[
		["UK3CB_KRG_O_M270_Avenger"],
		BATTLESPACE_SQUAD_SIZE
	],
	[
		["UK3CB_KRG_O_M270_Avenger","UK3CB_KRG_O_M270_Avenger"],
		BATTLESPACE_SQUAD_SIZE
	],
	[
		["UK3CB_KRG_O_M270_Avenger"],
		BATTLESPACE_SQUAD_SIZE * 2
	],
	[
		["UK3CB_MEE_O_Hilux_Zu23_Front"],
		BATTLESPACE_SQUAD_SIZE
	],
	[
		["UK3CB_MEE_O_Hilux_Zu23_Front","UK3CB_MEE_O_Hilux_Zu23_Front"],
		BATTLESPACE_SQUAD_SIZE
	],
	[
		["UK3CB_MEE_O_Hilux_Zu23_Front"],
		BATTLESPACE_SQUAD_SIZE * 2
	],
	[
		["UK3CB_KRG_O_M60A3"],
		BATTLESPACE_SQUAD_SIZE
	],
	[
		["UK3CB_MEE_O_M113tank_MK19_90"],
		BATTLESPACE_SQUAD_SIZE
	],
	[
		["UK3CB_MEE_O_M113tank_MK19_90","UK3CB_MEE_O_M113tank_MK19_90"],
		BATTLESPACE_SQUAD_SIZE
	],
	[
		["UK3CB_MEE_O_M113tank_MK19_90"],
		BATTLESPACE_SQUAD_SIZE * 2
	]
];

// Return [infantrySquadCount, staticCount]
BATTLESPACE_DEFENDERS_SECTOR_SCALING = {
	params ["_sector"];

	private _numberOfPlayers = ([] call KPLIB_fnc_getPlayerCount);
	private _numberOfStatics = floor(_numberOfPlayers / BATTLESPACE_DEFENDERS_STATICS_RATIO);
	private _numberOfInfantry = floor(_numberOfPlayers / BATTLESPACE_DEFENDERS_INFANTRY_RATIO);

	private _staticCount = _numberOfStatics;
	private _squadCount = round(_numberOfInfantry / BATTLESPACE_SQUAD_SIZE);

	// Size calculations (Statics: 1 per 10 players, Infantry: 2 per 1 players, Squads: 10 per):
	// 10 players, statics 1, squads 2
	// 20 players, statics 2, squads 4
	// 30 players, statics 3, squads 5
	// 50 players, statics 5, squads 9
	// 75 players, statics 7, squads 13
	// 100 players, statics 10, squads 18

	// Sector scaling, ensure minimum/maximum bounds to maintain challenge while accomodating for possible nearby points

	// Small-scale residential, of least strategic value to OPFOR
	if(_sector in sectors_capture) then {
		_squadCount = 8 max _squadCount;
		_squadCount = 11 min _squadCount;
		_staticCount = 6 min _staticCount;
	};

	// Production points, kept under baseline military protection
	if(_sector in sectors_factory) then {
		_squadCount = 9 max _squadCount;
		_squadCount = 12 min _squadCount;
		_staticCount = 6 max _staticCount;
		_staticCount = 5 min _staticCount;
	};

	// Communication hub, defended with garrison
	if(_sector in sectors_tower) then {
		_squadCount = 10 max _squadCount;
		_squadCount = 13 min _squadCount;
		_staticCount = 2 max _staticCount;
		_staticCount = 6 min _staticCount;
	};

	// Military points should be quite tough for lower player counts but possible with good coordination
	if(_sector in sectors_military) then {
		_squadCount = 10 max _squadCount;
		_squadCount = 14 min _squadCount;
		_staticCount = 7 max _staticCount; // Always see some statics, no max
	};

	// Big towns should be basically impossible for lower player counts
	if(_sector in sectors_bigtown) then {
		_squadCount = 11 max _squadCount;
		_squadCount = 15 min _squadCount;
		_staticCount = 4 max _staticCount; // Always see some statics, no max
	};

	[_squadCount, _staticCount]
};


BATTLESPACE_DEFENDERS_VEHICLE_CLASSES = [
	"UK3CB_MEE_O_Hilux_Vulcan_Front",
	"UK3CB_MEE_O_Hilux_Vulcan_Front",  
	"UK3CB_MEE_O_M1025_MK19",
	"UK3CB_MEE_O_M1025_MK19", 
	"UK3CB_MEE_O_M1025_M2",
	"UK3CB_MEE_O_M1025_M2", 
	"UK3CB_MEE_O_M1025_TOW",
	"UK3CB_MEE_O_M1025_TOW",
	//
	"UK3CB_KRG_O_M270_Avenger",
	"UK3CB_KRG_O_M270_Avenger", 
	"UK3CB_MEE_O_MTLB_ZU23",
	"UK3CB_MEE_O_MTLB_ZU23",
	// 
	"UK3CB_MEE_O_M113tank_MK19_90",
	"UK3CB_MEE_O_M113tank_MK19_90",
	//
	"UK3CB_MEE_O_BMP1",
	"UK3CB_MEE_O_BMP1",
	"UK3CB_KRG_O_M60A3",
	"UK3CB_KRG_O_M60A3",
	"ZSU-23-4 Shilka",
	"ZSU-23-4 Shilka",
	"UK3CB_MEE_O_MTLB_BMP",
	"UK3CB_MEE_O_MTLB_BMP", 
	"UK3CB_MEE_O_MTLB_KPVT",
	"UK3CB_MEE_O_MTLB_KPVT", 
	"UK3CB_MEE_O_MTLB_PKT",
	"UK3CB_MEE_O_MTLB_PKT"
];
BATTLESPACE_DEFENDERS_STATIC_CLASSES = [
	"UK3CB_MEE_O_DSHkM_Mini_TriPod",												// NSV Minitripod
	"UK3CB_MEE_O_DSHkM_Mini_TriPod",												// NSV Minitripod
	"UK3CB_MEE_O_KORD",														// KORD Minitripod
	"UK3CB_MEE_O_KORD",														// KORD Minitripod
	"UK3CB_MEE_O_KORD_high",												// KORD Tripod
	"UK3CB_MEE_O_KORD_high",												// KORD Tripod
	"UK3CB_MEE_O_AGS",												// AGS-30
	"UK3CB_MEE_O_AGS",												// AGS-30
	"UK3CB_MEE_O_AGS",												// AGS-30
	"UK3CB_MEE_O_AGS",												// AGS-30
	"UK3CB_MEE_O_AGS",												// AGS-30
	"UK3CB_MEE_O_AGS",												// AGS-30
	"UK3CB_MEE_O_ZU23",														// ZU-23-2
	"UK3CB_MEE_O_ZU23",														// ZU-23-2
	"UK3CB_MEE_O_ZU23",														// ZU-23-2
	"rhsgref_ins_d30_at",
	"rhsgref_ins_d30_at",
	"UK3CB_MEE_O_Igla_AA_pod",												// 9K38 Djigit
	"UK3CB_MEE_O_Igla_AA_pod"
];

// https://community.bistudio.com/wiki/selectBestPlaces
BATTLESPACE_DEFENDERS_STATIC_EXPRESSIONS = [
	"(2 * hills) - (4 * sea) - meadow + houses",
	"(4 * houses) - (4 * sea) - (2 * meadow)",
	"hills + (2 * houses) - (4 * sea) - (2 * meadow)",
	"forest + trees - (4 * sea) - meadow",
	"trees + meadow - (4 * sea)",
	"hills + (2 * trees) - (4 * sea) - (2 * meadow)",
	"hills + forest + (2 * trees) - (4 * sea) - (3 * meadow)",	
	"(2 * houses) + forest + trees - (4 * sea) - (4 * meadow)"
];

BATTLESPACE_MORTAR_OVERRIDE_EXPRESSIONS = [
	"(4 * houses) - (4 * sea) - meadow - hills",
	"(2 * forest) + (2 * trees) - (4 * meadow) - (4 * sea)",
	"(2 * houses) + (2 * trees) - (4 * meadow) - (4 * sea)"
];


// TODO: Move mortar stuff it to its own file eventually
BATTLESPACE_MORTARS = [
	"UK3CB_MEE_O_Hilux_Mortar",
	"UK3CB_MEE_O_2b14_82mm",
	"rhs_2s3_tv"												// 2B14-1 Podnos
];

BATTLESPACE_BLACKLIST_MORTAR_FROM_HC = {
	params ["_mortar"];

	_mortar setVariable ["acex_headless_blacklist", true, true];
	{
		_x setVariable ["acex_headless_blacklist", true, true];
	} forEach (crew _mortar);

	(group _mortar) setVariable ["acex_headless_blacklist", true, true];

};

{
	[
		_x,
		"init",
		{
			[(_this#0)] call BATTLESPACE_BLACKLIST_MORTAR_FROM_HC
		},
		true,
		[],
		true
	] call CBA_fnc_addClassEventHandler;
} forEach BATTLESPACE_MORTARS;
