/*
    Faction-neutral Battlespace policy.
    Vehicle, static, SAM, artillery, and infantry classes are generated from
    the selected OPFOR catalog before these rules are consumed.
*/

opfor_fuel_container = "B_Slingload_01_Fuel_F";                         // HURON Fuel
opfor_ammo_container = "B_Slingload_01_Ammo_F";                         // HURON Ammo
opfor_flag = "Flag_CSAT_W";                                             // RU Flag

BATTLESPACE_MORTAR_OVERRIDE_EXPRESSIONS = [
	"(4 * houses) - (4 * sea) - meadow - hills",
	"(2 * forest) + (2 * trees) - (4 * meadow) - (4 * sea)",
	"(2 * houses) + (2 * trees) - (4 * meadow) - (4 * sea)"
];


// TODO: Move mortar stuff it to its own file eventually
BATTLESPACE_MORTARS = [];
