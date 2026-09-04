/*
    Resolves required faction selections and maps generated catalogs onto
    Liberation globals. No legacy faction, arsenal, or resupply fallback is
    permitted: invalid configuration stops initialization explicitly.
*/

private _bluforFactions = +(missionNamespace getVariable ["KP_liberation_autoFaction_blufor", []]);
private _opforFactions = +(missionNamespace getVariable ["KP_liberation_autoFaction_opfor", []]);
private _resistanceFactions = +(missionNamespace getVariable ["KP_liberation_autoFaction_resistance", []]);
private _civilianFactions = +(missionNamespace getVariable ["KP_liberation_autoFaction_civilians", []]);

private _catalogs = createHashMapFromArray [
    ["blufor", [_bluforFactions, 1] call KPLIB_fnc_buildFactionCatalog],
    ["opfor", [_opforFactions, 0] call KPLIB_fnc_buildFactionCatalog],
    ["resistance", [_resistanceFactions, 2] call KPLIB_fnc_buildFactionCatalog],
    ["civilians", [_civilianFactions, 3] call KPLIB_fnc_buildFactionCatalog]
];

private _configurationErrors = [];
{
    _x params ["_label", "_catalog", "_requireVehicles"];
    if ((_catalog get "factions") isEqualTo []) then {
        _configurationErrors pushBack format ["%1 selection is empty, invalid, or assigned to the wrong side", _label];
        continue;
    };
    if ((_catalog get "units") isEqualTo []) then {
        _configurationErrors pushBack format ["%1 selection exposes no public units", _label];
    };
    if (_requireVehicles && {(_catalog get "allVehicles") isEqualTo []}) then {
        _configurationErrors pushBack format ["%1 selection exposes no public vehicles", _label];
    };
} forEach [
    ["BLUFOR", _catalogs get "blufor", true],
    ["OPFOR", _catalogs get "opfor", true],
    ["Resistance", _catalogs get "resistance", false],
    ["Civilian", _catalogs get "civilians", false]
];

if (_configurationErrors isNotEqualTo []) then {
    private _message = format [
        "Automatic faction initialization failed: %1. Correct the four KP_liberation_autoFaction_* arrays in kp_liberation_config.sqf.",
        _configurationErrors joinString "; "
    ];
    [_message, "FACTIONS"] call KPLIB_fnc_log;
    throw _message;
};

KPLIB_autoFactionCatalogs = _catalogs;
KPLIB_autoFactionSelections = createHashMapFromArray [
    ["blufor", (_catalogs get "blufor") get "factions"],
    ["opfor", (_catalogs get "opfor") get "factions"],
    ["resistance", (_catalogs get "resistance") get "factions"],
    ["civilians", (_catalogs get "civilians") get "factions"]
];

private _first = {
    params ["_values", ["_default", ""]];
    _values param [0, _default]
};
private _last = {
    params ["_values", ["_default", ""]];
    if (_values isEqualTo []) exitWith {_default};
    _values select ((count _values) - 1)
};
private _without = {
    params ["_values", "_excluded"];
    _values select {!(_x in _excluded)}
};
private _makeEntries = {
    params ["_classes", "_category"];
    _classes apply {
        private _cost = [_x, _category] call KPLIB_fnc_getAutomaticFactionPrice;
        [
            _x,
            _cost param [0, 0],
            _cost param [1, 0],
            _cost param [2, 0],
            getText (configFile >> "CfgVehicles" >> _x >> "displayName")
        ]
    }
};
private _squad = {
    params ["_groups", "_defaultUnits", ["_size", 8]];
    private _result = +(_groups param [0, _defaultUnits]);
    if (_result isEqualTo []) then {_result = +_defaultUnits};
    if (count _result > _size) then {_result resize _size};
    _result
};
private _transportConfigClasses = KPLIB_transportConfigs apply {toLower (_x select 0)};
private _registerTransportConfig = {
    params ["_vehicleClass"];
    private _classLower = toLower _vehicleClass;
    if (_vehicleClass isEqualTo "" || {_classLower in _transportConfigClasses}) exitWith {};

    private _vehicleSize = (sizeOf _vehicleClass) max 4;
    KPLIB_transportConfigs pushBack [_vehicleClass, -((_vehicleSize / 2) + 2), [0, -1, 1]];
    _transportConfigClasses pushBack _classLower;
};

