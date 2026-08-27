
KPLIB_initPresets = false;

private _start = diag_ticktime;
if (isServer) then {
    ["----- Server starts preset initialization -----", "PRESETS"] call KPLIB_fnc_log;
    ["Not found vehicles listed below are not an issue in general. It just sorts out vehicles from not loaded mods.", "PRESETS"] call KPLIB_fnc_log;
    ["Only if you e.g. use a CUP preset and you get messages about missing CUP classes, then check your loaded mods.", "PRESETS"] call KPLIB_fnc_log;
};

// Fixed mission policy loads before automatic faction combat catalogs.
[] call compileFinal preprocessFileLineNumbers "presets\mission_infrastructure.sqf";
[] call compileFinal preprocessFileLineNumbers "presets\battlespace_tuning.sqf";

KPLIB_autoFactionActive = false;
[] call KPLIB_fnc_applyAutomaticFactionPresets;

// Prices for the blufor infantry squads (supplies, ammo, fuel)
KPLIB_b_allSquads = [
    [blufor_squad_inf_light,0,0,0],
    [blufor_squad_inf,0,0,0],
    [blufor_squad_at,0,0,0],
    [blufor_squad_aa,0,0,0],
    [blufor_squad_recon,0,0,0],
    [blufor_squad_para,0,0,0]
];

// Squad names for build menu
squads_names = [
    localize "STR_LIGHT_RIFLE_SQUAD",
    localize "STR_RIFLE_SQUAD",
    localize "STR_AT_SQUAD",
    localize "STR_AA_SQUAD",
    localize "STR_RECON_SQUAD",
    localize "STR_PARA_SQUAD"
];

