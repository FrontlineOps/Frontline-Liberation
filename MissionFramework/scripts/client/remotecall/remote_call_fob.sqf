if ( isDedicated ) exitWith {};


params [ "_fob", "_status" ];
private [ "_fobname" ];

_fobname = [_fob] call KPLIB_fnc_getFobName;

if ( _status == 0 ) then {
    [ "lib_fob_built", [ _fobname ] ] call BIS_fnc_showNotification;
};

if ( _status == 1 ) then {
    [ "lib_fob_attacked", [ _fobname ] ] call BIS_fnc_showNotification;
};

if ( _status == 2 ) then {
    [ "lib_fob_lost", [ _fobname ] ] call BIS_fnc_showNotification;
};

if ( _status == 3 ) then {
    [ "lib_fob_safe", [ _fobname ] ] call BIS_fnc_showNotification;
};
