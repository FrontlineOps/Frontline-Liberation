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

/* Automatic per-group allowance: one active crate per four connected members. */
ResupplyPlayersPerCrate = 4;
ResupplyMinimumGroupCrates = 1;
ResupplyMaximumGroupCrates = 4;

// Legacy mission-role metadata used only by unrelated specialty/logistics permissions.
// It no longer controls whether a player can see or pull automatic faction crates.
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
// Legacy specialty/logistics profile matching. Automatic group identity comes from the networked Arma Group.
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


// Legacy specialty and cross-group resupplier profiles. Base crate limits are automatic per Arma group.
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


ResupplyCrates = createHashMap;



// Cache what is special
[] call KPLIB_fnc_buildAutomaticResupplyCrates;

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



/* Group allocation state is created lazily by setResupplyFlags on the server. */
