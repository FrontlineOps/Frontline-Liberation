if (isServer) then {
    KPLIB_TRASH_CLEANUP_QUEUE = [];

    KPLIB_TRASH_CLEANUP_SERVER_GET_CALLER = {
        if (!isRemoteExecuted) exitWith {objNull};
        private _ownerId = remoteExecutedOwner;
        (allPlayers select {isPlayer _x && {owner _x == _ownerId}}) param [0, objNull]
    };

    KPLIB_TRASH_CLEANUP_SERVER_REGISTER = {
        params [["_holder", objNull, [objNull]]];
        if (!isServer || {!isRemoteExecuted}) exitWith {};

        private _caller = [] call KPLIB_TRASH_CLEANUP_SERVER_GET_CALLER;
        if (
            isNull _caller
            || {isNull _holder}
            || {!(typeOf _holder in KPLIB_trashCleanup_classnames)}
            || {_caller distance _holder > 10}
            || {_holder getVariable ["KPLIB_trashCleanupQueued", false]}
        ) exitWith {};

        _holder setVariable ["KPLIB_trashCleanupQueued", true];
        KPLIB_TRASH_CLEANUP_QUEUE pushBack [_holder, CBA_missionTime + KPLIB_trashCleanup_lifetime];
    };

    KPLIB_TRASH_CLEANUP_PFH = [{
        private _now = CBA_missionTime;
        private _count = (count KPLIB_TRASH_CLEANUP_QUEUE) min KPLIB_trashCleanup_batchSize;

        for "_index" from 1 to _count do {
            private _entry = KPLIB_TRASH_CLEANUP_QUEUE deleteAt 0;
            _entry params ["_holder", "_deleteAt"];

            if (!isNull _holder) then {
                if (_now >= _deleteAt) then {
                    deleteVehicle _holder;
                } else {
                    KPLIB_TRASH_CLEANUP_QUEUE pushBack _entry;
                };
            };
        };
    }, KPLIB_trashCleanup_interval] call CBA_fnc_addPerFrameHandler;

    [format ["Dropped-item cleanup initialized (lifetime=%1s, interval=%2s, batch=%3)", KPLIB_trashCleanup_lifetime, KPLIB_trashCleanup_interval, KPLIB_trashCleanup_batchSize], "TRASH CLEANUP"] call KPLIB_fnc_log;
};

if (hasInterface) then {
    ["KPLIB_TRASH_CLEANUP_INVENTORY_CLOSED", "InventoryClosed", {
        params ["_unit", "_holder"];
        if (!isNull _holder && {typeOf _holder in KPLIB_trashCleanup_classnames}) then {
            [_holder] remoteExecCall ["KPLIB_TRASH_CLEANUP_SERVER_REGISTER", 2];
        };
    }] call CBA_fnc_addBISPlayerEventHandler;
};
