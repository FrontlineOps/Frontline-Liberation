// MANUAL FACTIONS
// Put classnames inside quotes, separated by commas: ["B_Soldier_F", "B_medic_F"].
// [] means an empty list. "" means one empty name. Keep the setting names unchanged.
// Lines starting with // are comments. Remove // from copied example rows to use them.
// Finish all four sides, select MANUAL in kp_liberation_config.sqf, rebuild/restart.
// AUTO is still enabled. These lists are empty for you to fill in.

// BLUFOR - vehicles, player equipment and supply crates.
private _blufor = createHashMapFromArray [
    ["catalog", createHashMapFromArray [
        ["factions", []], // Faction IDs, e.g. ["BLU_F"]. Required.
        ["units", []], // Classes used by crew/pilot/FOB defenders below. Required.
        ["light", []], // Cars and MRAPs.
        ["recon", []], // Scout vehicles.
        ["medical", []], // Ambulances and medical helicopters.
        ["groundLogistics", []], // Supply, repair, ammo and fuel trucks.
        ["heavy", []], // Tanks, APCs and IFVs.
        ["transport", []], // Troop trucks.
        ["artillery", []], // Artillery.
        ["atgm", []], // Anti-tank missile vehicles/weapons.
        ["aa", []], // Anti-air vehicles/weapons.
        ["rotaryLogistics", []], // Transport helicopters.
        ["rotaryCas", []], // Attack helicopters.
        ["fixedWing", []], // Planes and drones.
        ["static", []], // Stationary weapons.
        ["boat", []] // Boats.
    ]],

    // Crew fallback and pilot identification. Also list these classes in units.
    ["unitRoles", createHashMapFromArray [
        ["crew", ""],
        ["pilot", ""]
    ]],

    // Pick from your vehicle lists above. Leave unused optional jobs as "".
    ["vehicleRoles", createHashMapFromArray [
        ["Respawn_truck_typename", ""], // Mobile respawn truck. Required.
        ["KP_liberation_smallhelo_classname", ""], // Small helicopter.
        ["KP_liberation_midhelo_classname", ""], // Medium helicopter.
        ["KP_liberation_bighelo_classname", ""], // Large helicopter.
        ["KP_liberation_medhelo_classname", ""], // Medical helicopter.
        ["KP_liberation_atkhelo_classname", ""], // Attack helicopter.
        ["KP_liberation_car_classname", ""], // Car/MRAP.
        ["KP_liberation_atcar_classname", ""], // Anti-tank vehicle.
        ["KP_liberation_truck_classname", ""], // Troop truck.
        ["KP_liberation_medcar_classname", ""], // Ambulance.
        ["KP_liberation_zodiac_classname", ""], // Small boat.
        ["KP_liberation_rhib_classname", ""], // Patrol boat.
        ["KP_liberation_ifv_classname", ""], // IFV.
        ["KP_liberation_apc_classname", ""], // APC.
        ["KP_liberation_cas_classname", ""], // Ground-attack plane.
        ["KP_liberation_cap_classname", ""], // Fighter.
        ["KP_liberation_drone_classname", ""], // Drone.
        ["KP_liberation_repair_classname", ""], // Repair truck.
        ["KP_liberation_fuel_classname", ""] // Fuel truck.
    ]],

    // Squad members must be listed in units. Repeat a class for multiple soldiers.
    // Only used by the optional automatic FOB defenders.
    ["squads", createHashMapFromArray [
        ["blufor_squad_inf", []] // Soldier classnames from units. Required.
    ]],

    // One price for EVERY BLUFOR vehicle: [supplies, ammunition, fuel].
    ["prices", createHashMapFromArray [
        // ["B_MRAP_01_F", [100, 20, 10]]
    ]],

    // Optional shared gear. Roles get a list only when they name it below.
    ["equipment", createHashMapFromArray [
        // ["common", ["U_B_CombatUniform_mcam", "V_PlateCarrier1_rgr", "H_HelmetB", "B_AssaultPack_mcamo", "ItemMap", "ItemCompass", "ItemWatch", "FirstAidKit"]]
    ]],

    // Copy this whole block per player role; give each a unique ID and label.
    // gear: paste this role's weapons, ammo, clothing, backpacks, radios and items here.
    // equipment adds shared lists from above; use [] if all its gear is listed here.
    // medic/engineer: 0=off, 1=on, 2=advanced ACE.
    // starter is the spawn kit. Only gear allowed by the role is kept.
    ["roles", createHashMapFromArray [
        // ["rifleman", createHashMapFromArray [
        //     ["label", "Rifleman"],
        //     ["equipment", ["common"]],
        //     ["gear", [
        //         "arifle_MX_F",
        //         "30Rnd_65x39_caseless_mag",
        //         "optic_Aco"
        //     ]],
        //     ["medic", 0],
        //     ["engineer", 0],
        //     ["starter", [
        //         ["arifle_MX_F", "", "", "optic_Aco", ["30Rnd_65x39_caseless_mag", 30], [], ""],
        //         [],
        //         [],
        //         ["U_B_CombatUniform_mcam", [["FirstAidKit", 2]]],
        //         ["V_PlateCarrier1_rgr", [["30Rnd_65x39_caseless_mag", 6, 30]]],
        //         ["B_AssaultPack_mcamo", []],
        //         "H_HelmetB",
        //         "",
        //         [],
        //         ["ItemMap", "", "", "ItemCompass", "ItemWatch", ""]
        //     ]]
        // ]]
    ]],

    // To copy a kit: equip your player, then LOCAL EXEC in the debug console:
    // copyToClipboard str (getUnitLoadout player)
    // Paste the result as starter. Include its items in the allowed gear lists too.

    ["defaultRole", ""], // Required: one role ID from above, e.g. "rifleman".

    // Lobby role ending -> role ID. Create that role first. Admin assignments win.
    ["slots", createHashMapFromArray [
        // ["Rifleman", "rifleman"],
        // ["Medic", "medic"]
    ]],

    // Player-requested boxes. Copy a block and choose its name, contents and roles.
    // Cargo rows are ["classname", quantity]. roles=[] permits nobody.
    // Cooldown is seconds; Limit is boxes per group; SpecialtyCost is group tokens.
    ["crates", createHashMapFromArray [
        // ["Medical supplies", createHashMapFromArray [
        //     ["Model", "Box_NATO_Ammo_F"],
        //     ["Category", "Medical"],
        //     ["roles", ["medic"]],
        //     ["Weapons", createHashMapFromArray []],
        //     ["Magazines", createHashMapFromArray []],
        //     ["Items", createHashMapFromArray [["FirstAidKit", 30], ["Medikit", 2]]],
        //     ["Backpacks", createHashMapFromArray []],
        //     ["SpecialtyCost", 0],
        //     ["CustomCooldown", 60],
        //     ["Limit", 1],
        //     ["Offset", [0, 1, 1]]
        // ]]
    ]],

    ["specialtyResources", 0] // Group token budget. Leave 0 for free crates.
];