// Classnames of objects which should be ignored when building
GRLIB_ignore_colisions_when_building = [
    "Land_Cargo40_military_green_F",
    "UK3CB_B_M270_MLRS_HE_WDL",
    "rhsusf_m109_usarmy",
    "rhsusf_m966_d",
    "rhsusf_m1151_m2crows_usmc_d",
    "rhsusf_stryker_m1132_m2_d",
    "B_LSV_01_unarmed_F",
    "rhsusf_m1240a1_mk19crows_usarmy_d",
    "rhsusf_m1151_mk19crows_usarmy_d",		
    "rhsusf_m1240a1_m2crows_usarmy_d",     
    "rhsusf_m1240a1_mk19_usarmy_d",            
    "rhsusf_m1165a1_gmv_mk19_m240_socom_d",         
    "rhsusf_stryker_m1126_mk19_d",
    // TRANSPORT
    //
    "rhsusf_M1078A1P2_D_fmtv_usarmy",
    "rhsusf_M1083A1P2_B_M2_D_fmtv_usarmy",
    //
    "UK3CB_MDF_B_LSV_02_Armed",
    //
    "rhsusf_m1165a1_gmv_m134d_m240_socom_d",
    // STRYKER
    "B_T_AFV_Wheeled_01_up_cannon_F",
    "rhsusf_stryker_m1126_m2_d",
    "rhsusf_stryker_m1127_m2_d",
    // HUMVEE
    "rhsusf_m1151_m2_v3_usmc_d",
    // MRAP'S
    "rhsusf_M1220_M2_usarmy_d",
    "rhsusf_m1240a1_m240_usarmy_d",
    "rhsusf_m1240a1_m2_usarmy_d",
    "rhsusf_M1220_M153_M2_usarmy_d",
    //
    "UK3CB_MDF_B_LSV_02_Armed",
    "B_Quadbike_01_F",
    "rhsusf_M1084A1R_SOV_M2_D_fmtv_socom",
    "UK3CB_CW_US_B_LATE_M151_Jeep_TOW",
    "WarfareBunkerSign",
    "RHS_M2A3_BUSKIII_wd",
    "rhsusf_m1a2sep1tuskiiwd_usarmy",
    "rhsusf_M1220_M2_usarmy_wd",
    "rhsusf_M1220_M153_M2_usarmy_wd",
    "B_T_UAV_03_dynamicLoadout_F",
    "ITC_Land_B_UAV_UCAVi",
    "cwa_Stretcher",
    "B_Quadbike_01_F",
    "pook_NASAMS_BASE",
    "rhsusf_m1151_mk19crows_usarmy_wd",
    "rhsusf_m1240a1_m240_uik_usarmy_wd",
    "pook_MEADS_base",
    "UK3CB_KRG_B_M270_Avenger",
    "UK3CB_C_AC500",
    "pook_CRAM_BASE",
    "B_AAA_System_01_F",
    "UK3CB_FIA_B_Cessna_T41",
    "B_Ship_Gun_01_F",
    "rhsusf_m1151_m2_v1_usarmy_wd",
    "rhsusf_m1151_m240_v1_usarmy_wd",
    "rhsusf_m1165_usarmy_wd",
    "rhsusf_m1151_m2_lras3_v1_usarmy_wd",
    "rhsusf_m1165a1_gmv_m2_m240_socom_d",
    "rhsusf_m1165a1_gmv_m134d_m240_socom_d",
    "rhsusf_M1078A1P2_D_fmtv_usarmy",
    "rhsusf_M1083A1P2_D_fmtv_usarmy",
	"rhsusf_M1084A1P2_D_fmtv_usarmy",
    "rhsusf_M1078A1P2_WD_fmtv_usarmy",
    "rhsusf_M1083A1P2_B_M2_WD_fmtv_usarmy",
	"rhsusf_M977A4_usarmy_d",
	"rhsusf_M977A4_AMMO_usarmy_d",
	"rhsusf_M977A4_REPAIR_usarmy_d",
	"rhsusf_M978A4_usarmy_d",
	"rhsusf_M1078A1P2_B_D_CP_fmtv_usarmy",
    "rhsusf_m1025_d",
    "rhsusf_m1025_w",
    "rhsusf_m1045_w_s",
    "rhsusf_m998_d_2dr_halftop",
    "rhsusf_m998_w_2dr_halftop",
    "rhsusf_m966_w",
    "rhsusf_m1043_d_m2",
    "rhsusf_m1043_w_m2",
    "rhsusf_m1025_d_Mk19",
    "rhsusf_m1025_w_Mk19",
    "rhsusf_m1045_d",
    "rhsusf_m1045_w",
    "CUP_B_HMMWV_Avenger_USA",
    "CUP_B_MTVR_USA",
    "rhsusf_m113d_usarmy_unarmed",
    "rhsusf_m113d_usarmy_M240",
    "rhsusf_m113d_usarmy",
    "rhsusf_m113d_usarmy_MK19_90",
    "rhsusf_m113d_usarmy_medical",
    "rhsusf_m113_usarmy_medical",
    "rhsusf_m113_usarmy_M240",
    "rhsusf_M1230a1_usarmy_wd",
    "rhsusf_stryker_m1127_m2_wd",
    "rhsusf_stryker_m1126_m2_wd",
    "rhsusf_stryker_m1132_m2_wd",//eod vic
    "UK3CB_B_AAV_US_WDL",
    "UK3CB_MDF_B_RHIB",
    "rhsusf_m998_w_4dr",
    "rhsusf_mrzr4_d",
    "RHS_M2A2",
    "RHS_M2A3",
    "RHS_M2A3_wd",
    "RHS_M6",
    "RHS_M6_wd",
    "UK3CB_B_LAV25_US_WDL",
    "rhsusf_m1a1aimd_usarmy",
    "rhsusf_m1a2sep1d_usarmy",
    "rhsusf_m1a2sep2wd_usarmy",
    "rhsusf_m109d_usarmy",
    "CFP_B_USMC_M270_MLRS_HE_DES_01",
    "CFP_B_USMC_M270_MLRS_DPICM_DES_01",
    "CUP_O_UH1H_TKA",
    "RHS_MELB_AH6M_H",
    "RHS_MELB_AH6M_L",
    "RHS_MELB_AH6M_M",
    "RHS_MELB_AH6M",
    "rhsusf_CH53E_USMC",
    "rhsusf_CH53e_USMC_cargo",
    "RHS_CH_47F_cargo",
    "RHS_CH_47F",
    "vtx_HH60",
    "vtx_UH60M",
    "vtx_UH60M_SLICK",
    "vtx_MH60M_DAP",
    "fza_ah64d_b2e",
    "fza_ah64d_b2e_nr",
    "ITC_Land_B_UAV_MQ4i",
    "RHS_C130J",
    "CUP_B_CUP_SearchLight_static_US",
    "RHS_M2StaticMG_MiniTripod_D",
    "RHS_M2StaticMG_D",
    "RHS_MK19_TriPod_D",
    "RHS_TOW_TriPod_D",
    "RHS_Stinger_AA_pod_WD",
    "RHS_Stinger_AA_pod_D",
    "UK3CB_B_Static_M240_Elcan_High_US_W",
    "pook_M777_DES",
    "pook_MLRS_BLUFOR",
    "itc_land_b_vls2_slam",
    "itc_land_rhsusf_m252_d",
    "itc_land_rhsusf_m119_d",
	"Base_WarfareBBarrier10xTall",
    "Land_HBarrierWall6_F",
    "Land_HBarrierWall4_F",
    "Land_HBarrierWall_corner_F",
    "Land_HBarrierWall_corridor_F",
    "Land_HBarrierTower_F",
    "Land_Fort_Watchtower_EP1",
    "Land_HBarrier_Big_F",
    "Land_HBarrier_5_F",
    "Land_HBarrier_3_F",
    "land_pmc_opx_hesco_stack",
    "Land_HBarrier1",
    "Land_Billboard_F",
    "Land_Billboard_03_blank_F",
    "Land_Billboard_03_aan_F",
	"Land_Billboard_03_koke_F",
	"Land_Billboard_03_cheese_F",
    "Land_Billboard_03_bluking_F",
    "Land_Billboard_03_ionbase_F",
    "Land_Billboard_03_lyfe_F",
    "Land_Billboard_03_argois_F",
    "Land_Billboard_03_ygont_F",
    "Land_Billboard_03_pate_F",
    "SignAd_SponsorS_Suatmm_F",
    "SignAd_SponsorS_Fuel_white_F",
    "SignAd_SponsorS_Larkin_F",
    "Land_BagFence_Short_F",
	"SignAd_SponsorS_ARMEX_F",
	"SignAd_SponsorS_ION_F",
    "Land_Billboard_03_ygont_F",
    "SignAd_SponsorS_Suatmm_F",
    "SignAd_SponsorS_Fuel_white_F",
    "SignAd_SponsorS_Larkin_F",
    "Land_BagFence_Short_F",
	"SignAd_SponsorS_ARMEX_F",
	"SignAd_SponsorS_ION_F",
	"SignAd_SponsorS_Larkin_F",
	"SignAd_SponsorS_Quontrol_F",
	"SignAd_SponsorS_Vrana_F",
    "SignAd_SponsorS_Larkin_F",
    "Land_Sign_WarningMilitaryArea_F", 
    "Land_Sign_WarningMilAreaSmall_F", 
    "Land_Sign_WarningMilitaryVehicles_F", 
    "Land_Sign_WarningNoWeapon_F", 
    "TFAR_Land_Communication_F",
    "US_WarfareBFieldhHospital_Base_EP1",
    "East_EP1",
    "Land_Barrack2_EP1",
    "Land_Mil_Guardhouse_EP1",
    "WarfareBCamp",
    "Fortress2",
    "Land_fortified_nest_big_EP1",
    "Fortress1",
    "Land_fortified_nest_small_EP1",
    "ShedSmall",
    "Land_fort_artillery_nest_EP1",
    "Land_fort_rampart_EP1",
    "Land_GuardShed",
    "Hedgehog",
    "Land_Army_hut_storrage",
    "Land_jezekbeton",
    "Land_fort_bagfence_round",
    "Land_fort_bagfence_corner",
    "Land_fort_bagfence_long",
    "Land_BagFence_Round_F",
    "Land_BagFence_Short_F",
    "Land_BagFence_Long_F",
    "Land_BagFence_Corner_F",
    "Land_BagFence_End_F",
    "land_pmc_opx_tx_barrier",
    "land_pmc_opx_tx_barrier_2",
    "land_pmc_opx_alaska1",
    "Land_CncBarrierMedium_F",
    "Land_CncBarrierMedium4_F",
    "Land_Concrete_SmallWall_4m_F",
    "Land_Concrete_SmallWall_8m_F",
    "land_pmc_opx_c_bar1",
    "Land_HelipadCircle_F",
    "Land_HelipadRescue_F",
    "Land_runway_edgelight",
    "Land_runway_edgelight_blue_F",
    "Land_Flush_Light_yellow_F",
    "Land_Flush_Light_green_F",
    "Land_Flush_Light_red_F",
    "Land_PortableLight_single_F",
    "Land_PortableLight_double_F",
    "Land_LampHarbour_F",
    "Land_LampHalogen_F",
    "Flag_NATO_F",
    "Flag_US_F", 
    "Flag_CW_US_ARMY", 
    "Flag_CW_US_NAVY", 
    "Flag_CW_US_AIR", 
    "Flag_UK_F", 
    "UnitedKingdom_Army_Flag",
    "FlagCarrierINDFOR_EP1", 
    "FlagCarrierBLUFOR_EP1", 
    "FlagCarrierOPFOR_EP1", 
    "FlagCarrierWhite_EP1", 
    "Flag_FD_Purple_F", 
    "Flag_FD_Orange_F", 
    "ITC_Land_loudspeakers2",
    "US_WarfareBUAVterminal_Base_EP1", 
    "PowGen_Big_EP1", 
    "Land_CamoNet_NATO_EP1", 
    "Land_CamoNetVar_NATO_EP1", 
    "Land_CamoNetB_NATO_EP1", 
    "Land_CampingChair_V1_F", 
    "Land_CampingChair_V2_F", 
    "Land_CampingTable_F", 
    "MapBoard_altis_F", 
    "MapBoard_stratis_F", 
    "Land_BarGate_F",
    "land_pmc_opx_speedbump",
    "Land_Pallet_MilBoxes_F",
    "Land_PaperBox_open_empty_F",
    "Land_PaperBox_open_full_F",
    "Land_PaperBox_closed_F",
    "Land_DieselGroundPowerUnit_01_F",
    "Land_ToolTrolley_02_F",
    "Land_WeldingTrolley_01_F",
    "Land_Workbench_01_F",
    "Land_Fuel_tank_big",
    "Land_Fuel_tank_stairs",
    "Land_GasTank_01_yellow_F",
    "Land_GasTank_02_F",
    "Land_BarrelWater_F",
    "Land_BarrelWater_grey_F",
    "Land_WaterBarrel_F",
    "Land_WaterTank_F",
	"B_Slingload_01_Repair_F",
	"B_Slingload_01_Ammo_F",
	"B_Slingload_01_Fuel_F",
	"Land_Cargo20_military_green_F",
	"WarfareBDepot",
	"B_Slingload_01_Cargo_F",
	"B_supplyCrate_F",
	"ContainmentArea_02_sand_F",
	"ContainmentArea_01_sand_F",
	"Land_Mil_Repair_center_EP1",
	"Land_Airport_01_controlTower_F",
	"Land_HelipadCircle_F",
	"Land_TentHangar_V1_F",
	"CargoNet_01_box_F",
	"B_CargoNet_01_ammo_F",
	"CargoNet_01_barrels_F",
    "Sign_Sphere100cm_F",
    "Land_ClutterCutter_large_F",
    "CUP_A2_Road_PMC_dirt2_25",
    "CUP_A2_Road_PMC_dirt2_3025",
    "Land_Cargo_Tower_V3_F",
    "CUP_A2_Road_grav_60_10",
    "CUP_A2_Road_grav_25",
    "CUP_A2_Road_grav_22_50",
    "CUP_A2_Road_grav_30_25",
    "CUP_A2_Road_grav_25",
    "Land_CncWall4_F"
];

