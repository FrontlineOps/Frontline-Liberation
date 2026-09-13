/* Native fire control remains responsible for launch decisions and turret modes.
   Battlespace SAM callbacks retain paid-ammunition accounting. This registry
   supplies real radar support to guidance and the existing artillery/EWR consumers. */
IADS_SearchRadars = [];
IADS_LaunchVehicles = [];
IADS_VLS = [];

KPLIB_GUIDANCE_REGISTER_RADAR = {
    params ["_vehicle"];
    if (isRemoteExecuted || {isNull _vehicle}) exitWith {};
    private _capability = [typeOf _vehicle] call KPLIB_fnc_getVehicleAirDefense;
    if (_capability get "radar") then {IADS_SearchRadars pushBackUnique _vehicle};
    if ((_capability get "missileAmmo") isNotEqualTo []) then {IADS_LaunchVehicles pushBackUnique _vehicle};
    if (isServer && {local _vehicle} && {_capability get "radar"}) then {
        _vehicle setVehicleRadar 1;
        // Native vehicle configuration determines datalink availability.
    };
    if ((IADS_SearchRadars isNotEqualTo [] || {IADS_LaunchVehicles isNotEqualTo []})
        && {(localNamespace getVariable ["KPLIB_guidanceRadarPFH", -1]) < 0}) then {
        private _pfh = [{
            IADS_SearchRadars = IADS_SearchRadars select {!isNull _x && {alive _x}};
            IADS_LaunchVehicles = IADS_LaunchVehicles select {!isNull _x && {alive _x}};
            if (IADS_SearchRadars isEqualTo [] && {IADS_LaunchVehicles isEqualTo []}) then {
                [_this select 1] call CBA_fnc_removePerFrameHandler;
                localNamespace setVariable ["KPLIB_guidanceRadarPFH", -1];
            };
        }, 10] call CBA_fnc_addPerFrameHandler;
        localNamespace setVariable ["KPLIB_guidanceRadarPFH", _pfh];
    };
};
{
    [_x, "init", {_this call KPLIB_GUIDANCE_REGISTER_RADAR}, true, [], true] call CBA_fnc_addClassEventHandler;
} forEach ["LandVehicle", "StaticWeapon"];
