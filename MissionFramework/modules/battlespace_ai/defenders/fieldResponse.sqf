// Field casualty pressure consumes shared contact memory; it owns no sighting cache.
// Incidents are transient; dispatched reserves save their destination and expiry timers.
BATTLESPACE_RESERVE_FIELD_INCIDENTS = createHashMap;
BATTLESPACE_RESERVE_FIELD_SEQUENCE = 0;

BATTLESPACE_RESERVE_FIELD_GET_CONTACT = {
    params ["_position"];
    private _contacts = [_position, BATTLESPACE_STRATEGIC_RESERVE_FIELD_CONTACT_RADIUS, BATTLESPACE_STRATEGIC_RESERVE_FIELD_CONTACT_MAX_AGE, true] call BATTLESPACE_CONTACT_QUERY;
    _contacts = [_contacts, [], {_x select 1}, "DESCEND"] call BIS_fnc_sortBy;
    if (_contacts isEqualTo []) then {[]} else {(_contacts select 0) select [0, 2]}
};

BATTLESPACE_RESERVE_RECORD_FIELD_LOSS = {
    params ["_taskForceId", "_lossType", "_unit"];
    if (!isServer || {isNull _unit}) exitWith {};
    private _taskForce = BATTLESPACE_TASK_FORCES getOrDefault [_taskForceId, []];
    if ((_taskForce param [6, sideUnknown]) != GRLIB_side_enemy || {_unit isKindOf "Air"} || {(vehicle _unit) isKindOf "Air"}) exitWith {};
    private _position = getPosATL _unit;
    private _weight = if (_lossType == "MANPOWER") then {1} else {4};
    // A casualty belongs to its physical location, not the patrol's assigned objective.
    private _sector = [_position] call BATTLESPACE_STRATEGIC_FIND_NEAREST_OPFOR_SECTOR;
    if (_sector != "" && {_position distance2D getMarkerPos _sector <= GRLIB_capture_size}) exitWith {
        [_sector, _weight] call BATTLESPACE_STRATEGIC_ADD_SECTOR_PRESSURE;
    };
    private _incidentId = "";
    private _nearest = BATTLESPACE_STRATEGIC_RESERVE_FIELD_RADIUS;
    {
        private _distance = _position distance2D (_y get "position");
        if (_distance <= _nearest) then {_incidentId = _x; _nearest = _distance};
    } forEach BATTLESPACE_RESERVE_FIELD_INCIDENTS;
    if (_incidentId == "") then {
        if (count BATTLESPACE_RESERVE_FIELD_INCIDENTS >= 32) exitWith {};
        BATTLESPACE_RESERVE_FIELD_SEQUENCE = BATTLESPACE_RESERVE_FIELD_SEQUENCE + 1;
        _incidentId = format ["FIELD:%1:%2", CBA_missionTime, BATTLESPACE_RESERVE_FIELD_SEQUENCE];
        BATTLESPACE_RESERVE_FIELD_INCIDENTS set [_incidentId, createHashMapFromArray [
            ["position", _position], ["pressure", 0]
        ]];
    };
    if (_incidentId == "") exitWith {};
    private _incident = BATTLESPACE_RESERVE_FIELD_INCIDENTS get _incidentId;
    if (CBA_missionTime - (_incident getOrDefault ["lastLossAt", -1e9]) > BATTLESPACE_STRATEGIC_RESERVE_FIELD_LOSS_WINDOW) then {_incident set ["pressure", 0]};
    _incident set ["pressure", (_incident get "pressure") + _weight];
    _incident set ["lastLossAt", CBA_missionTime];
    {[_x] call BATTLESPACE_CONTACT_SAMPLE_GROUP} forEach ((_taskForce param [4, []]) select [0, 4]);
};

