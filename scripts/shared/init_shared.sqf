kill_manager = compileFinal preprocessFileLineNumbers "scripts\shared\kill_manager.sqf";

if (isServer) then {
    KPLIB_deadObjectCleanupQueue = [];
    KPLIB_fnc_queueDeadObjectCleanup = {
        params [["_object", objNull, [objNull]]];

        if (isNull _object) exitWith {};
        if ((KPLIB_deadObjectCleanupQueue findIf {(_x select 0) isEqualTo _object}) != -1) exitWith {};

        private _hideAt = time + GRLIB_cleanup_delay;
        KPLIB_deadObjectCleanupQueue pushBack [_object, _hideAt, _hideAt + 10];
    };

    build_remote_call = compileFinal preprocessFileLineNumbers "scripts\server\remotecall\build_remote_call.sqf";
    build_fob_remote_call = compileFinal preprocessFileLineNumbers "scripts\server\remotecall\build_fob_remote_call.sqf";
    cancel_build_remote_call = compileFinal preprocessFileLineNumbers "scripts\server\remotecall\cancel_build_remote_call.sqf";
    recycle_remote_call = compileFinal preprocessFileLineNumbers "scripts\server\remotecall\recycle_remote_call.sqf";
    sector_liberated_remote_call = compileFinal preprocessFileLineNumbers "scripts\server\remotecall\sector_liberated_remote_call.sqf";
    change_prod_remote_call = compileFinal preprocessFileLineNumbers "scripts\server\remotecall\change_prod_remote_call.sqf";
    build_fac_remote_call = compileFinal preprocessFileLineNumbers "scripts\server\remotecall\build_fac_remote_call.sqf";

    [] spawn {
        while {true} do {
            sleep 5;
            private _now = time;
            private _remaining = [];

            {
                _x params ["_object", "_hideAt", "_deleteAt"];
                if (isNull _object) then {
                    continue;
                };
                if (_now >= _deleteAt) then {
                    deleteVehicle _object;
                    continue;
                };
                if (_now >= _hideAt) then {
                    if (_object isKindOf "Man") then {
                        hideBody _object;
                    } else {
                        _object hideObjectGlobal true;
                    };
                };
                _remaining pushBack _x;
            } forEach KPLIB_deadObjectCleanupQueue;

            KPLIB_deadObjectCleanupQueue = _remaining;
        };
    };
};

remote_call_sector = compileFinal preprocessFileLineNumbers "scripts\client\remotecall\remote_call_sector.sqf";
remote_call_fob = compileFinal preprocessFileLineNumbers "scripts\client\remotecall\remote_call_fob.sqf";
remote_call_endgame = compileFinal preprocessFileLineNumbers "scripts\client\remotecall\remote_call_endgame.sqf";
remote_call_incoming = compileFinal preprocessFileLineNumbers "scripts\client\remotecall\remote_call_incoming.sqf";

civinfo_notifications = compileFinal preprocessFileLineNumbers "scripts\client\civinformant\civinfo_notifications.sqf";
civinfo_escort = compileFinal preprocessFileLineNumbers "scripts\client\civinformant\civinfo_escort.sqf";

execVM "scripts\shared\diagnostics.sqf";
