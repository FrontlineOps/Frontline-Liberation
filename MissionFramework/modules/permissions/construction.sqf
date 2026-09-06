/* Final construction is an unscheduled server transaction. Previews never reserve
   resources. Only the catalog, physical crates and server permissions authorize it. */
KPLIB_fnc_buildFobPosition = {
    params ["_caller"];
    private _fobs = (missionNamespace getVariable ["GRLIB_all_fobs", []]) + [getMarkerPos "startbase_marker"];
    private _nearest = [];
    private _distance = GRLIB_fob_range * 0.8;
    {
        private _candidate = _caller distance2D _x;
        if (_candidate < _distance) then {_nearest = _x; _distance = _candidate};
    } forEach _fobs;
    _nearest
};

KPLIB_fnc_buildStorage = {
    params ["_position", "_range", ["_type", 0]];
    (nearestObjects [_position, [KP_liberation_small_storage_building, KP_liberation_large_storage_building], _range, false]) select {
        alive _x && {(_x getVariable ["KP_liberation_storage_type", -1]) == _type}
    }
};

KPLIB_fnc_buildStock = {
    params ["_areas"];
    private _totals = [0, 0, 0];
    private _types = [KP_liberation_supply_crate, KP_liberation_ammo_crate, KP_liberation_fuel_crate];
    {
        {
            private _index = _types find typeOf _x;
            if (_index >= 0) then {
                _totals set [_index, (_totals select _index) + (0 max (_x getVariable ["KP_liberation_crate_value", 0]))];
            };
        } forEach attachedObjects _x;
    } forEach _areas;
    _totals
};

// Mutation helpers are local code values, not remotely callable endpoints.
localNamespace setVariable ["KPLIB_buildDebit", {
    params ["_areas", "_prices"];
    private _remaining = +_prices;
    private _types = [KP_liberation_supply_crate, KP_liberation_ammo_crate, KP_liberation_fuel_crate];
    {
        private _area = _x;
        private _crates = attachedObjects _area;
        reverse _crates;
        {
            private _index = _types find typeOf _x;
            if (_index < 0) then {continue};
            private _value = 0 max (_x getVariable ["KP_liberation_crate_value", 0]);
            private _take = _value min (_remaining select _index);
            if (_take <= 0) then {continue};
            _remaining set [_index, (_remaining select _index) - _take];
            if (_take == _value) then {
                detach _x;
                deleteVehicle _x;
            } else {
                _x setVariable ["KP_liberation_crate_value", _value - _take, true];
            };
        } forEach _crates;
        ([_area] call KPLIB_fnc_getStoragePositions) params ["_positions"];
        {
            private _position = +(_positions select _forEachIndex);
            _position set [2, [typeOf _x] call KPLIB_fnc_getCrateHeight];
            _x attachTo [_area, _position];
        } forEach attachedObjects _area;
    } forEach _areas;
    stats_supplies_spent = stats_supplies_spent + (_prices select 0);
    stats_ammo_spent = stats_ammo_spent + (_prices select 1);
    stats_fuel_spent = stats_fuel_spent + (_prices select 2);
    please_recalculate = true;
}];

KPLIB_fnc_validBuildPosition = {
    params ["_caller", "_position", "_direction", "_class"];
    _position isEqualType [] && {count _position == 3}
        && {(_position findIf {!(_x isEqualType 0) || {!finite _x}}) == -1}
        && {_direction isEqualType 0 && {finite _direction}}
        && {_caller distance2D _position <= ((0.6 * sizeOf _class) max 3.5) + 8}
        && {abs (_position select 2) <= 100}
};