// Checking all preset arrays for missing mods and sort out not available classnames

// BLUFOR
infantry_units                              = infantry_units                            select {[( _x select 0)] call KPLIB_fnc_checkClass};
light_vehicles                              = light_vehicles                            select {[( _x select 0)] call KPLIB_fnc_checkClass};
recon_vehicles                              = recon_vehicles                            select {[( _x select 0)] call KPLIB_fnc_checkClass};
medical_vehicles                            = medical_vehicles                          select {[( _x select 0)] call KPLIB_fnc_checkClass};
groundlogi_vehicles                         = groundlogi_vehicles                       select {[( _x select 0)] call KPLIB_fnc_checkClass};
artillery_vehicles                          = artillery_vehicles                        select {[( _x select 0)] call KPLIB_fnc_checkClass};
atgm_vehicles                               = atgm_vehicles                             select {[( _x select 0)] call KPLIB_fnc_checkClass};
aa_vehicles                                 = aa_vehicles                               select {[( _x select 0)] call KPLIB_fnc_checkClass};
heavy_vehicles                              = heavy_vehicles                            select {[( _x select 0)] call KPLIB_fnc_checkClass};
rotarylogi_vehicles                         = rotarylogi_vehicles                       select {[( _x select 0)] call KPLIB_fnc_checkClass};
rotarycas_vehicles                          = rotarycas_vehicles                        select {[( _x select 0)] call KPLIB_fnc_checkClass};
fixedwing_vehicles                          = fixedwing_vehicles                        select {[( _x select 0)] call KPLIB_fnc_checkClass};
static_vehicles                             = static_vehicles                           select {[( _x select 0)] call KPLIB_fnc_checkClass};
buildings                                   = buildings                                 select {[( _x select 0)] call KPLIB_fnc_checkClass};
support_vehicles                            = support_vehicles                          select {[( _x select 0)] call KPLIB_fnc_checkClass};
blufor_squad_inf_light                      = blufor_squad_inf_light                    select {[_x] call KPLIB_fnc_checkClass};
blufor_squad_inf                            = blufor_squad_inf                          select {[_x] call KPLIB_fnc_checkClass};
blufor_squad_at                             = blufor_squad_at                           select {[_x] call KPLIB_fnc_checkClass};
blufor_squad_aa                             = blufor_squad_aa                           select {[_x] call KPLIB_fnc_checkClass};
blufor_squad_recon                          = blufor_squad_recon                        select {[_x] call KPLIB_fnc_checkClass};
blufor_squad_para                           = blufor_squad_para                         select {[_x] call KPLIB_fnc_checkClass};
elite_vehicles                              = elite_vehicles                            select {[_x] call KPLIB_fnc_checkClass};

