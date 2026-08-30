KPLIB_COPS_STATE = createHashMap;
KPLIB_COPS_NEXT_ID = 0;
KPLIB_COPS_REVISION = 0;
KPLIB_COPS_REQUEST_DEADLINES = createHashMap;
KPLIB_COPS_READY = false;

KPLIB_COPS_SERVER_LOG = {
    params ["_message", ["_level", "COPS"]];
    [_message, _level] call KPLIB_fnc_log;
};

KPLIB_COPS_SERVER_GET_CALLER = {
    if (!isServer || {!isRemoteExecuted}) exitWith {objNull};
    private _ownerId = remoteExecutedOwner;
    (allPlayers select {isPlayer _x && {owner _x == _ownerId}}) param [0, objNull]
};

KPLIB_COPS_SERVER_IS_SQUAD_LEADER = {
    params [["_unit", objNull, [objNull]]];
    !isNull _unit && {(toLower roleDescription _unit) find "squad leader" >= 0}
};

KPLIB_COPS_SERVER_POSITION_VALID = {
    params ["_position"];
    _position isEqualType []
        && {(count _position) in [2, 3]}
        && {_position findIf {!(_x isEqualType 0)} == -1}
};

KPLIB_COPS_SERVER_BUILD_SNAPSHOT = {
    private _entries = [];
    {
        private _markerPos = +(_y getOrDefault ["markerPos", []]);
        if ([_markerPos] call KPLIB_COPS_SERVER_POSITION_VALID) then {
            _entries pushBack [_x, _markerPos];
        };
    } forEach KPLIB_COPS_STATE;
    _entries sort true;
    [KPLIB_COPS_REVISION, KPLIB_COPS_MAX, _entries]
};

KPLIB_COPS_SERVER_SEND_SNAPSHOT = {
    params [["_ownerId", -1, [0]]];
    private _snapshot = [] call KPLIB_COPS_SERVER_BUILD_SNAPSHOT;

    if (_ownerId >= 0) exitWith {
        [_snapshot] remoteExecCall ["KPLIB_COPS_CLIENT_APPLY_SNAPSHOT", _ownerId];
    };

    {
        if (isPlayer _x && {side _x == GRLIB_side_friendly}) then {
            [_snapshot] remoteExecCall ["KPLIB_COPS_CLIENT_APPLY_SNAPSHOT", owner _x];
        };
    } forEach allPlayers;
};

KPLIB_COPS_SERVER_SAVE = {
    if (!isServer || {isRemoteExecuted}) exitWith {false};

    private _savedEntries = [];
    {
        private _id = _x;
        private _entry = _y;
        private _primary = _entry getOrDefault ["primary", objNull];
        private _markerPos = +(_entry getOrDefault ["markerPos", []]);
        private _objects = _entry getOrDefault ["objects", []];

        if (!isNull _primary && {alive _primary} && {[_markerPos] call KPLIB_COPS_SERVER_POSITION_VALID}) then {
            private _savedObjects = [];
            {
                if (!isNull _x) then {
                    _savedObjects pushBack [
                        typeOf _x,
                        getPosWorld _x,
                        vectorDir _x,
                        vectorUp _x,
                        _x isEqualTo _primary
                    ];
                };
            } forEach _objects;

            if !(_savedObjects isEqualTo []) then {
                _savedEntries pushBack [_id, _markerPos, _savedObjects];
            };
        };
    } forEach KPLIB_COPS_STATE;

    _savedEntries sort true;
    profileNamespace setVariable [KPLIB_COPS_SAVE_KEY, [KPLIB_COPS_NEXT_ID, _savedEntries]];
    saveProfileNamespace;
    true
};

KPLIB_COPS_SERVER_ATTACH_LIFECYCLE = {
    params ["_primary", "_id"];
    _primary setVariable ["KPLIB_COPS_ID", _id, true];

    _primary addEventHandler ["Killed", {
        params ["_object"];
        private _id = _object getVariable ["KPLIB_COPS_ID", -1];
        if (isServer && {_id >= 0} && {!isNil "KPLIB_COPS_SERVER_REMOVE"}) then {
            [_id, true, "DESTROYED"] call KPLIB_COPS_SERVER_REMOVE;
        };
    }];

    _primary addEventHandler ["Deleted", {
        params ["_object"];
        private _id = _object getVariable ["KPLIB_COPS_ID", -1];
        if (isServer && {_id >= 0} && {!isNil "KPLIB_COPS_SERVER_REMOVE"}) then {
            [_id, false, "DELETED"] call KPLIB_COPS_SERVER_REMOVE;
        };
    }];
};

