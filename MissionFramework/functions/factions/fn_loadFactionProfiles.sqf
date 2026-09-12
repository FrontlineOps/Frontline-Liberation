/* Prepare explicit faction data once per machine. Server-local copies own permission decisions. */
if (isRemoteExecuted) exitWith {createHashMap};
params ["_definitions"];
private _fail = {
    params ["_message"];
    [_message, "FACTIONS"] call KPLIB_fnc_log;
    throw ("Manual faction configuration: " + _message);
};
if !(_definitions isEqualType createHashMap) then {["root must return a HashMap"] call _fail};
private _profiles = createHashMap;
private _catalogs = createHashMap;
private _errors = [];
private _optionalMissing = [];
private _vehiclePools = ["light", "recon", "medical", "groundLogistics", "artillery", "atgm", "aa", "samTel", "samRadar", "samShorad", "aaGun", "heavy", "rotaryLogistics", "rotaryCas", "fixedWing", "static", "transport", "boat"];
private _item = {
    params ["_class"];
    if !(_class isEqualType "" && {_class != ""}) exitWith {
        _errors pushBack "Equipment entries must be nonempty classnames";
        ["", ""]
    };
    private _key = [_class] call KPLIB_fnc_normalizeGearClass;
    private _result = ["", ""];
    {
        _x params ["_root", "_bucket"];
        private _cfg = configFile >> _root >> _key;
        if (isClass _cfg) exitWith {
            if (_root == "CfgWeapons" && {getNumber (_cfg >> "type") in [1, 2, 4, 4096]}) then {_bucket = "weapons"};
            if (_root == "CfgVehicles" && {!(_key isKindOf "Bag_Base")}) exitWith {};
            _result = [_bucket, configName _cfg];
        };
    } forEach [["CfgMagazines", "magazines"], ["CfgWeapons", "items"], ["CfgGlasses", "items"], ["CfgVehicles", "backpacks"]];
    if ((_result select 0) == "") then {
        private _optional = KPLIB_factionOptionalEquipment findIf {
            _x params ["_prefix", "_patch"];
            (_key find _prefix) == 0 && {!isClass (configFile >> "CfgPatches" >> _patch)}
        };
        if (_optional >= 0) then {
            _optionalMissing pushBackUnique _class;
        } else {
            _errors pushBack format ["Unknown equipment class %1", _class];
        };
    };
    _result
};
{
    _x params ["_sideKey", "_sideNumber"];
    private _path = "kp_liberation_manual_factions.sqf/" + _sideKey;
    private _profile = _definitions getOrDefault [_sideKey, createHashMap];
    if !(_profile isEqualType createHashMap) then {
        _errors pushBack format ["%1 must return a profile HashMap", _path];
        continue;
    };
    private _sections = switch (_sideKey) do {
        case "blufor": {["catalog", "vehicleRoles", "prices", "equipment", "roles", "slots", "crates", "defaultRole", "specialtyResources"]};
        case "opfor": {["catalog", "unitRoles"]};
        default {["catalog"]};
    };
    {
        if !(_x in _sections) then {
            [format ["%1/%2 is not used by this side. Follow the sections in the manual template.", _path, _x]] call _fail;
        };
    } forEach _profile;
    {
        private _value = _profile getOrDefault [_x, createHashMap];
        if !(_value isEqualType createHashMap) then {[format ["%1/%2 must be a HashMap", _path, _x]] call _fail};
        _profile set [_x, _value];
    } forEach ["catalog", "unitRoles", "vehicleRoles", "prices", "equipment", "roles", "slots", "crates"];
    private _catalog = _profile getOrDefault ["catalog", createHashMap];
    if !(_catalog isEqualType createHashMap) then {_errors pushBack format ["Invalid catalog in %1", _path]; continue};
    if (_sideKey == "blufor" && {"units" in _catalog}) then {
        ["blufor/catalog/units is not used. Configure player equipment under roles."] call _fail;
    };
    private _catalogKeys = ["factions", "units"] + _vehiclePools;
    {
        if !(_x in _catalogKeys) then {
            [format ["Unknown roster list %1/catalog/%2", _path, _x]] call _fail;
        };
    } forEach _catalog;
    _catalog set ["side", _sideNumber];
    private _factions = _catalog getOrDefault ["factions", []];
    if !(_factions isEqualType [] && {(_factions findIf {!(_x isEqualType "" && {isClass (configFile >> "CfgFactionClasses" >> _x)})}) == -1}) then {
        [format ["%1/catalog/factions must list valid CfgFactionClasses", _path]] call _fail;
    };
    _catalog set ["factions", _factions];
    private _allVehicles = [];
    {
        private _poolName = _x;
        private _pool = _catalog getOrDefault [_x, []];
        if !(_pool isEqualType []) then {_errors pushBack format ["%1/%2 must be an array", _path, _x]; continue};
        private _normalized = [];
        {
            if !(_x isEqualType "" && {isClass (configFile >> "CfgVehicles" >> _x)}) then {
                _errors pushBack format ["Missing CfgVehicles class %1 in %2", _x, _path];
                continue;
            };
            private _isUnit = _x isKindOf "CAManBase";
            if ((_poolName == "units") != _isUnit) then {
                _errors pushBack format ["%1/%2 has the wrong object type: %3", _path, _poolName, _x];
            };
            _normalized pushBackUnique configName (configFile >> "CfgVehicles" >> _x);
        } forEach _pool;
        _catalog set [_x, _normalized];
        if (_x in _vehiclePools) then {_allVehicles append _normalized};
    } forEach (["units"] + _vehiclePools);
    if (_sideKey != "blufor" && {(_catalog get "units") isEqualTo []}) then {
        _errors pushBack format ["%1 has no infantry/civilians", _path];
    };
    _catalog set ["allVehicles", _allVehicles arrayIntersect _allVehicles];
    private _unitJobs = ["officer", "squadleader", "rifleman", "at", "grenadier", "machinegunner", "heavygunner", "marksman", "aa", "medic", "rto"];
    {
        if !(_x in _unitJobs) then {[format ["Unknown AI job %1/unitRoles/%2", _path, _x]] call _fail};
        if !(_y isEqualType "") then {[format ["%1/unitRoles/%2 must be a classname", _path, _x]] call _fail};
        private _canonical = configName (configFile >> "CfgVehicles" >> _y);
        (_profile get "unitRoles") set [_x, _canonical];
        if !(_canonical in (_catalog get "units")) then {_errors pushBack format ["%1 unit role %2 uses unlisted infantry %3", _path, _x, _y]};
    } forEach (_profile getOrDefault ["unitRoles", createHashMap]);
    private _requiredUnits = [[], _unitJobs] select (_sideKey == "opfor");
    {
        if !(_x in (_profile get "unitRoles")) then {_errors pushBack format ["%1/unitRoles requires %2", _path, _x]};
    } forEach _requiredUnits;
    {
        if !(_y isEqualType "") then {[format ["%1/vehicleRoles/%2 must be a classname", _path, _x]] call _fail};
        private _canonical = configName (configFile >> "CfgVehicles" >> _y);
        (_profile get "vehicleRoles") set [_x, _canonical];
        if !(_y == "" || {_canonical in (_catalog get "allVehicles")}) then {_errors pushBack format ["%1/vehicleRoles/%2 must be an explicitly listed vehicle or empty string", _path, _x]};
    } forEach (_profile get "vehicleRoles");
    private _requiredVehicles = switch (_sideKey) do {
        case "blufor": {["Respawn_truck_typename"]};
        default {[]};
    };
    {
        if (((_profile get "vehicleRoles") getOrDefault [_x, ""]) == "") then {_errors pushBack format ["%1/vehicleRoles requires %2", _path, _x]};
    } forEach _requiredVehicles;
    private _prices = createHashMap;
    {
        if !(_x isEqualType "" && {isClass (configFile >> "CfgVehicles" >> _x)}) then {[format ["%1/prices has an invalid classname", _path]] call _fail};
        _prices set [configName (configFile >> "CfgVehicles" >> _x), _y];
    } forEach (_profile get "prices");
    _profile set ["prices", _prices];
    if (_sideKey == "blufor") then {
        {
            private _cost = (_profile get "prices") getOrDefault [_x, []];
            if !(_cost isEqualType [] && {count _cost == 3} && {(_cost findIf {!(_x isEqualType 0 && {finite _x} && {_x >= 0})}) == -1}) then {
                _errors pushBack format ["%1/prices needs [supplies, ammo, fuel] for %2", _path, _x];
            };
        } forEach (_catalog get "allVehicles");
    };
    private _specialty = _profile getOrDefault ["specialtyResources", 0];
    if !(_specialty isEqualType 0 && {finite _specialty} && {_specialty >= 0} && {_specialty == floor _specialty}) then {
        _errors pushBack format ["%1/specialtyResources must be a nonnegative integer", _path];
    };
    private _equipment = _profile getOrDefault ["equipment", createHashMap];
    private _arsenal = createHashMapFromArray [["weapons", []], ["magazines", []], ["items", []], ["backpacks", []], ["all", []]];
    {
        if !(_y isEqualType []) then {[format ["%1/equipment/%2 must be an array of classnames", _path, _x]] call _fail};
        private _group = _x;
        private _classes = [];
        {
            ([_x] call _item) params ["_bucket", "_class"];
            if (_bucket != "") then {
                _classes pushBackUnique _class;
                (_arsenal get _bucket) pushBackUnique _class;
                (_arsenal get "all") pushBackUnique _class;
            };
        } forEach _y;
        _equipment set [_group, _classes];
    } forEach _equipment;
    _profile set ["arsenal", _arsenal];
    private _roles = _profile getOrDefault ["roles", createHashMap];
    if ((count _roles > 0 || {_sideKey == "blufor"}) && {!((_profile getOrDefault ["defaultRole", ""]) in _roles)}) then {_errors pushBack format ["%1 needs a valid defaultRole", _path]};
    {
        if !(_x isEqualType "" && {_x != ""} && {(_x find ":") == -1} && {_y isEqualType createHashMap}) then {[format ["Invalid role ID/definition in %1", _path]] call _fail};
        private _roleID = _x;
        private _role = _y;
        private _allowed = [];
        if !((_role getOrDefault ["equipment", []]) isEqualType []) then {[format ["%1/%2 equipment must be an array of group names", _path, _roleID]] call _fail};
        {
            if !(_x in _equipment) then {_errors pushBack format ["%1 role %2 references missing equipment group %3", _path, _roleID, _x]};
            _allowed append (_equipment getOrDefault [_x, []]);
        } forEach (_role getOrDefault ["equipment", []]);
        private _gear = _role getOrDefault ["gear", []];
        if !(_gear isEqualType []) then {
            [format ["%1/roles/%2/gear must be a list of item classnames", _path, _roleID]] call _fail;
        };
        private _directGear = [];
        {
            ([_x] call _item) params ["_bucket", "_class"];
            if (_bucket != "") then {
                _directGear pushBackUnique _class;
                _allowed pushBackUnique _class;
                (_arsenal get _bucket) pushBackUnique _class;
                (_arsenal get "all") pushBackUnique _class;
            };
        } forEach _gear;
        _role set ["gear", _directGear];
        _allowed = _allowed arrayIntersect _allowed;
        _role set ["allowed", _allowed];
        private _starter = _role getOrDefault ["starter", [[], [], [], [], [], [], "", "", [], ["", "", "", "", "", ""]]];
        if !(_starter isEqualType [] && {count _starter == 10}) then {
            _errors pushBack format ["%1/%2 needs a ten-element starter loadout", _path, _roleID];
        } else {
            private _shapeOK = ({(_starter select _x) isEqualType []} count [0, 1, 2, 3, 4, 5, 8, 9]) == 8;
            if (!_shapeOK || {!((_starter select 6) isEqualType "")} || {!((_starter select 7) isEqualType "")}) then {[format ["Malformed starter loadout in %1/%2", _path, _roleID]] call _fail};
            // Unloaded optional integrations are removed, never replaced with unapproved items.
            _role set ["starter", ([_starter, _allowed, _starter] call KPLIB_fnc_filterRoleLoadout) select 0];
        };
        {if !((_role getOrDefault [_x, 0]) in [0, 1, 2]) then {_errors pushBack format ["Invalid %1 trait in %2/%3", _x, _path, _roleID]}} forEach ["medic", "engineer"];
    } forEach _roles;
    {if !(_x isEqualType "" && {_x != ""} && {_y in _roles}) then {_errors pushBack format ["%1 slot %2 references unknown role %3", _path, _x, _y]}} forEach (_profile getOrDefault ["slots", createHashMap]);
    private _crates = _profile getOrDefault ["crates", createHashMap];
    {
        if !(_x isEqualType "" && {_x != ""} && {_y isEqualType createHashMap}) then {[format ["Invalid crate name/definition in %1", _path]] call _fail};
        private _name = _x;
        private _crate = _y;
        private _model = _crate getOrDefault ["Model", ""];
        if !(_model isEqualType "") then {[format ["%1/%2 Model must be a classname", _path, _name]] call _fail};
        if !(isClass (configFile >> "CfgVehicles" >> _model) && {_model isKindOf "ReammoBox_F"}) then {_errors pushBack format ["Invalid crate model %1/%2", _path, _name]};
        if !((_crate getOrDefault ["roles", []]) isEqualType []) then {[format ["%1/%2 roles must be an array", _path, _name]] call _fail};
        {if !(_x in _roles) then {_errors pushBack format ["Unknown requesting role %1/%2/%3", _path, _name, _x]}} forEach (_crate getOrDefault ["roles", []]);
        {
            private _bucket = _x;
            private _cargo = _crate getOrDefault [_bucket, createHashMap];
            if !(_cargo isEqualType createHashMap) then {[format ["%1/%2/%3 must be a HashMap", _path, _name, _bucket]] call _fail};
            private _normalized = createHashMap;
            {
                ([_x] call _item) params ["_kind", "_class"];
                if !(_y isEqualType 0 && {finite _y} && {_y >= 0} && {_y == floor _y}) then {_errors pushBack format ["Invalid quantity %1/%2/%3", _path, _name, _x]; continue};
                if (_kind != "") then {
                    if (_kind != toLower _bucket) then {_errors pushBack format ["%1/%2: %3 belongs in %4", _path, _name, _x, _kind]};
                    _normalized set [_class, _y];
                };
            } forEach _cargo;
            _crate set [_bucket, _normalized];
        } forEach ["Weapons", "Magazines", "Items", "Backpacks"];
        {
            private _value = _crate getOrDefault [_x, 0];
            if !(_value isEqualType 0 && {finite _value} && {_value >= 0}) then {_errors pushBack format ["Invalid %1 on crate %2/%3", _x, _path, _name]};
        } forEach ["CustomCooldown", "SpecialtyCost", "Limit"];
        private _offset = _crate getOrDefault ["Offset", [0, 1, 1]];
        if !(_offset isEqualType [] && {count _offset == 3} && {(_offset findIf {!(_x isEqualType 0 && {finite _x})}) == -1}) then {_errors pushBack format ["Invalid crate Offset in %1/%2", _path, _name]};
        _crate set ["Offset", _offset];
        _crate set ["Category", _crate getOrDefault ["Category", "Faction Supplies"]];
        _crate set ["faction", _sideKey];
    } forEach _crates;
    _profiles set [_sideKey, _profile];
    _catalogs set [_sideKey, _catalog];
} forEach [["blufor", 1], ["opfor", 0], ["resistance", 2], ["civilians", 3]];
if (_errors isNotEqualTo []) then {
    {[_x, "FACTIONS"] call KPLIB_fnc_log} forEach _errors;
    throw "Manual faction configuration is invalid. See the FACTIONS errors in the server RPT.";
};
localNamespace setVariable ["KPLIB_factionProfiles", _profiles];
if (_optionalMissing isNotEqualTo []) then {
    [format ["Skipped %1 explicitly listed equipment classes from unloaded optional integrations", count _optionalMissing], "FACTIONS"] call KPLIB_fnc_log;
};
[format ["Loaded %1 manual faction profiles", count _profiles], "FACTIONS"] call KPLIB_fnc_log;
_catalogs
