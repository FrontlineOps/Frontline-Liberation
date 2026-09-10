/*
 * Mission garrison allocator. Server-only, unscheduled: reserve before dispatch.
 * Reservations are transient and pruned on every allocation. At most one row
 * per living assigned unit survives; no timer, save data or client ledger.
 * Slot: [building/weapon, position index, AGL position, floor band, mode].
 */
if (!isServer || {isRemoteExecuted}) exitWith {[]};
if (canSuspend) exitWith {[KPLIB_fnc_garrisonSelect, _this] call CBA_fnc_directCall};
params ["_units", "_center", "_radius", "_area", "_height", "_token", ["_excluded", []], ["_groundOnly", false]];

private _reservations = (localNamespace getVariable ["KPLIB_garrisonReservations", []]) select {
    _x params ["_unit", "_oldToken", "_group", "_slot"];
    !isNull _unit && {_unit call KPLIB_fnc_isAlive} && {!captive _unit} && {!isPlayer _unit}
    && {group _unit == _group}
    && {(_unit getVariable ["KPLIB_garrisonToken", []]) isEqualTo _oldToken}
    && {!(_unit in _units)}
    && {(_slot select 4) == "GROUND" || {!isNull (_slot select 0) && {alive (_slot select 0)}}}
};
private _inside = {
    params ["_position"];
    _position distance2D _center <= _radius && {!surfaceIsWater _position}
    && {_area isEqualTo [] || {_position inArea ([_center] + _area)}}
};
private _slots = [];
private _buildings = if (_groundOnly) then {[]} else {[_center, _radius] call KPLIB_fnc_findBuildings};
{
    private _building = _x;
    if (!alive _building) then {continue};
    private _positions = _building buildingPos -1;
    // AGL heights alone compare the terrain beneath each point, not floors.
    private _ordered = [];
    {_ordered pushBack [(AGLToASL _x) select 2, _forEachIndex]} forEach _positions;
    _ordered sort true;
    private _floor = -1;
    private _floorBase = -1e10;
    {
        _x params ["_altitude", "_index"];
        if (_altitude - _floorBase > 1.8) then {
            _floor = _floor + 1;
            _floorBase = _altitude;
        };
        private _position = _positions select _index;
        if ([_position] call _inside) then {
            private _asl = AGLToASL _position;
            _slots pushBack [_building, _index, _position, _floor, "BUILDING", lineIntersects [_asl, _asl vectorAdd [0, 0, 6]]];
        };
    } forEach _ordered;
} forEach _buildings;
{
    if (alive _x && {simulationEnabled _x} && {!isObjectHidden _x}
        && {locked _x != 2} && {_x emptyPositions "Gunner" > 0}
        && {[getPos _x] call _inside}) then {
        _slots pushBack [_x, -1, getPos _x, 0, "WEAPON", false];
    };
} forEach (if (_groundOnly) then {[]} else {nearestObjects [_center, ["LandVehicle"], _radius, true]});

private _buildingLoads = createHashMap;
private _floorLoads = createHashMap;
private _occupied = [];
private _countSlot = {
    params ["_slot"];
    _slot params ["_building", "_index", "_position", "_floor"];
    private _buildingKey = str _building;
    private _floorKey = str [_building, _floor];
    _buildingLoads set [_buildingKey, 1 + (_buildingLoads getOrDefault [_buildingKey, 0])];
    _floorLoads set [_floorKey, 1 + (_floorLoads getOrDefault [_floorKey, 0])];
    _occupied pushBack (AGLToASL _position);
};
{
    private _slot = _x select 3;
    if ((_slot select 2) distance2D _center <= _radius + 3) then {[_slot] call _countSlot};
} forEach _reservations;
_slots = _slots select {
    private _slot = _x;
    private _asl = AGLToASL (_slot select 2);
    !((_slot select [0, 2]) in _excluded) && {_occupied findIf {_x vectorDistance _asl < 1.5} < 0}
};
// Aim for several soldiers per nearby building, so a wide search does not
// scatter one squad across an entire town. Grow the pool for later squads or
// limited-capacity houses; existing reservations still balance every floor.
private _nearbyOccupants = {
    private _slot = _x select 3;
    (_slot select 4) == "BUILDING" && {(_slot select 2) distance2D _center <= _radius}
} count _reservations;
private _buildingLimit = (3 max ceil ((count _units + _nearbyOccupants) / 3)) min count _buildings;
private _selectedBuildings = _buildings select [0, _buildingLimit];
while {_buildingLimit < count _buildings && {
    {(_x select 0) in _selectedBuildings} count _slots < count _units
}} do {
    _selectedBuildings pushBack (_buildings select _buildingLimit);
    _buildingLimit = _buildingLimit + 1;
};
_slots = _slots select {(_x select 4) == "WEAPON" || {(_x select 0) in _selectedBuildings}};
private _result = [];
{
    private _unit = _x;
    private _ranked = [];
    {
        _x params ["_building", "_index", "_position", "_floor", "_mode", "_covered"];
        _ranked pushBack [
            [1, 0] select (_mode == "WEAPON"),
            _buildingLoads getOrDefault [str _building, 0],
            _floorLoads getOrDefault [str [_building, _floor], 0],
            [0, -_floor] select _height,
            [1, 0] select _covered,
            random 1,
            _forEachIndex
        ];
    } forEach _slots;
    private _slot = [];
    if (_ranked isNotEqualTo []) then {
        _ranked sort true;
        _slot = _slots deleteAt ((_ranked select 0) select 6);
        private _chosen = AGLToASL (_slot select 2);
        _slots = _slots select {(AGLToASL (_x select 2)) vectorDistance _chosen >= 1.5};
    } else {
        // Overflow still defends the objective. Never invent a building slot
        // or teleport a walking soldier through a wall when pathfinding fails.
        for "_attempt" from 0 to 11 do {
            private _candidate = _center getPos [(_radius min 60) * (0.25 + random 0.7), random 360];
            _candidate = _candidate findEmptyPosition [0, 5, typeOf _unit];
            if (_candidate isEqualTo [] || {!([_candidate] call _inside)}) then {continue};
            private _asl = AGLToASL _candidate;
            if (_occupied findIf {_x vectorDistance _asl < 3} >= 0) then {continue};
            _slot = [objNull, -1, _candidate, 0, "GROUND"];
            break;
        };
    };
    if (_slot isNotEqualTo []) then {
        [_slot] call _countSlot;
        _reservations pushBack [_unit, _token, group _unit, _slot];
    };
    _result pushBack [_unit, _slot];
} forEach _units;
localNamespace setVariable ["KPLIB_garrisonReservations", _reservations];
_result
