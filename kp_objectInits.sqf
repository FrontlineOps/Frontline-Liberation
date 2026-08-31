KPLIB_objectInits = [

	// Add helipads to zeus, as they can't be recycled after built
    [
        ["Helipad_base_F","Helipad"],
        {{[_x, [[_this], true]] remoteExecCall ["addCuratorEditableObjects", 2]} forEach allCurators;},
        true
    ],

    // Add ViV and build action to FOB box/truck
    [
        [FOB_box_typename, FOB_truck_typename],
        {
            [_this] spawn {
                params ["_fobBox"];
                waitUntil {sleep 0.1; time > 0};
                [_fobBox] call KPLIB_fnc_setFobMass;
                if ((typeOf _fobBox) isEqualTo FOB_box_typename) then {
                    [_fobBox] call KPLIB_fnc_setFobMass;
                    [_fobBox] remoteExecCall ["KPLIB_fnc_setLoadableViV", 0, _fobBox];
                };
                [_fobBox] remoteExecCall ["KPLIB_fnc_addActionsFob", 0, _fobBox];
            };
        }
    ],

    // Add FOB building damage handler override and repack action
    [
        [FOB_typename],
        {
            _this addEventHandler ["HandleDamage", {0}];
            [_this] spawn {
                params ["_fob"];
                waitUntil {sleep 0.1; time > 0};
                [_fob] remoteExecCall ["KPLIB_fnc_addActionsFob", 0, _fob];
            };
        }
    ],

    // Add storage type variable to built storage areas (only for FOB built/loaded ones)
    [
        [KP_liberation_small_storage_building, KP_liberation_large_storage_building],
        {_this setVariable ["KP_liberation_storage_type", 0, true];}
    ],

    // Add ACE variables to corresponding building types
    [
        [KP_liberation_recycle_building],
        {_this setVariable ["ace_isRepairFacility", 1, true];}
    ],
    [
        KP_liberation_medical_facilities,
        {_this setVariable ["ace_medical_isMedicalFacility", true, true];}
    ],    
    [
        ["nyoom"], // THIS IS THE FACILITY THAT AUTO HEALS AT OPS BASE, KEEP IT UP TO DATE.
        {
            [_this, false] spawn KC_AUTOHEALER; // Second parameter determines if auto heal is disabled when enemies are within 1km including Air. For the future if we want to put it at FOBs.
        }
    ],
    [
        KP_liberation_medical_vehicles,
        {_this setVariable ["ace_medical_isMedicalVehicle", true, true];}
    ],

    // Make sure a slingloaded object is local to the helicopter pilot
    [
        ["Helicopter"],
        {if (isServer) then {[_this] call KPLIB_fnc_addRopeAttachEh;} else {[_this] remoteExecCall ["KPLIB_fnc_addRopeAttachEh", 2];};},
        true
    ],

    // Add valid vehicles to support module, if system is enabled
    [
        KP_liberation_suppMod_artyVeh,
        {if (KP_liberation_suppMod > 0) then {KPLIB_suppMod_arty synchronizeObjectsAdd [_this];};}
    ],
    
    // Disable autocombat (if set in parameters) and fleeing
    [
        ["Man"],
        {
            if (!(GRLIB_autodanger) && {(side _this) isEqualTo GRLIB_side_friendly}) then {
                _this disableAI "AUTOCOMBAT";
            };
            _this allowFleeing 0;

            if((side _this) isEqualTo GRLIB_side_enemy) then {
                _this linkItem "";
            };
            if((typeOf _this) == opfor_rto) then {
                _this setUnitLoadout [opfor_rto_loadout, true];
                [ 
                    { _this call BATTLESPACE_ARTILLERY_OBSERVER_COROUTINE }, 
                    10, 
                    [_this] 
                ] call CBA_fnc_addPerFrameHandler;
            };
        },
        true
    ],
    [
        ["UK3CB_FIA_B_Cessna_T41"],
        {   
            _this setObjectTexture [0, "UK3CB_Factions\addons\UK3CB_Factions_Vehicles\air\UK3CB_Factions_Vehicles_Cessna\data\aircraft_e_us_army_wdl_co.paa"];
            [_this, 4] call ace_cargo_fnc_setSpace;
        }
    ],
    [
        ["UK3CB_CW_US_B_LATE_Cessna_T41"],
        {   
            [_this, 4] call ace_cargo_fnc_setSpace;
        }
    ],
    //
    //
    [
        ["USAF_MQ9"],
        {   
            _this setVariable ["LESH_canBeTowed", 1];  
    	    _this setVariable ["LESH_towFromFront", 1];  
    	    _this setVariable ["LESH_AxisOffsetTarget", [0,8,-0.8]];  
            _this setVariable ["LESH_WheelOffset", [0,-1.5]];
        }
    ],
    [
        ["ITC_Land_B_UAV_UCAVi"],
        {   
            _this setVariable ["LESH_canBeTowed", 1];  
    	    _this setVariable ["LESH_towFromFront", 1];  
    	    _this setVariable ["LESH_AxisOffsetTarget", [0,8,-0.8]];  
            _this setVariable ["LESH_WheelOffset", [0,-1.5]];
        }
    ],
    [
        ["B_T_UAV_03_dynamicLoadout_F"],
        {   
            _this setVariable ["LESH_canBeTowed", 1];  
    	    _this setVariable ["LESH_towFromFront", 1];  
    	    _this setVariable ["LESH_AxisOffsetTarget", [0,8,-0.8]];  
            _this setVariable ["LESH_WheelOffset", [0,-1.5]];
        }
    ],
	[
        ["SignAd_SponsorS_ARMEX_F"],
        { 
			_this setObjectTextureGlobal [0, "res\Resources.paa"];
		}
    ],
	[
        ["SignAd_SponsorS_ION_F"],
        { 
			_this setObjectTextureGlobal [0, "res\Artillery.paa"];
		}
    ],
	[
        ["SignAd_SponsorS_F"],
        { 
			_this setObjectTextureGlobal [0, "res\CCP.paa"];
		}
    ],
	[
        ["SignAd_SponsorS_Vrana_F"],
        { 
			_this setObjectTextureGlobal [0, "res\Motor_Pool.paa"];
		}
    ],
    [
        ["SignAd_SponsorS_Quontrol_F"],
        { 
			_this setObjectTextureGlobal [0, "res\Helipads.paa"];
		}
    ],
    [
        ["Land_Billboard_03_blank_F"],
        {
            _this setObjectTextureGlobal [0, "res\KarmaAdmin.paa"];
        }
    ],
    [
        ["SignAd_SponsorS_Suatmm_F"],
        {
            _this setObjectTextureGlobal [0, "res\KarmaArtyPitSign.paa"];
        }
    ],
    [
        ["SignAd_SponsorS_Larkin_F"],
        {
            _this setObjectTextureGlobal [0, "res\KarmaBoatDock.paa"];
        }
    ]    
];
// Role arsenal