// OPFOR
militia_squad                               = militia_squad                             select {[_x] call KPLIB_fnc_checkClass};
militia_vehicles                            = militia_vehicles                          select {[_x] call KPLIB_fnc_checkClass};
opfor_vehicles                              = opfor_vehicles                            select {[_x] call KPLIB_fnc_checkClass};
opfor_vehicles_low_intensity                = opfor_vehicles_low_intensity              select {[_x] call KPLIB_fnc_checkClass};
opfor_battlegroup_vehicles                  = opfor_battlegroup_vehicles                select {[_x] call KPLIB_fnc_checkClass};
opfor_battlegroup_vehicles_low_intensity    = opfor_battlegroup_vehicles_low_intensity  select {[_x] call KPLIB_fnc_checkClass};
opfor_troup_transports                      = opfor_troup_transports                    select {[_x] call KPLIB_fnc_checkClass};
opfor_choppers                              = opfor_choppers                            select {[_x] call KPLIB_fnc_checkClass};
opfor_air                                   = opfor_air                                 select {[_x] call KPLIB_fnc_checkClass};

// Resistance
KP_liberation_guerilla_units                = KP_liberation_guerilla_units              select {[_x] call KPLIB_fnc_checkClass};
KP_liberation_guerilla_vehicles             = KP_liberation_guerilla_vehicles           select {[_x] call KPLIB_fnc_checkClass};

