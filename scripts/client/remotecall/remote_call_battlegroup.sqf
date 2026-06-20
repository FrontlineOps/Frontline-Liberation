if ( isDedicated ) exitWith {};
if (!GRLIB_battlegroup_Show_Spawn_Location) exitWith {};

params [ "_battlegroup_position" ];


private _pos = markerPos _battlegroup_position;


private _offsetPos = _pos vectorAdd [-999 + (random 1999), -999 + (random 1999), 0];
"opfor_bg_marker" setMarkerPosLocal ( _offsetPos );
"opfor_bg_marker" setMarkerShapeLocal "ELLIPSE";
"opfor_bg_marker" setMarkerColorLocal "ColorEAST";
"opfor_bg_marker" setMarkerSize [1000,1000];
"opfor_bg_marker" setMarkerBrush "BDiagonal";

[ "lib_battlegroup", [ markerText ( [ 100, markerPos _battlegroup_position ] call KPLIB_fnc_getNearestSector ) ] ] call BIS_fnc_showNotification;

sleep 600;

"opfor_bg_marker" setMarkerPosLocal markers_reset;
