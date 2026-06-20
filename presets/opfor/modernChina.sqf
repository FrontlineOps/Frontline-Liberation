// If changing opfor factions change these:
// presets\init_presets.sqf

// Enemy infantry classes
opfor_officer = "PLA_Soldier_OF_F";                          // Officer 
opfor_squad_leader = "PLA_Soldier_SL_F";                     // Sergeant 
opfor_team_leader = "PLA_Soldier_TL_F";                    		// Junior Sergeant 
opfor_sentry = "PLA_Soldier_AT_HJ12";                            // Efreitor 
opfor_rifleman = "PLA_Soldier_F";                            // Rifleman 
opfor_rpg = "PLA_Soldier_AT89B_F";                                // Rifleman w/ RPG-26 
opfor_grenadier = "PLA_Soldier_GL_F";                            	// Grenadier w/ GP-25 
opfor_machinegunner = "PLA_Soldier_MG_F";				// Autorifleman (PKP)
opfor_heavygunner = "PLA_Soldier_HMG_F";                 // Machinegunner 
opfor_marksman = "PLA_Soldier_LR_F";                              	// Marksman 
opfor_sharpshooter = "PLA_Soldier_mk_F";                           // Sharpshooter 
opfor_sniper = "PLA_Soldier_QL";                                	// Sniper 
opfor_at = "PLA_Soldier_QL";                                // AT Specialist 
opfor_aa = "PLA_Soldier_AA_F";                               	// AA Specialist 
opfor_medic = "PLA_Soldier_medic_F";                                    	// Medic 
opfor_engineer = "VME_PLA_soldier_UAV";                              // Engineer 
opfor_paratrooper = "PLA_Soldier_GLA_F";						// Rifleman w/ RShG2 
opfor_rto = "VME_PLA_soldier_UAV";									// Officer (Armored) EMR

// From exported arsenal
opfor_rto_loadout = [["vme_pla_qbz95_1","","","",["VME_QBZ95_1_30Rnd_DBP10",30],[],""],[],[],["PLA_CombatUniform_SBCB",[["FirstAidKit",1],["VME_QBZ95_1_30Rnd_DBP10",3,30],["SmokeShell",1,1]]],["PLA_B04_RF",[["VME_QBZ95_1_30Rnd_DBP10",4,30],["VME_QBZ95_1_30Rnd_DBP10_Tracer_Green",3,30],["SmokeShell",1,1],["HandGrenade",2,1],["Chemlight_green",2,1]]],["TFAR_rt1523g_bwmod",[]],"VME_PLA_Helmet","G_Sport_Blackyellow",[],["ItemMap","PLA_UavTerminal","ItemRadio","ItemCompass","Itemwatch","NVGoggles_INDEP"]],[["ace_arsenal_face","Default"]];

// Enemy vehicles used by secondary objectives.
opfor_mrap = "vme_WZ551";                                 // GAZ-233011
opfor_mrap_armed = "VME_PLA_EQ2050_reconGL";                    // GAZ-233014 (Armed)
opfor_transport_helo = "VME_PLA_Mi171";                    // Mi-8MT (Cargo)
opfor_transport_truck = "VME_PLA_SX2190";                // KamAZ-5350 (Covered)
opfor_ammobox_transport = "VME_PLA_SX2190_Ammo";                   // KamAZ-5350 Flatbed
opfor_fuel_truck = "VME_PLA_SX2190_Fuel";                             // TZ-8-255B1 (Fuel)
opfor_ammo_truck = "VME_PLA_SX2190_Repair";                             // KamAZ-5350 (Ammo)
opfor_fuel_container = "B_Slingload_01_Fuel_F";             			// HURON Fuel
opfor_ammo_container = "B_Slingload_01_Ammo_F";             			// HURON Ammo
opfor_flag = "rhs_Flag_Russia_F";                                       // RU Flag

// To force add uniform
opfor_uniforms = [
	"PLA_CombatUniform_SBCB"
];
// Kit to put in uniform if replacing due to invalid ID
opfor_uniform_kit = [
	["VME_QBZ95_1_30Rnd_DBP10",3],
	["ACE_packingBandage",10],
	["ACE_tourniquet",4],
	["ACE_morphine",1]
];
// Force add a backpack
opfor_backpacks = [
	"TFAR_rt1523g_bwmod"
];
// Force add a vest
opfor_vests = [
	"PLA_B04_RF"
];


