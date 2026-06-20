/*
    Crates can be grabbed from an ammo source with a limit set to the Squad itself
    Some squads have access to specialty crates
    Some squads can grab more than other squads.
    Some squads can resupply the crates of other squads while the rest cannot.
    Some squads have access to different kinds of specialty crates
    Each specialty crate has a different cooldown that occurs when they grab or refill it.
    Crate refill cooldowns belong to the squad the crate belongs to, not the squad that refills it.
    Some squads may have access to more than just 1 specialty crate they can pull or refill at a time.
    Architecture will be a client-server authoritative as much as it can. Clients send requests. Server will receive and create the crates and fill them via global commands. It will also be the source of truth on current allocations.
*/
"config.sqf" call resupplyLog;


// What provides a source for refililng and grabbing crates
ResupplyCrateSourceClasses = [
    "Land_Cargo40_military_green_F",         // USMC Vehicle Service Point
    "Land_Cargo20_yellow_F"				                // Vehicle Service Point (RU)
];

// Maps a role description name to a shorthand flag that is used by the scripts to determine what ROLE someone belongs to
// Format is:
// [FLAG]: SUBSTRING OF ROLE DESCRIPTION NAME
// They will be cached to have the SL flag.
// Use is primarily for devs, however the search string must be updated if role names are going to be changed to properly set flags.
// i.e. Someone that picks the SL slot for 1-1 will have the role description 'Assassin 1-1 Squad Leader@Assassin 1-1 (Infantry)'
// We read the "Squad Leader" part to set them an SL flag.
// These flags are used in conjunction with the group flags to gain access to a variety of specialty crates, etc..
// i.e. A player with MED flag in 1-1 can have different stuff than a player in 1-6 with MED flag.
// NOTE: Key or value, it doesn't matter as we need to loop through and do a string find anyway. None of the role descriptions match exactly with a key to enable a O(1) lookup.
ResupplyRoleDescriptionsToRoleFlags = createHashMapFromArray [
    ["SL", "Squad Leader"],
    ["PL", "Platoon Commander"],
    ["PSG", "Platoon Sergeant"],
    ["PMed", "Platoon Medic"],
    ["FTL", "Team Leader"],
    ["CO", "Company Commander"],
    ["XO", "Company Executive Officer"],
    ["PJ", "Banshee Team Lead"],
    ["CHV", "Chevy"],
    ["CWO", "Pilot"],
    ["WO", "Crew"],
    ["JFO", "TACP"],
    ["MED", "Medic"],
    ["ENG", "Engineer"],
    ["LOGI", "Ogre"],
    ["PH", "Phantom Sniper"],
    ["Shad", "Shadow Team Leader"],
    ["IDF", "Mortarman"],
    ["IDFM", "Shade Team Leader"],
    ["HAAA", "Harpy 1 Team Leader"],
    ["AAAS", "AA Specialist"],
    ["WTL", "Wraith Team Leader"],
    ["GBT", "Goblin Team Leader"],
    ["GBS", "Goblin Squad Leader"],
    ["WPSQ", "Assassin 1-4 (Heavy Weapons Squad)"],
    // OPFOR UNDER HERE
    //["OPDC", "Detachment Commander"],
    //["OPADC", "Assistant Detachment Commander"],
    ["OPSL", "Squad Leader"],
    ["OPMD", "Medical Specialist"],
    //["OPHWS", "Launcher Specialist"],
    //["OPHWS", "Machine Gunner"],
    //["OPHWS", "Automatic Rifleman"],
    //["OPDRON", "Drone Specialist"],
    ["OPTL", "Weapons Team Leader"],
    ["OPGN", "Weapons Gunner"]
    //["OPLSPEC", "Launcher Specialist"],
    //["OPSNIP", "Sniper"],
    //["OPENGI", "Demolitions Specialist"],
    //["OPETL", "Engineer Team Leader"],
    //["OPSAP", "Sapper"],
    //["TERSL", "Terminator 1 Team Leader"],
    //["TERMMM", "Terminator 1 Mortarman"],
    //["TERMAM", "Terminator 1 Asst. Mortarman"],
    //["OPPIL", "Pilot"]
];
// Maps a role description to a shorthand flag that is used by the scripts to determine what type of SQUAD someone belongs to
// If someone in their role description contains one of these strings then they will be marked to that flag.
// i.e. "Assassin 1-6 Platoon Commander@Assassin 1-6 (Leadership)" will contain Assassin 1-6, thus will be marked as belong to a PLHQ squad.
// Each squad should uniquely belong to only one type... If additional types are required, refactoring will be required to deconflict Specialty allocations, max crate, caching the squad flags for the player's current squad instead of a singular.

