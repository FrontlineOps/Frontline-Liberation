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

build_remote_call = compileFinal preprocessFileLineNumbers "scripts\server\remotecall\build_remote_call.sqf";
build_fob_remote_call = compileFinal preprocessFileLineNumbers "scripts\server\remotecall\build_fob_remote_call.sqf";
cancel_build_remote_call = compileFinal preprocessFileLineNumbers "scripts\server\remotecall\cancel_build_remote_call.sqf";
prisonner_remote_call = compileFinal preprocessFileLineNumbers "scripts\server\remotecall\prisonner_remote_call.sqf";
recycle_remote_call = compileFinal preprocessFileLineNumbers "scripts\server\remotecall\recycle_remote_call.sqf";
reinforcements_remote_call = compileFinal preprocessFileLineNumbers "scripts\server\remotecall\reinforcements_remote_call.sqf";
sector_liberated_remote_call = compileFinal preprocessFileLineNumbers "scripts\server\remotecall\sector_liberated_remote_call.sqf";
intel_remote_call = compileFinal preprocessFileLineNumbers "scripts\server\remotecall\intel_remote_call.sqf";
start_secondary_remote_call = compileFinal preprocessFileLineNumbers "scripts\server\remotecall\start_secondary_remote_call.sqf";
change_prod_remote_call = compileFinal preprocessFileLineNumbers "scripts\server\remotecall\change_prod_remote_call.sqf";
build_fac_remote_call = compileFinal preprocessFileLineNumbers "scripts\server\remotecall\build_fac_remote_call.sqf";
remote_call_sector = compileFinal preprocessFileLineNumbers "scripts\client\remotecall\remote_call_sector.sqf";
remote_call_fob = compileFinal preprocessFileLineNumbers "scripts\client\remotecall\remote_call_fob.sqf";
remote_call_battlegroup = compileFinal preprocessFileLineNumbers "scripts\client\remotecall\remote_call_battlegroup.sqf";
remote_call_endgame = compileFinal preprocessFileLineNumbers "scripts\client\remotecall\remote_call_endgame.sqf";
remote_call_prisonner = compileFinal preprocessFileLineNumbers "scripts\client\remotecall\remote_call_prisonner.sqf";
remote_call_intel = compileFinal preprocessFileLineNumbers "scripts\client\remotecall\remote_call_intel.sqf";
remote_call_incoming = compileFinal preprocessFileLineNumbers "scripts\client\remotecall\remote_call_incoming.sqf";
remote_call_incoming_airdrop = compileFinal preprocessFileLineNumbers "scripts\client\remotecall\remote_call_incoming_airdrop.sqf";

civinfo_notifications = compileFinal preprocessFileLineNumbers "scripts\client\civinformant\civinfo_notifications.sqf";
civinfo_escort = compileFinal preprocessFileLineNumbers "scripts\client\civinformant\civinfo_escort.sqf";
civinfo_delivered = compileFinal preprocessFileLineNumbers "scripts\server\civinformant\civinfo_delivered.sqf";

execVM "scripts\shared\diagnostics.sqf";