KPLIB_fnc_buildSectorStorage = {
    if (!isServer || {canSuspend}) exitWith {};
    params [["_sector", "", [""]], ["_position", [], [[]]], ["_direction", 0, [0]], ["_level", true, [false]]];
    private _caller = ["BUILD"] call KPLIB_fnc_permissionRequest;
    if (isNull _caller || {!(_sector in blufor_sectors)}) exitWith {};
    if !([_caller, _position, _direction, KP_liberation_small_storage_building] call KPLIB_fnc_validBuildPosition) exitWith {};
    private _centre = getMarkerPos _sector;
    if (_caller distance2D _centre > 100 || {_position distance2D _centre > 100} || {surfaceIsWater _position}) exitWith {};
    private _index = KP_liberation_production findIf {(_x select 1) == _sector};
    if (_index < 0) exitWith {};
    if (([_centre, 100, 1] call KPLIB_fnc_buildStorage) isNotEqualTo []) exitWith {};
    private _building = createVehicle [KP_liberation_small_storage_building, _position, [], 0, "CAN_COLLIDE"];
    if (isNull _building) exitWith {};
    _building setDir _direction;
    _building setPos _position;
    _building setVectorUp (if (_level) then {[0, 0, 1]} else {surfaceNormal position _building});
    _building setVariable ["KP_liberation_storage_type", 1, true];
    recalculate_sectors = true;
    [format ["Sector storage built at %1", _sector], "BUILD"] call KPLIB_fnc_log;
};

