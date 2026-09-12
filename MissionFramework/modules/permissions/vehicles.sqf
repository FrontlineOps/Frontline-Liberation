/* Shared decisions; the server confirms player entry and clients correct their local unit. */
private _profiles = localNamespace getVariable "KPLIB_factionProfiles";
private _friendly = (_profiles get "blufor") get "catalog";
private _rules = createHashMap;
{
    _x params ["_permission", "_label", "_categories", "_seats"];
    {
        {
            _rules set [toLower _x, [_permission, _seats]];
        } forEach (_friendly getOrDefault [_x, []]);
    } forEach _categories;
} forEach KPLIB_vehiclePermissionDefinitions;
// Fixed mission transport must remain operable even when outside a faction catalog.
{
    private _class = missionNamespace getVariable [_x, ""];
    if (_class == "" || {toLower _class in _rules}) then {continue};
    private _category = if (_class isKindOf "Helicopter") then {"rotaryLogistics"} else {
        if (_class isKindOf "Plane") then {"fixedWing"} else {"groundLogistics"}
    };
    private _definition = KPLIB_vehiclePermissionDefinitions select {_category in (_x select 2)};
    if (_definition isNotEqualTo []) then {
        (_definition select 0) params ["_permission", "_label", "_categories", "_seats"];
        _rules set [toLower _class, [_permission, _seats]];
    };
} forEach ["FOB_truck_typename", "huron_typename"];
{
    _x params ["_class", "_permission"];
    private _definition = (KPLIB_vehiclePermissionDefinitions select {(_x select 0) == _permission}) param [0, []];
    if (_definition isEqualTo []) then {throw format ["Unknown vehicle permission %1 for %2", _permission, _class]};
    _rules set [toLower _class, [_permission, _definition select 3]];
} forEach KPLIB_vehiclePermissionExceptions;
localNamespace setVariable ["KPLIB_vehicleAccessRules", _rules];
private _enemyClasses = ((_profiles get "opfor") get "catalog") get "allVehicles";
localNamespace setVariable ["KPLIB_enemyVehicleClasses", createHashMapFromArray (_enemyClasses apply {[toLower _x, true]})];

KPLIB_fnc_vehicleAccess = {
    params ["_unit", "_vehicle", ["_seat", "cargo"]];
    if (isNull _unit || {isNull _vehicle}) exitWith {[false, "Vehicle is unavailable."]};
    if (_vehicle isKindOf "ParachuteBase") exitWith {[true, ""]};
    private _class = toLower typeOf _vehicle;
    private _side = side group _unit;
    if (_side != GRLIB_side_friendly) exitWith {
        [false, "Player vehicle access is available only to BLUFOR."]
    };
    if (_class in (localNamespace getVariable "KPLIB_enemyVehicleClasses")
        || {getNumber (configOf _vehicle >> "side") == 0}) exitWith {
        [false, "OPFOR vehicles cannot be used."]
    };
    private _rules = localNamespace getVariable "KPLIB_vehicleAccessRules";
    if !(_class in _rules) exitWith {[false, "This vehicle is not authorized for BLUFOR."]};
    (_rules get _class) params ["_permission", "_seats"];
    if !(_seat in _seats) exitWith {[true, ""]};
    if ([_unit, _permission] call KPLIB_fnc_hasPermission) exitWith {[true, ""]};
    [false, "You need the corresponding vehicle permission from an admin."]
};

KPLIB_fnc_playerVehicleSeat = {
    params ["_unit", "_vehicle"];
    private _row = (fullCrew [_vehicle, "", false] select {(_x select 0) isEqualTo _unit}) param [0, []];
    if (_row isEqualTo []) exitWith {"cargo"};
    if (_row param [4, false]) exitWith {"cargo"};
    private _seat = toLower (_row select 1);
    if (_seat == "turret") then {_seat = "gunner"};
    _seat
};

KPLIB_fnc_correctVehicleAccess = {
    if (!hasInterface || {isRemoteExecuted && {remoteExecutedOwner != 2}}) exitWith {};
    params ["_vehicle", "_seat", "_allowed", "_reason"];
    if (objectParent player != _vehicle || {([player, _vehicle] call KPLIB_fnc_playerVehicleSeat) != _seat}) exitWith {};
    if (_allowed) exitWith {};
    // Prefer an authorized passenger seat when a player switches into a forbidden control seat.
    private _cargo = (fullCrew [_vehicle, "cargo", true] select {isNull (_x select 0)}) param [0, []];
    if (_cargo isNotEqualTo [] && {([player, _vehicle, "cargo"] call KPLIB_fnc_vehicleAccess) select 0}) then {
        player moveInCargo [_vehicle, _cargo select 2];
    } else {
        // A late grant revocation must not drop an occupant to their death.
        private _position = getPosATL _vehicle;
        private _airborne = (_position select 2) > 3;
        moveOut player;
        if (_airborne) then {
            player setPosATL [_position select 0, _position select 1, 0];
            player setVelocity [0, 0, 0];
        };
    };
    systemChat _reason;
};

KPLIB_fnc_validatePlayerVehicle = {
    params ["_unit"];
    if (!isServer || {!isPlayer _unit}) exitWith {};
    private _vehicle = objectParent _unit;
    if (isNull _vehicle) exitWith {};
    private _seat = [_unit, _vehicle] call KPLIB_fnc_playerVehicleSeat;
    ([_unit, _vehicle, _seat] call KPLIB_fnc_vehicleAccess) params ["_allowed", "_reason"];
    if (!_allowed) then {
        [_vehicle, _seat, false, _reason] remoteExecCall ["KPLIB_fnc_correctVehicleAccess", owner _unit];
        [_unit, _reason] call KPLIB_fnc_permissionRejected;
    };
};

KPLIB_fnc_requestVehicleAccess = {
    private _caller = call KPLIB_fnc_permissionCaller;
    if (!isNull _caller) then {[_caller] call KPLIB_fnc_validatePlayerVehicle};
};

KPLIB_fnc_checkLocalVehicleAccess = {
    private _vehicle = objectParent player;
    if (isNull _vehicle) exitWith {true};
    private _seat = [player, _vehicle] call KPLIB_fnc_playerVehicleSeat;
    private _decision = [player, _vehicle, _seat] call KPLIB_fnc_vehicleAccess;
    if !(_decision select 0) then {
        [_vehicle, _seat, false, _decision select 1] call KPLIB_fnc_correctVehicleAccess;
    };
    [] remoteExecCall ["KPLIB_fnc_requestVehicleAccess", 2];
    _decision select 0
};