ResupplyRoleDescriptionToSquadFlags = [
    createHashMapFromArray [
        ["FlagName", "JFO"],
        ["SquadNames",
            [
                "Scout/JO@Fox",
                "Scout/SO@Fox"
            ]
        ]
    ],
    createHashMapFromArray [
        ["FlagName", "SL"],
        ["SquadNames",
            [
                "Squad Leader@Ares 1-1",
                "Scout/SO@Fox"
            ]
        ]
    ],
     createHashMapFromArray [
        ["FlagName", "FTL"],
        ["SquadNames",
            [
                "Team Leader (A)@Ares 1-1",
                "Team Leader (B)@Ares 1-1",
                "Team Leader (A)@Ares 1-2",
                "Team Leader (B)@Ares 1-2"
            ]
        ]
    ],
    createHashMapFromArray [
        ["FlagName", "MED"],
        ["SquadNames",
            [
                "Medic@Ares 1-1",
                "Medic@Ares 1-2",   
                "Scout/Medic@Fox"
            ]
        ]
    ],
    createHashMapFromArray [
        ["FlagName", "WPSQ"],
        ["SquadNames",
            [
                "Squad Leader@Ares 1-2"
            ]
        ]
    ],
    createHashMapFromArray [
        ["FlagName", "PLHQ"],
        ["SquadNames",
            [
                "Platoon Commander@Ares 1-6"
            ]
        ]
    ],
    createHashMapFromArray [
        ["FlagName", "PMed"],
        ["SquadNames",
            [
                "Platoon Medic@Ares 1-6"
            ]
        ]
    ],
    createHashMapFromArray [
        ["FlagName", "CHQ"],
        ["SquadNames",
            [
                "Company Commander@Zeus"
            ]
        ]
    ],
    createHashMapFromArray [
        ["FlagName", "PH"],
        ["SquadNames",
            [
                "Squad Leader@Fox"
            ]
        ]
    ],
    createHashMapFromArray [
        ["FlagName", "Shad"],
        ["SquadNames",
            [
                "Shadow 1"
            ]
        ]
    ],
    createHashMapFromArray [
        ["FlagName", "HAAA"],
        ["SquadNames",
            [
                "Harpy 1 Team Leader"
            ]
        ]
    ],
    createHashMapFromArray [
        ["FlagName", "AAAS"],
        ["SquadNames",
            [
                "Harpy 1-A AA Specialist",
                "Harpy 1-B AA Specialist"
            ]
        ]
    ],
    createHashMapFromArray [
        ["FlagName", "LOGI"],
        ["SquadNames",
            [
                "Ogre"
            ]
        ]
    ],
    createHashMapFromArray [
        ["FlagName", "GBS"],
        ["SquadNames",
            [
                "Goblin Squad Leader"
            ]
        ]
    ],
    createHashMapFromArray [
        ["FlagName", "GBT"],
        ["SquadNames",
            [
                "Goblin Team Leader",
                "Goblin Team Leader"
            ]
        ]
    ],
    createHashMapFromArray [
        ["FlagName", "AIR"],
        ["SquadNames",
            [
                "Hermes"
            ]
        ]
    ],
    createHashMapFromArray [
        ["FlagName", "CHV"],
        ["SquadNames",
            [
                "Chevy"
            ]
        ]
    ],
    createHashMapFromArray [
        ["FlagName", "PJ"],
        ["SquadNames",
            [
                "Banshee 1"
            ]
        ]
    ],
    createHashMapFromArray [
        ["FlagName", "IDFM"],
        ["SquadNames",
            [
                "Shade Team Leader"
            ]
        ]
    ],
    createHashMapFromArray [
        ["FlagName", "WTL"],
        ["SquadNames",
            [
                "Wraith Team Leader"
            ]
        ]
    ],
    createHashMapFromArray [
        ["FlagName", "IDF"],
        ["SquadNames",
            [
                "Scout/Mortarman (A)@Fox",
                "Scout/Mortarman (B)@Fox"
            ]
        ]
    ],

    //////////////////////// OPFOR STARTS UNDER HERE /////////////////////////////

    createHashMapFromArray [
        ["FlagName", "OPDC"],
        ["SquadNames",
            [
                "Detachment Commander"
            ]
        ]
    ],
    createHashMapFromArray [
        ["FlagName", "OPSL"],
        ["SquadNames",
            [
                "K11 Squad Leader",
                "K12 Squad Leader"
            ]
        ]
    ],
     createHashMapFromArray [
        ["FlagName", "OPDRON"],
        ["SquadNames",
            [
                "K11 Drone Specialist",
                "K12 Drone Specialist"
            ]
        ]
    ],
    createHashMapFromArray [
        ["FlagName", "OPHWS"],
        ["SquadNames",
            [
                "K11 Launcher Specialist",
                "K12 Launcher Specialist"
            ]
        ]
    ],
    createHashMapFromArray [
        ["FlagName", "OPTL"],
        ["SquadNames",
            [
                "Weapons Team Leader"
            ]
        ]
    ],
     createHashMapFromArray [
        ["FlagName", "OPGN"],
        ["SquadNames",
            [
                "Weapons Gunner"
            ]
        ]
    ],
    createHashMapFromArray [
        ["FlagName", "OPLSPEC"],
        ["SquadNames",
            [
                "K11 Machine Gunner",
                "K12 Machine Gunner"
            ]
        ]
    ],
    createHashMapFromArray [
        ["FlagName", "OPSNIP"],
        ["SquadNames",
            [
                "SNOT Sniper"
            ]
        ]
    ],
    createHashMapFromArray [
        ["FlagName", "OPENGI"],
        ["SquadNames",
            [
                "K11 Demolitions Specialist",
                "K12 Demolitions Specialist"
            ]
        ]
    ],
    createHashMapFromArray [
        ["FlagName", "OPSAP"],
        ["SquadNames",
            [
                "K11 Sapper",
                "K12 Sapper"
            ]
        ]
    ],
    createHashMapFromArray [
        ["FlagName", "TERSL"],
        ["SquadNames",
            [
                "Terminator 1 Team Leader"
            ]
        ]
    ],
    createHashMapFromArray [
        ["FlagName", "TERMMM"],
        ["SquadNames",
            [
                "Terminator 1 Mortarman"
            ]
        ]
    ],
    createHashMapFromArray [
        ["FlagName", "TERMAM"],
        ["SquadNames",
            [
                "Terminator 1 Asst. Mortarman"
            ]
        ]
    ],
    createHashMapFromArray [
        ["FlagName", "OPETL"],
        ["SquadNames",
            [
                "Engineer Team Leader"
            ]
        ]
    ],
    createHashMapFromArray [
        ["FlagName", "OPPIL"],
        ["SquadNames",
            [
                "Sokol 1"
            ]
        ]
    ]
];


