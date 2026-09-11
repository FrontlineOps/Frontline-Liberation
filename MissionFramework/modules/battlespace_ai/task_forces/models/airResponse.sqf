[
    "Air Response",
    createHashMapFromArray [
        [
            "canProc",
            {
                params ["_taskForceName", "_taskForce"];
                private _currentLocation = _taskForce param [1, []];
                private _requiredPlayers = [] call BATTLESPACE_TASK_FORCE_GET_NEEDED_PLAYERCOUNT_FOR_PROC;
                private _procRange = ["Air Response"] call BATTLESPACE_TASK_FORCE_GET_PROC_RANGE;
                private _canProc = false;
                private _operation = BATTLESPACE_STRATEGIC_OPERATIONS getOrDefault [_taskForceName, createHashMap];
                private _target = objectFromNetId (_operation getOrDefault ["targetNetId", ""]);
                if (
                    (_taskForce param [8, []]) isNotEqualTo []
                    && {(_operation getOrDefault ["phase", ""]) != "RETURNING"}
                    && {!isNull _target}
                    && {([_target] call BATTLESPACE_AIR_RESPONSE_CLASSIFY_CONTACT) != ""
                        || {(_operation getOrDefault ["targetKind", ""]) == "INFANTRY"
                            && {[_target] call BATTLESPACE_AIR_INFANTRY_IS_TARGET}}}
                    && {_currentLocation distance2D _target <= BATTLESPACE_AIR_ENGAGEMENT_KEEP_RANGE}
                ) exitWith {true};
                {
                    if (
                        (count (_x getOrDefault ["Players", []])) >= _requiredPlayers
                        && {(_x getOrDefault ["Position", []]) distance2D _currentLocation <= _procRange}
                    ) exitWith {_canProc = true};
                } forEach BATTLESPACE_TASK_FORCES_BLUFOR_CLUSTERS;
                _canProc
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
                        private _destination = _taskForce select 2;
                        private _height = if (_class isKindOf "Plane") then {BATTLESPACE_AIR_BOMB_HEIGHT} else {BATTLESPACE_AIR_HELI_ATTACK_HEIGHT};
                        private _aircraft = [_position, _class, _height, _position getDir _destination] call BATTLESPACE_TASK_FORCE_SPAWN_VEHICLE;
                        private _responseGroup = createGroup [_taskForce param [6, east], true];
                        _responseGroup setVariable ["TASKFORCEID", _taskForceName];
                        _responseGroup setVariable ["acex_headless_blacklist", true, true];
                        private _oldGroup = group driver _aircraft;
                        (crew _aircraft) joinSilent _responseGroup;
                        if (!isNull _oldGroup && {units _oldGroup isEqualTo []}) then {deleteGroup _oldGroup};
                        _aircraft setVariable ["TASKFORCEID", _taskForceName];
                        _aircraft addMPEventHandler ["MPKilled", {["VEHICLE", _this] call BATTLESPACE_TASK_FORCE_OBJECT_KILLED}];
                        {
                            _x setVariable ["TASKFORCEID", _taskForceName];
                        } forEach crew _aircraft;
                        _taskForce set [4, [_responseGroup]];
                        _taskForce set [8, [_aircraft] + crew _aircraft];
                        [_aircraft, BATTLESPACE_STRATEGIC_OPERATIONS getOrDefault [_taskForceName, createHashMap]] call BATTLESPACE_AIR_RESTORE_AIRCRAFT;
                        _success = alive driver _aircraft;
                    };
                    if ([_taskForceName, _taskForce, _success] call BATTLESPACE_TASK_FORCE_DEFAULT_FINISH_SPAWN) then {
                        [_taskForceName] call BATTLESPACE_AIR_START;
                    };
                };
            }
        ],
        [
            "isAlive",
            {
                params ["_taskForceName", "_taskForce"];
                private _composition = _taskForce param [3, createHashMap];
                private _activeObjects = _taskForce param [8, []];
                if (_activeObjects isNotEqualTo []) exitWith {
                    _activeObjects findIf {
                        !isNull _x
                        && {!(_x isKindOf "Man")}
                        && {_x isKindOf "Air"}
                        && {_x getVariable ["KPLIB_captured", false]}
                    } < 0
                };
                (_composition getOrDefault ["vehicles", []]) isNotEqualTo []
            }
        ],
        [
            "onDecisionTick",
            {
                params ["_taskForceName", "_taskForce"];
                if ([_taskForceName, _taskForce] call BATTLESPACE_TASK_FORCE_RELEASE_DISABLED_AIRCRAFT) exitWith {true};
                private _activeGroups = (_taskForce param [4, []]) select {!isNull _x && {units _x isNotEqualTo []}};
                private _activeObjects = _taskForce param [8, []];
                _taskForce set [4, _activeGroups];

                if (_activeObjects isNotEqualTo [] && {_activeGroups isNotEqualTo []}) then {
                    private _leader = leader (_activeGroups select 0);
                    if (!isNull _leader) then {_taskForce set [1, getPosATL _leader]};
                };

                private _done = false;
                if (!isNil "BATTLESPACE_AIR_RESPONSE_ON_DECISION_TICK") then {
                    _done = [_taskForceName, _taskForce] call BATTLESPACE_AIR_RESPONSE_ON_DECISION_TICK;
                };
                if (_done) exitWith {true};

                if (_activeObjects isEqualTo []) then {
                    [_taskForceName, _taskForce] call BATTLESPACE_TASK_FORCE_MOVE_SIMULATED_GROUP;
                };
                false
            }
        ]
    ]
] call BATTLESPACE_TASK_FORCE_REGISTER_MODEL;