private _blufor = _catalogs get "blufor";
    private _specialized =
        (_blufor get "recon") + (_blufor get "medical") +
        (_blufor get "groundLogistics") + (_blufor get "artillery") +
        (_blufor get "atgm") + (_blufor get "aa");
    private _light = [_blufor get "light", _specialized] call _without;
    private _groundMedical = (_blufor get "medical") select {!(_x isKindOf "Air")};
    private _airMedical = (_blufor get "medical") select {_x isKindOf "Air"};
    private _groundTransport = (_blufor get "transport") select {!(_x isKindOf "Air")};

    infantry_units = [_blufor get "units", "infantry"] call _makeEntries;
    light_vehicles = [_light, "light"] call _makeEntries;
    recon_vehicles = [_blufor get "recon", "recon"] call _makeEntries;
    medical_vehicles = [_groundMedical, "medical"] call _makeEntries;
    groundlogi_vehicles = [_blufor get "groundLogistics", "groundLogistics"] call _makeEntries;
    artillery_vehicles = [_blufor get "artillery", "artillery"] call _makeEntries;
    atgm_vehicles = [_blufor get "atgm", "atgm"] call _makeEntries;
    aa_vehicles = [_blufor get "aa", "aa"] call _makeEntries;
    heavy_vehicles = [_blufor get "heavy", "heavy"] call _makeEntries;
    rotarylogi_vehicles = [_blufor get "rotaryLogistics", "rotaryLogistics"] call _makeEntries;
    rotarycas_vehicles = [_blufor get "rotaryCas", "rotaryCas"] call _makeEntries;
    fixedwing_vehicles = [_blufor get "fixedWing", "fixedWing"] call _makeEntries;
    static_vehicles = [_blufor get "static", "static"] call _makeEntries;

    {
        [_x select 0] call _registerTransportConfig;
    } forEach (groundlogi_vehicles + rotarylogi_vehicles);

    private _units = _blufor get "units";
    private _groups = _blufor get "infantryGroups";
    private _defaultSquad = +_units;
    if (count _defaultSquad > 8) then {_defaultSquad resize 8};
    blufor_squad_inf_light = [_groups, _defaultSquad, 4] call _squad;
    blufor_squad_inf = [_groups, _defaultSquad, 8] call _squad;
    blufor_squad_at = [_blufor get "atGroups", blufor_squad_inf, 8] call _squad;
    blufor_squad_aa = [_blufor get "aaGroups", blufor_squad_inf, 8] call _squad;
    blufor_squad_recon = [_blufor get "reconGroups", blufor_squad_inf_light, 6] call _squad;
    blufor_squad_para = [_blufor get "paraGroups", blufor_squad_inf, 8] call _squad;

    crewman_classname = [_units, "crew"] call KPLIB_fnc_pickFactionUnit;
    pilot_classname = [_units, "pilot"] call KPLIB_fnc_pickFactionUnit;
    private _rotaryPool = (_blufor get "rotaryLogistics") + (_blufor get "rotaryCas");
    private _generalGroundPool = _light + (_blufor get "recon") + _groundTransport + (_blufor get "heavy");
    private _logisticsPool = (_blufor get "groundLogistics") + _groundTransport;
    Respawn_truck_typename = [_groundTransport + _logisticsPool, ""] call _first;

    KP_liberation_smallhelo_classname = [_blufor get "rotaryLogistics", [_rotaryPool, ""] call _first] call _first;
    KP_liberation_midhelo_classname = [_blufor get "rotaryCas", [_rotaryPool, ""] call _first] call _first;
    KP_liberation_bighelo_classname = [_blufor get "rotaryLogistics", [_rotaryPool, ""] call _last] call _last;
    KP_liberation_medhelo_classname = [_airMedical, [_rotaryPool, ""] call _first] call _first;
    KP_liberation_atkhelo_classname = [_blufor get "rotaryCas", [_rotaryPool, ""] call _first] call _first;
    KP_liberation_car_classname = [_light, [_generalGroundPool, ""] call _first] call _first;
    KP_liberation_atcar_classname = [_blufor get "atgm", [_generalGroundPool, ""] call _first] call _first;
    KP_liberation_truck_classname = [_groundTransport, [_logisticsPool, ""] call _first] call _first;
    KP_liberation_medcar_classname = [_groundMedical, [_groundTransport, ""] call _first] call _first;
    KP_liberation_zodiac_classname = [_blufor get "boat", ""] call _first;
    KP_liberation_rhib_classname = [_blufor get "boat", ""] call _last;
    KP_liberation_ifv_classname = [_blufor get "heavy", [_generalGroundPool, ""] call _first] call _first;
    KP_liberation_apc_classname = [_groundTransport, [_blufor get "heavy", ""] call _first] call _first;
    KP_liberation_cas_classname = [_blufor get "fixedWing", ""] call _first;
    KP_liberation_cap_classname = [_blufor get "fixedWing", ""] call _last;
    KP_liberation_drone_classname = [_blufor get "fixedWing", ""] call _first;
    KP_liberation_repair_classname = [_blufor get "groundLogistics", [_groundTransport, ""] call _first] call _first;
    KP_liberation_fuel_classname = [_blufor get "groundLogistics", [_groundTransport, ""] call _last] call _last;