// What type of squad has what type of allocations
/* Format is [SHORTHAND_SQUAD_IDENTIFIER]: {
    "CrateAllocations": number // How many crates they can have out at once
    "SpecialtyAllocations": number // How much specialty resource they have currently
    "WhitelistedFlags": Array<string> // What role flags are allowed to see the crate system within the squad. Empty array means anyone is allowed
    "Resupplier": boolean // Can this role resupply crates from other squads that is not their own
}*/
ResupplyCrateAllocations = createHashMapFromArray [
    [
        "FAC",
        createHashMapFromArray [
            ["CrateAllocations", 1],
            ["SpecialtyAllocations", 1],
            ["WhitelistedFlags", []]
        ]
    ],
    [
        "JFO",
        createHashMapFromArray [
            ["CrateAllocations", 1],
            ["SpecialtyAllocations", 1],
            ["WhitelistedFlags", []]
        ]
    ],
    [
        "MED",
        createHashMapFromArray [
            ["CrateAllocations", 0],
            ["SpecialtyAllocations", 0],
            ["WhitelistedFlags", ["MED"]]
        ]
    ],
    [
        "SL",
        createHashMapFromArray [
            ["CrateAllocations", 2],
            ["SpecialtyAllocations", 1],
            ["WhitelistedFlags", ["SL"]]
        ]
    ],
    [
        "FTL",
        createHashMapFromArray [
            ["CrateAllocations", 1],
            ["SpecialtyAllocations", 1],
            ["WhitelistedFlags", ["FTL"]]
        ]
    ],
    [
        "WPSQ",
        createHashMapFromArray [
            ["CrateAllocations", 2],
            ["SpecialtyAllocations", 1],
            ["WhitelistedFlags", ["WPSQ"]]
        ]
    ],
    [
        "CHQ",
        createHashMapFromArray [
            ["CrateAllocations", 2],
            ["SpecialtyAllocations", 1],
            ["WhitelistedFlags", ["CO", "XO", "MED", "FAC"]]
        ]
    ],
    [
        "PLHQ",
        createHashMapFromArray [
            ["CrateAllocations", 2],
            ["SpecialtyAllocations", 1],
            ["WhitelistedFlags", ["PL", "PSG", "MED"]]
        ]
    ],
    [
        "PMed",
        createHashMapFromArray [
            ["CrateAllocations", 1],
            ["SpecialtyAllocations", 1],
            ["WhitelistedFlags", []]
        ]
    ],
    [
        "PH",
        createHashMapFromArray [
            ["CrateAllocations", 1],
            ["SpecialtyAllocations", 1],
            ["WhitelistedFlags", []]
        ]
    ],
    [
        "Shad",
        createHashMapFromArray [
            ["CrateAllocations", 1],
            ["SpecialtyAllocations", 1],
            ["WhitelistedFlags", []]
        ]
    ],
    [
        "LOGI",
        createHashMapFromArray [
            ["CrateAllocations", 9],
            ["SpecialtyAllocations", 2],
            ["WhitelistedFlags", []],
            ["Resupplier", true]
        ]
    ],
    [
        "GBS",
        createHashMapFromArray [
            ["CrateAllocations", 2],
            ["SpecialtyAllocations", 1],
            ["WhitelistedFlags", []]
        ]
    ],
    [
        "GBT",
        createHashMapFromArray [
            ["CrateAllocations", 1],
            ["SpecialtyAllocations", 1],
            ["WhitelistedFlags", []]
        ]
    ],
    [
        "HAAA",
        createHashMapFromArray [
            ["CrateAllocations", 1],
            ["SpecialtyAllocations", 1],
            ["WhitelistedFlags", []]
        ]
    ],
    [
        "AAAS",
        createHashMapFromArray [
            ["CrateAllocations", 1],
            ["SpecialtyAllocations", 1],
            ["WhitelistedFlags", []]
        ]
    ],
    [
        "WTL",
        createHashMapFromArray [
            ["CrateAllocations", 2],
            ["SpecialtyAllocations", 2],
            ["WhitelistedFlags", []]
        ]
    ],
    [
        "AIR",
        createHashMapFromArray [
            ["CrateAllocations", 2],
            ["SpecialtyAllocations", 0],
            ["WhitelistedFlags", ["WO", "CWO"]]
        ]
    ],
    [
        "PJ",
        createHashMapFromArray [
            ["CrateAllocations", 2],
            ["SpecialtyAllocations", 2],
            ["WhitelistedFlags", []]
        ]
    ],
    [
        "CHV",
        createHashMapFromArray [
            ["CrateAllocations", 4],
            ["SpecialtyAllocations", 4],
            ["WhitelistedFlags", []],
            ["Resupplier", true]
        ]
    ],
    [
        "IDFM",
        createHashMapFromArray [
            ["CrateAllocations", 4],
            ["SpecialtyAllocations", 4],
            ["WhitelistedFlags", []]
        ]
    ],
    
    //////////////////////////// OPFOR STARTS UNDER HERE//////////////////////////////

    [
        "OPDC",
        createHashMapFromArray [
            ["CrateAllocations", 1],
            ["SpecialtyAllocations", 0],
            ["WhitelistedFlags", []]
        ]
    ],
    [
        "OPSL",
        createHashMapFromArray [
            ["CrateAllocations", 1],
            ["SpecialtyAllocations", 0],
            ["WhitelistedFlags", []]
        ]
    ],
    [
        "OPDRON",
        createHashMapFromArray [
            ["CrateAllocations", 1],
            ["SpecialtyAllocations", 1],
            ["WhitelistedFlags", []]
        ]
    ],
    [
        "OPHWS",
        createHashMapFromArray [
            ["CrateAllocations", 1],
            ["SpecialtyAllocations", 1],
            ["WhitelistedFlags", []]
        ]
    ],
    [
        "OPTL",
        createHashMapFromArray [
            ["CrateAllocations", 3],
            ["SpecialtyAllocations", 3],
            ["WhitelistedFlags", []]
        ]
    ],
    [
        "OPGN",
        createHashMapFromArray [
            ["CrateAllocations", 2],
            ["SpecialtyAllocations", 2],
            ["WhitelistedFlags", []]
        ]
    ],
    [
        "OPLSPEC",
        createHashMapFromArray [
            ["CrateAllocations", 0],
            ["SpecialtyAllocations", 0],
            ["WhitelistedFlags", []]
        ]
    ],
    [
        "OPENGI",
        createHashMapFromArray [
            ["CrateAllocations", 1],
            ["SpecialtyAllocations", 1],
            ["WhitelistedFlags", []]
        ]
    ],
    [
        "OPSNIP",
        createHashMapFromArray [
            ["CrateAllocations", 1],
            ["SpecialtyAllocations", 1],
            ["WhitelistedFlags", []]
        ]
    ],
    [
        "OPSAP",
        createHashMapFromArray [
            ["CrateAllocations", 1],
            ["SpecialtyAllocations", 1],
            ["WhitelistedFlags", []]
        ]
    ],
    [
        "TERMTL",
        createHashMapFromArray [
            ["CrateAllocations", 0],
            ["SpecialtyAllocations", 0],
            ["WhitelistedFlags", []]
        ]
    ],
    [
        "TERMMM",
        createHashMapFromArray [
            ["CrateAllocations", 1],
            ["SpecialtyAllocations", 1],
            ["WhitelistedFlags", []]
        ]
    ],
    [
        "TERMAM",
        createHashMapFromArray [
            ["CrateAllocations", 1],
            ["SpecialtyAllocations", 1],
            ["WhitelistedFlags", []]
        ]
    ],
    [
        "OPETL",
        createHashMapFromArray [
            ["CrateAllocations", 3],
            ["SpecialtyAllocations", 3],
            ["WhitelistedFlags", []]
        ]
    ]
];