[Arsenal_typename, "init",
    { 
        private _box = (_this select 0);
        private _player = player;

        //diag_log format ["WATERGARD - ROLE ARSENAL EH Role: %1", roleDescription _player];

        /*
        // Loop through every box just to be safe.
        {
            [_box, _player] call roleArsenal;          
        } forEach KARMA_ARSENAL_CRATES;
        */
        
        KARMA_ARSENAL_CRATES pushBackUnique _box;
        [roleArsenal, [_box, _player], 5] call CBA_fnc_waitAndExecute;
    },
    true,
    [],
    true
] call CBA_fnc_addClassEventHandler;

["UK3CB_AK47_Equipbox_Indfor", "init",
    { 
        private _box = (_this select 0);
        [_box, false, [0, 0, 0], 1] call ace_dragging_fnc_setDraggable;
        [_box, false, [0, 0, 0], 1] call ace_dragging_fnc_setCarryable;
        private _player = player;

        if (isServer) then {
            clearMagazineCargoGlobal _box;
	        clearItemCargoGlobal _box;
	        clearBackpackCargoGlobal _box;
	        clearWeaponCargoGlobal _box;
        };

        OPFOR_ARSENAL_CRATES pushBackUnique _box;

        if (side player == GRLIB_side_enemy) then {
            [_box, false] call ace_arsenal_fnc_removeBox;
            private _items = [player] call OpforArsenal_DetermineGear;
	        [_box, _items, false] call ace_arsenal_fnc_initBox;
        };
    },
    true,
    [],
    true
] call CBA_fnc_addClassEventHandler;

["ttt_phalanx", "init",
    { 
        deleteVehicle (_this select 0);
    },
    true,
    [],
    true
] call CBA_fnc_addClassEventHandler;

["ttt_rim116", "init",
    { 
        deleteVehicle (_this select 0);
    },
    true,
    [],
    true
] call CBA_fnc_addClassEventHandler;

["jdg_mk29", "init",
    { 
        deleteVehicle (_this select 0);
    },
    true,
    [],
    true
] call CBA_fnc_addClassEventHandler;

["ATLAS_B_RAM_Launcher_naval", "init",
    { 
        deleteVehicle (_this select 0);
    },
    true,
    [],
    true
] call CBA_fnc_addClassEventHandler;

["ATLAS_B_Phalanx", "init",
    { 
        deleteVehicle (_this select 0);
    },
    true,
    [],
    true
] call CBA_fnc_addClassEventHandler;

["ATLAS_B_SS_Launcher_naval", "init",
    { 
        deleteVehicle (_this select 0);
    },
    true,
    [],
    true
] call CBA_fnc_addClassEventHandler;

["ATLAS_LHD_4", "init",
    { 
        deleteVehicle (_this select 0);
    },
    true,
    [],
    true
] call CBA_fnc_addClassEventHandler;
// ----------------- START VIC CUSTOMISATION -----------------

// ---------------------- BLUFOR TOWING ----------------------

["RHS_MELB_MH6M", "init",
    {
        _vehicle = _this select 0;
        _vehicle setVariable ["LESH_canBeTowed", 1];  
    	_vehicle setVariable ["LESH_towFromFront", 1];  
    	_vehicle setVariable ["LESH_AxisOffsetTarget", [0,8,-0.8]];  
        _vehicle setVariable ["LESH_WheelOffset", [0,-1.5]];
    },
    true,
    [],
    true
] call CBA_fnc_addClassEventHandler;

["vtx_MH60M", "init",
    {
        _vehicle = _this select 0;
        _vehicle setVariable ["LESH_canBeTowed", 1];
        _vehicle setVariable ["LESH_towFromFront", 1];
        _vehicle setVariable ["LESH_AxisOffsetTarget", [0,10,-0.8]];
        _vehicle setVariable ["LESH_WheelOffset", [0,-1.5]];

        [
            _vehicle,
            ["uh60m_usa",1], 
	        ["Cockpitdoors_Hide",0,"RADAR_HIDE",0,"FLIR_HIDE",0,"FuelProbe_show",0,"MAWS_Tubes_Show",1,"ERFS_show",0,"MH60MMisc_show",0,"Hoist_hide",1,"Skis_show",0,"HH60Flares_show",1,"HH60GRadar_show",1,"HH60GFlir_show",1,"GunnerSeats_Hide",0,"Minigun_Sight_L_hide",0,"Minigun_Sight_R_hide",0]
        ] call BIS_fnc_initVehicle;
    },
    true,
    [],
    true
] call CBA_fnc_addClassEventHandler;