// Civilians
civilians                                   = civilians                                 select {[_x] call KPLIB_fnc_checkClass};
civilian_vehicles                           = civilian_vehicles                         select {[_x] call KPLIB_fnc_checkClass};

// Misc
KPLIB_transportConfigs                      = KPLIB_transportConfigs                    select {[_x select 0] call KPLIB_fnc_checkClass};
KPLIB_aiResupplySources                     = KPLIB_aiResupplySources                   select {[_x] call KPLIB_fnc_checkClass};

/*
    Fetch arrays with only classnames from the blufor preset build arrays
    Beware that all classnames are converted to lowercase. Important for e.g. `in` checks, as it's case-sensitive.
*/
KPLIB_b_infantry_classes                    = infantry_units                            apply {toLower (_x select 0)};
KPLIB_b_light_classes                       = light_vehicles                            apply {toLower (_x select 0)};
KPLIB_b_recon_classes                       = recon_vehicles                            apply {toLower (_x select 0)};
KPLIB_b_medical_classes                     = medical_vehicles                          apply {toLower (_x select 0)};
KPLIB_b_groundlogi_classes                  = groundlogi_vehicles                       apply {toLower (_x select 0)};
KPLIB_b_artillery_classes                   = artillery_vehicles                        apply {toLower (_x select 0)};
KPLIB_b_atgm_classes                        = atgm_vehicles                             apply {toLower (_x select 0)};
KPLIB_b_aa_classes                          = aa_vehicles                               apply {toLower (_x select 0)};
KPLIB_b_heavy_classes                       = heavy_vehicles                            apply {toLower (_x select 0)};
KPLIB_b_rotarylogi_classes                  = rotarylogi_vehicles                       apply {toLower (_x select 0)};
KPLIB_b_rotarycas_classes                   = rotarycas_vehicles                        apply {toLower (_x select 0)};
KPLIB_b_fixedwing_classes                   = fixedwing_vehicles                        apply {toLower (_x select 0)};
KPLIB_b_air_classes                         = KPLIB_b_rotarylogi_classes + KPLIB_b_rotarycas_classes + KPLIB_b_fixedwing_classes;
KPLIB_b_static_classes                      = static_vehicles                           apply {toLower (_x select 0)};
KPLIB_b_buildings_classes                   = buildings                                 apply {toLower (_x select 0)};
KPLIB_b_support_classes                     = support_vehicles                          apply {toLower (_x select 0)};
KPLIB_transport_classes                     = KPLIB_transportConfigs                    apply {toLower (_x select 0)};