/*

    "ResupplyCrates": [
            "Crate Name": {
                "SquadLocks": Array<SQUAD NAMES> // An array of the shorthand squad identifiers that this crate will be locked to. If empty then its not locked to any specific squad.
                "WhitelistedRoles": Array<Flags> // What flags can pull this crate specifically, if left as empty array then it will use only blacklist to exclude
                "BlacklistedRoles": Array<Flags> // What flags can not pull this crate specifically, if left as empty array, then only whitelisted flags can pull. If both are empty, then anyone can pull.
                "Specialty"?: boolean // Is this a specialty crate (optional)
                "CustomCooldown"?: number // A custom cooldown can be specified (optional)
                "SpecialtyCost"?: number // A custom cost can be added too. (optional)
                "Model": string, // Crate model
                "Items": {
                    [key: string]: number // Items inside and how many
                },
                "Offset"?: [number, number, number], // Carrying offset (optional)
            }
        ]
*/
// Default timer for specialty crates on grabbing / refill
ResupplyDefaultSpecialtyCooldown = 2700; 
ResupplyDefaultRecallCooldown = 3600; 


ResupplyCrates = createHashMapFromArray [
    [
        "RESUPPLY, GENERAL",
        createHashMapFromArray [
            ["Model", "Box_NATO_Equip_F"],
            ["SquadLocks", ["SL", "PLHQ", "WPSQ", "CHQ", "LOGI", "GBS", "AIR"]],
            ["WhitelistedRoles", []],
            ["BlacklistedRoles", ["CHV", "IDF", "PJ"]],
            [
                "Items",
                createHashMapFromArray [
                    ["rhs_weap_M320", 1],
                    ["ACE_Humanitarian_Ration", 10],
                    ["rhs_mag_30Rnd_556x45_M855A1_PMAG", 50],
                    ["rhs_mag_30Rnd_556x45_M855A1_PMAG_Tracer_Red", 50],
                    ["rhsusf_200Rnd_556x45_mixed_soft_pouch_coyote", 25],
					["rhs_mag_M433_HEDP", 60],
					["rhs_mag_M441_HE", 40],
                    ["rhs_mag_m714_White", 30],
                    ["rhs_mag_M583A1_white", 30],
                    ["rhs_mag_m67", 30],
                    ["rhs_mag_an_m8hc", 15],
                    ["rhs_mag_m18_green", 15],
                    ["ACE_elasticBandage", 20],
                    ["ACE_packingBandage", 30],
                    ["ACE_quikclot", 30],
                    ["ACE_bloodIV", 15],
                    ["ACE_bloodIV_250", 20],
                    ["ACE_bloodIV_500", 20],
                    ["kat_PainKillers", 10],
                    ["kat_IV_16", 30]
                ]
            ]
        ]
    ],
    [
        "RESUPPLY 40MM CARTRIDGES, GRENADES",
        createHashMapFromArray [
            ["Model", "Box_NATO_Grenades_F"],
            ["SquadLocks", ["SL", "PLHQ", "WPSQ", "CHQ", "LOGI", "AIR"]],
            ["WhitelistedRoles", []],
            ["BlacklistedRoles", ["CHV", "IDF", "PJ"]],
            [
                "Items",
                createHashMapFromArray [
                    ["rhs_weap_M320", 1],
                    ["rhs_mag_M433_HEDP", 40],
					["rhs_mag_M441_HE", 40],
                    ["rhs_mag_m714_White", 30],
                    ["rhs_mag_m713_Red", 20],
                    ["rhs_mag_M583A1_white", 30],
                    ["rhs_mag_m67", 20],
                    ["rhs_mag_an_m8hc", 40],
                    ["rhs_mag_m18_green", 20],
                    ["rhs_mag_m18_purple", 10],
                    ["rhs_mag_m18_red", 20]
                    
                ]
            ]
        ]
    ],
    ["MEDICAL CRATE (BASIC)", 
        createHashMapFromArray [
            ["Model", "ACE_medicalSupplyCrate"],
            ["SquadLocks", ["MED", "PLHQ", "WPSQ", "CHQ", "LOGI", "AIR"]],
            ["WhitelistedRoles", []],
            ["BlacklistedRoles", ["CHV", "IDF", "PJ"]],
            [
                "Items", 
                createHashMapFromArray [
                    ["ACE_bloodIV", 15],
                    ["ACE_bloodIV_250", 20],
                    ["ACE_bloodIV_500", 20],
                    ["ACE_plasmaIV", 15],
                    ["ACE_plasmaIV_250", 20],
                    ["ACE_plasmaIV_500", 20],
                    ["ACE_elasticBandage", 50],
                    ["ACE_packingBandage", 50],
                    ["ACE_quikclot", 50],
                    ["ACE_epinephrine", 10],
                    ["kat_Painkiller", 15],
                    ["ACE_adenosine", 10],
                    ["ACE_surgicalKit", 2],
                    ["ACE_tourniquet", 8],
                    ["ACE_splint", 8],
                    ["kat_IV_16", 30]
                ]   
            ]
        ]
    ],
    ["100Rnd 762x51, AMMUNITION",
        createHashMapFromArray [
            ["Model", "Box_NATO_Support_F"],
            ["SquadLocks", ["PLHQ", "WPSQ", "CHQ", "LOGI", "AIR"]],
            ["WhitelistedRoles", []],
            ["BlacklistedRoles", ["CHV", "IDF" , "PJ", "GI"]],
            [
                "Items",
                createHashMapFromArray [
                    ["rhsusf_100Rnd_762x51_m80a1epr", 40],
                    ["rhsusf_100Rnd_762x51_m80a1epr", 40]
                ]   
            ]
        ]
    ],
    [
        "TACP CRATE",
        createHashmapFromArray [
            ["Model", "Box_NATO_Support_F"],
            ["SquadLocks", ["JFO"]],
            ["WhitelistedRoles", ["JFO"]],
            ["BlacklistedRoles", []],
            ["SpecialtyCost", 1],
            ["Offset", [0, 1.5, 1]],
            ["Category", "Special Equipment"],
            [
                "Items",
                createHashMapFromArray [
                    ["tfw_rf3080Item", 1]
                ]
            ]
        ]
    ],
    [
        "HQ AT",
        createHashmapFromArray [
            ["Model", "Box_T_NATO_WpsSpecial_F"],
            ["SquadLocks", ["PLHQ", "CHQ"]],
            ["WhitelistedRoles", ["PL", "CO", "XO"]],
            ["BlacklistedRoles", []],
            ["SpecialtyCost", 1],
            ["Offset", [0, 1.5, 1]],
            ["Category", "Special Equipment"],
            [
                "Items",
                createHashMapFromArray [
                    ["rhs_weap_m32", 1],
                    ["rhsusf_mag_6Rnd_M433_HEDP", 3],
                    ["rhsusf_mag_6Rnd_M583A1_white", 3],
                    ["rhsusf_mag_6Rnd_M714_white", 3],
                    ["rhsusf_mag_6Rnd_M585_white", 3],
                    ["rhs_weap_M136_hp", 6]
                ]
            ]
        ]
    ],
    [
        "PHANTOM CRATE",
        createHashmapFromArray [
            ["Model", "Box_T_NATO_Wps_F"],
            ["SquadLocks", ["PH"]],
            ["WhitelistedRoles", ["PH"]],
            ["BlacklistedRoles", []],
            ["SpecialtyCost", 1],
            ["Offset", [0, 1.5, 1]],
            ["Category", "Special Equipment"],
            [
                "Items",
                createHashMapFromArray [// ["ACE_FlareTripMine_Mag","rhsusf_m112_mag","ACE_M26_Clacker"]
                    ["tfw_rf3080Item", 1],
                    ["ACE_10Rnd_127x99_AMAX_Mag", 4]
                ]
            ]
        ]
    ],
    [
        "SHADOW DRONE CRATE",
        createHashmapFromArray [
            ["Model", "Box_NATO_Support_F"],
            ["SquadLocks", ["Shad"]],
            ["WhitelistedRoles", ["Shad"]],
            ["BlacklistedRoles", []],
            ["SpecialtyCost", 1],
            ["Offset", [0, 1.5, 1]],
            ["Category", "Special Equipment"],
            [
                "Items",
                createHashMapFromArray [
                    ["tfw_rf3080Item", 1],
                    ["DRNP_AR2P", 1],
                    ["DRNP_AR2_battery", 2]
                ]
            ]
        ]
    ],
    [
        "CHEVY Basic Resupply CRATE",
        createHashmapFromArray [
            ["Model", "rhs_7ya37_1_single"],
            ["SquadLocks", ["CHV"]],
            ["WhitelistedRoles", ["CHV"]],
            ["BlacklistedRoles", []],
            ["SpecialtyCost", 1],
            ["Offset", [0, 1.5, 1]],
            ["Category", "Special Equipment"],
            [
                "Items",
                createHashMapFromArray [
                    ["rhs_weap_M320", 1],
                    ["ACE_Humanitarian_Ration", 10],
                    ["rhs_mag_30Rnd_556x45_M855A1_PMAG", 50],
                    ["rhs_mag_30Rnd_556x45_M855A1_PMAG_Tracer_Red", 50],
                    ["rhsusf_200Rnd_556x45_mixed_soft_pouch_coyote", 25],
					["rhs_mag_M433_HEDP", 60],
					["rhs_mag_M441_HE", 40],
                    ["rhs_mag_m714_White", 30],
                    ["rhs_mag_M583A1_white", 30],
                    ["rhs_mag_m67", 30],
                    ["rhs_mag_an_m8hc", 15],
                    ["rhs_mag_m18_green", 15],
                    ["ACE_elasticBandage", 20],
                    ["ACE_packingBandage", 30],
                    ["ACE_quikclot", 30],
                    ["ACE_bloodIV", 15],
                    ["ACE_bloodIV_250", 20],
                    ["ACE_bloodIV_500", 20],
                    ["kat_PainKillers", 10],
                    ["kat_IV_16", 30]   
                ]
            ]
        ]
    ],
    [
        "MEDICAL CRATE (ADVANCED)", 
        createHashMapFromArray [
            ["Model", "ACE_medicalSupplyCrate"],
            ["SquadLocks", ["PJ", "PMed"]],
            ["WhitelistedRoles", ["PJ", "PMed"]],
            ["BlacklistedRoles", []],
            ["SpecialtyCost", 1],
            ["Offset", [0, 1.5, 1]],
            ["Category", "Special Equipment"],
            [
                "Items", 
                createHashMapFromArray [
                    ["ACE_bloodIV", 15],
                    ["ACE_bloodIV_250", 20],
                    ["ACE_bloodIV_500", 20],
                    ["ACE_plasmaIV", 15],
                    ["ACE_plasmaIV_250", 20],
                    ["ACE_plasmaIV_500", 20],
                    ["ACE_elasticBandage", 50],
                    ["ACE_packingBandage", 50],
                    ["ACE_quikclot", 50],
                    ["kat_IO_FAST", 10],
                    ["kat_lorazepam", 10],
                    ["kat_naloxone", 8],
                    ["kat_nitroglycerin", 10],
                    ["kat_norepinephrine", 10],
                    ["kat_phenylephrine", 10],
                    ["ACE_epinephrine", 10],
                    ["ACE_morphine", 15],
                    ["ACE_adenosine", 10],
                    ["kat_lidocaine", 15],
                    ["kat_TXA", 15],
                    ["ACE_surgicalKit", 2],
                    ["ACE_tourniquet", 8],
                    ["ACE_splint", 8],
                    ["kat_IV_16", 30]
                ]   
            ]
        ]
    ],
    [
        "Squad AT",
        createHashmapFromArray [
            ["Model", "Box_T_NATO_WpsSpecial_F"],
            ["SquadLocks", ["SL"]],
            ["WhitelistedRoles", ["SL"]],
            ["BlacklistedRoles", []],
            ["SpecialtyCost", 1],
            ["Offset", [0, 1.5, 1]],
            ["Category", "Special Equipment"],
            [
                "Items",
                createHashMapFromArray [
                    ["rhs_weap_M136_hp", 6]
                ]
            ]
        ]
    ],
    [
        "Heavy Weapons Squad AT Crate",
        createHashmapFromArray [
            ["Model", "Box_NATO_WpsSpecial_F"],
            ["SquadLocks", ["WPSQ"]],
            ["WhitelistedRoles", ["WPSQ"]],
            ["BlacklistedRoles", []],
            ["SpecialtyCost", 1],
            ["Offset", [0, 1.5, 1]],
            ["Category", "Special Equipment"],
            [
                "Items",
                createHashMapFromArray [
                    ["launch_MRAWS_green_F", 2],
                    ["MRAWS_HEAT55_F", 4],
                    ["MRAWS_HEAT_F", 3]
                

                ]
            ]
        ]
    ],
    [
        "Heavy Weapons Squad 2x HMG.50",
        createHashmapFromArray [
            ["Model", "Box_NATO_WpsSpecial_F"],
            ["SquadLocks", ["WPSQ"]],
            ["WhitelistedRoles", ["WPSQ"]],
            ["BlacklistedRoles", []],
            ["SpecialtyCost", 1],
            ["Offset", [0, 1.5, 1]],
            ["Category", "Special Equipment"],
            [
                "Items",
                createHashMapFromArray [//"rhs_mag_100rnd_127x99_mag_Tracer_Red","rhs_mag_200rnd_127x99_mag_Tracer_Red",
                    ["ace_compat_rhs_usf3_m2_carry", 2],
                    ["ace_csw_m3CarryTripod", 2],
                    ["ace_csw_100Rnd_127x99_mag_red", 10]

                ]
            ]
        ]
    ],
    [
        "Harpy AAA Crate",
        createHashmapFromArray [
            ["Model", "Box_NATO_WpsLaunch_F"],
            ["SquadLocks", ["HAAA","AAAS"]],
            ["WhitelistedRoles", ["HAAA","AAAS"]],
            ["BlacklistedRoles", []],
            ["SpecialtyCost", 1],
            ["Offset", [0, 1.5, 1]],
            ["Category", "Special Equipment"],
            [
                "Items",
                createHashMapFromArray [
                    ["rhs_weap_fim92", 1],
                    ["rhs_fim92_mag", 3]
                ]
            ]
        ]
    ],
    [
        "Goblin Crate",
        createHashmapFromArray [
            ["Model", "Box_Syndicate_Wps_F"],
            ["SquadLocks", ["GBS","GBT"]],
            ["WhitelistedRoles", ["GBS","GBT"]],
            ["BlacklistedRoles", []],
            ["SpecialtyCost", 1],
            ["Offset", [0, 1.5, 1]],
            ["Category", "Special Equipment"],
            [
                "Items",
                createHashMapFromArray [
                    ["rhsusf_m112_mag", 10],
                    ["SatchelCharge_Remote_Mag", 2],
                    ["SLAMDirectionalMine_Wire_Mag", 4],
                    ["ClaymoreDirectionalMine_Remote_Mag", 4],
                    ["ACE_M26_Clacker", 2],
                    ["bunwell_axe", 1],
                    ["ACE_DefusalKit", 2],
                    ["ACE_VMM3", 2]

                ]
            ]
        ]
    ],
    [
        "Wraith Tow (Launcher)",
        createHashmapFromArray [
            ["Model", "RHS_TOW_TriPod_WD"],
            ["SquadLocks", ["WTL"]],
            ["WhitelistedRoles", ["WTL"]],
            ["BlacklistedRoles", []],
            ["SpecialtyCost", 1],
            ["Offset", [0, 1.5, 1]],
            ["Category", "Special Equipment"],
            [
                "Items",
                createHashMapFromArray [
                ]
            ]
        ]
    ],
    [
        "Wraith Tow (AMMO)",
        createHashmapFromArray [
            ["Model", "Box_T_NATO_WpsSpecial_F"],
            ["SquadLocks", ["WTL"]],
            ["WhitelistedRoles", ["WTL"]],
            ["BlacklistedRoles", []],
            ["SpecialtyCost", 1],
            ["Offset", [0, 1.5, 1]],
            ["Category", "Special Equipment"],
            [
                "Items",
                createHashMapFromArray [
                ["ace_compat_rhs_usf3_mag_TOW2bb", 1],
                ["ace_compat_rhs_usf3_mag_TOW", 1],
                ["ace_compat_rhs_usf3_mag_TOWB", 1]
                ]
            ]
        ]
    ],
    [
        "Mortarman Mortor M252",
        createHashmapFromArray [
            ["Model", "RHS_M252_WD"],
            ["SquadLocks", ["IDFM"]],
            ["WhitelistedRoles", ["IDFM"]],
            ["BlacklistedRoles", []],
            ["SpecialtyCost", 1],
            ["Offset", [0, 1.5, 1]],
            ["Category", "Special Equipment"],
            [
                "Items",
                createHashMapFromArray [
                ]
            ]
        ]
    ],
    [
        "81mm Mortar Round (HE)",
        createHashMapFromArray [
            ["Model", "Box_NATO_AmmoOrd_F"],
            ["SquadLocks", ["IDFM"]],
            ["WhitelistedRoles", ["IDFM"]],
            ["BlacklistedRoles", []],
            ["SpecialtyCost", 1],
            ["Offset", [0, 1.5, 1]],
            ["Category", "Special Equipment"],
            [
                "Items",
                createHashMapFromArray [
                    ["ACE_1Rnd_82mm_Mo_HE", 32]
                ]
            ]
        ]
    ],
    [
        "81mm Mortar Round (Illum)",
        createHashMapFromArray [
            ["Model", "Box_NATO_AmmoOrd_F"],
            ["SquadLocks", ["IDFM"]],
            ["WhitelistedRoles", ["IDFM"]],
            ["BlacklistedRoles", []],
            ["SpecialtyCost", 1],
            ["Offset", [0, 1.5, 1]],
            ["Category", "Special Equipment"],
            [
                "Items",
                createHashMapFromArray [
                    ["ACE_1Rnd_82mm_Mo_Illum", 32]
                ]
            ]
        ]
    ],
    [
        "81mm Mortar Round (Smoke)",
        createHashMapFromArray [
            ["Model", "Box_NATO_AmmoOrd_F"],
            ["SquadLocks", ["IDFM"]],
            ["WhitelistedRoles", ["IDFM"]],
            ["BlacklistedRoles", []],
            ["SpecialtyCost", 1],
            ["Offset", [0, 1.5, 1]],
            ["Category", "Special Equipment"],
            [
                "Items",
                createHashMapFromArray [
                    ["ACE_1Rnd_82mm_Mo_Smoke", 32]
                ]
            ]
        ]
    ],
    [///////////////////////////// OPFOR STARTS HERE/////////////////////////////////
        "Russian Basic Resupply CRATE",
        createHashMapFromArray [
            ["Model", "Box_AAF_Uniforms_F"],
            ["SquadLocks", ["OPDC","OPSL","OPTL","OPPIL"]],
            ["WhitelistedRoles", ["OPDC","OPSL","OPTL","OPPIL"]],
            ["BlacklistedRoles", []],
            [
                "Items",
                createHashMapFromArray [
                    ["rhs_30Rnd_545x39_7N10_AK", 50],// ammo
                    ["rhs_20rnd_9x39mm_SP6", 20],
                    ["rhs_100Rnd_762x54mmR_7N13", 20],
                    ["rhs_mag_rgd5", 20],// Grenades
                    ["rhs_mag_rdg2_white", 30],
                    ["rhs_VOG25", 50],// 40mm
                    ["ACE_elasticBandage", 20],// misc
                    ["ACE_packingBandage", 30],
                    ["ACE_quikclot", 30],
                    ["ACE_bloodIV", 15],
                    ["ACE_bloodIV_250", 20],
                    ["ACE_bloodIV_500", 20],
                    ["ACE_plasmaIV", 15],
                    ["ACE_plasmaIV_250", 20],
                    ["ACE_plasmaIV_500", 20],
                    ["kat_PainKillers", 10],
                    ["kat_IV_16", 30],
                    ["ACE_bodyBag", 5]
                ]
            ]
        ]
    ],
    [/////////////////Enginer crate of EXPLOSIVES
        "Russian Explosives Ordinance CRATE",
        createHashMapFromArray [
            ["Model", "Box_IND_AmmoOrd_F"],
            ["SquadLocks", ["OPENGI","OPTL","OPGN"]],
            ["WhitelistedRoles", ["OPENGI","OPTL","OPGN"]],
            ["BlacklistedRoles", []],
            ["SpecialtyCost", 1],
            ["Offset", [0, 1.5, 1]],
            ["Category", "Special Equipment"],
            [
                "Items",
                createHashMapFromArray [
                    ["ACE_M26_Clacker", 1],
                    ["ClaymoreDirectionalMine_Remote_Mag", 6],
                    ["ATMine_Range_Mag", 2],
                    ["rhsusf_m112_mag", 3]
                ]
            ]
        ]
    ],

    [/////////////////DRONE IN A BOX /////////////////
        "Drone and Battery Crate",
        createHashMapFromArray [
            ["Model", "Box_IND_Support_F"],
            ["SquadLocks", ["OPDRON","OPPIL"]],
            ["WhitelistedRoles", ["OPDRON","OPPIL"]],
            ["BlacklistedRoles", []],
            ["SpecialtyCost", 1],
            ["Offset", [0, 1.5, 1]],
            ["Category", "Special Equipment"],
            [
                "Items",
                createHashMapFromArray [
                    ["DRNP_AR2P", 2],
                    ["DRNP_AR2_battery", 3],
                    ["O_UavTerminal", 1],
                    ["ItemAndroid", 1]
                ]
            ]
        ]
    ],

    [/////////////////////Launchers///////////
        "Crate 1 (RPG-7)",
        createHashmapFromArray [
            ["Model", "Box_IND_WpsLaunch_F"],
            ["SquadLocks", ["OPHWS","OPTL","OPGN"]],
            ["WhitelistedRoles", ["OPHWS","OPTL","OPGN"]],
            ["BlacklistedRoles", []],
            ["SpecialtyCost", 1],
            ["Offset", [0, 1.5, 1]],
            ["Category", "Special Equipment"],
            [
                "Items",
                createHashMapFromArray [
                    ["rhs_rpg7_PG7VR_mag",4],
                    ["rhs_rpg7_OG7V_mag", 4],
                    ["rhs_weap_rpg7", 2],
                    ["rhs_rpg7_PG7V_mag", 2]
                ]
            ]
        ]
    ],
    /*[
        "Crate 2 (Igla-S)",
        createHashmapFromArray [
            ["Model", "Box_East_WpsLaunch_F"],
            ["SquadLocks", ["OPHWS"]],
            ["WhitelistedRoles", ["OPHWS"]],
            ["BlacklistedRoles", []],
            ["SpecialtyCost", 1],
            ["Offset", [0, 1.5, 1]],
            ["Category", "Special Equipment"],
            [
                "Items",
                createHashMapFromArray [
                    ["karmakut_sa24_launcher", 1],
                    ["karmakut_sa24_x1", 3]
                ]
            ]
        ]
    ],*/
    [
        "Crate 2 (Stinger)",
        createHashmapFromArray [
            ["Model", "Box_IND_WpsLaunch_F"],
            ["SquadLocks", ["OPHWS","OPTL","OPGN"]],
            ["WhitelistedRoles", ["OPHWS","OPTL","OPGN"]],
            ["BlacklistedRoles", []],
            ["SpecialtyCost", 1],
            ["Offset", [0, 1.5, 1]],
            ["Category", "Special Equipment"],
            [
                "Items",
                createHashMapFromArray [
                    ["rhs_weap_fim92", 1],
                    ["rhs_fim92_mag", 3]
                ]
            ]
        ]
    ],
    /*[
        "Crate 3 (RPG-3)",
        createHashmapFromArray [
            ["Model", "Box_IND_WpsSpecial_F"],
            ["SquadLocks", ["OPHWS"]],
            ["WhitelistedRoles", ["OPHWS"]],
            ["BlacklistedRoles", []],
            ["SpecialtyCost", 1],
            ["Offset", [0, 1.5, 1]],
            ["Category", "Special Equipment"],
            [
                "Items",
                createHashMapFromArray [
                    ["launch_RPG32_green_F", 1],
                    ["RPG32_F", 3]
                ]
            ]
        ]
    ],
    //////////// SNIPERCRATE ////////////
    [
        "SNOT .50 AMMO CRATE",
        createHashmapFromArray [
            ["Model", "Box_East_Ammo_F"],
            ["SquadLocks", ["OPSNIP"]],
            ["WhitelistedRoles", ["OPSNIP"]],
            ["BlacklistedRoles", []],
            ["SpecialtyCost", 1],
            ["Offset", [0, 1.5, 1]],
            ["Category", "Special Equipment"],
            [
                "Items",
                createHashMapFromArray [// ["ACE_FlareTripMine_Mag","rhsusf_m112_mag","ACE_M26_Clacker"]
                    ["ACE_10Rnd_127x99_AMAX_Mag", 3]
                ]
            ]
        ]
    ],*/
    //////////// Emplacements ///////////
    [
        "Russian Metis AmmoBox",
        createHashmapFromArray [
            ["Model", "Box_IND_Wps_F"],
            ["SquadLocks", ["OPGN","OPTL"]],
            ["WhitelistedRoles", ["OPGN","OPTL"]],
            ["BlacklistedRoles", []],
            ["SpecialtyCost", 1],
            ["Offset", [0, 1.5, 1]],
            ["Category", "Special Equipment"],
            [
                "Items",
                createHashMapFromArray [
                    ["ace_compat_rhs_afrf3_metis_carry", 1],
                    ["ace_compat_rhs_afrf3_mag_9M131F", 2],
                    ["ace_compat_rhs_afrf3_mag_9M131M", 4]
                ]
            ]
        ]
    ], 
    [
        "Russian Spg9 AmmoBox",
        createHashmapFromArray [
            ["Model", "Box_IND_WpsSpecial_F"],
            ["SquadLocks", ["OPGN","OPTL"]],
            ["WhitelistedRoles", ["OPGN","OPTL"]],
            ["BlacklistedRoles", []],
            ["SpecialtyCost", 1],
            ["Offset", [0, 1.5, 1]],
            ["Category", "Special Equipment"],
            [
                "Items",
                createHashMapFromArray [
                    ["ace_compat_rhs_afrf3_spg9m_carry", 1],
                    ["ace_csw_spg9CarryTripod", 1],
                    ["ace_compat_rhs_afrf3_mag_OG9VM", 6],
                    ["ace_compat_rhs_afrf3_mag_PG9VNT", 6]
                ]
            ]
        ]
    ],
    ////////////////////////////////// MORTAR TEAM ///////////////////////////
    [
        "MORTAR",
        createHashmapFromArray [
            ["Model", "rhs_2b14_82mm_msv"],
            ["SquadLocks", ["TERMMM","OPTL","OPGN"]],
            ["WhitelistedRoles", ["TERMMM","OPTL","OPGN"]],
            ["BlacklistedRoles", []],
            ["SpecialtyCost", 1],
            ["Offset", [0, 1.5, 1]],
            ["Category", "Special Equipment"],
            [
                "Items",
                createHashMapFromArray [
                    
                ]
            ]
        ]
    ],
    [
        "82mm Mortar Ammo (HE,SMOKE,ILLUMINATION)",
        createHashmapFromArray [
            ["Model", "Box_AAF_Equip_F"],
            ["SquadLocks", ["TERMAM","OPTL","OPGN"]],
            ["WhitelistedRoles", ["TERMAM","OPTL","OPGN"]],
            ["BlacklistedRoles", []],
            ["SpecialtyCost", 1],
            ["Offset", [0, 1.5, 1]],
            ["Category", "Special Equipment"],
            [
                "Items",
                createHashMapFromArray [
                    ["ACE_1Rnd_82mm_Mo_HE", 25],
                    ["ACE_1Rnd_82mm_Mo_Illum", 20],
                    ["ACE_1Rnd_82mm_Mo_Smoke", 20]
                ]
            ]
        ]
    ]
];


