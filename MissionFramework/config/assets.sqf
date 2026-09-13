/* Frontline authored assets data and internal constants.
   Admin-facing options are registered in modules/settings/sections.
   Original mission configuration: https://github.com/KillahPotatoes/KP-Liberation */

KPLIB_vehiclePermissionDefinitions = [
    ["VEHICLE_GROUND", "Ground vehicles", ["light", "recon", "medical", "groundLogistics", "transport"], ["driver", "gunner", "commander"]],
    ["VEHICLE_ARMOR", "Armored vehicles", ["heavy"], ["driver", "gunner", "commander"]],
    ["VEHICLE_ROTARY", "Helicopters", ["rotaryLogistics", "rotaryCas"], ["driver", "gunner", "commander"]],
    ["VEHICLE_FIXED", "Fixed-wing aircraft", ["fixedWing"], ["driver", "gunner", "commander"]],
    ["VEHICLE_WEAPONS", "Artillery and static weapons", ["static", "artillery", "atgm", "aa"], ["driver", "gunner", "commander"]],
    ["VEHICLE_BOATS", "Boats", ["boat"], ["driver", "gunner", "commander"]]
];

KPLIB_vehiclePermissionExceptions = [];

KPLIB_COPS_REDEPLOY_REFRESH = 1;

KPLIB_COPS_REQUEST_COOLDOWN = 2;

KPLIB_COPS_MARKER_TEXT = "PB";

KPLIB_COPS_MARKER_OFFSET = [-17, 11, 0];

KPLIB_COPS_COMPOSITION = [
    ["Land_MedicalTent_01_NATO_generic_inner_F", [-16, 11, 0], [1, 0, 0], true],
    ["Flag_Blue_F", [-10, 7, -0.3], [1, 0, 0], false]
];

KPLIB_COPS_FLAG_TEXTURE = "\A3\Data_F\Flags\flag_blue_CO.paa";

KP_liberation_sector_monitor_sector_yield = 0.01;

KP_liberation_zeus_sync_batch_size = 32;

KPLIB_intelligence_site_guards = [14, 18, 16];

KPLIB_intelligence_uncertainty_radii = [1200, 600, 200];

KPLIB_intelligence_strength_bands = [12, 30];

KPLIB_intelligence_vehicle_strength_weight = 4;

KPLIB_intelligence_route_point_limit = 48;

KPLIB_intelligence_operation_kinds = [
    "CONVOY",
    "BATTLEGROUP",
    "DEFENDER",
    "RESERVE",
    "DEEP RECONNAISSANCE PATROL",
    "REINFORCEMENT",
    "AIR_RESPONSE",
    "AIRBORNE_TRANSPORT",
    "FORTIFICATION"
];

KP_liberation_medical_vehicles = [
    // Prairie Fire
    //
    "UK3CB_LDF_O_SUV_Armoured",// (LDF)Lavonein Defense Force) OPFOR medvic
    "vtx_HH60",
    "rhsusf_m113d_usarmy_medical",
    "CUP_B_nM997_USA_DES"
];

KPLIB_fieldHospital_classname = "vtx_stretcher_3";

KPLIB_fieldHospital_groundTolerance = 0.1;

KP_liberation_medical_facilities = [
    // Prairie Fire
    //
    "US_WarfareBFieldhHospital_Base_EP1",
    "rhsusf_M1085A1P2_B_D_Medical_fmtv_usarmy", // CSBD Truck
    "rhsusf_M1085A1P2_B_WD_Medical_fmtv_usarmy", // CSBD Truck
    "Land_MedicalTent_01_white_generic_outer_F", // Deployable CCP classname
    KPLIB_fieldHospital_classname // New CCP
    
];

KPLIB_trashCleanup_batchSize = 25;

KPLIB_trashCleanup_classnames = ["GroundWeaponHolder"];

KP_liberation_ace_crates = [];

KPLIB_radioTowerClassnames = [
    "Land_TTowerBig_2_F"
];