KPLIB_b_infantry_classes append (blufor_squad_inf_light + blufor_squad_inf + blufor_squad_at + blufor_squad_aa + blufor_squad_recon + blufor_squad_para);
KPLIB_b_infantry_classes                    = KPLIB_b_infantry_classes                  apply {toLower _x};
KPLIB_b_infantry_classes                    = KPLIB_b_infantry_classes                  arrayIntersect KPLIB_b_infantry_classes;

/*
    Opfor squad compositions
*/
KPLIB_o_squadStd    = [opfor_squad_leader, opfor_medic, opfor_machinegunner, opfor_heavygunner, opfor_medic, opfor_marksman, opfor_grenadier, opfor_rpg];
KPLIB_o_squadInf    = [opfor_squad_leader, opfor_medic, opfor_machinegunner, opfor_heavygunner, opfor_heavygunner, opfor_marksman, opfor_sharpshooter, opfor_sniper];
KPLIB_o_squadTank   = [opfor_squad_leader, opfor_medic, opfor_machinegunner, opfor_rpg, opfor_rpg, opfor_grenadier, opfor_grenadier, opfor_at];
KPLIB_o_squadAir    = [opfor_squad_leader, opfor_medic, opfor_machinegunner, opfor_rpg, opfor_rpg, opfor_aa, opfor_grenadier, opfor_aa];

