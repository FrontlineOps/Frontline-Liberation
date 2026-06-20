// HEY IF YOU NEED TO CHANGE FACTIONS, DO SO HERE:
// KC_Liberation_Master_Framework\presets\init_presets.sqf

FOB_typename = "Land_Cargo_HQ_V1_F";                                     	    // FOB HQ building
FOB_box_typename = "B_Slingload_01_Cargo_F";                      				// FOB Container
FOB_truck_typename = "rhsusf_M1078A1P2_B_WD_CP_fmtv_usarmy";            		// FOB Truck
Arsenal_typename = "B_supplyCrate_F";                							// Arsenal crate
Respawn_truck_typename = "";    							            		// Unused Mobile Respawn
crewman_classname = "";                    										// Unused AI
pilot_classname = "";                          									// Unused AI

huron_typename = "";                             								// Ops vehicle slot that respawns
KP_liberation_smallhelo_classname = "vtx_UH60M_SLICK";        					// Ops small helicopters
KP_liberation_midhelo_classname = "vtx_MH60M_DAP";        							// Ops medium helicopters (vtx_UH60M for land start, vtx_MH60S for carrier start)
KP_liberation_bighelo_classname = "RHS_CH_47F";       					        // Ops large helicopters
KP_liberation_medhelo_classname = "vtx_HH60";       							// Ops MEDEVAC helicopters
KP_liberation_atkhelo_classname = "fza_ah64d_b2e";       						    // Ops attack helicopters
KP_liberation_car_classname = "rhsusf_m1045_w";							        // Ops cars
KP_liberation_atcar_classname = "rhsusf_m998_w_4dr";							// Ops AT cars
KP_liberation_truck_classname = "rhsusf_M1078A1P2_WD_fmtv_usarmy";       		// Ops trucks
KP_liberation_medcar_classname = "rhsusf_M1230a1_usarmy_wd";					// Ops ambulance
KP_liberation_zodiac_classname = "B_Boat_Transport_01_F";						// Ops inflatable boats
KP_liberation_rhib_classname = "UK3CB_MDF_B_RHIB";								// Ops RHIBs
KP_liberation_ifv_classname = "RHS_M2A3_BUSKI_wd";       						// Ops IFVs
KP_liberation_apc_classname = "rhsusf_stryker_m1126_m2_wd";       					// Ops APCs
KP_liberation_cas_classname = "RHS_A10";       								// Ops CAS planes
KP_liberation_cap_classname = "rhsusf_f22";       						    // Ops CAP planes
KP_liberation_drone_classname = "ITC_Land_B_UAV_MQ4i";       								// Ops fixed wing drones
KP_liberation_repair_classname = "rhsusf_M977A4_REPAIR_BKIT_usarmy_wd";       	// Ops repair truck
KP_liberation_fuel_classname = "rhsusf_M978A4_BKIT_usarmy_wd";       			// Ops fuel truck

KP_liberation_small_storage_building = "ContainmentArea_02_forest_F";     		// Small storage
KP_liberation_large_storage_building = "ContainmentArea_01_forest_F";     		// Large storage
KP_liberation_recycle_building = "Land_Mil_Repair_center_EP1";          		// Salvage depot
KP_liberation_air_vehicle_building = "Land_Airport_01_controlTower_F";  		// Air control object
KP_liberation_heli_slot_building = "Land_HelipadCircle_F";              		// Helicopter slot object
KP_liberation_plane_slot_building = "Land_TentHangar_V1_F";             		// Fixed wing slot object
KP_liberation_supply_crate = "CargoNet_01_box_F";                       		// Supply crate
KP_liberation_ammo_crate = "B_CargoNet_01_ammo_F";                      		// Ammo crate
KP_liberation_fuel_crate = "CargoNet_01_barrels_F";                     		// Fuel crate

// Format: ["vehicle_classname",supplies,ammunition,fuel,"Custom Name",unlockCost]

infantry_units = [];

