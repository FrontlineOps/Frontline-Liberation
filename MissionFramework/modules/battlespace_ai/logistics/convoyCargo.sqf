/*
    Paid freight stays inside the carrier until recovery. These server-only
    records are runtime state; the saved manifest/cargoCratesLost count already
    preserves remaining shares when a convoy dematerializes or the game reloads.
*/
BATTLESPACE_CONVOY_CARGO_RELEASE = {
    if (!isServer || {isRemoteExecuted && {remoteExecutedOwner != 2}}) exitWith {false};
    params ["_truck", ["_reason", "recovered"]];
    private _records = localNamespace getVariable ["BATTLESPACE_CONVOY_CARGO_RECORDS", createHashMap];
    private _key = netId _truck;
    private _record = _records getOrDefault [_key, []];
    if (_record isEqualTo [] || {_record select 4} || {(_record select 2) != _truck}) exitWith {false};
    _record params ["_class", "_value", "_carrier", "_taskForceId"];
    private _operation = BATTLESPACE_STRATEGIC_OPERATIONS getOrDefault [_taskForceId, createHashMap];
    if ((_operation getOrDefault ["kind", ""]) != "CONVOY") exitWith {false};

    // Lock before creating anything: simultaneous unload/kill requests must
    // consume this paid share at most once.
    _record set [4, true];
    private _distance = (sizeOf typeOf _truck) / 2 + 3;
    private _position = _truck getPos [_distance, getDir _truck + 180];
    private _empty = _position findEmptyPosition [0, 12, _class];
    if (_empty isNotEqualTo [] && {_empty distance2D _truck >= _distance}) then {
        _position = _empty;
    };
    private _crate = [_class, _value, _position] call KPLIB_fnc_createCrate;
    if (isNull _crate) exitWith {_record set [4, false]; false};
    _crate setDir getDir _truck;
    _crate setVariable ["TASKFORCEID", _taskForceId];
    _crate setVariable ["BATTLESPACE_CONVOY_CARGO_CRATE", true, true];
    _crate setVariable ["BATTLESPACE_CONVOY_CARGO_CARRIER", _truck];
    if !([_crate, _reason] call BATTLESPACE_LOGISTICS_CLAIM_CONVOY_CRATE) exitWith {
        deleteVehicle _crate;
        _record set [4, false];
        false
    };
    _records deleteAt _key;
    true
};

BATTLESPACE_CONVOY_CARGO_CLEANUP = {
    if (!isServer || {isRemoteExecuted && {remoteExecutedOwner != 2}}) exitWith {};
    params ["_truck"];
    private _records = localNamespace getVariable ["BATTLESPACE_CONVOY_CARGO_RECORDS", createHashMap];
    // During Deleted, compare the recorded object as its network ID may vanish.
    private _keys = [];
    {
        if ((_y select 2) == _truck) then {_keys pushBack _x};
    } forEach _records;
    {_records deleteAt _x} forEach _keys;
};

BATTLESPACE_CONVOY_CARGO_RECONCILE = {
    if (!isServer || {isRemoteExecuted && {remoteExecutedOwner != 2}}) exitWith {};
    params ["_taskForceId", "_taskForce"];
    private _records = localNamespace getVariable ["BATTLESPACE_CONVOY_CARGO_RECORDS", createHashMap];
    private _release = [];
    {
        if ((_y select 3) != _taskForceId) then {continue};
        private _truck = _y select 2;
        private _reason = "";
        if (!alive _truck || {!canMove _truck}) then {
            _reason = "carrier disabled";
        } else {
            if (_truck getVariable ["KPLIB_captured", false]) then {
                _reason = "carrier captured";
            } else {
                if !(_truck in (_taskForce param [8, []])) then {
                    _reason = "carrier abandoned";
                };
            };
        };
        if (_reason != "") then {_release pushBack [_truck, _reason]};
    } forEach _records;
    {_x call BATTLESPACE_CONVOY_CARGO_RELEASE} forEach _release;
};

BATTLESPACE_CONVOY_CARGO_UNLOAD = {
    params [["_truck", objNull, [objNull]], ["_caller", objNull, [objNull]]];
    if (!isServer || {isNull _truck} || {isNull _caller}) exitWith {false};
    if (isRemoteExecuted && {remoteExecutedOwner != owner _caller}) exitWith {false};
    if (
        !isPlayer _caller || {!alive _caller} || {vehicle _caller != _caller}
        || {side group _caller != GRLIB_side_friendly}
        || {!(_caller isKindOf "Man")} || {_caller distance _truck >= 8}
        || {!(_truck isKindOf "LandVehicle")} || {abs speed _truck >= 5}
        || {((getPosATL _truck) select 2) > 5}
    ) exitWith {false};
    // Leave the client RPC context before the server-only release. The request
    // contains no class or amount; only the server's paid record can be consumed.
    [_truck, "unloaded"] spawn BATTLESPACE_CONVOY_CARGO_RELEASE;
    true
};