/*
    Liberation specific collections
*/

private _airBuildList = rotarylogi_vehicles + rotarycas_vehicles + fixedwing_vehicles;

// Combines Phantom recon vehicles into light vehicles list for building
KPLIB_buildList         = [[], infantry_units, light_vehicles + recon_vehicles + medical_vehicles, heavy_vehicles, _airBuildList, static_vehicles + artillery_vehicles + atgm_vehicles + aa_vehicles, buildings, support_vehicles + groundlogi_vehicles, KPLIB_b_allSquads];
KPLIB_crates            = [KP_liberation_supply_crate, KP_liberation_ammo_crate, KP_liberation_fuel_crate];
KPLIB_airSlots          = [KP_liberation_heli_slot_building, KP_liberation_plane_slot_building];
KPLIB_storageBuildings  = [KP_liberation_small_storage_building, KP_liberation_large_storage_building];
KPLIB_upgradeBuildings  = [KP_liberation_recycle_building, KP_liberation_air_vehicle_building, KP_liberation_heli_slot_building, KP_liberation_plane_slot_building];
KPLIB_aiResupplySources append [Respawn_truck_typename, huron_typename, Arsenal_typename];

KPLIB_crates            = KPLIB_crates              apply {toLower _x};
KPLIB_airSlots          = KPLIB_airSlots            apply {toLower _x};
KPLIB_storageBuildings  = KPLIB_storageBuildings    apply {toLower _x};
KPLIB_upgradeBuildings  = KPLIB_upgradeBuildings    apply {toLower _x};
KPLIB_aiResupplySources = KPLIB_aiResupplySources   apply {toLower _x};

/*
    Classname collections
*/
// All land vehicle classnames
KPLIB_allLandVeh_classes = [[], [huron_typename]] select (huron_typename isKindOf "Air");
{
    KPLIB_allLandVeh_classes append _x;
} forEach [
    militia_vehicles apply {toLower _x},
    opfor_vehicles apply {toLower _x},
    opfor_vehicles_low_intensity apply {toLower _x},
    opfor_battlegroup_vehicles apply {toLower _x},
    opfor_battlegroup_vehicles_low_intensity apply {toLower _x},
    opfor_troup_transports apply {toLower _x},
    KPLIB_b_light_classes,
    KPLIB_b_recon_classes,
    KPLIB_b_medical_classes,
    KPLIB_b_groundlogi_classes,
    KPLIB_b_artillery_classes,
    KPLIB_b_atgm_classes,
    KPLIB_b_aa_classes,
    KPLIB_b_heavy_classes,
    KPLIB_b_support_classes select {_x isKindOf "Car" || _x isKindOf "Tank"}
];
KPLIB_allLandVeh_classes = KPLIB_allLandVeh_classes arrayIntersect KPLIB_allLandVeh_classes;

// All air vehicle classnames
KPLIB_allAirVeh_classes = [[], [huron_typename]] select (huron_typename isKindOf "Air");
{
    KPLIB_allAirVeh_classes append _x;
} forEach [opfor_choppers apply {toLower _x}, opfor_air apply {toLower _x}, KPLIB_b_air_classes, KPLIB_b_support_classes select {_x isKindOf "Air"}];

