params [
	["_player", objNull, [objNull]],
	["_distance", 20, [0]]
];

if (isNull _player) exitWith { false };

private _pbs = [];
private _isNearPB = false;

if (side player == GRLIB_side_friendly) then {
	_pbs = missionnamespace getvariable [ "GRLIB_all_cops", [] ];
};

if (side _player == GRLIB_side_enemy) then {
    _pbs = missionnamespace getvariable [ "OPFOR_all_cops", [] ];
};

{
	if ((markerPos _x) distance _player <= _distance) then {
		_isNearPB = true;
	};
} forEach _pbs;

_isNearPB