KPLIB_transportConfigs = [
    [
        "USAF_C130J_Cargo",
        -9.5,
        [-0.75, 8,      2],
        [0.75,  8,      2],
        [-0.75, 7,      2],
        [0.75,  7,      2],
        [-0.75, 6,      2],
        [0.75,  6,      2],
        [-0.75, 5,      2],
        [0.75,  5,      2],
        [-0.75, 4,      2],
        [0.75,  4,      2],
        [-0.75, 3,      2],
        [0.75,  3,      2],
        [-0.75, 2,      2],
        [0.75,  2,      2],
        [-0.75, 1,      2],
        [0.75,  1,      2],
        [-0.75, 0,      2],
        [0.75,  0,      2],
        [-0.75, -1,     2],
        [0.75,  -1,     2],
        [-0.75, -2,     2],
        [0.75,  -2,     2]
    ],  // 22 crates
    [
        "USAF_C17",
        -15,
        [-0.75, 14.5,       -0.5],
        [0.75,  14.5,       -0.5],
        [-0.75, 13,         -0.5],
        [0.75,  13,         -0.5],
        [-0.75, 11.5,       -0.5],
        [0.75,  11.5,       -0.5],
        [-0.75, 10,         -0.5],
        [0.75,  10,         -0.5],
        [-0.75, 8.5,        -0.5],
        [0.75,  8.5,        -0.5],
        [-0.75, 7,          -0.5],
        [0.75,  7,          -0.5],
        [-0.75, 5.5,        -0.5],
        [0.75,  5.5,        -0.5],
        [-0.75, 4,          -0.5],
        [0.75,  4,          -0.5],
        [-0.75, 2.5,        -0.5],
        [0.75,  2.5,        -0.5],
        [-0.75, 1,          -0.5],
        [0.75,  1,          -0.5],
        [-0.75, -0.5,       -0.5],
        [0.75,  -0.5,       -0.5],
        [-0.75, -2,         -0.5],
        [0.75,  -2,         -0.5],
        [-0.75, -3.5,       -0.5],
        [0.75,  -3.5,       -0.5],
        [-0.75, -5,         -0.5],
        [0.75,  -5,         -0.5],
        [-0.75, 14.5,       0.55],
        [0.75,  14.5,       0.55],
        [-0.75, 13,         0.55],
        [0.75,  13,         0.55],
        [-0.75, 11.5,       0.55],
        [0.75,  11.5,       0.55],
        [-0.75, 10,         0.55],
        [0.75,  10,         0.55],
        [-0.75, 8.5,        0.55],
        [0.75,  8.5,        0.55],
        [-0.75, 7,          0.55],
        [0.75,  7,          0.55],
        [-0.75, 5.5,        0.55],
        [0.75,  5.5,        0.55],
        [-0.75, 4,          0.55],
        [0.75,  4,          0.55],
        [-0.75, 2.5,        0.55],
        [0.75,  2.5,        0.55],
        [-0.75, 1,          0.55],
        [0.75,  1,          0.55],
        [-0.75, -0.5,       0.55],
        [0.75,  -0.5,       0.55],
        [-0.75, -2,         0.55],
        [0.75,  -2,         0.55],
        [-0.75, -3.5,       0.55],
        [0.75,  -3.5,       0.55],
        [-0.75, -5,         0.55],
        [0.75,  -5,         0.55]
    ],  // 56 crates
    [
        "RHS_CH_47F_cargo",
        -9,
        [0,     -3.5,       -2],
        [0,     -2.5,       -2],
        [0,     -1.5,       -2],
        [0,     -0.5,       -2],
        [0,     0.5,        -2],
        [0,     1.5,        -2],
        [0,     2.5,        -2],
        [0,     3.5,        -2]
    ],  // 8 crates
        ["rhsusf_CH53e_USMC_cargo",
        -11.0, 
        [0, 2.5,    -3.3], 
        [0, 2.5,    -2.1], 
        [0, 1.0,    -3.3], 
        [0, 1.0,    -2.1], 
        [0, -0.5,   -3.3], 
        [0, -0.5,   -2.1], 
        [0, -0.5,   -3.3], 
        [0, -0.5,   -2.1], 
        [0, -2.0,   -3.3], 
        [0, -2.5,   -2.1]
     ],
        [
        "rhsusf_M977A4_usarmy_wd",
        -6.5,
        [0.28,  .6,     0.9],
        [-.32,  .6,     0.9],
        [.28,   -.7,    0.9],
        [-.32,  -.7,    0.9],
        [.28,   -2,     0.9],
        [-.32,  -2,     0.9],
        [.28,   -3.3,   0.9],
        [-.32,  -3.3,   0.9]
    ],  // 8 crates
        [
        "rhsusf_M977A4_usarmy_d",
        -6.5,
        [0.28,  .6,     0.9],
        [-.32,  .6,     0.9],
        [.28,   -.7,    0.9],
        [-.32,  -.7,    0.9],
        [.28,   -2,     0.9],
        [-.32,  -2,     0.9],
        [.28,   -3.3,   0.9],
        [-.32,  -3.3,   0.9]
    ],  // 8 crates
    [
        "rhsusf_M977A4_BKIT_usarmy_wd",
        -6.5,
        [0.28,  .6,     0.9],
        [-.32,  .6,     0.9],
        [.28,   -.7,    0.9],
        [-.32,  -.7,    0.9],
        [.28,   -2,     0.9],
        [-.32,  -2,     0.9],
        [.28,   -3.3,   0.9],
        [-.32,  -3.3,   0.9]
    ],  // 8 crates
    [
        "rhsusf_M977A4_BKIT_usarmy_d",
        -6.5,
        [0.28,  .6,     0.9],
        [-.32,  .6,     0.9],
        [.28,   -.7,    0.9],
        [-.32,  -.7,    0.9],
        [.28,   -2,     0.9],
        [-.32,  -2,     0.9],
        [.28,   -3.3,   0.9],
        [-.32,  -3.3,   0.9]
    ],  // 8 crates
    [
        "rhsusf_M977A4_BKIT_M2_usarmy_wd",
        -6.5,
        [0.28,  .6,     -0.1],
        [-.32,  .6,     -0.1],
        [.28,   -.7,    -0.1],
        [-.32,  -.7,    -0.1],
        [.28,   -2,     -0.1],
        [-.32,  -2,     -0.1],
        [.28,   -3.3,   -0.1],
        [-.32,  -3.3,   -0.1]
    ],  // 8 crates
    [
        "rhsusf_M977A4_BKIT_M2_usarmy_d",
        -6.5,
        [0.28,  .6,     -0.1],
        [-.32,  .6,     -0.1],
        [.28,   -.7,    -0.1],
        [-.32,  -.7,    -0.1],
        [.28,   -2,     -0.1],
        [-.32,  -2,     -0.1],
        [.28,   -3.3,   -0.1],
        [-.32,  -3.3,   -0.1]
    ],  // 8 crates
    [
        "rhsusf_M1084A1R_SOV_M2_D_fmtv_socom",
        -6.5,
        [.30,   .6,     0.6],
        [-.42,  .6,     0.6],
        [.37,   -0.8,   0.6],
        [-.42,  -0.8,   0.6],
        [.37,   -2.25,  0.6],
        [-.42,  -2.25,  0.6]
    ],
    [
        "rhsusf_M1084A1P2_B_WD_fmtv_usarmy",
        -6.5,
        [.30,   .6,     0.6],
        [-.42,  .6,     0.6],
        [.37,   -0.8,   0.6],
        [-.42,  -0.8,   0.6],
        [.37,   -2.25,  0.6],
        [-.42,  -2.25,  0.6]
    ],  // 6 crates
    
    [
        "UK3CB_B_MTVR_Recovery_WDL",
        -6.5,
        [.30,   .6,     0.6],
        [-.42,  .6,     0.6],
        [.37,   -0.8,   0.6],
        [-.42,  -0.8,   0.6],
        [.37,   -2.25,  0.6],
        [-.42,  -2.25,  0.6]
    ],  // 6 crates
    [
        "DEGA_V22_Vehicle_B_NATO",
        -6.5,
        [0,       2.3,  1.8],
        [0,        .6,  1.8],
        [0,        -1,  1.8],
        [0,      -2.7,  1.8]
    ],  // 4 crates
    [
        "vtx_UH60M_SLICK",
        -9.5,
        [0,     1.2,    -0.7],
        [0,     3,  -0.7]
    ]   // 2 crates
];

