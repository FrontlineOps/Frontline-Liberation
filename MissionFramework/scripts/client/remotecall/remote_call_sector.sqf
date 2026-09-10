if ( isDedicated ) exitWith {};


params [ "_sector", "_status" ];

if (_status == 0 && {!(_sector in sectors_factory)}) then {
    [ "lib_sector_captured", [ markerText _sector ] ] call BIS_fnc_showNotification;
};

if ( _status == 1 ) then {
    [ "lib_sector_attacked", [ markerText _sector ] ] call BIS_fnc_showNotification;
};

if ( _status == 2 ) then {
    [ "lib_sector_lost", [ markerText _sector ] ] call BIS_fnc_showNotification;
};

if ( _status == 3 ) then {
    [ "lib_sector_safe", [ markerText _sector ] ] call BIS_fnc_showNotification;
};

{ _x setMarkerColorLocal GRLIB_color_enemy; } foreach (sectors_allSectors - blufor_sectors);
{ _x setMarkerColorLocal GRLIB_color_friendly; } foreach blufor_sectors;