light_vehicles = [
    // TRANSPORT 
    ["rhsusf_M1078A1P2_WD_fmtv_usarmy",            75,    0,        75,       "FMTV USARMY (TRANSPORT)"],
    ["rhsusf_M1083A1P2_B_M2_WD_fmtv_usarmy",       75,    50,     75,         "FMTV-M2 USARMY (TRANSPORT)"],
    ["UK3CB_B_MTVR_Closed_USMC_WDL",               125,    0,       125,      "MTRV TROOP TRANSPORT CLOSED"],
    ["rhsusf_m998_w_2dr_fulltop",                  50,     0,       50,       "M998 (2DR-TRANSPORT)"],
    //
    //["rhsusf_m1165a1_gmv_m2_m240_socom_d",          175,    125,     125,        "GMV-M2-M240 (TRANSPORT)"],
    //["rhsusf_m1165a1_gmv_m134d_m240_socom_d",       275,    250,     200,        "GMV-M134D-M240 (TRANSPORT)"],
    ["rhsusf_mrzr4_d",                              125,      0,       125,        "MRZR4"],
    ["rhsusf_m113_usarmy_M240",                     75,    50,      50,          "M113-M240 (TRANSPORT)"],
    // STRYKER
    ["rhsusf_stryker_m1127_m2_wd",                  150,    75,      150,        "M1127-M2/LRAS3 STRYKER (ARMORED TRANSPORT)"],
    ["rhsusf_stryker_m1126_m2_wd",                  350,    250,     150,        "M1126-M2/CROW STRYKER (ARMORED TRANSPORT)"],
    // HUMVEE
    ["rhsusf_m1151_m240_v3_usmc_wd",                50,     50,      50,         "M1151-M240 (ARMORED HUMVEE)"],
    ["rhsusf_m1151_m2_v3_usmc_wd",                  75,     75,      50,         "M1151-M2 (ARMORED HUMVEE)"],
    ["rhsusf_m1151_m2crows_usmc_wd",                225,    75,      50,         "M1151-M2-CROWS (ARMORED HUMVEE)"],
    ["rhsusf_m1151_m2crows_usarmy_wd",              300,    475,     150,        "M2-SLAP-Crows (HUMVEE)"],
    // MRAP'S
    ["rhsusf_M1220_M2_usarmy_wd",                   125,    75,      125,        "M1220 O-GPK/M2 (TRANSPORT)"],
    ["rhsusf_M1230_M2_usarmy_wd",                   150,    75,      125,        "M1230 O-GPK/M2 (ARMORED TRANSPORT)"],
    //
    ["rhsusf_M1237_M2_usarmy_wd",                   175,    75,      125,        "M1237 O-GPK/M2 (Battle Bus ARMORED)"],
    //
    ["rhsusf_m1240a1_m240_uik_usarmy_wd",           75,     50,      100,        "Mrap M1240A1 (O-GPK/M240 CAGE)"],
    ["rhsusf_m1240a1_m2_usarmy_wd",                 100,    75,      100,        "Mrap M1240 (O-GPK/M2)"],
    ["rhsusf_m1240a1_m2_uik_usarmy_wd",             125,    75,      100,        "Mrap M1240A1 (O-GPK/M2 CAGE)"],
    ["rhsusf_m1240a1_m2crows_usarmy_wd",            175,    125,     100,        "Mrap M1277 (CROWS/M2)"],
    //
    ["rhsusf_CGRCAT1A2_M2_usmc_wd",                 100,    75,      75,         "CGR-CAT1A2 MCTAGS/M2 (TRANSPORT)"],
    // WATER
    //["UK3CB_B_AAV_US_WDL",                          450,    475,     225,        "AAVP-7A1-MK19-M2 (Assault Amphibious Vehicle)"],
    //
    ["UK3CB_MDF_B_RHIB",                            50,     75,       50,        "Assault RHIB M2"],
    ["B_Boat_Transport_01_F",                       25,     0,        25,        "Inflatable Boat"]
];
// Vehicles for Phantom + Ogre use, combined into light vehicles menu
recon_vehicles = [
    //["rhsusf_mrzr4_d",                200,      0,       100,     "MRZR4 (Recon)"],
    ["B_Quadbike_01_F",                 50,      0,       50,     "Phantom Quad (Recon)"],
    ["rhsusf_m998_w_4dr",               100,      0,       100,     "Phantom M1097A2 (Recon)"],
    ["UK3CB_MDF_B_Offroad_Unarmed",     100,      0,       100,     "Phantom Toyota (Recon)"]
];