// TODO: Add actual loadout stuff to force init to?

// Sector defender infantry pool
militia_squad = [
	"PLA_Soldier_OF_F",									// Sergeant
	"PLA_Soldier_SL_F",
	"PLA_Soldier_TL_F",										// Junior Sergeant 
	"PLA_Soldier_AT89B_F",
	"PLA_Soldier_AT89B_F",									// Efreitor 
	"PLA_Soldier_F",										// Rifleman 
	"PLA_Soldier_F",										// Rifleman 
	"PLA_Soldier_HMG_F",									// Rifleman 
	"PLA_Soldier_F",									// Rifleman 
	"PLA_Soldier_F",										// Rifleman 
	"PLA_Soldier_AT_HJ12",							// Rifleman w/ RPG-26 
	"PLA_Soldier_AT_HJ12",									// Rifleman w/ RPG-26 
	"PLA_Soldier_AT_HJ12",									// Rifleman w/ RShG2 
	"PLA_Soldier_GL_F",										// Grenadier w/ GP-25 
	"PLA_Soldier_GL_F",										// Grenadier w/ GP-25 
	"PLA_Soldier_GL_F",										// Grenadier w/ GP-25
	"PLA_Soldier_GLA_F",							// paradrop guy
	"PLA_Soldier_MG_F",
	"PLA_Soldier_MG_F",								// Autorifleman (PKP) 
	"PLA_Soldier_HMG_F",								// Machinegunner 
	"PLA_Soldier_LR_F",										// Marksman 
	"PLA_Soldier_mk_F",
	"PLA_Soldier_mk_F",										// Sharpshooter 
	"PLA_Soldier_LR_F",											// Sniper 
	"PLA_Soldier_medic_F",											// Medic 
	"PLA_Soldier_medic_F",											// Medic 
	"VME_PLA_soldier_UAV",										// Engineer 
	"VME_PLA_soldier_UAV",										// Engineer 
	"PLA_Soldier_QL",									// Grenadier w/ RPG-7V2 
	"PLA_Soldier_QL",									// Grenadier w/ RPG-7V2 
	"PLA_Soldier_QL",									// AT Specialist 
	"PLA_Soldier_AA_F" 									// AA Specialist 
];

militia_squad_lower = militia_squad apply {toLower _x};

