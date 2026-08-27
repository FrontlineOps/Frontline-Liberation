/*
    Faction-neutral battlegroup and Battlespace policy.
    Vehicle, static, SAM, artillery, and infantry classes are generated from
    the selected OPFOR catalog before these rules are consumed.
*/

opfor_fuel_container = "B_Slingload_01_Fuel_F";             			// HURON Fuel
opfor_ammo_container = "B_Slingload_01_Ammo_F";             			// HURON Ammo
opfor_flag = "Flag_CSAT_W";                                       // RU Flag

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

// TODO: Move to own file
// There will be one infantry spawning for every X players
// Infantry spawn using the opfor_at, opfor_aa etc.
BATTLESPACE_DEFENDERS_INFANTRY_RATIO = 1 / 2; // Flip to mean X infantry for every one player(s)
// There will be one vehicle for every X players
BATTLESPACE_DEFENDERS_VEHICLE_RATIO = 18;
// There will be one static for every X players
BATTLESPACE_DEFENDERS_STATICS_RATIO = 10;


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