["vtx_MH60M_DAP", "init",
    {
        _vehicle = _this select 0;
        _vehicle setVariable ["LESH_canBeTowed", 1];
        _vehicle setVariable ["LESH_towFromFront", 1];
        _vehicle setVariable ["LESH_AxisOffsetTarget", [0,10,-0.8]];
        _vehicle setVariable ["LESH_WheelOffset", [0,-1.5]];

        [
            _vehicle,
            ["uh60m_usa",1], 
	        ["GunnerSeats_Hide",1,"Minigun_Sight_L_hide",1,"Minigun_Sight_R_hide",1,"MH60MMisc_show",1,"Cockpitdoors_Hide",0,"FuelProbe_show",0,"RADAR_HIDE",0,"FLIR_HIDE",0,"MAWS_Tubes_Show",1,"Hoist_hide",0,"Skis_show",0,"HH60Flares_show",1,"HH60GRadar_show",1,"HH60GFlir_show",1,"ERFS_show",0]
        ] call BIS_fnc_initVehicle;
    },
    true,
    [],
    true
] call CBA_fnc_addClassEventHandler;

["vtx_UH60M", "init",
    {
        _vehicle = _this select 0;
        _vehicle setVariable ["LESH_canBeTowed", 1];  
    	_vehicle setVariable ["LESH_towFromFront", 1];  
    	_vehicle setVariable ["LESH_AxisOffsetTarget", [0,10,-0.8]];  
        _vehicle setVariable ["LESH_WheelOffset", [0,-1.5]];

        [
            _vehicle,
            ["uh60m_usa",1], 
	        ["Cockpitdoors_Hide",0,"RADAR_HIDE",0,"FLIR_HIDE",0,"FuelProbe_show",0,"MAWS_Tubes_Show",1,"ERFS_show",0,"MH60MMisc_show",1,"Hoist_hide",1,"Skis_show",0,"HH60Flares_show",1,"HH60GRadar_show",1,"HH60GFlir_show",1,"GunnerSeats_Hide",0,"Minigun_Sight_L_hide",0,"Minigun_Sight_R_hide",0]
        ] call BIS_fnc_initVehicle;
    },
    true,
    [],
    true
] call CBA_fnc_addClassEventHandler;

["vtx_UH60M_SLICK", "init",
    {
        _vehicle = _this select 0;
        _vehicle setVariable ["LESH_canBeTowed", 1];  
    	_vehicle setVariable ["LESH_towFromFront", 1];  
    	_vehicle setVariable ["LESH_AxisOffsetTarget", [0,10,-0.8]];  
        _vehicle setVariable ["LESH_WheelOffset", [0,-1.5]];

        [
	        _vehicle,
	        ["uh60m_usa",1], 
	        ["GunnerSeats_Hide",0,"Hoist_hide",0,"Skis_show",0,"HH60Flares_show",1,"HH60GRadar_show",1,"HH60GFlir_show",1,"Fuelprobe_show",0,"Cockpitdoors_Hide",0,"RADAR_HIDE",0,"FLIR_HIDE",0,"ERFS_show",0,"MAWS_Tubes_Show",1,"Minigun_Sight_L_hide",0,"Minigun_Sight_R_hide",0,"MH60MMisc_show",1]
        ] call BIS_fnc_initVehicle;

        vehicle _vehicle lockTurret [[1],true];
        vehicle _vehicle lockTurret [[2],true];
        vehicle _vehicle lockTurret [[3],true];
        vehicle _vehicle lockTurret [[4],true];

        _vehicle enableVehicleCargo false;
    },
    true,
    [],
    true
] call CBA_fnc_addClassEventHandler;

["vtx_MH60S", "init",
    {
        _vehicle = _this select 0;
        _vehicle setVariable ["LESH_canBeTowed", 1];  
    	_vehicle setVariable ["LESH_towFromFront", 1];  
    	_vehicle setVariable ["LESH_AxisOffsetTarget", [0,9,-0.8]];  
        _vehicle setVariable ["LESH_WheelOffset", [0,-1.5]];
    },
    true,
    [],
    true
] call CBA_fnc_addClassEventHandler;

["RHS_MELB_AH6M", "init",
    {
        _vehicle = _this select 0;
        _vehicle setVariable ["LESH_canBeTowed", 1];  
    	_vehicle setVariable ["LESH_towFromFront", 1];  
    	_vehicle setVariable ["LESH_AxisOffsetTarget", [0,4.5,-0.8]];  
        _vehicle setVariable ["LESH_WheelOffset", [0,-1.5]];
    },
    true,
    [],
    true
] call CBA_fnc_addClassEventHandler;

["RHS_CH_47F", "init",
    {
        _vehicle = _this select 0;
        _vehicle setVariable ["LESH_canBeTowed", 1];  
    	_vehicle setVariable ["LESH_towFromFront", 1];  
    	_vehicle setVariable ["LESH_AxisOffsetTarget", [0,10,-2.5]];  
        _vehicle setVariable ["LESH_WheelOffset", [0,-1.5]];
    },
    true,
    [],
    true
] call CBA_fnc_addClassEventHandler;