BATTLESPACE_RESERVE_FIELD_TICK = {
    if (!isServer) exitWith {};
    private _responding = createHashMap;
    {
        if ((_y getOrDefault ["kind", ""]) != "RESERVE" || {(_y getOrDefault ["phase", ""]) != "FIELD_HUNT"}) then {continue};
        _responding set [_y get "fieldIncident", true];
        private _taskForce = BATTLESPACE_TASK_FORCES getOrDefault [_x, []];
        {[_x] call BATTLESPACE_CONTACT_SAMPLE_GROUP} forEach ((_taskForce param [4, []]) select [0, 4]);
        private _contact = [_y get "fieldPosition"] call BATTLESPACE_RESERVE_FIELD_GET_CONTACT;
        if (_contact isNotEqualTo []) then {
            _y set ["fieldContact", +(_contact select 0)];
            _y set ["contactGraceUntil", (_contact select 1) + BATTLESPACE_STRATEGIC_RESERVE_FIELD_CONTACT_MAX_AGE];
        };
    } forEach BATTLESPACE_STRATEGIC_OPERATIONS;
    {
        private _id = _x;
        private _incident = _y;
        private _expired = CBA_missionTime - (_incident getOrDefault ["lastLossAt", -1e9]) > BATTLESPACE_STRATEGIC_RESERVE_FIELD_LOSS_WINDOW;
        if (_expired) then {_incident set ["pressure", 0]};
        if (_expired && {!(_responding getOrDefault [_id, false])} && {CBA_missionTime >= (_incident getOrDefault ["nextResponseAt", 0])}) then {
            BATTLESPACE_RESERVE_FIELD_INCIDENTS deleteAt _id;
            continue;
        };
        if (_responding getOrDefault [_id, false]) then {continue};
        if ((_incident get "pressure") < BATTLESPACE_STRATEGIC_CASUALTY_RESPONSE_THRESHOLD || {CBA_missionTime < (_incident getOrDefault ["nextResponseAt", 0])}) then {continue};
        private _contact = [_incident get "position"] call BATTLESPACE_RESERVE_FIELD_GET_CONTACT;
        if (_contact isEqualTo []) then {continue};
        private _anchor = [_incident get "position"] call BATTLESPACE_STRATEGIC_FIND_NEAREST_OPFOR_SECTOR;
        if (_anchor != "" && {[_anchor, _id, _incident, _contact] call BATTLESPACE_RESERVE_DISPATCH}) then {
            _incident set ["pressure", 0];
            _incident set ["nextResponseAt", CBA_missionTime + BATTLESPACE_STRATEGIC_RESERVE_RESPONSE_COOLDOWN];
        };
    } forEach BATTLESPACE_RESERVE_FIELD_INCIDENTS;
};

// Route and search orders execute on the group's owner and have no background hunt loop.
BATTLESPACE_RESERVE_SET_GROUP_MODE = {
    params ["_group", "_hunt", ["_returning", false]];
    if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {};
    if (!isRemoteExecuted && {!isServer}) exitWith {};
    if (isNull _group || {!local _group}) exitWith {};
    _group setVariable ["BATTLESPACE_RESERVE_FIELD_HUNT", _hunt];
    _group setVariable ["BATTLESPACE_DEFENDER_RETURNING", _returning];
    { _group setVariable [_x, (_group getVariable [_x, 0]) + 1] } forEach ["BATTLESPACE_ROUTE_WAYPOINT_TOKEN", "BATTLESPACE_TRANSPORT_ROUTE_TOKEN"];
    [_group, true, true] call KPLIB_fnc_taskReset;
};

BATTLESPACE_RESERVE_APPLY_ROUTE = {
    params ["_group", "_destination", "_route", "_hunt", "_returning"];
    if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {};
    if (!isRemoteExecuted && {!isServer}) exitWith {};
    if (isNull _group || {!local _group}) exitWith {};
    [_group, _hunt, _returning] call BATTLESPACE_RESERVE_SET_GROUP_MODE;
    if (!isNull (_group getVariable ["BATTLESPACE_TRANSPORT_PARENT_GROUP", grpNull])) exitWith {};
    private _vehicle = _group getVariable ["BATTLESPACE_TRANSPORT_VEHICLE", objNull];
    private _cargo = _group getVariable ["BATTLESPACE_TRANSPORT_CARGO_GROUP", grpNull];
    if (!isNull _vehicle && {!isNull _cargo}) then {
        [_vehicle, _group, _cargo, _destination, false, _route] spawn BATTLESPACE_TASK_FORCE_TRANSPORT_AI;
    } else {
        [_group, _destination, "FULL", false, [_group] call BATTLESPACE_TASK_FORCE_HAS_VEHICLES, _route] spawn BATTLESPACE_TASK_FORCE_ADD_WAYPOINTS;
    };
};
