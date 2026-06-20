waitUntil {!isNil "save_is_loaded"};
waitUntil {save_is_loaded};

private _placeholder = objNull;
private _spawnPos = [];
private _veh = objNull;
{
    _x params ["_id", "_classname"];

    for [{_i = 0}, {!isNil ([_id, _i] joinString "")}, {_i = _i + 1}] do {
        _placeholder = missionNamespace getVariable ([_id, _i] joinString "");
        _spawnPos = getPosATL _placeholder;
        _veh = _classname createVehicle [_spawnPos select 0, _spawnPos select 1, (_spawnPos select 2) + 0.2];
        _veh allowDamage false;
        _veh setDir (getDir _placeholder);
        _veh setPosATL _spawnPos;
        [_veh] call KPLIB_fnc_clearCargo;
        sleep 1;
        _veh setDamage 0;
        _veh allowDamage true;
        _veh setVariable ["KP_liberation_preplaced", true, true];
        [_veh] call KPLIB_fnc_addObjectInit;
    };
} forEach [
    ["smallhelo_", KP_liberation_smallhelo_classname],
    ["midhelo_", KP_liberation_midhelo_classname],
    ["bighelo_", KP_liberation_bighelo_classname],
    ["medhelo_", KP_liberation_medhelo_classname],
    ["atkhelo_", KP_liberation_atkhelo_classname],
    ["car_", KP_liberation_car_classname],
    ["atcar_", KP_liberation_atcar_classname],
    ["truck_", KP_liberation_truck_classname],
    ["medcar_", KP_liberation_medcar_classname],
    ["zodiac_", KP_liberation_zodiac_classname],
    ["rhib_", KP_liberation_rhib_classname],
    ["ifv_", KP_liberation_ifv_classname],
    ["apc_", KP_liberation_apc_classname],
    ["cas_", KP_liberation_cas_classname],
    ["cap_", KP_liberation_cap_classname],
    ["drone_", KP_liberation_drone_classname],
    ["repair_", KP_liberation_repair_classname],
    ["fuel_", KP_liberation_fuel_classname]
];