KPLIB_fnc_commitBuild = {
    if (!isServer || {canSuspend}) exitWith {};
    params [["_type", -1, [0]], ["_index", -1, [0]], ["_position", [], [[]]], ["_direction", 0, [0]], ["_level", true, [false]], ["_manned", false, [false]]];
    private _caller = ["BUILD"] call KPLIB_fnc_permissionRequest;
    if (isNull _caller) exitWith {};
    if !(_type in [1, 2, 3, 4, 5, 6, 7, 8]) exitWith {};
    private _catalog = KPLIB_buildList select _type;
    if (_index < 0 || {_index != floor _index} || {_index >= count _catalog}) exitWith {};
    private _entry = _catalog select _index;
    private _class = _entry select 0;
    private _prices = _entry select [1, 3];
    private _fob = [_caller] call KPLIB_fnc_buildFobPosition;
    if (_fob isEqualTo []) exitWith {};
    if (([getPos _caller, 500, GRLIB_side_enemy] call KPLIB_fnc_getUnitsCount) > 4) exitWith {
        [localize "STR_BUILD_ENEMIES_NEARBY"] remoteExecCall ["hint", owner _caller];
    };
    private _commander = _caller isEqualTo ([] call KPLIB_fnc_getCommander);
    if (_manned && {!_commander}) exitWith {};
    if (_manned && {unitcap >= ([] call KPLIB_fnc_getLocalCap)}) exitWith {};
    private _infantry = _type in [1, 8];
    if (_infantry && {(missionNamespace getVariable ["unitcap", 0]) >= ([] call KPLIB_fnc_getLocalCap)}) exitWith {};
    if (_type == 1 && {count units group _caller >= GRLIB_max_squad_size}) exitWith {};
    private _requirement = _entry param [5, 0];
    private _required = if (_requirement < 1) then {round (count sectors_military * _requirement)} else {_requirement};
    if (count blufor_military_sectors < _required) exitWith {};
    if (!_infantry) then {
        if !([_caller, _position, _direction, _class] call KPLIB_fnc_validBuildPosition) exitWith {_class = ""};
        if (_position distance2D _fob >= GRLIB_fob_range) exitWith {_class = ""};
        if (surfaceIsWater _position && {!(_class in boats_names)}) exitWith {_class = ""};
        if (!KP_liberation_allow_fob_vehcile_building && {_fob isNotEqualTo getMarkerPos "startbase_marker"}) then {
            if (_class isKindOf "LandVehicle" || {_class isKindOf "Helicopter"}
                || {!KP_liberation_allow_fixedwing_at_fobs && {_class isKindOf "Plane"}}) then {_class = ""};
        };
        if (_class == "") exitWith {};
        private _air = toLower _class in KPLIB_b_air_classes && {!([_class] call KPLIB_fnc_isClassUAV)};
        if (_air || {toLower _class in KPLIB_airSlots}) then {
            if ((nearestObjects [_fob, [KP_liberation_air_vehicle_building], GRLIB_fob_range]) findIf {alive _x} == -1) exitWith {_class = ""};
        };
        if (_air) then {
            private _kind = if (_class isKindOf "Helicopter") then {"Helicopter"} else {"Plane"};
            private _slots = if (_kind == "Helicopter") then {KP_liberation_heli_slots} else {KP_liberation_plane_slots};
            private _count = {alive _x && {_x isKindOf _kind} && {toLower typeOf _x in KPLIB_b_air_classes} && {!unitIsUAV _x} && {!(_x getVariable ["KP_liberation_preplaced", false])}} count vehicles;
            if (_count >= _slots) then {_class = ""};
        };
    };
    if (_class isEqualTo "") exitWith {};
    private _areas = [_fob, GRLIB_fob_range * 2] call KPLIB_fnc_buildStorage;
    private _stock = [_areas] call KPLIB_fnc_buildStock;
    if ((_prices select 0) > (_stock select 0) || {(_prices select 1) > (_stock select 1)} || {(_prices select 2) > (_stock select 2)}) exitWith {
        ["Construction cancelled: this FOB no longer has enough resources."] remoteExecCall ["hint", owner _caller];
    };
    private _created = [];
    private _group = grpNull;
    if (_infantry) then {
        _group = createGroup [GRLIB_side_friendly, true];
        private _classes = if (_type == 8) then {_class} else {[_class]};
        {
            private _unit = _group createUnit [_x, getPosATL _caller vectorAdd [1, 1, 0], [], 0, "NONE"];
            if (!isNull _unit) then {
                _unit setSkill 0.5;
                _unit setRank (if (_type == 1) then {"PRIVATE"} else {["SERGEANT", "CORPORAL"] param [_forEachIndex, "PRIVATE"]});
                if (_type == 8 && {_class isEqualTo blufor_squad_para}) then {
                    removeBackpackGlobal _unit;
                    _unit addBackpackGlobal "B_parachute";
                };
                _created pushBack _unit;
            };
        } forEach _classes;
        if (count _created != count _classes) then {
            {deleteVehicle _x} forEach _created;
            _created = [];
            deleteGroup _group;
        };
    } else {
        private _object = createVehicle [_class, _position, [], 0, "CAN_COLLIDE"];
        if (!isNull _object) then {
            _object allowDamage false;
            _object setDir _direction;
            if (toLower _class in KPLIB_b_static_classes) then {_object setPosATL _position} else {_object setPos _position};
            _object setVectorUp (if (_level) then {[0, 0, 1]} else {surfaceNormal position _object});
            _created pushBack _object;
        };
    };
    if (_created isEqualTo []) exitWith {
        ["Construction failed; no resources were spent."] remoteExecCall ["hint", owner _caller];
    };
    [_areas, _prices] call (localNamespace getVariable "KPLIB_buildDebit");
    if (_infantry) then {
        stats_blufor_soldiers_recruited = stats_blufor_soldiers_recruited + count _created;
        unitcap = unitcap + count _created;
        if (_type == 1 && {!_manned}) then {_created joinSilent group _caller} else {
            if (_type == 8) then {_group setGroupId [format ["%1 %2", squads_names select _index, groupId _group]]};
            _group setBehaviour "SAFE";
        };
    } else {
        private _object = _created select 0;
        [_object] call KPLIB_fnc_addObjectInit;
        [_object] call KPLIB_fnc_clearCargo;
        if (unitIsUAV _object || {_manned}) then {[_object] call KPLIB_fnc_forceBluforCrew};
        [{params ["_object"]; if (!isNull _object) then {_object allowDamage true}}, [_object], 0.3] call CBA_fnc_waitAndExecute;
        if !(_class isKindOf "Building") then {stats_blufor_vehicles_built = stats_blufor_vehicles_built + 1};
        _created append crew _object;
    };
    if (_type != 6) then {{_x addMPEventHandler ["MPKilled", {_this spawn kill_manager}]} forEach _created};
    [format ["Construction committed: category %1, entry %2, cost %3", _type, _index, _prices], "BUILD"] call KPLIB_fnc_log;
};
