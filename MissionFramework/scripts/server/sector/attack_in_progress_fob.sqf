params [["_fobPosition", [], [[]], [2, 3]]];
if (_fobPosition isEqualTo []) exitWith {};

private _defenderGroup = grpNull;
private _getOwnership = {
    [_fobPosition] call KPLIB_fnc_getSectorOwnership
};
private _cleanupDefenders = {
    if (!isNull _defenderGroup) then {
        {
            if (alive _x) then {deleteVehicle _x};
        } forEach units _defenderGroup;
    };
};
private _clearAttackState = {
    sectors_under_attack set [_fobPosition, false];
    KPLIB_sectorsUnderAttack = KPLIB_sectorsUnderAttack - [_fobPosition];
    publicVariable "KPLIB_sectorsUnderAttack";
};

sleep 5;
private _ownership = call _getOwnership;
if (_ownership != GRLIB_side_enemy) exitWith {
    call _clearAttackState;
    [format ["FOB attack monitor cancelled before activation at %1", mapGridPosition _fobPosition], "SECTOR"] call KPLIB_fnc_log;
};

if (GRLIB_blufor_defenders) then {
    _defenderGroup = createGroup [GRLIB_side_friendly, true];
    {[_x, _fobPosition, _defenderGroup] call KPLIB_fnc_createManagedUnit} forEach blufor_squad_inf;
    sleep 3;
    _defenderGroup setBehaviour "COMBAT";
};

sleep 60;
KPLIB_sectorsUnderAttack pushBackUnique _fobPosition;
publicVariable "KPLIB_sectorsUnderAttack";

_ownership = call _getOwnership;
if (_ownership == GRLIB_side_friendly) exitWith {
    call _clearAttackState;
    call _cleanupDefenders;
    [format ["FOB attack ended before vulnerability at %1", mapGridPosition _fobPosition], "SECTOR"] call KPLIB_fnc_log;
};

[_fobPosition, 1] remoteExec ["remote_call_fob"];
private _attackTime = GRLIB_vulnerability_timer;
while {_attackTime > 0 && {_ownership in [GRLIB_side_enemy, GRLIB_side_resistance]} && {GRLIB_endgame == 0}} do {
    _ownership = call _getOwnership;
    _attackTime = _attackTime - 1;
    sleep 1;
};

waitUntil {
    sleep 1;
    GRLIB_endgame != 0 || {(call _getOwnership) != GRLIB_side_resistance}
};

if (GRLIB_endgame == 0) then {
    _ownership = call _getOwnership;
    if (_attackTime <= 1 && {_ownership == GRLIB_side_enemy}) then {
        [_fobPosition, 2] remoteExec ["remote_call_fob"];
        sleep 3;
        GRLIB_all_fobs = GRLIB_all_fobs - [_fobPosition];
        publicVariable "GRLIB_all_fobs";
        [_fobPosition] call KPLIB_fnc_destroyFob;
        stats_fobs_lost = stats_fobs_lost + 1;
        [] spawn KPLIB_fnc_doSave;
        [format ["FOB attack succeeded at %1", mapGridPosition _fobPosition], "SECTOR"] call KPLIB_fnc_log;
    } else {
        [_fobPosition, 3] remoteExec ["remote_call_fob"];
        [_fobPosition, GRLIB_capture_size * 0.8, "FOB_DEFENDED"] call KPLIB_SURRENDER_SERVER_TRIGGER_AREA;
        [format ["FOB attack defeated at %1", mapGridPosition _fobPosition], "SECTOR"] call KPLIB_fnc_log;
    };
};

call _clearAttackState;
sleep 60;
call _cleanupDefenders;
