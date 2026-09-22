/*
kp_fuel_consumption.sqf
Author: Wyqer
Website: www.killahpotatoes.de
Date: 2017-02-02

Description:
This script handles the fuel consumption of vehicles, so that refueling will be necessary more often.

Parameters:
_this select 0 - OBJECT - Vehicle

Method:
execVM

Example for initPlayerLocal.sqf:
["TAG_PLAYER_GET_IN", "GetInMan", {[_this select 2] spawn kp_fuel_consumption;}] call CBA_fnc_addBISPlayerEventHandler;
*/

// Read current endurance settings inside the existing vehicle loop.
if (isNil "kp_fuel_consumption_vehicles") then {
    kp_fuel_consumption_vehicles = [];
};

if (!((_this select 0) in kp_fuel_consumption_vehicles)) then {
    kp_fuel_consumption_vehicles pushBack (_this select 0);
    while {local (_this select 0)} do {
        if (isEngineOn (_this select 0)) then {
            if (speed (_this select 0) > 5) then {
                if (speed (_this select 0) > (getNumber (configOf (_this select 0) >> "maxSpeed") * 0.9)) then {
                    (_this select 0) setFuel (fuel (_this select 0) - (1 / (KP_liberation_fuel_max * 60)));
                } else {
                    (_this select 0) setFuel (fuel (_this select 0) - (1 / (KP_liberation_fuel_normal * 60)));
                };
            } else {
                (_this select 0) setFuel (fuel (_this select 0) - (1 / (KP_liberation_fuel_neutral * 60)));
            };
        };
        uiSleep 1;
    };
    kp_fuel_consumption_vehicles deleteAt (kp_fuel_consumption_vehicles find (_this select 0));
};