vehicle_repair_sources = [];

vehicle_rearm_sources = [];

vehicle_refuel_sources = [];

boats_names = [
    "B_Boat_Transport_01_F",
    "UK3CB_TKA_B_RHIB",
    "UK3CB_TKA_B_RHIB_Gunboat",
    "rhsusf_mkvsoc"
];

KPLIB_intelObjectClasses = [
    "Land_File1_F",
    "Land_Document_01_F"
];

KPLIB_intelBuildingClasses = [
    //
    "Land_Cargo_House_V1_F",
    "Land_Cargo_House_V2_F",
    "Land_Cargo_House_V3_F",
    "Land_Cargo_HQ_V1_F",
    "Land_Cargo_HQ_V2_F",
    "Land_Cargo_HQ_V3_F",
    "Land_i_Barracks_V1_dam_F",
    "Land_i_Barracks_V1_F",
    "Land_i_Barracks_V2_dam_F",
    "Land_i_Barracks_V2_F",
    "Land_Medevac_house_V1_F",
    "Land_Medevac_HQ_V1_F",
    "Land_MilOffices_V1_F",
    "Land_Research_house_V1_F",
    "Land_Research_HQ_F",
    "Land_u_Barracks_V2_F"
];

KP_liberation_large_storage_positions = [
    [-5.59961,3.60938,0.6],
    [-3.99902,3.60938,0.6],
    [-2.39941,3.60938,0.6],
    [-0.799805,3.60938,0.6],
    [0.800781,3.60938,0.6],
    [2.40039,3.60938,0.6],
    [4.00098,3.60938,0.6],
    [5.60059,3.60938,0.6],
    [-5.59961,1.80859,0.6],
    [-3.99902,1.80859,0.6],
    [-2.39941,1.80859,0.6],
    [-0.799805,1.80859,0.6],
    [0.800781,1.80859,0.6],
    [2.40039,1.80859,0.6],
    [4.00098,1.80859,0.6],
    [5.60059,1.80859,0.6],
    [-5.59961,0.00976563,0.6],
    [-3.99902,0.00976563,0.6],
    [-2.39941,0.00976563,0.6],
    [-0.799805,0.00976563,0.6],
    [0.800781,0.00976563,0.6],
    [2.40039,0.00976563,0.6],
    [4.00098,0.00976563,0.6],
    [5.60059,0.00976563,0.6],
    [-5.59961,-1.79102,0.6],
    [-3.99902,-1.79102,0.6],
    [-2.39941,-1.79102,0.6],
    [-0.799805,-1.79102,0.6],
    [0.800781,-1.79102,0.6],
    [2.40039,-1.79102,0.6],
    [4.00098,-1.79102,0.6],
    [5.60059,-1.79102,0.6],
    [-5.59961,-3.58984,0.6],
    [-3.99902,-3.58984,0.6],
    [-2.39941,-3.58984,0.6],
    [-0.799805,-3.58984,0.6],
    [0.800781,-3.58984,0.6],
    [2.40039,-3.58984,0.6],
    [4.00098,-3.58984,0.6],
    [5.60059,-3.58984,0.6]
];

KP_liberation_small_storage_positions = [
    [-2.34961,1.80078,0.6],
    [-0.75,1.80078,0.6],
    [0.850586,1.80078,0.6],
    [2.4502,1.80078,0.6],
    [-2.34961,0,0.6],
    [-0.75,0,0.6],
    [0.850586,0,0.6],
    [2.4502,0,0.6],
    [-2.34961,-1.79883,0.6],
    [-0.75,-1.79883,0.6],
    [0.850586,-1.79883,0.6],
    [2.4502,-1.79883,0.6]
];