// NOTE: Still used for now for Lib config stuff
militia_vehicles = [];
opfor_vehicles = [];
opfor_vehicles_low_intensity = [];
opfor_battlegroup_vehicles_low_intensity = [];
opfor_battlegroup_vehicles = [
	// Static
	"VME_PLA_HJ11", 
	"VME_PLA_HJ73_static", 
	"VME_PLA_HJ8", 
	"VME_PLA_HJ9A", 
	"VME_PLA_PF98_Tripod", 
	"VME_PLA_Type87Mortar", 
	"VME_QJY88_Static_AA", 
	"VME_PLA_QJZ89A", 
	"VME_PLA_QLZ04", 
	"VME_PLA_QLZ04", 
	"VME_Type85_Static", 
	"VME_Type85_Static_AA",
	// ARTILLERY
	"vme_SM4", 
	"DF15_rearm", 
	"VME_PLA_PLZ07", 
	"VME_PLA_PLZ05", 
	"vme_PLL05", 
	"VME_PLA_Type86", 
	"PLA_PHZ81", 
	"VME_PLA_PHZ10", 
	"PLA_PHL03", 
	"PLA_DF15",
	// AA EMPLACEMENT
	"vme_PLA_DK9",												// 9K38 Djigit
	// AA VEHICLES
	"VME_PLA_HQ61",
	"VME_PLA_LD2000",
	// KOG TRANSPORT VICS
	"UK3CB_MDF_O_Quadbike", 
	"UK3CB_MDF_O_M1030", 
	"UK3CB_LDF_O_SUV_Armoured", 
	"UK3CB_MDF_O_MB4WD_Unarmed",
	"UK3CB_TKC_O_LR_Closed", 
	"O_G_Van_02_transport_F",
	// KOG AIR
	"rhs_ka60_grey",
	"RHS_Mi8AMT_vdv",
	// VICS
	"vme_AFT9", 
	"vme_PTL02", 
	"VME_PLA_ZBD03", 
	"VME_PLA_ZBD04", 
	"VME_PLA_ZBD08", 
	"vme_AFT9", 
	"vme_ZSL92A", 
	"vme_ZSL92B", 
	"VME_PLA_ZTL11", 
	"VME_PLA_BJ2022patrol", 
	"VME_PLA_EQ2050_AT", 
	"VME_PLA_EQ2050_GL", 
	"VME_PLA_EQ2050_MG", 
	"VME_PLA_EQ2050_reconGL", 
	"VME_PLA_EQ2050_reconMG", 
	"VME_PLA_SX2190", 
	"VME_QN506", 
	"VME_PLA_ZTZ96A", 
	"VME_PLA_ZTZ99", 
	"VME_PLA_ZTZ99A",
	// AIR transport
	"VME_PLA_Mi17", 
	"PLA_Z18", 
	"VME_Z20", 
	"VME_PLA_z9_base",
	// AIR heli cas
	"VME_PLA_Mi171", 
	"VME_WZ10_FOR", 
	"VME_WZ10", 
	"VME_PLA_z19", 
	"VME_PLA_z9_CAS",
	// Planes Cas
	"VME_PLA_J10B", 
	"VME_PLA_J11", 
	"VME_PLA_J16", 
	"VME_PLA_J20", 
	"VME_PLA_JH7",
	//Planes Transport
	"VME_PLA_AN178", 
	"VME_PLA_AN225", 
	"VME_PLA_Y20", 
	"VME_PLA_Y7A", 
	"VME_PLA_Y7", 
	"VME_PLA_Y9",
	// Drones
	"vme_CH4B",
	//
	"DF15_rearm", 
	"PLA_DF15",
	//
	"karmakut_9s32",													// 9S32 Radar
	"karmakut_sa6",														// SA-6 Gainful
	"karmakut_sa15",													// SA-15 Gauntlet
	"karmakut_sa20"														// SA-20 Gargoyle

];