KPLIB_COPS_SERVER_REMOVE = {
    params ["_id", ["_keepWreck", false, [false]], ["_reason", "", [""]]];
    if (!isServer || {isRemoteExecuted}) exitWith {false};

    private _entry = KPLIB_COPS_STATE getOrDefault [_id, createHashMap];
    if (count _entry == 0) exitWith {false};

    KPLIB_COPS_STATE deleteAt _id;
    private _primary = _entry getOrDefault ["primary", objNull];
    {
        if (!isNull _x) then {
            if (_keepWreck && {_x isEqualTo _primary} && {!alive _x}) then {
                if (!isNil "KPLIB_fnc_queueDeadObjectCleanup") then {
                    [_x] call KPLIB_fnc_queueDeadObjectCleanup;
                } else {
                    deleteVehicle _x;
                };
            } else {
                deleteVehicle _x;
            };
        };
    } forEach (_entry getOrDefault ["objects", []]);

    KPLIB_COPS_REVISION = KPLIB_COPS_REVISION + 1;
    [] call KPLIB_COPS_SERVER_SAVE;
    [-1] call KPLIB_COPS_SERVER_SEND_SNAPSHOT;

    if (_reason == "DESTROYED") then {
        private _markerPos = _entry getOrDefault ["markerPos", [0, 0, 0]];
        [
            "lib_admin_notification",
            ["PB lost", format ["PB - %1 has been destroyed!", mapGridPosition _markerPos], "res\notif\ui_notif_sec_los.paa"]
        ] remoteExecCall ["BIS_fnc_showNotification", GRLIB_side_friendly];
    };
    true
};

KPLIB_COPS_SERVER_CREATE_FROM_PLAYER = {
    params ["_player", "_id"];

    private _markerPos = _player modelToWorld KPLIB_COPS_MARKER_OFFSET;
    _markerPos set [2, 0];
    if (surfaceIsWater _markerPos) exitWith {[]};

    private _objects = [];
    private _primary = objNull;
    private _failed = false;

    {
        _x params ["_class", "_offset", "_direction", "_isPrimary"];
        if (!isClass (configFile >> "CfgVehicles" >> _class)) exitWith {_failed = true};

        private _position = _player modelToWorld _offset;
        _position set [2, _offset select 2];
        if (surfaceIsWater _position) exitWith {_failed = true};

        private _object = createVehicle [_class, _position, [], 0, "CAN_COLLIDE"];
        if (isNull _object) exitWith {_failed = true};

        _object setPosATL _position;
        _object setVectorDirAndUp [_player vectorModelToWorld _direction, surfaceNormal _position];
        _object enableSimulationGlobal false;
        _objects pushBack _object;
        if (_isPrimary) then {_primary = _object};
    } forEach KPLIB_COPS_COMPOSITION;

    if (_failed || {isNull _primary}) exitWith {
        {if (!isNull _x) then {deleteVehicle _x}} forEach _objects;
        []
    };

    [_objects, _primary, _markerPos]
};

