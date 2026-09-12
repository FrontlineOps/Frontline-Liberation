/* Permission decisions live on the server; client copies only control presentation. */
KPLIB_PERMISSION_OPTIONS = [["BUILD", "Building and FOB construction"], ["RECYCLE", "Recycling"], ["PRODUCTION", "Production management"]];
{KPLIB_PERMISSION_OPTIONS pushBack [_x select 0, _x select 1]} forEach KPLIB_vehiclePermissionDefinitions;
KPLIB_ROLE_OPTIONS = [];
{
    private _sideKey = _x;
    if (_sideKey != "blufor") then {continue};
    {
        KPLIB_ROLE_OPTIONS pushBack ["ROLE:" + _sideKey + ":" + _x, _sideKey + " / " + (_y getOrDefault ["label", _x])];
    } forEach (_y get "roles");
} forEach (localNamespace getVariable "KPLIB_factionProfiles");
KPLIB_PERMISSION_KEYS = (KPLIB_PERMISSION_OPTIONS + KPLIB_ROLE_OPTIONS) apply {_x select 0};
localNamespace setVariable ["KPLIB_permissionKeys", +KPLIB_PERMISSION_KEYS];

KPLIB_fnc_isPermissionAdmin = {
    params [["_unit", objNull, [objNull]]];
    if (isNull _unit || {!isPlayer _unit}) exitWith {false};
    if (isServer) exitWith {
        (hasInterface && {_unit isEqualTo player}) || {admin (owner _unit) == 2}
    };
    _unit isEqualTo player && {serverCommandAvailable "#kick"}
};

KPLIB_fnc_hasPermission = {
    params [["_unit", objNull, [objNull]], ["_permission", "", [""]]];
    if (isNull _unit || {!(_permission in (localNamespace getVariable "KPLIB_permissionKeys"))}) exitWith {false};
    if (isServer) exitWith {
        if !(isPlayer _unit) exitWith {false};
        if ([_unit] call KPLIB_fnc_isPermissionAdmin) exitWith {true};
        private _records = localNamespace getVariable ["KPLIB_permissionRecords", createHashMap];
        _permission in ((_records getOrDefault [getPlayerUID _unit, ["", []]]) select 1)
    };
    _unit isEqualTo player && {
        ([_unit] call KPLIB_fnc_isPermissionAdmin)
        || {_permission in (localNamespace getVariable ["KPLIB_permissionGrants", []])}
    }
};

[] call compileFinal preprocessFileLineNumbers "modules\permissions\recycleYield.sqf";
if (isServer) then {
    [] call compileFinal preprocessFileLineNumbers "modules\permissions\server.sqf";
    [] call compileFinal preprocessFileLineNumbers "modules\permissions\construction.sqf";
};
if (hasInterface) then {
    [] call compileFinal preprocessFileLineNumbers "modules\permissions\client.sqf";
};

[] call compileFinal preprocessFileLineNumbers "modules\permissions\vehicles.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\permissions\equipment.sqf";