// TODO: Utilize these arrays and add to the overall KPLIB config that it needs
// KPLIB_o_allVeh_classes
// KPLIB_allLandVeh_classes
opfor_tanks = [
	[0,
		[
			"vme_ZSL92B"														// T-80BVK
		]	
	],	
	[40, 	
		[
			"vme_ZSL92B",
			"vme_ZSL92B",
			"vme_PTL02",
			"vme_PTL02",
			"VME_PLA_ZBD03",
			"VME_PLA_ZBD03", 
			"VME_PLA_ZBD04",
			"VME_PLA_ZBD04"
		]	
	],	
	[80,	
		[
			"vme_ZSL92B",
			"vme_ZSL92B",
			"vme_PTL02",
			"vme_PTL02",
			"VME_PLA_ZBD04",
			"VME_PLA_ZBD04", 
			"VME_PLA_ZBD08",
			"VME_PLA_ZBD08",
			"VME_PLA_ZTZ96A",
			"VME_PLA_ZTZ96A", 
			"VME_PLA_ZTZ99",
			"VME_PLA_ZTZ99"
		]	
	],	
	[120,	
		[
			"VME_PLA_ZBD04",
			"VME_PLA_ZBD04", 
			"VME_PLA_ZBD08",
			"VME_PLA_ZBD08",
			"VME_PLA_ZTZ96A",
			"VME_PLA_ZTZ96A", 
			"VME_PLA_ZTZ99",
			"VME_PLA_ZTZ99", 
			"VME_PLA_ZTZ99A",
			"VME_PLA_ZTZ99A"
		]	
	]	
];	
// Vehicles considered Anti-Air (Only high readiness)	
opfor_sams = [	
	[0,	
		[	
			"VME_PLA_EQ2050_AA"												// Ural (ZU-23)
		]	
	],	
	[60, 	
		[	
			"VME_PLA_HQ61",
			"VME_PLA_HQ61",
			"VME_PLA_EQ2050_AA",												// Ural (ZU-23)
			"VME_PLA_EQ2050_AA",												// Ural (ZU-23)
			"VME_PLA_EQ2050_AA",												// Ural (ZU-23)
			"VME_PLA_EQ2050_AA",												// Ural (ZU-23)
			"VME_PLA_EQ2050_AA"												// ZSU-23-4V
		]	
	],	
	[120, 	
		[	
			"VME_PLA_EQ2050_AA",												// Ural (ZU-23)
			"VME_PLA_EQ2050_AA",												// Ural (ZU-23)
			"VME_PLA_EQ2050_AA",												// ZSU-23-4V
			"VME_PLA_HQ61",
			"VME_PLA_HQ61",
			"VME_PLA_HQ61",												// ZSU-23-4V
			"VME_PLA_HQ61"												// ZSU-23-4V
		]
	]
];
// Vehicles considered IFVs (APCs with an autocannon)
opfor_ifvs = [
	[0,
		[
			"VME_PLA_BJ2022patrol", 
			"VME_PLA_EQ2050_AT", 
			"VME_PLA_EQ2050_GL", 
			"VME_PLA_EQ2050_MG"
		]
	],
	[40,
		[
			"VME_PLA_BJ2022patrol", 
			"VME_PLA_EQ2050_AT", 
			"VME_PLA_EQ2050_GL", 
			"VME_PLA_EQ2050_MG"
		]
	],
	[80,
		[
			"vme_WZ551", 
			"vme_ZSL92A",
			"VME_PLA_BJ2022patrol", 
			"VME_PLA_EQ2050_AT", 
			"VME_PLA_EQ2050_GL", 
			"VME_PLA_EQ2050_MG",
			"VME_PLA_ZBD03", 
			"VME_PLA_ZBD04"
		]
	],
	[120, 
		[
			"vme_WZ551", 
			"vme_ZSL92A",
			"VME_PLA_BJ2022patrol", 
			"VME_PLA_EQ2050_AT", 
			"VME_PLA_EQ2050_GL", 
			"VME_PLA_EQ2050_MG",
			"VME_PLA_ZBD03", 
			"VME_PLA_ZBD04",
			"vme_PTL02", 
			"VME_PLA_ZBD08", 
			"vme_ZSL92B", 
			"VME_PLA_ZTL11"
		]
	]
];
// Vehicles considered APCs (machineguns)
opfor_apcs = [
	[0,
		[
			"vme_WZ551",
			"vme_ZSL92A"
		]
	]
];
// Vehicles considered pure troop transport
opfor_transports = [
	[0,
		[
			"VME_PLA_SX2190"                  						// Ural-4320 Open
		]
	],
	[75, 
		[
			"VME_PLA_SX2190",                  						// Ural-4320 Open
			"VME_PLA_SX2190",                  							// Ural-4320 Covered
			"VME_PLA_SX2190",                  							// Ural-4320 Covered
			"VME_PLA_SX2190",                    					// KamAZ-5350 Open
			"VME_PLA_SX2190",
			"VME_PLA_SX2190",
			"VME_PLA_EQ2050_AT",
			"VME_PLA_EQ2050_AT",
			"vme_AFT9",	                    					// KamAZ-5350 Covered
			"vme_AFT9"	                    					// KamAZ-5350 Covered
		]
	]
];
// Vehicles considered scout cars
opfor_scout_cars = [
	[0,
		[
			"vme_AFT9", 
			"vme_WZ551", 
			"vme_ZSL92A", 
			"VME_PLA_BJ2022patrol", 
			"VME_PLA_EQ2050_AT", 
			"VME_PLA_EQ2050_GL", 
			"VME_PLA_EQ2050_MG"
		]
	],
	[60, 
		[

			"vme_AFT9", 
			"vme_WZ551", 
			"vme_ZSL92A", 
			"VME_PLA_BJ2022patrol", 
			"VME_PLA_EQ2050_AT", 
			"VME_PLA_EQ2050_GL", 
			"VME_PLA_EQ2050_MG"
		]
	]
];