KPLIB_COPS_SERVER_RESTORE_ENTRY = {
    params ["_savedEntry"];
    if !(_savedEntry isEqualType [] && {count _savedEntry == 3}) exitWith {false};
    _savedEntry params ["_id", "_markerPos", "_savedObjects"];
    if !(
        _id isEqualType 0
        && {_id >= 0}
        && {[_markerPos] call KPLIB_COPS_SERVER_POSITION_VALID}
        && {_savedObjects isEqualType []}
        && {!(_savedObjects isEqualTo [])}
    ) exitWith {false};

    private _objects = [];
    private _primary = objNull;
    private _valid = true;

    {
        if !(_x isEqualType [] && {count _x == 5}) exitWith {_valid = false};
        _x params ["_class", "_position", "_vectorDir", "_vectorUp", "_isPrimary"];
        if !(
            _class isEqualType ""
            && {isClass (configFile >> "CfgVehicles" >> _class)}
            && {[_position] call KPLIB_COPS_SERVER_POSITION_VALID}
            && {[_vectorDir] call KPLIB_COPS_SERVER_POSITION_VALID}
            && {[_vectorUp] call KPLIB_COPS_SERVER_POSITION_VALID}
            && {_isPrimary isEqualType false}
        ) exitWith {_valid = false};

        private _object = createVehicle [_class, ASLToAGL _position, [], 0, "CAN_COLLIDE"];
        if (isNull _object) exitWith {_valid = false};
        _object setPosWorld _position;
        _object setVectorDirAndUp [_vectorDir, _vectorUp];
        _object enableSimulationGlobal false;
        _objects pushBack _object;

        if (_isPrimary) then {
            if (!isNull _primary) then {_valid = false};
            _primary = _object;
        };
    } forEach _savedObjects;

    if (!_valid || {isNull _primary}) exitWith {
        {if (!isNull _x) then {deleteVehicle _x}} forEach _objects;
        false
    };

    private _entry = createHashMapFromArray [
        ["markerPos", +_markerPos],
        ["objects", _objects],
        ["primary", _primary]
    ];
    KPLIB_COPS_STATE set [_id, _entry];
    [_primary, _id] call KPLIB_COPS_SERVER_ATTACH_LIFECYCLE;
    KPLIB_COPS_NEXT_ID = KPLIB_COPS_NEXT_ID max (_id + 1);
    true
};

KPLIB_COPS_SERVER_LOAD = {
    if (!isServer || {isRemoteExecuted}) exitWith {false};

    private _wipe = (missionNamespace getVariable ["GRLIB_param_wipe_savegame_1", 0]) == 1
        && {(missionNamespace getVariable ["GRLIB_param_wipe_savegame_2", 0]) == 1};
    if (_wipe) then {
        profileNamespace setVariable [KPLIB_COPS_SAVE_KEY, nil];
        saveProfileNamespace;
    };

    private _saved = profileNamespace getVariable [KPLIB_COPS_SAVE_KEY, []];
    if !(_saved isEqualType [] && {count _saved == 2}) exitWith {
        if !(_saved isEqualTo []) then {
            ["Rejected malformed PB snapshot", "COPS"] call KPLIB_COPS_SERVER_LOG;
        };
        true
    };

    _saved params ["_nextId", "_savedEntries"];
    if !(_nextId isEqualType 0 && {_savedEntries isEqualType []}) exitWith {
        ["Rejected malformed PB snapshot containers", "COPS"] call KPLIB_COPS_SERVER_LOG;
        true
    };

    KPLIB_COPS_NEXT_ID = _nextId max 0;
    {
        if !([_x] call KPLIB_COPS_SERVER_RESTORE_ENTRY) then {
            [format ["Skipped malformed PB snapshot entry %1", _forEachIndex], "COPS"] call KPLIB_COPS_SERVER_LOG;
        };
    } forEach (_savedEntries select [0, KPLIB_COPS_MAX]);
    true
};

KPLIB_COPS_SERVER_VALIDATE_DEPLOYMENT = {
    params ["_player"];
    if (isNull _player || {!isPlayer _player} || {!alive _player}) exitWith {"Unable to deploy a PB while dead."};
    if (side _player != GRLIB_side_friendly) exitWith {"PB deployment is available only to BLUFOR."};
    if !(isNull objectParent _player) exitWith {"Leave your vehicle before deploying a PB."};
    if !([_player] call KPLIB_COPS_SERVER_IS_SQUAD_LEADER) exitWith {"Only a Squad Leader may deploy the PB."};
    if (count KPLIB_COPS_STATE >= KPLIB_COPS_MAX) exitWith {"The PB limit has already been reached."};

    private _position = getPosATL _player;
    private _nearestFob = [_position] call KPLIB_fnc_getNearestFOB;
    if (_nearestFob distance2D _position < KPLIB_COPS_MIN_FOB_DISTANCE) exitWith {
        format ["Move at least %1 m away from the nearest FOB or starting base.", KPLIB_COPS_MIN_FOB_DISTANCE]
    };

    private _nearestHostile = [KPLIB_COPS_SECTOR_SEARCH_DISTANCE, _position] call KPLIB_fnc_getNearestOpforSector;
    if (
        _nearestHostile != ""
        && {(getMarkerPos _nearestHostile) distance2D _position < KPLIB_COPS_MIN_HOSTILE_SECTOR_DISTANCE}
    ) exitWith {
        format ["Move at least %1 m away from the nearest hostile objective.", KPLIB_COPS_MIN_HOSTILE_SECTOR_DISTANCE]
    };
    ""
};