private _opfor = _catalogs get "opfor";
    private _units = _opfor get "units";
    opfor_officer = [_units, "officer"] call KPLIB_fnc_pickFactionUnit;
    opfor_squad_leader = [_units, "squadleader"] call KPLIB_fnc_pickFactionUnit;
    opfor_team_leader = [_units, "teamleader"] call KPLIB_fnc_pickFactionUnit;
    opfor_sentry = [_units, "rifleman"] call KPLIB_fnc_pickFactionUnit;
    opfor_rifleman = opfor_sentry;
    opfor_rpg = [_units, "at"] call KPLIB_fnc_pickFactionUnit;
    opfor_grenadier = [_units, "grenadier"] call KPLIB_fnc_pickFactionUnit;
    opfor_machinegunner = [_units, "machinegunner"] call KPLIB_fnc_pickFactionUnit;
    opfor_heavygunner = [_units, "heavygunner"] call KPLIB_fnc_pickFactionUnit;
    opfor_marksman = [_units, "marksman"] call KPLIB_fnc_pickFactionUnit;
    opfor_sharpshooter = opfor_marksman;
    opfor_sniper = [_units, "sniper"] call KPLIB_fnc_pickFactionUnit;
    opfor_at = [_units, "at"] call KPLIB_fnc_pickFactionUnit;
    opfor_aa = [_units, "aa"] call KPLIB_fnc_pickFactionUnit;
    opfor_medic = [_units, "medic"] call KPLIB_fnc_pickFactionUnit;
    opfor_engineer = [_units, "engineer"] call KPLIB_fnc_pickFactionUnit;
    opfor_paratrooper = [_units, "paratrooper"] call KPLIB_fnc_pickFactionUnit;
    opfor_rto = [_units, "rto"] call KPLIB_fnc_pickFactionUnit;
    opfor_rto_loadout = getUnitLoadout opfor_rto;
    KPLIB_autoFactionOpforNightVision = (opfor_rto_loadout param [9, []]) param [5, ""];

    private _unitLoadouts = _units apply {getUnitLoadout _x};
    opfor_uniforms = [];
    opfor_vests = [];
    opfor_backpacks = [];
    {
        private _uniform = (_x param [3, []]) param [0, ""];
        private _vest = (_x param [4, []]) param [0, ""];
        private _backpack = (_x param [5, []]) param [0, ""];
        if (_uniform != "") then {opfor_uniforms pushBackUnique _uniform};
        if (_vest != "") then {opfor_vests pushBackUnique _vest};
        if (_backpack != "") then {opfor_backpacks pushBackUnique _backpack};
    } forEach _unitLoadouts;
    opfor_uniform_kit = (opfor_rto_loadout param [3, []]) param [1, []];

    private _defaultGroup = +_units;
    if (count _defaultGroup > 8) then {_defaultGroup resize 8};
    militia_squad = [(_opfor get "infantryGroups"), _defaultGroup, 8] call _squad;
    militia_squad_lower = militia_squad apply {toLower _x};
    private _allVehicles = _opfor get "allVehicles";
    private _generalPool = (_opfor get "light") + (_opfor get "recon");
    private _groundVehicles = _allVehicles select {!(_x isKindOf "Air")};
    if (_generalPool isEqualTo []) then {_generalPool = +_groundVehicles};
    if (_generalPool isEqualTo []) then {_generalPool = +_allVehicles};
    private _generalClass = _generalPool param [0, ""];
    private _heavyPool = +(_opfor get "heavy");
    if (_heavyPool isEqualTo []) then {_heavyPool = +_generalPool};
    private _transportPool = (_opfor get "transport") select {!(_x isKindOf "Air")};
    if (_transportPool isEqualTo []) then {_transportPool = +_generalPool};
    private _aaPool = +(_opfor get "aa");
    if (_aaPool isEqualTo []) then {_aaPool = +_generalPool};

    militia_vehicles = +_generalPool;
    opfor_vehicles = +_generalPool;
    opfor_vehicles_low_intensity = +opfor_vehicles;
    opfor_battlegroup_vehicles = _heavyPool + (_opfor get "aa") + (_opfor get "atgm") + (_opfor get "artillery");
    opfor_battlegroup_vehicles_low_intensity = _heavyPool + _generalPool;
    opfor_troup_transports = +_transportPool;
    opfor_choppers = (_opfor get "rotaryCas") + (_opfor get "rotaryLogistics");
    opfor_air = (_opfor get "fixedWing") + (_opfor get "rotaryCas");
    opfor_cap = +(_opfor get "fixedWing");
    if (opfor_cap isEqualTo []) then {opfor_cap = +opfor_air};
    opfor_tanks = [[0, _heavyPool]];
    opfor_sams = [[0, _aaPool]];
    private _armoredTransports = (_opfor get "heavy") select {
        getNumber (configFile >> "CfgVehicles" >> _x >> "transportSoldier") > 0
    };
    if (_armoredTransports isEqualTo []) then {_armoredTransports = +_transportPool};
    private _scoutPool = +(_opfor get "recon");
    if (_scoutPool isEqualTo []) then {_scoutPool = +_generalPool};
    opfor_ifvs = [[0, _armoredTransports]];
    opfor_apcs = [[0, _armoredTransports]];
    opfor_transports = [[0, _transportPool]];
    opfor_scout_cars = [[0, _scoutPool]];

    opfor_mrap = [_generalPool, _generalClass] call _first;
    opfor_mrap_armed = [_generalPool, _generalClass] call _last;
    opfor_transport_helo = [_opfor get "rotaryLogistics", opfor_choppers param [0, _generalClass]] call _first;
    opfor_transport_truck = [_transportPool, _generalClass] call _first;
    private _logisticsPool = +(_opfor get "groundLogistics");
    if (_logisticsPool isEqualTo []) then {_logisticsPool = +_transportPool};
    opfor_ammobox_transport = [_logisticsPool, _generalClass] call _first;
    opfor_fuel_truck = [_logisticsPool, _generalClass] call _last;
    opfor_ammo_truck = [_logisticsPool, _generalClass] call _first;
    [opfor_ammobox_transport] call _registerTransportConfig;

    BATTLESPACE_DEFENDERS_STATIC_CLASSES = +(_opfor get "static");

    BATTLESPACE_SAM_SITE_TELS = +(_opfor get "aa");
    BATTLESPACE_SAM_SITE_FCRS = +(_opfor get "aa");
    BATTLESPACE_SAM_SITE_SHORAD = (_opfor get "aa") apply {[_x]};
    BATTLESPACE_ENABLE_SAM_SPAWNS = (_opfor get "aa") isNotEqualTo [];

    private _artillery = _opfor get "artillery";
    if (_artillery isNotEqualTo []) then {
        BATTLESPACE_ARTILLERY_PIECE_CLASSES = +_artillery;
    } else {
        BATTLESPACE_DISABLE_ARTILLERY = true;
    };