// Cache what is special
SpecialCategories = createHashMap;

ResupplyModelsUsed = createHashMap;

ResupplyCratesInit = createHashMap;
ON_SUPPLY_CRATE_INIT = {
    params ["_supplyCrate"];

    [{
        params ["_supplyCrate"];

        
        private _set = ResupplyCratesInit get (str _supplyCrate);

        diag_log format ["Supply Crate Initialize %1", str _supplyCrate];

        if(!(isNil { _set })) exitWith {};

        diag_log format ["  Supply Crate is not initialized... adding actions and setting carryable"];

        ResupplyCratesInit set [str _supplyCrate, true];

        private _offset = ResupplyModelsUsed get (typeOf _supplyCrate);
        
        [_supplyCrate, true, _offset, 0, true] call ace_dragging_fnc_setCarryable;
        [_supplyCrate, true, _offset, 0, true] call ace_dragging_fnc_setDraggable;
        // Add supply crate ace actions for clients.
        if( hasInterface) then {
            [_supplyCrate] call addResupplyActions;
        };
        
    }, [_supplyCrate], 2] call CBA_fnc_waitAndExecute; 
    
};
{ 
    private _crateName = _x; 
    private _crateInfo = _y; 
 
    private _model = _crateInfo get "Model"; 
    private _offset = _crateInfo get "Offset"; 
 
    private _exists = ResupplyModelsUsed getOrDefault [_model, []]; 
 
    if((_exists isEqualTo [])) then { 
 
        if(isNil { _offset }) then { 
            _offset = [0, 1, 1]; 
        }; 
        diag_log format ["%1 does not exist yet, apply init (%2)", _model, _offset]; 
        ResupplyModelsUsed set [_model, _offset]; 
 
        [_model, "init", 
            { 
                _this call ON_SUPPLY_CRATE_INIT; 
            }, 
            false, 
            [], 
            true 
        ] call CBA_fnc_addClassEventHandler; 
    }; 
     
    
 
    private _category = _crateInfo get "Category"; 
 
    if (isNil { _category }) then { 
        continue 
    }; 
    private _specialtyCost = _crateInfo getOrDefault ["SpecialtyCost", 0]; 
 
    if(_specialtyCost > 0) then { 
        SpecialCategories set [_category, true]; 
    }; 
} forEach ResupplyCrates;



