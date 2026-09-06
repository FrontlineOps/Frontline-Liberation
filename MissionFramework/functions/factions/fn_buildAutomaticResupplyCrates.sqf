/* Builds the only squad-resupply crate map from selected faction data. */

private _catalogs = missionNamespace getVariable ["KPLIB_autoFactionCatalogs", createHashMap];
private _catalog = _catalogs getOrDefault ["blufor", createHashMap];
private _factionModels = +(_catalog getOrDefault ["crates", []]);
_factionModels = _factionModels select {
    isClass (configFile >> "CfgVehicles" >> _x) && {_x isKindOf "ReammoBox_F"}
};
_factionModels = _factionModels arrayIntersect _factionModels;
private _crateClasses = +_factionModels;

/* Include loaded ACE/ACM medical crates even if their config faction is generic. */
if (missionNamespace getVariable ["KP_liberation_autoFaction_includeAceMedical", true]) then {
    private _medicalCrates = [];
    {
        if !(isClass (configFile >> "CfgVehicles" >> _x) && {_x isKindOf "ReammoBox_F"}) then {
            continue;
        };
        private _cargo = [_x] call KPLIB_fnc_getConfigCargo;
        private _medicalCargo = false;
        {
            if (getNumber (configFile >> "CfgWeapons" >> _x >> "ACE_isMedicalItem") > 0) exitWith {
                _medicalCargo = true;
            };
        } forEach keys (_cargo get "Items");
        if (_medicalCargo) then {_medicalCrates pushBackUnique _x};
    } forEach (
        getArray (configFile >> "CfgPatches" >> "ace_medical_treatment" >> "units") +
        getArray (configFile >> "CfgPatches" >> "acm_core" >> "units")
    );
    _crateClasses = (_crateClasses + _medicalCrates) arrayIntersect (_crateClasses + _medicalCrates);
};

private _usableModels = _crateClasses select {
    isClass (configFile >> "CfgVehicles" >> _x) && {_x isKindOf "ReammoBox_F"}
};
_usableModels = _usableModels arrayIntersect _usableModels;
private _limit = missionNamespace getVariable ["KP_liberation_autoFaction_resupplyCrateLimit", 16];
if (_limit > 0 && {count _usableModels > _limit}) then {_usableModels resize _limit};
private _usableFactionModels = _usableModels select {_x in _factionModels};

private _generated = createHashMap;
private _nativeFactionDefinitions = 0;
{
    private _class = _x;
    if !(_class isKindOf "ReammoBox_F") then {continue};
    private _cfg = configFile >> "CfgVehicles" >> _class;
    if !(isClass _cfg) then {continue};

    private _cargo = [_class] call KPLIB_fnc_getConfigCargo;
    private _cargoClassCount = 0;
    {
        _cargoClassCount = _cargoClassCount + count (_cargo get _x);
    } forEach ["Weapons", "Magazines", "Items", "Backpacks"];
    if (_cargoClassCount == 0) then {continue};

    private _displayName = getText (_cfg >> "displayName");
    if (_displayName isEqualTo "") then {_displayName = _class};
    private _entryName = format ["[AUTO] %1", _displayName];
    if (_entryName in _generated) then {_entryName = format ["%1 (%2)", _entryName, _class]};

    _generated set [_entryName, createHashMapFromArray [
        ["Model", _class],
        ["Offset", [0, 1, 1]],
        ["Category", "Faction Supplies"],
        ["SquadLocks", []],
        ["WhitelistedRoles", []],
        ["BlacklistedRoles", []],
        ["Weapons", _cargo get "Weapons"],
        ["Magazines", _cargo get "Magazines"],
        ["Items", _cargo get "Items"],
        ["Backpacks", _cargo get "Backpacks"]
    ]];
    if (_class in _usableFactionModels) then {
        _nativeFactionDefinitions = _nativeFactionDefinitions + 1;
    };
} forEach _usableModels;

