// One funded UAV orbits an unconfirmed report; its crew's sightings enter contact memory.
// Unarmed by order (hold fire): it finds, the commander answers.
BATTLESPACE_UAV_RECON_BEGIN_RETURN = {
    params ["_taskForceName", "_taskForce", "_operation"];
    private _origin = _operation getOrDefault ["originSector", ""];
    if (((BATTLESPACE_SECTOR_STATES getOrDefault [_origin, createHashMap]) getOrDefault ["owner", ""]) != "OPFOR") then {
        _origin = [_taskForce param [1, [0, 0, 0]]] call BATTLESPACE_STRATEGIC_FIND_NEAREST_OPFOR_SECTOR;
        _operation set ["originSector", _origin];
    };
    if (_origin == "") exitWith {
        _operation set ["outcome", "LOST"];
        BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceName, _operation];
        false
    };
    [_taskForceName, _taskForce, _operation, "RETURNING", getMarkerPos _origin] call BATTLESPACE_AIR_RESPONSE_SET_DESTINATION
};

[
    "UAV Recon",
    createHashMapFromArray [
        [
            "canProc",
            {
                params ["_taskForceName", "_taskForce"];
                private _currentLocation = _taskForce param [1, []];
                private _requiredPlayers = [] call BATTLESPACE_TASK_FORCE_GET_NEEDED_PLAYERCOUNT_FOR_PROC;
                private _procRange = ["Air Response"] call BATTLESPACE_TASK_FORCE_GET_PROC_RANGE;
                BATTLESPACE_TASK_FORCES_BLUFOR_CLUSTERS findIf {
                    (count (_x getOrDefault ["Players", []])) >= _requiredPlayers
                    && {(_x getOrDefault ["Position", []]) distance2D _currentLocation <= _procRange}
                } >= 0
            }
        ],
        [
            "doSpawn",
            {
                params ["_taskForceName", "_taskForce"];
                if (!isServer || {isRemoteExecuted}) exitWith {};
                if (_taskForce param [11, false]) exitWith {};
                _taskForce set [11, true];
                [_taskForceName, _taskForce] spawn {
                    params ["_taskForceName", "_taskForce"];
                    private _vehicles = (_taskForce param [3, createHashMap]) getOrDefault ["vehicles", []];
                    private _success = count _vehicles == 1 && {(_vehicles select 0) isKindOf "Air"}
                        && {([] call KPLIB_fnc_getOpforCap) < BATTLESPACE_UNIT_CAP};
                    if (_success) then {
                        private _class = _vehicles select 0;
                        private _position = _taskForce select 1;
                        private _height = [120, 350] select (_class isKindOf "Plane");
                        private _uav = [_position, _class, _height, _position getDir (_taskForce select 2)] call BATTLESPACE_TASK_FORCE_SPAWN_VEHICLE;
                        private _group = createGroup [_taskForce param [6, east], true];
                        _group setVariable ["TASKFORCEID", _taskForceName];
                        _group setVariable ["acex_headless_blacklist", true, true];
                        private _oldGroup = group driver _uav;
                        (crew _uav) joinSilent _group;
                        if (!isNull _oldGroup && {units _oldGroup isEqualTo []}) then {deleteGroup _oldGroup};
                        _group setCombatMode "BLUE";
                        _group setBehaviour "AWARE";
                        _uav setVariable ["TASKFORCEID", _taskForceName];
                        _uav addMPEventHandler ["MPKilled", {["VEHICLE", _this] call BATTLESPACE_TASK_FORCE_OBJECT_KILLED}];
                        {_x setVariable ["TASKFORCEID", _taskForceName]} forEach crew _uav;
                        _taskForce set [4, [_group]];
                        _taskForce set [8, [_uav] + crew _uav];
                        _success = alive driver _uav;
                    };
                    [_taskForceName, _taskForce, _success] call BATTLESPACE_TASK_FORCE_DEFAULT_FINISH_SPAWN;
                };
            }
        ],
        [
            "isAlive",
            {
                params ["_taskForceName", "_taskForce"];
                private _objects = _taskForce param [8, []];
                if (_objects isNotEqualTo []) exitWith {_objects findIf {alive _x && {_x isKindOf "Air"}} >= 0};
                ((_taskForce param [3, createHashMap]) getOrDefault ["vehicles", []]) isNotEqualTo []
            }
        ],
        [
            "onDecisionTick",
            {
                params ["_taskForceName", "_taskForce"];
                private _operation = BATTLESPACE_STRATEGIC_OPERATIONS get _taskForceName;
                if (isNil "_operation") exitWith {true};
                private _groups = (_taskForce param [4, []]) select {!isNull _x && {units _x isNotEqualTo []}};
                _taskForce set [4, _groups];
                private _group = if ((_taskForce param [8, []]) isEqualTo [] || {_groups isEqualTo []}) then {grpNull} else {_groups select 0};
                if (!isNull _group) then {
                    _taskForce set [1, getPosATL leader _group];
                    [_group] call BATTLESPACE_CONTACT_SAMPLE_GROUP;
                };
                private _phase = _operation getOrDefault ["phase", "INTERCEPT"];
                private _position = _taskForce param [1, []];

                if (_phase == "RETURNING") then {
                    private _origin = _operation getOrDefault ["originSector", ""];
                    if (((BATTLESPACE_SECTOR_STATES getOrDefault [_origin, createHashMap]) getOrDefault ["owner", ""]) != "OPFOR") then {
                        [_taskForceName, _taskForce, _operation] call BATTLESPACE_UAV_RECON_BEGIN_RETURN;
                    };
                } else {
                    private _originOwned = ((BATTLESPACE_SECTOR_STATES getOrDefault [_operation getOrDefault ["originSector", ""], createHashMap]) getOrDefault ["owner", ""]) == "OPFOR";
                    if (!_originOwned || {CBA_missionTime >= (_operation getOrDefault ["expiresAt", 0])}) exitWith {
                        [_taskForceName, _taskForce, _operation] call BATTLESPACE_UAV_RECON_BEGIN_RETURN;
                    };
                    // Follow the newest unconfirmed report near the orbit.
                    private _orbit = _operation getOrDefault ["contactPosition", _position];
                    private _reports = ([_orbit, 1500, 300, false, grpNull, true, true] call BATTLESPACE_CONTACT_QUERY)
                        select {(_x select 6) in BATTLESPACE_CONTACT_UNCONFIRMED};
                    if (_reports isNotEqualTo []) then {
                        _reports = [_reports, [], {_x select 1}, "DESCEND"] call BIS_fnc_sortBy;
                        _orbit = +((_reports select 0) select 0);
                        _orbit set [2, 0];
                        _operation set ["contactPosition", _orbit];
                    };
                    if (_phase == "INTERCEPT" && {_position distance2D _orbit <= 800}) then {
                        _phase = "ON_STATION";
                        [format ["UAV recon %1 on station over %2", _taskForceName, mapGridPosition _orbit]] call BATTLESPACE_STRATEGIC_LOG;
                    };
                    if ((_taskForce param [2, []]) distance2D _orbit > 300 || {_phase != (_operation getOrDefault ["phase", ""])}) then {
                        [_taskForceName, _taskForce, _operation, _phase, _orbit] call BATTLESPACE_AIR_RESPONSE_SET_DESTINATION;
                    } else {
                        BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceName, _operation];
                    };
                };
                if ((_operation getOrDefault ["outcome", ""]) == "LOST") exitWith {true};
                _phase = _operation getOrDefault ["phase", _phase];
                private _destination = _taskForce param [2, []];
                if (_phase == "RETURNING" && {_position distance2D _destination <= 300}) exitWith {
                    _operation set ["outcome", "RETURNED"];
                    BATTLESPACE_STRATEGIC_OPERATIONS set [_taskForceName, _operation];
                    true
                };
                if (isNull _group) exitWith {
                    [_taskForceName, _taskForce] call BATTLESPACE_TASK_FORCE_MOVE_SIMULATED_GROUP;
                    false
                };
                // Spawned: one loiter (or return) waypoint, replaced only when the order changes.
                private _order = [_phase == "RETURNING", _destination];
                if (local _group && {(_group getVariable ["BATTLESPACE_UAV_ORDER", []]) isNotEqualTo _order}) then {
                    _group setVariable ["BATTLESPACE_UAV_ORDER", _order];
                    [_group] call CBA_fnc_clearWaypoints;
                    private _waypoint = _group addWaypoint [_destination, 0];
                    if (_phase == "RETURNING") then {
                        _waypoint setWaypointType "MOVE";
                    } else {
                        _waypoint setWaypointType "LOITER";
                        _waypoint setWaypointLoiterType "CIRCLE_L";
                        _waypoint setWaypointLoiterRadius 700;
                    };
                };
                false
            }
        ]
    ]
] call BATTLESPACE_TASK_FORCE_REGISTER_MODEL;