KPLIB_COPS_SERVER_REQUEST_DEPLOY = {
    if (!isServer || {!isRemoteExecuted} || {!KPLIB_COPS_READY}) exitWith {};
    private _ownerId = remoteExecutedOwner;
    private _player = [] call KPLIB_COPS_SERVER_GET_CALLER;
    if (isNull _player) exitWith {};

    private _now = diag_tickTime;
    private _deadline = KPLIB_COPS_REQUEST_DEADLINES getOrDefault [_ownerId, 0];
    if (_now < _deadline) exitWith {
        [false, "PB deployment request is already being processed."] remoteExecCall ["KPLIB_COPS_CLIENT_RECEIVE_RESULT", _ownerId];
    };
    KPLIB_COPS_REQUEST_DEADLINES set [_ownerId, _now + KPLIB_COPS_REQUEST_COOLDOWN];

    private _error = [_player] call KPLIB_COPS_SERVER_VALIDATE_DEPLOYMENT;
    if (_error != "") exitWith {
        [false, _error] remoteExecCall ["KPLIB_COPS_CLIENT_RECEIVE_RESULT", _ownerId];
    };

    private _id = KPLIB_COPS_NEXT_ID;
    private _spawned = [_player, _id] call KPLIB_COPS_SERVER_CREATE_FROM_PLAYER;
    if (_spawned isEqualTo []) exitWith {
        [false, "The PB composition could not be placed at this position."] remoteExecCall ["KPLIB_COPS_CLIENT_RECEIVE_RESULT", _ownerId];
    };
    _spawned params ["_objects", "_primary", "_markerPos"];

    KPLIB_COPS_STATE set [_id, createHashMapFromArray [
        ["markerPos", _markerPos],
        ["objects", _objects],
        ["primary", _primary]
    ]];
    KPLIB_COPS_NEXT_ID = _id + 1;
    [_primary, _id] call KPLIB_COPS_SERVER_ATTACH_LIFECYCLE;

    KPLIB_COPS_REVISION = KPLIB_COPS_REVISION + 1;
    [] spawn KPLIB_COPS_SERVER_SAVE;
    [-1] call KPLIB_COPS_SERVER_SEND_SNAPSHOT;
    [true, "PB deployed."] remoteExecCall ["KPLIB_COPS_CLIENT_RECEIVE_RESULT", _ownerId];
};

KPLIB_COPS_SERVER_REQUEST_SNAPSHOT = {
    if (!isServer || {!isRemoteExecuted} || {!KPLIB_COPS_READY}) exitWith {};
    private _player = [] call KPLIB_COPS_SERVER_GET_CALLER;
    if (isNull _player || {side _player != GRLIB_side_friendly}) exitWith {};
    [remoteExecutedOwner] call KPLIB_COPS_SERVER_SEND_SNAPSHOT;
};

KPLIB_COPS_SERVER_INIT = {
    if (!isServer) exitWith {};
    waitUntil {sleep 0.25; !isNil "save_is_loaded" && {save_is_loaded}};
    [] call KPLIB_COPS_SERVER_LOAD;
    KPLIB_COPS_REVISION = KPLIB_COPS_REVISION + 1;
    KPLIB_COPS_READY = true;
    [-1] call KPLIB_COPS_SERVER_SEND_SNAPSHOT;
    [format ["Initialized %1 persistent PB(s)", count KPLIB_COPS_STATE], "COPS"] call KPLIB_COPS_SERVER_LOG;
};