["RHS_CH_47F_cargo", "init",
    {
        _vehicle = _this select 0;
        _vehicle setVariable ["LESH_canBeTowed", 1];  
    	_vehicle setVariable ["LESH_towFromFront", 1];  
    	_vehicle setVariable ["LESH_AxisOffsetTarget", [0,10,-2.5]];  
        _vehicle setVariable ["LESH_WheelOffset", [0,-1.5]];
    },
    true,
    [],
    true
] call CBA_fnc_addClassEventHandler;

["USAF_C17", "init",
    {
        _vehicle = _this select 0; 
        _vehicle setVariable ["LESH_canBeTowed", 1];   
        _vehicle setVariable ["LESH_towFromFront", 1];   
        _vehicle setVariable ["LESH_AxisOffsetTarget", [0,25,-2.5]];   
        _vehicle setVariable ["LESH_WheelOffset", [0,-1.5]];
    },
    true,
    [],
    true
] call CBA_fnc_addClassEventHandler;

["USAF_AC130U", "init",
    {
        _vehicle = _this select 0; 
        _vehicle setVariable ["LESH_canBeTowed", 1];   
        _vehicle setVariable ["LESH_towFromFront", 1];   
        _vehicle setVariable ["LESH_AxisOffsetTarget", [0,18,-5.5]];   
        _vehicle setVariable ["LESH_WheelOffset", [0,-1.5]];
    },
    true,
    [],
    true
] call CBA_fnc_addClassEventHandler;

//----------------------- AIRCRAFT CARGO -------------------------------------

["DEGA_V22_Vehicle_B_NATO", "init",
    {
        _vehicle = _this select 0;
        [
	        _vehicle,
	        ["CV22_NATO_Olive",1], 
	        ["seats_hide_source",1,"turn_wing",0]
        ] call BIS_fnc_initVehicle;
        [_vehicle, 4] call ace_cargo_fnc_setSpace;
    },
    true,
    [],
    true
] call CBA_fnc_addClassEventHandler;

["DEGA_V22_Infantry_B_NATO", "init",
    {
        _vehicle = _this select 0;
        [
	        _vehicle,
	        ["CV22_NATO_Olive",1], 
	        ["seats_hide_source",0,"turn_wing",0]
        ] call BIS_fnc_initVehicle;
        [_vehicle, 4] call ace_cargo_fnc_setSpace;
    },
    true,
    [],
    true
] call CBA_fnc_addClassEventHandler;

// ---------------------- BLUFOR VEHICLE RANDOMIZATION ----------------------

// ---------------------- Trucks -------------------------------

["rhsusf_M977A4_BKIT_usarmy_wd", "init",
    {
        _vehicle = _this select 0;
        _vehicle setVariable ["LESH_canTow", 1];
        _vehicle setVariable ["LESH_AxisOffsetTower", [0,-6,-0.5]];
        [_vehicle, 10] call ace_cargo_fnc_setSpace;
    },
    true,
    [],
    true
] call CBA_fnc_addClassEventHandler;
["rhsusf_M977A4_BKIT_usarmy_d", "init",
    {
        _vehicle = _this select 0;
        _vehicle setVariable ["LESH_canTow", 1];
        _vehicle setVariable ["LESH_AxisOffsetTower", [0,-6,-0.5]];
        [_vehicle, 10] call ace_cargo_fnc_setSpace;
    },
    true,
    [],
    true
] call CBA_fnc_addClassEventHandler;

["rhsusf_M977A4_BKIT_M2_usarmy_wd", "init",
    {
        _vehicle = _this select 0;
        _vehicle setVariable ["LESH_canTow", 1];
        _vehicle setVariable ["LESH_AxisOffsetTower", [0,-6,-1.5]];
        [_vehicle, 10] call ace_cargo_fnc_setSpace;
    },
    true,
    [],
    true
] call CBA_fnc_addClassEventHandler;
["rhsusf_M977A4_BKIT_M2_usarmy_d", "init",
    {
        _vehicle = _this select 0;
        _vehicle setVariable ["LESH_canTow", 1];
        _vehicle setVariable ["LESH_AxisOffsetTower", [0,-6,-1.5]];
        [_vehicle, 10] call ace_cargo_fnc_setSpace;
    },
    true,
    [],
    true
] call CBA_fnc_addClassEventHandler;