// Vehicles for Banshee + Ogre use, combined into light vehicles menu
// Don't add air vehicles into this list
medical_vehicles = [
    ["rhsusf_M1230a1_usarmy_wd",			    50,     0,      400,     "Banshee M123OA1 (MEDVAC)"],      // M123OA1 (MEDVAC)
    ["rhsusf_m113_usarmy_medical",			    75,	    0,      375,     "Banshee M113A3 (MEV)"]           // M123OA1 (MEDVAC)
];

// Ogre Specific Vehicles
groundlogi_vehicles = [
    ["rhsusf_M1084A1P2_B_WD_fmtv_usarmy",			150,	0,		150,	"Ogre HEMTT Logistics Truck (SMALL)"],
    ["rhsusf_M977A4_BKIT_usarmy_wd",				200,	0,		200,	"Ogre HEMTT Logistics Truck"],    // M977A4-B Flatbed
    ["rhsusf_M977A4_REPAIR_BKIT_usarmy_wd",			250,	0,		150,	"Ogre HEMTT Repair Truck"],		  // M977A4-B Repair
    ["rhsusf_M978A4_BKIT_usarmy_wd",				250,	0,		250,	"Ogre HEMTT Fuel Truck"],		  // M978A4-B Fuel
    ["rhsusf_stryker_m1132_m2_wd",				    250,	0,		250,	"M1132 (SMP/M2) Mine Sweeper"]		// Eod
];

// Savage
artillery_vehicles = [     
    ["pook_M777_DES",         			        1000,   1000,	0,	    "Savage M-777"],        	     // M777
    //["pook_MLRS_BLUFOR",         			    1100,   1100,	700,	"Savage MLRS (M983 Tractor)"],   // truck versio
    ["rhsusf_m109_usarmy",         			    1200,   1300,	700,	"Savage M109A6 Paladin"],
    ["UK3CB_B_M270_MLRS_HE_WDL",         	    1500,   1500,	700,	"Savage MLRS (M270 (HE)"],
    ["itc_land_b_vls2_slam",         			4500,   5000,	0,      "Savage MN230 VLS (Cruise Missile)"]
];

atgm_vehicles = [
    //["UK3CB_CW_US_B_LATE_M151_Jeep_TOW",         50,     75,     50,          "Wraith M151 Jeep (TOW)"],
    ["rhsusf_m966_w",                            100,    200,    100,         "Wraith TOW Humvee (TOW)"],
    ["rhsusf_stryker_m1134_wd",                  350,    250,    150,         "Wraith M1134 Stryker (ATGM)"]
];

aa_vehicles = [
    ["pook_CRAM_BASE",                     350,    350,    300,         "Harpy (C-RAM Air Defense System)"],
    ["pook_NASAMS_BASE",                   450,    250,    250,         "Harpy (National Advanced Surface to-Air Missle System)"],
    ["UK3CB_KRG_B_M270_Avenger",           650,    450,    250,         "Harpy (M270 Avenger)"]
];

heavy_vehicles = [
    ["rhsusf_stryker_m1126_m2_wd",		    350,	600,    150,	    "Stryker M-1126 M2 (LIGHT ARMOR)"],
    ["rhsusf_m1151_mk19crows_usarmy_wd",		225,	475,    175,	    "MK-19 CROWS (HUMVEE)"],
    ["rhsusf_M1117_W",		                    325,	575,    200,	    "M1117 M (LIGHT ARMOR)"],
    ["rhsusf_stryker_m1126_mk19_wd",		        375,	625,    250,	    "Stryker MK19 (LIGHT ARMOR)"],
    ["RHS_M2A3_wd",		                        550,	800,    350,	    "M2A3 Bradley (LIGHT ARMOR)"],
    ["RHS_M2A3_BUSKI_wd",		                750,	850,    400,	    "M2A3 Bradley BUSK I (LIGHT ARMOR)"],
    ["RHS_M2A3_BUSKIII_wd",		                950,	900,    450,	    "M2A3 Bradley BUSK III (LIGHT ARMOR)"],
    ["RHS_M6_wd",		                        450,	700,    350,	    "M6 Linebacker (LIGHT ARMOR AA)"],
    ["rhsusf_m1a1aim_tuski_wd",		            950,	850,   350,	    "M1A1AIM ABRAMS (HEAVY ARMOR)"],
    ["rhsusf_m1a2sep1wd_usarmy",		        1000,	1000,   1000,	    "M1A2SEPv1 ABRAMS (HEAVY ARMOR)"],
    ["rhsusf_m1a2sep1tuskiiwd_usarmy",		    1250,	1200,   1100,	    "M1A2SEPv1 ABRAMS TUSK II (HEAVY ARMOR)"],	               
    ["rhsusf_m1a2sep2wd_usarmy",		        1550,	1300,   1200,	    "M1A2SEPv2 ABRAMS (HEAVY ARMOR)"]		                	                
];