private _syntheticFactionDefinitions = 0;
if (_nativeFactionDefinitions == 0) then {
    private _arsenalData = missionNamespace getVariable ["KPLIB_autoFactionPlayerArsenalData", createHashMap];
    private _weapons = +(_arsenalData getOrDefault ["weapons", []]);
    private _magazines = +(_arsenalData getOrDefault ["magazines", []]);
    private _items = +(_arsenalData getOrDefault ["items", []]);
    private _backpacks = +(_arsenalData getOrDefault ["backpacks", []]);
    private _syntheticModels = +_usableFactionModels;
    if (_syntheticModels isEqualTo []) then {
        private _fallbackModel = "Box_NATO_Ammo_F";
        if !(isClass (configFile >> "CfgVehicles" >> _fallbackModel) && {_fallbackModel isKindOf "ReammoBox_F"}) then {
            private _message = format [
                "No selected-faction ReammoBox_F model was found and fallback model %1 is unavailable",
                _fallbackModel
            ];
            [_message, "FACTIONS"] call KPLIB_fnc_log;
            throw _message;
        };
        _syntheticModels = [_fallbackModel];
        [format [
            "Selected BLUFOR faction exposes no public ReammoBox_F; using %1 for synthesized faction resupply containers",
            _fallbackModel
        ], "FACTIONS"] call KPLIB_fnc_log;
    };

    private _toCargoMap = {
        params ["_classes", "_quantity", "_classLimit"];
        private _selected = +_classes;
        if (_classLimit > 0 && {count _selected > _classLimit}) then {
            _selected resize _classLimit;
        };
        private _cargo = createHashMap;
        {
            _cargo set [_x, _quantity];
        } forEach _selected;
        _cargo
    };

    private _setSyntheticEntry = {
        params ["_name", "_modelIndex", "_weaponCargo", "_magazineCargo", "_itemCargo", "_backpackCargo"];
        if (
            count _weaponCargo == 0 &&
            {count _magazineCargo == 0} &&
            {count _itemCargo == 0} &&
            {count _backpackCargo == 0}
        ) exitWith {};

        _generated set [_name, createHashMapFromArray [
            ["Model", _syntheticModels param [_modelIndex, _syntheticModels select 0]],
            ["Offset", [0, 1, 1]],
            ["Category", "Faction Supplies"],
            ["SquadLocks", []],
            ["WhitelistedRoles", []],
            ["BlacklistedRoles", []],
            ["Weapons", _weaponCargo],
            ["Magazines", _magazineCargo],
            ["Items", _itemCargo],
            ["Backpacks", _backpackCargo]
        ]];
    };

    private _beforeSynthesis = count _generated;
    [
        "[AUTO] Faction Ammunition",
        0,
        createHashMap,
        [_magazines, 12, 128] call _toCargoMap,
        createHashMap,
        createHashMap
    ] call _setSyntheticEntry;
    [
        "[AUTO] Faction Weapons",
        1,
        [_weapons, 2, 48] call _toCargoMap,
        [_magazines, 4, 128] call _toCargoMap,
        createHashMap,
        createHashMap
    ] call _setSyntheticEntry;
    [
        "[AUTO] Faction Equipment",
        2,
        createHashMap,
        createHashMap,
        [_items, 4, 128] call _toCargoMap,
        [_backpacks, 2, 24] call _toCargoMap
    ] call _setSyntheticEntry;
    _syntheticFactionDefinitions = (count _generated) - _beforeSynthesis;

    [format [
        "Selected faction produced no native resupply definitions; synthesized %1 definitions from generated BLUFOR arsenal data",
        _syntheticFactionDefinitions
    ], "FACTIONS"] call KPLIB_fnc_log;
};

if (
    count _generated == 0 ||
    {_nativeFactionDefinitions == 0 && {_syntheticFactionDefinitions == 0}}
) exitWith {
    private _message = "Selected crate configs and generated BLUFOR arsenal contain no usable resupply cargo";
    [_message, "FACTIONS"] call KPLIB_fnc_log;
    throw _message;
};
ResupplyCrates = _generated;
[format ["Generated %1 faction resupply crate definitions", count ResupplyCrates], "FACTIONS"] call KPLIB_fnc_log;
true