// ----------------------- AIR AND STUFF --------------------------
["fza_ah64d_b2e", "init",
    {
        [
	        _this select 0,
	        ["211th_weathered",1], 
	        ["fcr_enable",1,"magazine_set_1200",0,"pdoor",0,"gdoor",0]
        ] call BIS_fnc_initVehicle;
    },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;

["vtx_HH60", "init",
    {
        _vehicle = _this select 0;
        _vehicle setVariable ["ace_medical_ismedicalvehicle", true];
        [
	        _vehicle,
	        ["hh60g",1], 
	        ["FuelProbe_show",0,"HH60Flares_show",1,"HH60GRadar_show",1,"HH60GFlir_show",1,"MAWS_Tubes_Show",1,"ERFS_show",0,"GunnerSeats_Hide",0,"Hoist_hide",0,"Skis_show",0,"Cockpitdoors_Hide",0,"RADAR_HIDE",0,"FLIR_HIDE",0,"Minigun_Sight_L_hide",0,"Minigun_Sight_R_hide",0,"MH60MMisc_show",1]
        ] call BIS_fnc_initVehicle;
    },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;

["USAF_F22_Heavy", "init",
    {
        [
	        _this select 0,
	        ["USAF_27FS",1], 
	        ["canopy_orange",1]
        ] call BIS_fnc_initVehicle;
    },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;

["USAF_F22", "init",
    {
        [
	        _this select 0,
	        ["USAF_27FS",1], 
	        ["canopy_orange",1]
        ] call BIS_fnc_initVehicle;
    },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;

["USAF_F35A", "init",
    {
        [
	        _this select 0,
	        ["TestColors",1], 
	        true
        ] call BIS_fnc_initVehicle;
    },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;

["USAF_A10", "init",
    {
        [
	        _this select 0,
	       ["Base_Grey_Hog_Worn",1], 
	       ["serial_gear",0]
        ] call BIS_fnc_initVehicle;
    },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;

// ----------------------- MRAPs --------------------------

["rhsusf_m1165a1_gmv_m134d_m240_socom_d", "init",
    {
        [
	        _this select 0,
	        ["rhs_sofwoodland",0], 
	        ["Hide_Scopes",0,"door_M",0,"door_R",0,"tools_hide",1,"runningboard_hide",0,"ammo_carrier_hide",1,"sag_ammo_hide",0,"sparewheel_carrier_hide",1,"sagr_hide",0,"door_LF",0,"door_LB",0,"door_RF",0,"door_RB",0,"BFT_Hide",0,"Antennas_Hide",0,"hide_spare",1]
        ] call BIS_fnc_initVehicle;
    },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;

["rhsusf_m1165a1_gmv_m2_m240_socom_d", "init",
    {
        [
	        _this select 0,
	        ["rhs_sofwoodland",0], 
	        ["door_M",0,"door_R",0,"tools_hide",1,"runningboard_hide",0,"ammo_carrier_hide",1,"sag_ammo_hide",1,"sparewheel_carrier_hide",0,"sagr_hide",0,"door_LF",0,"door_LB",0,"door_RF",0,"door_RB",0,"BFT_Hide",0,"Antennas_Hide",0,"hide_spare",0]
        ] call BIS_fnc_initVehicle;
    },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;

["rhsusf_m1151_mk19crows_usarmy_d", "init",
    {
        [
	        _this select 0,
	        ["rhs_woodland",0], 
	        ["hide_rhino",1,"door_LF",0,"door_LB",0,"door_RF",0,"door_RB",0,"door_trunk",0,"DUKE_Hide",1,"iff_hide",0,"dwf_kit_Hide",0,"snorkel_lower",0,"BFT_Hide",0,"Antennas_Hide",0,"hide_spare",0]
        ] call BIS_fnc_initVehicle;
    },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;

["UK3CB_KRG_B_M270_Avenger", "init",
    {
        [
	        _this select 0,
	        ["WDL",0], 
	        ["Hide_External_Kit",1]
        ] call BIS_fnc_initVehicle;
    },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;

["rhsusf_m998_d_4dr", "init",
    {
        [
	        _this select 0,
	       ["hide_backTop",0,"hide_frontTop",1,"hide_snorkel",0,"hide_middleTop",1,"hide_CIP",0,"hide_BFT",0,"hide_Antenna",0,"hide_A2_Parts",0,"Hide_A2Bumper",0,"Hide_Brushguard",0]
        ] call BIS_fnc_initVehicle;
    },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;

["UK3CB_MDF_B_Offroad_Unarmed", "init",
    {
        [
	       _this select 0,
	       ["MDF",1], 
	       ["HideDoor1",0,"HideDoor2",0,"HideDoor3",0,"HideBackpacks",0,"HideBumper1",1,"HideBumper2",0,"HideConstruction",0,"hidePolice",1,"HideServices",1,"BeaconsStart",0,"BeaconsServicesStart",0]
        ] call BIS_fnc_initVehicle;

    },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;
// stryker
["rhsusf_stryker_m1127_m2_d", "init",
    {
        [
	       _this select 0, 
	       ["Tan",1], 
	       ["Hide_DUKE",1,"Hatch_Commander",0,"Hatch_Left",0,"Hatch_Right",0,"Ramp",0,"Hide_Antenna_1",0,"Hide_Antenna_2",0,"Hide_Antenna_3",0,"Hide_CIP",0,"Hide_DEK",0,"Hide_ExDiff",0,"Hide_FCans",0,"Hide_WCans",0,"Hide_GPS",0,"Hide_PioKit",0,"Hide_StgBar",0,"Hide_SuspCov",0,"Hide_Towbar",0,"Extend_Mirrors",0,"Hatch_Driver",0]
        ] call BIS_fnc_initVehicle;

    },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;

["B_T_AFV_Wheeled_01_up_cannon_F", "init",
    {
        [
	       _this select 0, 
	       ["Green",1], 
	       ["showCamonetHull",1,"showCamonetTurret",1,"showSLATHull",0]
        ] call BIS_fnc_initVehicle;

    },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;

["rhsusf_stryker_m1126_mk19_d", "init",
    {
        [
	       _this select 0, 
	       ["Tan",1], 
	       ["Hatch_Commander",0,"Hatch_Front",0,"Hatch_Left",0,"Hatch_Right",0,"Ramp",0,"Hide_Antenna_1",0,"Hide_Antenna_2",0,"Hide_Antenna_3",0,"Hide_CIP",0,"Hide_DEK",0,"Hide_DUKE",1,"Hide_ExDiff",0,"Hide_FCans",0,"Hide_WCans",0,"Hide_GPS",0,"Hide_PioKit",1,"Hide_StgBar",0,"Hide_STORM",0,"Hide_SuspCov",0,"Hide_Towbar",1,"Extend_Mirrors",0,"Hatch_Driver",0]
        ] call BIS_fnc_initVehicle;

    },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;

["rhsusf_stryker_m1126_m2_d", "init",
    {
        [
	       _this select 0, 
	       ["Tan",1], 
	       ["Hatch_Commander",0,"Hatch_Front",0,"Hatch_Left",0,"Hatch_Right",0,"Ramp",0,"Hide_Antenna_1",0,"Hide_Antenna_2",0,"Hide_Antenna_3",0,"Hide_CIP",0,"Hide_DEK",0,"Hide_DUKE",1,"Hide_ExDiff",0,"Hide_FCans",0,"Hide_WCans",0,"Hide_GPS",0,"Hide_PioKit",0,"Hide_StgBar",0,"Hide_STORM",0,"Hide_SuspCov",0,"Hide_Towbar",0,"Extend_Mirrors",0,"Hatch_Driver",0]
        ] call BIS_fnc_initVehicle;

    },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;

["rhsusf_stryker_m1134_d", "init",
    {
        [
	       _this select 0, 
	       ["Tan",1], 
	       ["Hide_DUKE",1,"Mast_Folded",0,"Hatch_Loader",0,"Hatch_Commander",0,"Ramp",0,"Hide_Antenna_1",0,"Hide_Antenna_2",0,"Hide_Antenna_3",0,"Hide_CIP",0,"Hide_DEK",0,"Hide_ExDiff",0,"Hide_FCans",0,"Hide_WCans",0,"Hide_GPS",0,"Hide_PioKit",0,"Hide_StgBar",0,"Hide_SuspCov",0,"Hide_Towbar",0,"Extend_Mirrors",0,"Hatch_Driver",0]
        ] call BIS_fnc_initVehicle;

    },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;

["rhsusf_stryker_m1132_m2_d", "init",
    {
        [
	       _this select 0, 
	       ["Tan",1], 
	       ["SMP",1,"SMP_L",1,"SMP_R",1,"hide_SMP",0,"Hide_CIP",1,"Dispenser_Fold",0,"Hatch_Commander",0,"Hatch_Front",0,"Hatch_Left",0,"Hatch_Right",0,"Ramp",0,"Hide_Antenna_1",0,"Hide_Antenna_2",0,"Hide_Antenna_3",0,"Hide_DEK",0,"Hide_DUKE",1,"Hide_ExDiff",0,"Hide_FCans",0,"Hide_WCans",0,"Hide_GPS",0,"Hide_PioKit",0,"Hide_StgBar",0,"Hide_STORM",0,"Hide_SuspCov",0,"Hide_Towbar",0,"Extend_Mirrors",0,"Hatch_Driver",0]
        ] call BIS_fnc_initVehicle;

    },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;
//

["rhsusf_mrzr4_d", "init",
    {
        [
	       _this select 0,
	       ["mud_olive",0, 
	        "tailgateHide",0,
            "tailgate_open",0,
            "cage_fold",0]
        ] call BIS_fnc_initVehicle;

    },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;

["rhsusf_m1240a1_usarmy_wd", "init",
    {
        [
	        _this select 0,
	        nil,
	        ["DUKE_Hide",1,
	        "hide_spare",0]
        ] call BIS_fnc_initVehicle;
    },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;

["rhsusf_m1240a1_m2_usarmy_wd", "init",
    {
        [
	        _this select 0,
            nil,
	        ["rhs_woodland",0, 
	        "hide_ogpkover",1,
	        "hide_rhino",1,
	        "DUKE_Hide",1]
        ] call BIS_fnc_initVehicle;
     },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;

["rhsusf_m1240a1_m2_uik_usarmy_d", "init",
    {
        [
	        _this select 0,
	        nil,
	        ["rhs_woodland",0], 
	        ["hide_qnet",0,"hide_qnetwindow",0,"hide_towBar",1,"hide_mirrorStalks",0,"hide_ogpkover",0,"hide_ogpknet",0,"hide_ogpkbust",0,"hide_rhino",1,"DoorLF",0,"DoorRF",0,"DoorLB",0,"DoorRB",0,"DUKE_Hide",0,"hide_spare",0]
        ] call BIS_fnc_initVehicle;
     },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;

["rhsusf_m1240a1_m2_uik_usarmy_wd", "init",
    {
        [
            _this select 0,
            nil,
            ["hide_qnet",0,
            "hide_qnetwindow",0,
            "hide_towBar",1,
            "hide_mirrorStalks",1,
            "hide_ogpkover",1,
            "hide_ogpknet",0,
            "hide_ogpkbust",1,
            "hide_rhino",0,
            "DoorLF",0,
            "DoorRF",0,
            "DoorLB",0,
            "DoorRB",0,
            "DUKE_Hide",0,
            "hide_spare",0]
        ] call BIS_fnc_initVehicle;
     },
    true,
    [],
    true
] call CBA_fnc_addClassEventHandler;

["rhsusf_M1230_M2_usarmy_wd", "init",
    {
        [
	        _this select 0,
	        nil,
	        ["lwpk_hide",1,
            "hide_rhino",0,
            "hide_ogpkover",1,
            "hide_ogpknet",1,
            "hide_ogpkbust",0,
            "DUKE_Hide",0]
        ] call BIS_fnc_initVehicle;
     },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;

["rhsusf_M1220_M2_usarmy_wd", "init",
    {
        [
	        _this select 0,
	        nil,
	        ["hide_ogpkover",1,
            "hide_ogpknet",1,
            "hide_ogpkbust",0,
            "DUKE_Hide",0]
        ] call BIS_fnc_initVehicle;
     },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;

["rhsusf_M1238A1_socom_d", "init",
    {
        [
	        _this select 0,
	        ["rhs_woodland",0], 
	        ["DUKE_Hide",0,
            "hide_rhino",0,
            "hide_spare",0,
            "hide_ammoboxes",1,
            "hide_towbar",0,
            "hide_srchlight_cvr",0]
        ] call BIS_fnc_initVehicle;
     },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;

["rhsusf_M1237_M2_usarmy_d", "init",
    {
        [
	        _this select 0,
	        nil,
	       ["rhs_desert",1, 
	       "hide_rhino",1,
	       "hide_ogpkover",0,
	       "hide_ogpknet",0,
	       "hide_ogpkbust",0,
	       "DUKE_Hide",0]
        ] call BIS_fnc_initVehicle;
     },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;

["RHS_TOW_TriPod_WD", "init",
    {
        [_this select 0] call ace_rearm_fnc_disable;
     },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;

["RHS_TOW_TriPod_D", "init",
    {
        [_this select 0] call ace_rearm_fnc_disable;
     },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;

// OPFOR RADIO CHANGE VIC

//WAMBULANCE
["rhsusf_M1230a1_usarmy_d", "init",
    {
        [
	        _this select 0,
	        ["rhs_woodland",0], 
	        ["DUKE_Hide",1]
        ] call BIS_fnc_initVehicle;

    },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;

["rhsusf_M1230a1_usarmy_wd", "init",
    {
        [
	        _this select 0,
	        ["rhs_woodland",1], 
	        ["DUKE_Hide",1]
        ] call BIS_fnc_initVehicle;

    },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;



// ---------------------- TRUCKS ----------------------

["pook_NASAMS_BASE", "init",
    {
        _this select 0 setVariable ["tf_hasRadio", true, true];
        _this select 0 setVariable ["tf_range", 20000, true];
        _this select 0 setVariable ["tf_side", "west", true];
        [
            _this select 0,
            nil,
			[]
        ] call BIS_fnc_initVehicle;
    },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;

["rhsusf_M1078A1P2_D_fmtv_usarmy", "init",
    {
        _this select 0 setVariable ["tf_hasRadio", true, true];
        _this select 0 setVariable ["tf_range", 20000, true];
        _this select 0 setVariable ["tf_side", "west", true];
        [
            _this select 0,
            nil,
			[
                "hide_cover",0,
                "hide_spare",0,
                "hide_scaffold",0,
                "hide_bench",0
            ]
        ] call BIS_fnc_initVehicle;
    },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;

["rhsusf_M1083A1P2_D_fmtv_usarmy", "init",
    {
        _this select 0 setVariable ["tf_hasRadio", true, true];
        _this select 0 setVariable ["tf_range", 20000, true];
        _this select 0 setVariable ["tf_side", "west", true];
        [
            _this select 0,
            nil,
			[
				"hide_cover",0,
                "hide_spare",0,
                "hide_scaffold",0,
				"hide_bench",0
			]
        ] call BIS_fnc_initVehicle;
    },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;

["rhsusf_M1084A1P2_D_fmtv_usarmy", "init",
    {
        _this select 0 setVariable ["tf_hasRadio", true, true];
        _this select 0 setVariable ["tf_range", 20000, true];
        _this select 0 setVariable ["tf_side", "west", true];
        [
            _this select 0,
            ["rhs_woodland",1],
			["hide_spare",selectRandom [0,1]]
        ] call BIS_fnc_initVehicle;
    },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;


["rhsusf_M1078A1P2_WD_fmtv_usarmy", "init",
    {
        _this select 0 setVariable ["tf_hasRadio", true, true];
        _this select 0 setVariable ["tf_range", 20000, true];
        _this select 0 setVariable ["tf_side", "west", true];
        [
            _this select 0,
            nil,
			[
                "hide_cover",0,
                "hide_spare",0,
                "hide_scaffold",0,
                "hide_bench",0
            ]
        ] call BIS_fnc_initVehicle;
    },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;

["rhsusf_M1083A1P2_WD_fmtv_usarmy", "init",
    {
        _this select 0 setVariable ["tf_hasRadio", true, true];
        _this select 0 setVariable ["tf_range", 20000, true];
        _this select 0 setVariable ["tf_side", "west", true];
        [
            _this select 0,
            nil,
			[
				"hide_cover",0,
                "hide_spare",0,
                "hide_scaffold",0,
				"hide_bench",0
			]
        ] call BIS_fnc_initVehicle;
    },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;

["rhsusf_M1084A1P2_WD_fmtv_usarmy", "init",
    {
        _this select 0 setVariable ["tf_hasRadio", true, true];
        _this select 0 setVariable ["tf_range", 20000, true];
        _this select 0 setVariable ["tf_side", "west", true];
        [
            _this select 0,
            ["rhs_woodland",1],
			["hide_spare",selectRandom [0,1]]
        ] call BIS_fnc_initVehicle;
    },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;

// ------------------------- ARTILLERY ---------------------------------------

["UK3CB_CHD_W_B_Hilux_Mortar", "init",
    {
        [
            _this select 0,
            ["AD",1], 
            ["ClanLogo_Hide",1]
        ] call BIS_fnc_initVehicle;
    },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;

["RHS_M119_WD", "init",
    {
        [_this select 0, 9] call ace_cargo_fnc_setSize;
    },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;

["RHS_M119_D", "init",
    {
        [_this select 0, 9] call ace_cargo_fnc_setSize;
    },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;

["pook_M777", "init",
    {
        [
	        _this select 0,
	        ["Green",1], 
	        true
        ] call BIS_fnc_initVehicle;
         [_this select 0, 9] call ace_cargo_fnc_setSize;
    },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;

["pook_M777_DES", "init",
    {
        [
	        _this select 0,
	        ["Green",1], 
	        true
        ] call BIS_fnc_initVehicle;
         [_this select 0, 9] call ace_cargo_fnc_setSize;
    },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;

["itc_land_b_vls2_slam", "init",  
    {  
        _vehicle = _this select 0; 
        _vehicle spawn {sleep 3;  
        deleteVehicleCrew _this;}; 
    },  
    true,   
    [],   
    true  
] call CBA_fnc_addClassEventHandler;

// ------------------------- IVF/APCs ---------------------------------------
["UK3CB_B_LAV25_US_WDL", "init",
    {
        [
            _this select 0,
            ["WDL",1], 
	        ["Duke_Hide",0,"Basket_Hide",0,"Sparewheel_3_Hide",0,"ClanLogo_Hide",0,"ClanSign_Hide",0,"Backpacks_Front_Left_Hide",1,"Backpacks_Front_Right_Hide",1,"Backpacks_Rear_Left_Hide",1,"Backpacks_Rear_Right_Hide",1,"Camonet_Roll_Hide",0,"Jerrycan_Left_Hide",0,"Jerrycan_Right_Hide",0,"Sparewheel_1_Hide",0,"Sparewheel_2_Hide",0,"Shovels_Hide",1,"Tools_Hide",1,"Tow_Rope_Hide",0]
        ] call BIS_fnc_initVehicle;
    },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;

// -------------------------- END VIC CUSTOMISATION -------------------------
///
["Man", "init",
    {
        _unit = _this select 0; 
        [_unit] spawn {
            params ["_unit"];
            waitUntil {alive _unit};
            _unit setUnitAbility 1;
            _unit setskill ["general",1];
            _unit setskill ["aimingAccuracy",0.78];
            _unit setskill ["aimingShake",0.82];
            _unit setskill ["aimingSpeed",0.78];
            _unit setskill ["Endurance",1];
            _unit setskill ["spotDistance",1];
            _unit setskill ["spotTime",0.79];
            _unit setskill ["courage",0.82];
            _unit setskill ["reloadSpeed",0.9];
        };
    },
    true,
    [],
    true
] call CBA_fnc_addClassEventHandler;

// ----------------- START VIC CUSTOMISATION -----------------

// ---------------------- BLUFOR TOWING ----------------------


["B_Slingload_01_Repair_F", "init",
    {
        [_this select 0, 9] call ace_cargo_fnc_setSize;
    },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;

["B_Slingload_01_Ammo_F", "init",
    {
        [_this select 0, 9] call ace_cargo_fnc_setSize;
    },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;

["B_Slingload_01_Fuel_F", "init",
    {
        [_this select 0, 9] call ace_cargo_fnc_setSize;
    },
    true, 
    [], 
    true
] call CBA_fnc_addClassEventHandler;

// EWR
["karmakut_mpq65", "init",
    { 
        [EvaluateRadarTargets, [_this select 0, blufor, true], 5] call CBA_fnc_waitAndExecute; 
        (_this select 0) call itc_land_cobra_fnc_vehicleInit;
    },
    true,
    [],
    true
] call CBA_fnc_addClassEventHandler;
["B_Radar_System_01_F", "init",
    { 
        [EvaluateRadarTargets, [_this select 0, blufor, true], 5] call CBA_fnc_waitAndExecute; 
    },
    true,
    [],
    true
] call CBA_fnc_addClassEventHandler;



["Land_TentHangar_V1_F", "init",
    { 
        private _tent = _this select 0;
        _tent setVariable [ "usaf_servicemenu_allowloadoutmodification", false ];
        _tent setVariable [ "usaf_servicemenu_servicesavailable", [false, false, false] ];
    },
    true,
    [],
    true
] call CBA_fnc_addClassEventHandler;


// Humanitarian ration system

{
  [_x, "init",
    {
        _conditions = "!(_target getVariable ['CivilianHelped', false])";
        (_this select 0) addaction ["Give Ration", 
        {
            params ["_target","_caller","_actionId","_arguments"];
            if ([_caller, "ACE_Humanitarian_Ration"] call bis_fnc_hasItem) then {
            _caller removeitem "ACE_Humanitarian_Ration";
            _target setVariable ["CivilianHelped", true, true];
            [_target] call ace_interaction_fnc_sendAway;

            private _amount = 1;

            if ((random 100) < 40) then {
                _amount = 2;
            };

            if((random 100) < 20) then {
                _amount = 3;
            };
            [_amount] remoteExecCall ["F_cr_changeCR"];
            hintC format ["%1 thanks you for the ration you gave them.", name _target];
            hintC_EH = findDisplay 57 displayAddEventHandler ["Unload", {
                _this spawn {
                    _this select 0 displayRemoveEventHandler ["Unload", hintC_EH];
                    hintSilent "";
                };
            }];
            } else {hint "You don't have any rations."};
        },
        nil, 1.5, true, true, "", _conditions, 3
        ];
    },
    false,
    [],
    true
  ] call CBA_fnc_addClassEventHandler;
} forEach civilians;