private _resistance = _catalogs get "resistance";
    KP_liberation_guerilla_units = +(_resistance get "units");
    KP_liberation_guerilla_vehicles = +(_resistance get "allVehicles");

    private _weapons = [];
    private _uniforms = [];
    private _vests = [];
    private _headgear = [];
    private _facegear = [];
    {
        private _loadout = getUnitLoadout _x;
        private _primary = _loadout param [0, []];
        private _weapon = _primary param [0, ""];
        private _magazine = (_primary param [4, []]) param [0, ""];
        private _optic = _primary param [3, ""];
        if (_weapon != "" && {_magazine != ""}) then {
            _weapons pushBackUnique [_weapon, _magazine, 6, _optic, ""];
        };
        private _uniform = (_loadout param [3, []]) param [0, ""];
        private _vest = (_loadout param [4, []]) param [0, ""];
        private _helmet = _loadout param [6, ""];
        private _glasses = _loadout param [7, ""];
        if (_uniform != "") then {_uniforms pushBackUnique _uniform};
        if (_vest != "") then {_vests pushBackUnique _vest};
        if (_helmet != "") then {_headgear pushBackUnique _helmet};
        if (_glasses != "") then {_facegear pushBackUnique _glasses};
    } forEach (_resistance get "units");
    KP_liberation_guerilla_weapons_1 = +_weapons;
    KP_liberation_guerilla_weapons_2 = +_weapons;
    KP_liberation_guerilla_weapons_3 = +_weapons;
    KP_liberation_guerilla_uniforms_1 = +_uniforms;
    KP_liberation_guerilla_uniforms_2 = +_uniforms;
    KP_liberation_guerilla_uniforms_3 = +_uniforms;
    KP_liberation_guerilla_vests_1 = +_vests;
    KP_liberation_guerilla_vests_2 = +_vests;
    KP_liberation_guerilla_vests_3 = +_vests;
    KP_liberation_guerilla_headgear_1 = +_headgear;
    KP_liberation_guerilla_headgear_2 = +_headgear;
    KP_liberation_guerilla_headgear_3 = +_headgear;
    KP_liberation_guerilla_facegear = +_facegear;