rotarylogi_vehicles = [
    ["RHS_MELB_MH6M",			        225,	0,	    250,	"MH6M Littlebird"],
    ["vtx_UH60M_SLICK",			            225,	50,	    225,	"UH60 Slick"],

    ["RHS_CH_47F_cargo",			    600,	100,	600,	"CH-47F Chinook (Cargo)"], 			    // MH-60M Blackhawk
    ["RHS_CH_47F",			        475,	100,	500,	"CH-47F Chinook"],                                       				            
    ["RHS_CH_47F_cargo",			    600,	100,	500,	"CH-47F Chinook (Cargo)"]              
];

rotarycas_vehicles = [
    ["RHS_MELB_AH6M",				250,	500,	300,    "AH-6M (Dual-gau19)"], 					            	// AH-6M Littlebird Custom
    ["RHS_MELB_AH6M_L",				450,	700,	300,    "AH-6L (DAGR M310)"], 					            	// AH-6M Littlebird
    ["RHS_MELB_AH6M_M",				500,	750,	300,    "AH-6MM (Dual-M151)"],						// AH-6M Littlebird Custom
    ["RHS_MELB_AH6M_H",				350,	600,	300,    "AH-6M Littlebird"],
    ["fza_ah64d_b2e",			   1100,	1000,	1000,	"AH-64D Apache Longbow"], 						// AH-64D Apache Longbow
    ["vtx_MH60M_DAP",		       300,	    275,	275,	"MH-60M DAP"] 					// MH-60M DAP
];

fixedwing_vehicles = [
    //["USAF_MQ9",				            100,	  0,       100,    "Reaper (Drone)"],								// MQ-9 Reaper
    ["ITC_Land_B_UAV_UCAVi",				250,	  0,       250,    "UCAVi Sentinel 2 (Drone)"],
    ["ITC_Land_B_UAV_MQ4i",		            300,	  0,       300,    "MQ-12 Falcon (Drone)"],								// MQ-9 Reaper
    ["UK3CB_FIA_B_Cessna_T41",              100,      0,       100,     "Chevy Cessna T-41 (Supply Drop Plane)"],                              // T-41 Mescalero
	["RHS_C130J",				            500,	  0,       600,       "C-130J Super Hercules"],								// C-130J Super Hercules
    ["RHS_C130J_Cargo",		                750,	  0,       700,   "C-130J Super Hercules (Cargo)"],						// C-130J Super Hercules
    ["RHS_A10",		                        1750,	  0,       1000,   "A-10A Warthog"],						
    ["rhsusf_f22",		                    2250,	  0,       1200,   "F-22 Raptor"]											
];

static_vehicles = [
    ["I_HMG_02_high_F",                         50,     75,     0,      "M2 HMG .50 (Raised)"],
    ["UK3CB_B_Static_M240_Elcan_High_US_W",     25,     50,     0,      "M-240 High"],				
    ["RHS_Stinger_AA_pod_D",				    100,	175,	0,      "Stinger AA"] 					// FIM-92F (DMS)
];

