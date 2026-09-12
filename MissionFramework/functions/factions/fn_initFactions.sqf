/* Load building configuration, resolve factions and index runtime catalogs. */
if (isRemoteExecuted) exitWith {false};
KPLIB_initPresets = false;
private _start = diag_tickTime;
if (isServer) then {
    ["Initializing faction and build catalogs", "FACTIONS"] call KPLIB_fnc_log;
};

[] call compileFinal preprocessFileLineNumbers "kp_liberation_build_config.sqf";
KPLIB_autoFactionActive = false;
[] call KPLIB_fnc_applyFactionPresets;

// Remove unavailable classes before building the runtime indexes.

// BLUFOR
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
elite_vehicles                              = elite_vehicles                            select {[_x] call KPLIB_fnc_checkClass};

// OPFOR
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

/*
    Fetch arrays with only classnames from the BLUFOR build catalogs.
    Beware that all classnames are converted to lowercase. Important for e.g. `in` checks, as it's case-sensitive.
*/
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


/*
    Liberation specific collections
*/

private _airBuildList = rotarylogi_vehicles + rotarycas_vehicles + fixedwing_vehicles;

// Categories 0 and 1 remain reserved; vehicles and structures retain their IDs.
KPLIB_buildList         = [[], [], light_vehicles + recon_vehicles + medical_vehicles, heavy_vehicles, _airBuildList, static_vehicles + artillery_vehicles + atgm_vehicles + aa_vehicles, buildings, support_vehicles + groundlogi_vehicles];
KPLIB_crates            = [KP_liberation_supply_crate, KP_liberation_ammo_crate, KP_liberation_fuel_crate];
KPLIB_airSlots          = [KP_liberation_heli_slot_building, KP_liberation_plane_slot_building];
KPLIB_storageBuildings  = [KP_liberation_small_storage_building, KP_liberation_large_storage_building];
KPLIB_upgradeBuildings  = [KP_liberation_recycle_building, KP_liberation_air_vehicle_building, KP_liberation_heli_slot_building, KP_liberation_plane_slot_building];

KPLIB_crates            = KPLIB_crates              apply {toLower _x};
KPLIB_airSlots          = KPLIB_airSlots            apply {toLower _x};
KPLIB_storageBuildings  = KPLIB_storageBuildings    apply {toLower _x};
KPLIB_upgradeBuildings  = KPLIB_upgradeBuildings    apply {toLower _x};

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

// Include every enemy soldier class when identifying surrendered prisoners.
KPLIB_o_inf_classes = ((KPLIB_autoFactionCatalogs get "opfor") get "units") apply {toLower _x};

// Military alphabet used for FOBs and convois
military_alphabet = ["Alpha", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot", "Golf", "Hotel", "India", "Juliet", "Kilo", "Lima", "Mike", "November", "Oscar", "Papa", "Quebec", "Romeo", "Sierra", "Tango", "Uniform", "Victor", "Whiskey", "X-Ray", "Yankee", "Zulu"];

// Misc variables
markers_reset = [99999,99999,0];

KPLIB_initPresets = true;

if (isServer) then {
    [format ["Faction and build catalogs ready in %1 seconds", diag_tickTime - _start], "FACTIONS"] call KPLIB_fnc_log;
};