private _civilian = _catalogs get "civilians";
    civilians = +(_civilian get "units");
    civilians_lower = civilians apply {toLower _x};
    civilian_vehicles = +(_civilian get "allVehicles");

private _arsenalByFaction = createHashMap;
    KPLIB_autoFactionPlayerArsenalData = [_blufor, 1] call KPLIB_fnc_collectFactionArsenal;
    KPLIB_autoFactionPlayerArsenal = KPLIB_autoFactionPlayerArsenalData get "all";
    KPLIB_autoFactionPlayerUniforms = [];
    KPLIB_autoFactionPlayerHeadgear = [];
    KPLIB_autoFactionPlayerGoggles = [];
    KPLIB_autoFactionPlayerStartingItems = [];
    {
        private _loadout = getUnitLoadout _x;
        private _uniform = (_loadout param [3, []]) param [0, ""];
        private _headgear = _loadout param [6, ""];
        private _goggles = _loadout param [7, ""];
        if (_uniform != "") then {KPLIB_autoFactionPlayerUniforms pushBackUnique _uniform};
        if (_headgear != "") then {KPLIB_autoFactionPlayerHeadgear pushBackUnique _headgear};
        if (_goggles != "") then {KPLIB_autoFactionPlayerGoggles pushBackUnique _goggles};
        {
            if (_x isEqualType "" && {_x != ""}) then {
                KPLIB_autoFactionPlayerStartingItems pushBackUnique _x;
            };
        } forEach (_loadout param [9, []]);
    } forEach (_blufor get "units");
    {
        _arsenalByFaction set [toLower _x, KPLIB_autoFactionPlayerArsenal];
    } forEach (_blufor get "factions");
    KPLIB_autoFactionOpforArsenalData = [_opfor, 0] call KPLIB_fnc_collectFactionArsenal;
    KPLIB_autoFactionOpforArsenal = KPLIB_autoFactionOpforArsenalData get "all";
    KPLIB_autoFactionOpforStartingItems = [];
    {
        if (_x isEqualType "" && {_x != ""}) then {
            KPLIB_autoFactionOpforStartingItems pushBackUnique _x;
        };
    } forEach (opfor_rto_loadout param [9, []]);
    {
        _arsenalByFaction set [toLower _x, KPLIB_autoFactionOpforArsenal];
    } forEach (_opfor get "factions");
KPLIB_autoFactionArsenalByFaction = _arsenalByFaction;
KPLIB_autoFactionActive = true;

[format ["Automatic faction selections applied: %1", KPLIB_autoFactionSelections], "FACTIONS"] call KPLIB_fnc_log;
KPLIB_autoFactionActive