buildings = [
    ["Land_LampHarbour_F",0,0,0],
    ["Land_LampHalogen_F",0,0,0],
    ["Land_Hlidac_budka",0,0,0,"Sensor Operator Building"],
    ["Camp_EP1",0,0,0,"Sensor Operator Tent"],
	["Base_WarfareBBarrier10xTall",0,0,0,"HESCO Wall Long"],			       // H-Barriers
    ["Land_HBarrierWall6_F",0,0,0,"HESCO Wall Long w/ Ramp"],
    ["Land_HBarrierWall4_F",0,0,0,"HESCO Wall Short w/ Ramp"],
    ["Land_HBarrierWall_corner_F",0,0,0,"HESCO Wall Corner"],
    ["Land_HBarrierWall_corridor_F",0,0,0,"HESCO Corridor"],
    ["Land_HBarrierTower_F",0,0,0,"HESCO Bunker"],
    ["Land_Fort_Watchtower_EP1",0,0,0,"HESCO Tower"],
    ["Land_HBarrier_Big_F",0,0,0,"HESCO Large 4"],
    ["Land_HBarrier_5_F",0,0,0,"HESCO Small 5"],
    ["Land_HBarrier_3_F",0,0,0,"HESCO Small 3"],
    ["Land_HBarrier1",0,0,0,"HESCO Small Single"],
    ["Land_Billboard_F",0,0,0,"Rules Billboard"],					        	// Signs and Billboards
    ["Land_Billboard_03_blank_F",0,0,0,"Admin Billboard"],
    ["Land_Billboard_03_aan_F",0,0,0,"Radios Billboard"],                       // updated
	["Land_Billboard_03_koke_F",0,0,0,"Odin Billboard"],
	["Land_Billboard_03_cheese_F",0,0,0,"Tutorial Billboard"],
    ["Land_Billboard_03_bluking_F",0,0,0,"Karmakut Logo Billboard"],
    ["Land_Billboard_03_ionbase_F",0,0,0,"Karmakut Spread Sheet Radios"],
    ["Land_Billboard_03_lyfe_F",0,0,0,"Karmakut TFAR HELP"],
    ["Land_Billboard_03_argois_F",0,0,0,"Karmakut Insurance"],
    ["Land_Billboard_03_supermarket_F",0,0,0,"Karmakut Role"],
    ["Land_Billboard_03_ygont_F",0,0,0,"Karmakut Builders"],
    ["SignAd_SponsorS_ARMEX_F",0,0,0,"Direction Sign - Resources"],
	["SignAd_SponsorS_Fuel_white_F",0,0,0,"Direction Sign - Arsenal"],
    ["SignAd_SponsorS_F",0,0,0,"Direction Sign - Boat Dock"],
	["SignAd_SponsorS_ION_F",0,0,0,"Direction Sign - Arty Pit"],
    ["SignAd_SponsorS_Suatmm_F",0,0,0,"Direction Sign - Karmakut Arty Pit"],		
	["SignAd_SponsorS_Larkin_F",0,0,0,"Direction Sign - CCP"],			
	["SignAd_SponsorS_Quontrol_F",0,0,0,"Direction Sign - Helipads"],	
	["SignAd_SponsorS_Vrana_F",0,0,0,"Direction Sign - Motor Pool"],	
    ["TFAR_Land_Communication_F",500,0,0,"TFAR Signal Repeater (20km)"],
    ["Land_Medevac_house_V1_F",200,0,0,"Medical Building (Small)"],				// Medical Building
    ["Land_Medevac_HQ_V1_F",200,0,0,"Medical Building (Large)"],				// Medical Building
    ["CampEast_EP1",0,0,0,"Squad Tent"],
    ["WarfareBCamp",0,0,0,"HESCO, Sandbag, Camo Net Position"],		        // Fortifications
    ["Fortress2",0,0,0,"Sandbag Bunker w/ Camo Net"],
    ["Land_fortified_nest_big_EP1",0,0,0,"Sandbag Bunker (Large)"],
    ["Fortress1",0,0,0,"Sandbag Guardpost 1"],
    ["Land_fortified_nest_small_EP1",0,0,0,"Sandbag Guardpost 2"],
    ["ShedSmall",0,0,0,"Sandbags w/ Camo Net (Small)"],
    ["Land_fort_artillery_nest",0,0,0],
    ["Land_fort_rampart",0,0,0],
    ["Land_GuardShed",0,0,0,"Guard Shack"],
    ["Hedgehog",0,0,0],
    ["Land_Army_hut_storrage",0,0,0],
    ["Land_jezekbeton",0,0,0],
    ["Land_CncBarrierMedium_F",0,0,0],									// Concrete Stuff
    ["Land_CncBarrierMedium4_F",0,0,0],
    ["Land_Concrete_SmallWall_4m_F",0,0,0],
    ["Land_Concrete_SmallWall_8m_F",0,0,0],
    ["Land_Rampart_F",0,0,0],
    ["Land_RampConcreteHigh_F",0,0,0],
    ["RampConcrete",0,0,0],
    ["BlockConcrete_F",0,0,0],
    ["Land_ConcretePipe_F",0,0,0],
    ["Land_Rail_ConcreteRamp_F",0,0,0],
    ["Land_runway_edgelight",0,0,0,"Runway Edgelight (White)"],
    ["Land_runway_edgelight_blue_F",0,0,0,"Runway Edgelight (Blue)"],
    ["Land_Flush_Light_yellow_F",0,0,0,"Runway Flush Light (Yellow)"],
    ["Land_Flush_Light_green_F",0,0,0,"Runway Flush Light (Green)"],
    ["Land_Flush_Light_red_F",0,0,0,"Runway Flush Light (Red)"],
    ["Land_PortableLight_single_F",0,0,0],								// Lamps
    ["Land_PortableLight_double_F",0,0,0],
    ["Land_HelipadSquare_F",0,0,0,"Helipad Square"],          // Cosmetic Helipad
    ["Land_HelipadRescue_F",0,0,0,"Helipad Rescue H"],
    ["Flag_White_F",0,0,0,"Flag (Karmakut Logo)"],						// Flags
    ["Flag_NATO_F",0,0,0],
    ["Flag_UNO_F",0,0,0,"Flag (United Nations)"],
    ["Flag_US_F",0,0,0],
    ["Flag_CW_US_ARMY",0,0,0],
    ["Flag_CW_US_MARINES",0,0,0],
    ["Flag_CW_US_AIR",0,0,0],
    ["Flag_CW_US_NAVY",0,0,0],
    ["Flag_Red_F",0,0,0],
    ["Flag_Green_F",0,0,0],
    ["Flag_Blue_F",0,0,0],
    ["Flag_FD_Orange_F",0,0,0,"Flag (Orange)"],
    ["Flag_FD_Purple_F",0,0,0,"Flag (Purple)"],
    ["FlagCarrierWhite_EP1",0,0,0,"Flag (White)"],
    ["Flag_RedCrystal_F",0,0,0,"Flag (Medical)"],
    ["CUP_sign_hospital",0,0,0],
    ["Land_SignM_WarningMilitaryArea_english_F",0,0,0],
    ["Land_SignM_WarningMilAreaSmall_english_F",0,0,0],
    ["Land_SignM_WarningMilitaryVehicles_english_F",0,0,0],
    ["Land_Sign_WarningNoWeapon_F",0,0,0],
    ["ITC_Land_loudspeakers2",0,0,0],								    // Flavor Items
    ["USMC_WarfareBUAVterminal",0,0,0,"UAV Terminal (Cosmetic)"],
    ["Land_Mil_Guardhouse",0,0,0],
    ["PowGen_Big_EP1",0,0,0],
    ["CamoNet_BLUFOR_F",0,0,0],
    ["CamoNet_BLUFOR_open_F",0,0,0],
    ["CamoNet_BLUFOR_big_F",0,0,0],
    ["Land_CampingChair_V1_F",0,0,0],
    ["Land_CampingChair_V2_F",0,0,0],
    ["Land_CampingTable_F",0,0,0],
    ["Campfire_burning_F",0,0,0],                                       // Campfire (burning)
    ["MapBoard_altis_F",0,0,0],
    ["MapBoard_stratis_F",0,0,0],
    ["Land_BarGate_F",0,0,0],
    ["Land_Pallet_MilBoxes_F",0,0,0],
    ["Land_PaperBox_open_empty_F",0,0,0],
    ["Land_PaperBox_open_full_F",0,0,0],
    ["Land_PaperBox_closed_F",0,0,0],
    ["Land_DieselGroundPowerUnit_01_F",0,0,0],
    ["Land_ToolTrolley_02_F",0,0,0],
    ["Land_WeldingTrolley_01_F",0,0,0],
    ["Land_Workbench_01_F",0,0,0],
    ["Land_Fuel_tank_big",0,0,0],
    ["Land_Fuel_tank_stairs",0,0,0],
    ["Land_GasTank_01_yellow_F",0,0,0],
    ["Land_GasTank_02_F",0,0,0],
    ["Land_BarrelWater_F",0,0,0],
    ["Land_BarrelWater_grey_F",0,0,0],
    ["Land_WaterBarrel_F",0,0,0],
    ["Land_WaterTank_F",0,0,0],
    ["Land_ClutterCutter_large_F",0,0,0],
    ["Land_Razorwire_F",0,0,0],
    ["Land_Cargo_Tower_V1_F",0,0,0],
    ["Land_Cargo_Patrol_V1_F",0,0,0],
    ["Land_Cargo_Tower_V3_F",0,0,0],
    ["Land_CncShelter_F",0,0,0],
    ["Land_CncWall1_F",0,0,0],
    ["Land_CncWall4_F",0,0,0],
    ["Land_MedicalTent_01_NATO_generic_inner_F",0,0,0],
    ["USMC_WarfareBBarracks",0,0,0],
    ["CUP_A2_Road_PMC_dirt2_25",0,0,0],
    ["CUP_A2_Road_PMC_dirt2_3025",0,0,0],
    ["Land_Rampart_F",0,0,0],                                           // Dirt rampet/and ramps
    ["Dirthump_1_F",0,0,0],
    ["Dirthump_2_F",0,0,0]
];

