params [
	["_markerPos", [0, 0, 0], [[2, 3]]],
	["_canSpawnAtCOP", false, [false]],
	["_pbIDX", 0, [0]],
	["_side", west, [west]]
];

private _pbMarkerName = format ["%1PB%2",_side, _pbIDX];

private _markerPB = createMarker [_pbMarkerName, _markerPos, 1];

if (_markerPB == "") then {
    _markerPB = _pbMarkerName;
};

_markerPB setMarkerText "PB";
_markerPB setMarkerType "b_support";

if (_canSpawnAtCOP) then {
	if (_side == GRLIB_side_friendly) then {
		_markerPB setMarkerColor "colorBLUFOR";
		GRLIB_all_cops pushBackUnique _markerPB;
		publicVariable "GRLIB_all_cops";
	} else {
		_markerPB setMarkerColor "colorOPFOR";
		OPFOR_all_cops pushBackUnique _markerPB;
		publicVariable "OPFOR_all_cops";
	};
};