// All blufor vehicle (land and air) classnames
KPLIB_b_allVeh_classes = [];
{
    KPLIB_b_allVeh_classes append _x;
} forEach [KPLIB_b_light_classes, KPLIB_b_recon_classes, KPLIB_b_medical_classes, KPLIB_b_groundlogi_classes, KPLIB_b_artillery_classes, KPLIB_b_atgm_classes, KPLIB_b_aa_classes, KPLIB_b_heavy_classes, KPLIB_b_air_classes, KPLIB_b_static_classes, KPLIB_b_support_classes];

// All opfor vehicle (land and air) classnames
KPLIB_o_allVeh_classes  = [];
{
    KPLIB_o_allVeh_classes append _x;
} forEach [
    militia_vehicles,
    opfor_vehicles,
    opfor_vehicles_low_intensity,
    opfor_battlegroup_vehicles,
    opfor_battlegroup_vehicles_low_intensity,
    opfor_troup_transports,
    opfor_choppers,
    opfor_air
];
KPLIB_o_allVeh_classes = KPLIB_o_allVeh_classes apply {toLower _x};
KPLIB_o_allVeh_classes = KPLIB_o_allVeh_classes arrayIntersect KPLIB_o_allVeh_classes;

// All regular opfor soldier classnames
KPLIB_o_inf_classes = [opfor_sentry, opfor_rifleman, opfor_grenadier, opfor_squad_leader, opfor_team_leader, opfor_marksman, opfor_machinegunner, opfor_heavygunner, opfor_medic, opfor_rpg, opfor_at, opfor_aa, opfor_officer, opfor_sharpshooter, opfor_sniper,opfor_engineer,opfor_paratrooper,opfor_rto];
KPLIB_o_inf_classes = KPLIB_o_inf_classes apply {toLower _x};

/*
    Vehicle type permission arrays
*/
KPLIB_typeLightClasses = +KPLIB_b_light_classes;
KPLIB_typeReconClasses = +KPLIB_b_recon_classes;
KPLIB_typeMedicalClasses = +KPLIB_b_medical_classes;
KPLIB_typeGroundLogiClasses = +KPLIB_b_groundlogi_classes;
KPLIB_typeArtilleryClasses = +KPLIB_b_artillery_classes;
KPLIB_typeATGMClasses = +KPLIB_b_atgm_classes;
KPLIB_typeAAClasses = +KPLIB_b_aa_classes;
KPLIB_typeHeavyClasses = +KPLIB_b_heavy_classes;
KPLIB_typeRotaryLogiClasses = +KPLIB_b_rotarylogi_classes;
KPLIB_typeRotaryCasClasses = +(KPLIB_b_rotarycas_classes + ["rhs_melb_ah6m"]);
KPLIB_typeFixedWingClasses = +KPLIB_b_fixedwing_classes;
{
    switch (true) do {
        case (_x isKindOf "Tank"):  {KPLIB_typeHeavyClasses      pushBack _x};
        case (_x isKindOf "Air"):   {KPLIB_typeRotaryLogiClasses pushBack _x};
        default                     {KPLIB_typeLightClasses      pushBack _x};
    };
} forEach (KPLIB_b_support_classes + [toLower huron_typename]);

// Military alphabet used for FOBs and convois
military_alphabet = ["Alpha", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot", "Golf", "Hotel", "India", "Juliet", "Kilo", "Lima", "Mike", "November", "Oscar", "Papa", "Quebec", "Romeo", "Sierra", "Tango", "Uniform", "Victor", "Whiskey", "X-Ray", "Yankee", "Zulu"];

// Misc variables
markers_reset = [99999,99999,0];
zeropos = [0,0,0];
KPLIB_sarWreck = "Land_Wreck_Heli_Attack_01_F";
KPLIB_sarFire = "test_EmptyObjectForFireBig";

KPLIB_initPresets = true;

if (isServer) then {[format ["----- Preset initialization finished. Time needed: %1 seconds -----", diag_ticktime - _start], "PRESETS"] call KPLIB_fnc_log;};
