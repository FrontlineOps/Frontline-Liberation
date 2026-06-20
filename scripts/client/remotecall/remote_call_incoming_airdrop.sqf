if ( isDedicated ) exitWith {};

params [ "_attack_destination" ];

if ( isNil "GRLIB_last_incoming_airdrop_notif_time" ) then { GRLIB_last_incoming_airdrop_notif_time = -9999 };

if ( time > GRLIB_last_incoming_airdrop_notif_time + 60 ) then {

    GRLIB_last_incoming_airdrop_notif_time = time;

    private [ "_attack_location_name" ];
    _attack_location_name = [_attack_destination] call KPLIB_fnc_getLocationName;

    [ "lib_incoming_airdrop", [ _attack_location_name ] ] call BIS_fnc_showNotification;

};