// OPFOR - enemy AI only. Soldiers use their unit class's built-in equipment.
private _opfor = createHashMapFromArray [
    ["catalog", createHashMapFromArray [
        ["factions", []], // Enemy faction IDs, e.g. ["OPF_F"]. Required.
        ["units", []], // All enemy soldier classes used below. Required.
        ["light", []], // Cars and MRAPs.
        ["recon", []], // Scout vehicles.
        ["heavy", []], // Tanks, APCs and IFVs.
        ["transport", []], // Troop trucks.
        ["groundLogistics", []], // Supply, ammo and fuel trucks.
        ["artillery", []], // Artillery; [] disables it.
        ["atgm", []], // Anti-tank missile vehicles/weapons.
        ["aa", []], // Anti-air assets.
        ["samTel", []], // SAM launchers; also list in aa.
        ["samRadar", []], // SAM radars; also list in aa.
        ["samShorad", []], // Short-range SAM-site defense; also list in aa.
        ["rotaryLogistics", []], // Transport helicopters.
        ["rotaryCas", []], // Attack helicopters.
        ["fixedWing", []], // Attack/interception planes.
        ["static", []] // Defensive stationary weapons.
    ]],

    // All these AI jobs need a soldier classname from units above.
    // Example: ["medic", "O_medic_F"]. One class may fill multiple jobs.
    ["unitRoles", createHashMapFromArray [
        ["officer", ""],
        ["squadleader", ""],
        ["teamleader", ""],
        ["rifleman", ""],
        ["at", ""],
        ["grenadier", ""],
        ["machinegunner", ""],
        ["heavygunner", ""],
        ["marksman", ""],
        ["sniper", ""],
        ["aa", ""],
        ["medic", ""],
        ["engineer", ""],
        ["paratrooper", ""],
        ["rto", ""]
    ]],

    // Choose from the enemy vehicle lists. The four truck jobs are required.
    ["vehicleRoles", createHashMapFromArray [
        ["opfor_mrap", ""],
        ["opfor_mrap_armed", ""],
        ["opfor_transport_helo", ""],
        ["opfor_transport_truck", ""],
        ["opfor_ammobox_transport", ""], // Enemy logistics truck.
        ["opfor_fuel_truck", ""],
        ["opfor_ammo_truck", ""]
    ]],

    // Required basic enemy squad. Use soldier names from units; repeat as needed.
    ["squads", createHashMapFromArray [
        ["militia_squad", []]
    ]]
];

// INSURGENTS - the existing resistance/guerrilla AI roster.
private _insurgents = createHashMapFromArray [
    ["catalog", createHashMapFromArray [
        ["factions", []], // Insurgent faction IDs. Required.
        ["units", []],    // Insurgent soldiers. Required; their built-in kits are used.
        ["light", []]     // Insurgent vehicles.
    ]]
];

// CIVILIANS - civilian people and vehicles.
private _civilians = createHashMapFromArray [
    ["catalog", createHashMapFromArray [
        ["factions", []], // Civilian faction IDs, e.g. ["CIV_F"]. Required.
        ["units", []],    // Civilian people, e.g. ["C_man_1"]. Required.
        ["light", []]     // Civilian vehicles, e.g. ["C_Offroad_01_F"].
    ]]
];

// Leave these names alone; resistance is the mission's name for the insurgent list.
createHashMapFromArray [
    ["blufor", _blufor],
    ["opfor", _opfor],
    ["resistance", _insurgents],
    ["civilians", _civilians]
]