support_vehicles = [
    [Arsenal_typename,								0,		25,	    0,		"Arsenal Box"],					// Arsenal Box
    ["Land_Cargo40_military_green_F",			    100,	100,	0,		"Resupply Point"], 				// Resupply Point
    [KP_liberation_recycle_building,				200,	0,		0],										// Salvage Depot
    [KP_liberation_air_vehicle_building,			400,	0,		0],										// Flight Control
    [KP_liberation_small_storage_building,			0,		0,		0],										// Small Storage Flat
    [KP_liberation_large_storage_building,			0,		0,		0],										// Large Storage Flat
    [KP_liberation_heli_slot_building,				25,	    0,		0],										// Heli Slot Helipad
    ["karmakut_mpq65",                              250,    0,      0,      "Early Warning Radar"],        	// AN/MPQ-105 Radar
    ["karmakut_tamir",                              1000,  1300,    0,      "Iron Dome"],               	// Iron Dome
    [KP_liberation_plane_slot_building,				250,	0,		0],										// Plane Slot Hangar
    ["ACE_Wheel",									5,		0,		0],										// Spare Wheel
    ["ACE_Track",									5,		0,		0],										// Spare Track
    ["B_Truck_01_flatbed_F",				        150,	0,		150,	"HEMTT Flatbed (Artillery Transport Truck)"],  	            // Cargo Loader Flatbed Nato
    //["Burnes_LCAC_1",        				        250,    50,		200,    "LCAC-Landing Craft Air Cushion"],                        //LCAC
    ["rhsusf_mkvsoc",                               400,    250,    300,    "Mk.V SOC (Assault Transport Boat)"],                       // Mk.V SOC boat
    ["B_Slingload_01_Repair_F",						250,	0,		0,		"Repair Container"],    		// HURON Repair
    ["B_Slingload_01_Ammo_F",						50,		250,	0,		"Ammo Container"],      		// HURON Ammo
	["B_Slingload_01_Fuel_F",						50,		0,		250,	"Fuel Container"],      		// HURON Fuel
    //["rhsusf_M1239_M2_Deploy_socom_d",              300,    300,    300,    "COP Truck"],                   // COP Truck
    [FOB_box_typename,								1500,	0,		400],									// FOB Container
    [FOB_truck_typename,							1800,	0,		500]  									// FOB Truck
];

blufor_squad_inf_light = [];
blufor_squad_inf = [];
blufor_squad_at = [];
blufor_squad_aa = [];
blufor_squad_recon = [];
blufor_squad_para = [];

elite_vehicles = [];
bypass_perm_vehicles = [
	"UK3CB_TKA_B_RHIB",
	"UK3CB_TKA_B_RHIB_Gunboat",
    //"UK3CB_B_AAV_US_DES",
	"rhsusf_mkvsoc",
    //"itc_land_rhsusf_m109_usarmy",
	//"itc_land_rhsusf_m109d_usarmy",
    //"rhsusf_m109_usarmy",
    "rhsusf_m113wd_usarmy_unarmed",
    //"rhsusf_m113wd_usarmy_medical",
    "rhsusf_m113wd_usarmy",
    "rhsusf_m113d_usarmy_unarmed",
    //"rhsusf_m113d_usarmy_medical",
    "rhsusf_m113d_usarmy",
    "rhsusf_m113_usarmy_unarmed",
    //"rhsusf_m113_usarmy_medical",
    "rhsusf_m113_usarmy",
    "rhsusf_stryker_m1126_m2_wd",
    "rhsusf_stryker_m1126_m2_d",
    "rhsusf_stryker_m1126_m2"
];
