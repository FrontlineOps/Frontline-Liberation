params [["_veh", objNull, [objNull]], ["_caller", player, [objNull]]];

if (isNull _veh || {!alive _caller} || {!(_caller getUnitTrait "Engineer")}) exitWith {};

_veh setpos [(getpos _veh) select 0, (getpos _veh) select 1, 0.5];
_veh setVectorUp surfaceNormal position _veh;
