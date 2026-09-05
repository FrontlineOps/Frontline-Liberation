/*
    Server-authoritative FOB repack. The client supplies only the selected
    building, caller and package option. Failed placement leaves the FOB intact.
*/
if (!isServer) exitWith {false};
params [
    ["_building", objNull, [objNull]],
    ["_caller", objNull, [objNull]],
    ["_selection", 0, [0]]
];
if (isNull _caller || {!isPlayer _caller}) exitWith {false};
if (isRemoteExecuted && {remoteExecutedOwner != owner _caller}) exitWith {false};
if !(_selection in [1, 2]) exitWith {false};
private _requestOwner = owner _caller;

private _hasAccess = {
    [_caller, "BUILD"] call KPLIB_fnc_hasPermission
};
private _validRequest = {
    !isNull _building
        && {alive _building}
        && {typeOf _building == FOB_typename}
        && {getObjectType _building >= 8}
        && {alive _caller}
        && {isPlayer _caller}
        && {side group _caller == GRLIB_side_friendly}
        && {owner _caller == _requestOwner}
        && {isNull objectParent _caller}
        && {_caller distance _building <= 22}
        && {[] call _hasAccess}
};
if !([] call _validRequest) exitWith {false};

// A deployed building is offset roughly 15 m from its registered FOB centre.
private _fobs = (missionNamespace getVariable ["GRLIB_all_fobs", []]) select {
    _x distance2D _building <= 50
};
if (_fobs isEqualTo []) exitWith {false};
private _fob = [_fobs, [], {_x distance2D _building}, "ASCEND"] call BIS_fnc_sortBy;
_fob = _fob select 0;
private _class = [FOB_box_typename, FOB_truck_typename] select (_selection - 1);
if (!isClass (configFile >> "CfgVehicles" >> _class)) exitWith {false};

// One bounded engine search; an empty result is a normal recoverable failure.
private _spawnPos = (getPosATL _building) findEmptyPosition [10, 250, _class];
if (_spawnPos isEqualTo [] || {surfaceIsWater _spawnPos}) exitWith {
    ["FOB repack cancelled: no clear placement nearby. The FOB is unchanged."] remoteExecCall ["hint", owner _caller];
    false
};

private _package = objNull;
isNil {
    // Revalidate after the search, then claim and replace without a scheduler
    // interruption. Two requests cannot consume the same FOB.
    if (!([] call _validRequest) || {!(_fob in GRLIB_all_fobs)}) exitWith {};
    _package = createVehicle [_class, _spawnPos, [], 0, "CAN_COLLIDE"];
    if (isNull _package || {!alive _package}) exitWith {
        if (!isNull _package) then {deleteVehicle _package};
        _package = objNull;
    };

    GRLIB_all_fobs = GRLIB_all_fobs - [_fob];
    private _clearanceIndex = KP_liberation_clearances findIf {
        (_x select 0) isEqualTo _fob
            || {(_x select 0) distance2D _building < 1 && {(_x param [1, 0]) == 20}}
    };
    if (_clearanceIndex >= 0) then {
        KP_liberation_clearances deleteAt _clearanceIndex;
    };
    deleteVehicle _building;
};
if (isNull _package) exitWith {false};

[_package] call KPLIB_fnc_addObjectInit;
publicVariable "GRLIB_all_fobs";
publicVariable "KP_liberation_clearances";
[] spawn KPLIB_fnc_doSave;
[localize "STR_FOB_REPACKAGE_HINT"] remoteExecCall ["hint", owner _caller];
[format ["FOB repacked at %1 as %2", _fob, _class], "FOB"] call KPLIB_fnc_log;
true