// Server sets this globally and persistent for JIP via missionNamespace variable at start up.
// One source of truth.
// Clients can get from missionNamespace with their squad name in an O(1) lookup for data pertaining to current status even if JIP.
if (isServer) then {

    "Server Init Config" call resupplyLog;
    {
        
        private _flagInfo = _x;

    
        private _squadNames = _flagInfo get "SquadNames";
        private _squadFlag = _flagInfo get "FlagName";
        format ["Squad Flag %1: %2", _squadFlag, _squadNames] call resupplyLog;

        private _specialtyResourceToStart = ResupplyCrateAllocations getOrDefault [_squadFlag, createHashMapFromArray [["SpecialtyAllocations", 0]]] get "SpecialtyAllocations";

        

        {
            
            private _squadName = _x;
            format ["SpecialtyResourceToStart set to %1 for %2", _specialtyResourceToStart, _squadName] call resupplyLog;
            // TODO: Verify this isn't going to break anything or have conflicts.
            missionNamespace setVariable [_squadName,
                createHashMapFromArray [
                    ["SpecialtyResources", _specialtyResourceToStart],
                    ["Crates", 0],
                    ["ResetTime", -1],
                    ["RecallResetTime", -1],
                    ["CanReset", true],
                    ["CrateObjects", []]
                ],
                true
            ];
        } forEach _squadNames;
    } forEach ResupplyRoleDescriptionToSquadFlags;
};