opfor_halo_air = [
	[0,
		[
			"VME_PLA_Mi171",												// Mil Mi-24P
			"VME_PLA_Y20",                                       // Mi-8T Hip
			"VME_PLA_Mi171",                                        	// Mi-8MT Hip
			"VME_PLA_Y9",                                         // Mi-8AMT Hip
			"VME_PLA_Y20"                                           	// Tu-95 Bear BOMBS
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
					["Ratio", 0.2],
					["Max", 1],
					["Min", 0]
				]
			],
			["APC",
				createHashMapFromArray [
					["Ratio", 0.1],
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
					["Ratio", 0.4],
					["Max", 6],
					["Min", 3]
				]
			]
		]
	],
	[120,
		createHashMapFromArray [
			["Tanks", 
				createHashMapFromArray [
					["Ratio", 0.4],
					["Max", 7],
					["Min", 1]
				]
			],
			["AA",
				createHashMapFromArray [
					["Ratio", 0.2],
					["Max", 2],
					["Min", 1]
				]
			],
			["IFV",
				createHashMapFromArray [
					["Ratio", 0.3],
					["Max", 3],
					["Min", 0]
				]
			],
			["APC",
				createHashMapFromArray [
					["Ratio", 0.3],
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
					["Ratio", 0.4],
					["Max", 8],
					["Min", 4]
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
					["Ratio", 0.2],
					["Max", 2],
					["Min", 1]
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
					["Max", 6],
					["Min", 4]
				]
			],
			["Scouts",
				createHashMapFromArray [
					["Ratio", 0.3],
					["Max", 0],
					["Min", 0]
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
					["Ratio", 0.2],
					["Max", 0],
					["Min", 1]
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
					["Ratio", 0.4],
					["Max", 4],
					["Min", 1]
				]
			],
			["Transport",
				createHashMapFromArray [
					["Ratio", 0.4],
					["Max", 6],
					["Min", 3]
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
					["Ratio", 0.1],
					["Max", 2],
					["Min", 0]
				]
			],
			["AA",
				createHashMapFromArray [
					["Ratio", 0.1],
					["Max", 0],
					["Min", 0]
				]
			],
			["IFV",
				createHashMapFromArray [
					["Ratio", 0.1],
					["Max", 0],
					["Min", 0]
				]
			],
			["APC",
				createHashMapFromArray [
					["Ratio", 0.4],
					["Max", 7],
					["Min", 4]
				]
			],
			["Transport",
				createHashMapFromArray [
					["Ratio", 0.2],
					["Max", 4],
					["Min", 1]
				]
			],
			["Scouts",
				createHashMapFromArray [
					["Ratio", 0],
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
					["Ratio", 0.3],
					["Max", 5],
					["Min", 2]
				]
			],
			["AA",
				createHashMapFromArray [
					["Ratio", 0.2],
					["Max", 4],
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
					["Ratio", 0.4],
					["Max", 7],
					["Min", 3]
				]
			],
			["Transport",
				createHashMapFromArray [
					["Ratio", 0.2],
					["Max", 0],
					["Min", 0]
				]
			],
			["Scouts",
				createHashMapFromArray [
					["Ratio", 0],
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
	"VME_PLA_Mi171", 
	"VME_WZ10_FOR", 
	"VME_WZ10", 
	"VME_PLA_z19", 
	"VME_PLA_z9_CAS",
	"VME_PLA_Mi171"
];

// Enemy fixed-wings that will need to spawn in the air.
opfor_air = [
	"VME_PLA_Y20",											// Mi-8AMTSh Hip (S-8 x6)
    "VME_PLA_Mi171",                                             // Mi-24P Hind
    "VME_PLA_Y20", 	                                        // Mi-24V Hind
	"VME_PLA_J10B", 
	"VME_PLA_J11", 
	"VME_PLA_J16", 
	"VME_PLA_J20", 
	"VME_PLA_JH7",
	"VME_WZ10_FOR", 
	"VME_WZ10", 
	"VME_PLA_z19", 
	"VME_PLA_z9_CAS"
];

opfor_cap = [
	"VME_PLA_J10B", 
	"VME_PLA_J11", 
	"VME_PLA_J16", 
	"VME_PLA_J20", 
	"VME_PLA_JH7"										// rhs_mi28n_vvsc"
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
		["VME_PLA_EQ2050_reconGL"],
		BATTLESPACE_SQUAD_SIZE
	],
	[
		["VME_PLA_EQ2050_GL"],
		BATTLESPACE_SQUAD_SIZE
	],
	[
		["VME_PLA_EQ2050_AT"],
		BATTLESPACE_SQUAD_SIZE
	],
	[
		["vme_AFT9"],
		BATTLESPACE_SQUAD_SIZE * 2
	],
	[
		["VME_PLA_EQ2050_MG"],
		BATTLESPACE_SQUAD_SIZE
	],
	[
		["VME_PLA_ZBD08"],
		BATTLESPACE_SQUAD_SIZE
	],
	[
		["vme_WZ551"],
		BATTLESPACE_SQUAD_SIZE * 2
	],
	[
		["VME_PLA_ZBD03","VME_PLA_EQ2050_GL"],
		BATTLESPACE_SQUAD_SIZE
	],
	[
		["VME_PLA_BJ2022patrol"],
		BATTLESPACE_SQUAD_SIZE
	],
	[
		["VME_PLA_ZTZ99A"],
		BATTLESPACE_SQUAD_SIZE
	],
	[
		["VME_PLA_ZTZ96A"],
		BATTLESPACE_SQUAD_SIZE
	],
	[
		["vme_PTL02"],
		BATTLESPACE_SQUAD_SIZE
	],
	[
		["vme_ZSL92A"],
		BATTLESPACE_SQUAD_SIZE
	],
	[
		["VME_PLA_HQ61"],
		BATTLESPACE_SQUAD_SIZE * 2
	],
	[
		["VME_PLA_ZBD08"],
		BATTLESPACE_SQUAD_SIZE
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
		_squadCount = 4 max _squadCount;
		_squadCount = 6 min _squadCount;
		_staticCount = 4 min _staticCount;
	};

	// Production points, kept under baseline military protection
	if(_sector in sectors_factory) then {
		_squadCount = 4 max _squadCount;
		_squadCount = 7 min _squadCount;
		_staticCount = 2 max _staticCount;
		_staticCount = 5 min _staticCount;
	};

	// Communication hub, defended with garrison
	if(_sector in sectors_tower) then {
		_squadCount = 5 max _squadCount;
		_squadCount = 6 min _squadCount;
		_staticCount = 2 max _staticCount;
		_staticCount = 6 min _staticCount;
	};

	// Military points should be quite tough for lower player counts but possible with good coordination
	if(_sector in sectors_military) then {
		_squadCount = 6 max _squadCount;
		_squadCount = 8 min _squadCount;
		_staticCount = 4 max _staticCount; // Always see some statics, no max
	};

	// Big towns should be basically impossible for lower player counts
	if(_sector in sectors_bigtown) then {
		_squadCount = 8 max _squadCount;
		_squadCount = 12 min _squadCount;
		_staticCount = 4 max _staticCount; // Always see some statics, no max
	};

	[_squadCount, _staticCount]
};


BATTLESPACE_DEFENDERS_VEHICLE_CLASSES = [
	"VME_PLA_EQ2050_AA",											// Ural (ZU-23)
	"VME_PLA_EQ2050_AA",											// Ural (ZU-23)
	"vme_AFT9",													// GAZ-233014 (PKM/AGS-30)
	"vme_AFT9",													// GAZ-233014 (PKM/AGS-30)
	"VME_PLA_EQ2050_AT",
	"VME_PLA_EQ2050_AT",
	"vme_ZSL92A",												// GAZ-233014 (PKM/AGS-30)
	"vme_ZSL92A",												// GAZ-233014 (PKM/AGS-30)
	"vme_WZ551",
	"vme_WZ551",
	"VME_PLA_ZBD03",													// GAZ-233014 (PKM/AGS-30)
	"VME_PLA_ZBD03",													// GAZ-233014 (PKM/AGS-30)
	"VME_PLA_EQ2050_reconGL",													// BMP-1P
	"VME_PLA_EQ2050_reconGL",													// GAZ-233014 (PKM/AGS-30)
	"VME_PLA_ZBD03",												// BTR-80
	"VME_PLA_ZBD03",												// BTR-80
	"VME_PLA_EQ2050_GL",
	"VME_PLA_EQ2050_GL",
	"VME_PLA_EQ2050_MG",
	"VME_PLA_EQ2050_MG",
	"VME_PLA_BJ2022patrol",
	"VME_PLA_BJ2022patrol",
	"VME_PLA_ZTZ99A",
	"VME_PLA_ZTZ99A",
	"VME_PLA_ZTL11",
	"VME_PLA_ZTL11",
	"VME_PLA_ZTZ99",
	"VME_PLA_ZTZ99",
	"VME_PLA_ZTZ99",
	"VME_PLA_ZTZ99",
	"VME_PLA_ZTZ99A",
	"VME_PLA_ZTZ99A",
	"VME_PLA_ZTZ96A",														// BMP-3
	"VME_PLA_ZTZ96A",													// BMP-3 (late)
	"VME_PLA_ZBD08",													// 2S25 Sprut
	"VME_PLA_ZBD08",													// 2S25 Sprut
	"VME_PLA_ZBD04",
	"VME_PLA_ZBD04",
	"VME_PLA_ZBD08",
	"VME_PLA_ZBD08",
	"VME_PLA_ZBD08",
	"VME_PLA_ZBD08",
	"vme_PTL02",
	"vme_PTL02",
	"VME_PLA_HQ61",
	"VME_PLA_HQ61",
	"VME_PLA_HQ61",									// VME_PLA_HQ61
	"VME_PLA_HQ61"									// VME_PLA_HQ61
];
BATTLESPACE_DEFENDERS_STATIC_CLASSES = [
	"VME_Type85_Static",												// NSV Minitripod
	"VME_Type85_Static",												// NSV Minitripod
	"VME_Type85_Static",												// NSV Minitripod
	"VME_Type85_Static",												// NSV Minitripod
	"VME_Type85_Static",												// NSV Minitripod
	"VME_Type85_Static",												// NSV Minitripod
	"VME_Type85_Static",												// NSV Minitripod
	"VME_Type85_Static",												// NSV Minitripod
	"VME_Type85_Static",												// NSV Minitripod
	"VME_Type85_Static_AA",													// KORD Minitripod
	"VME_Type85_Static_AA",													// KORD Minitripod
	"VME_Type85_Static_AA",													// KORD Minitripod
	"VME_Type85_Static_AA",													// KORD Minitripod
	"VME_Type85_Static_AA",													// KORD Minitripod
	"VME_Type85_Static_AA",													// KORD Minitripod
	"VME_Type85_Static_AA",												// KORD Tripod
	"VME_Type85_Static_AA",												// KORD Tripod
	"VME_Type85_Static_AA",												// KORD Tripod
	"VME_Type85_Static_AA",												// KORD Tripod
	"VME_Type85_Static_AA",												// KORD Tripod
	"VME_Type85_Static_AA",												// KORD Tripod
	"VME_PLA_QLZ04",											// AGS-30
	"VME_PLA_QLZ04",											// AGS-30
	"VME_PLA_QLZ04",											// AGS-30
	"VME_PLA_QLZ04",											// AGS-30
	"VME_PLA_QLZ04",											// AGS-30
	"VME_PLA_QLZ04",											// AGS-30
	"VME_PLA_PF98_Tripod",												// SPG-9M
	"VME_PLA_HJ73_static",												// SPG-9M
	"VME_PLA_HJ73_static",												// SPG-9M
	"VME_PLA_HJ11",												// SPG-9M
	"VME_PLA_HJ73_static",												// SPG-9M
	"VME_PLA_LD2000",														// ZU-23-2
	"VME_PLA_LD2000",														// ZU-23-2
	"VME_PLA_LD2000",														// ZU-23-2
	"VME_PLA_LD2000",														// ZU-23-2
	"VME_PLA_LD2000",														// ZU-23-2
	"VME_PLA_QLZ04",
	"VME_PLA_QLZ04",
	"VME_PLA_QLZ04",
	"VME_PLA_QLZ04",
	"VME_PLA_QLZ04",
	"VME_PLA_QLZ04",
	"VME_PLA_QLZ04",
	"VME_PLA_QLZ04",
	"VME_PLA_QLZ04",
	"VME_PLA_QLZ04",
	"VME_PLA_QLZ04",
	"VME_PLA_QLZ04",
	"VME_PLA_QLZ04",												// 2B14-1 Podnos
	"vme_PLA_DK9"											// 9K38 Djigit
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
BATTLESPACE_MORTARS = [];

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
