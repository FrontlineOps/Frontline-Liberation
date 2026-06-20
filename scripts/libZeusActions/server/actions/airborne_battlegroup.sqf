airborne_battlegroup_remote = {
	params ["_objective"];
	private _scalingFactor = ([] call KPLIB_fnc_getOpforFactor);
	private _objectivePos = markerPos _objective;
	private _count = 2;
	// ~38 players
	if(_scalingFactor >= 0.65) then {
		_count = 3;
	};
	// ~60 players at 0.80 opfor factor
	if(_scalingFactor >= 0.80) then {
		_count = 4;
	};
	for "_i" from 1 to _count do {
		[_objectivePos, 4, 6] call send_paratroopers;
	};
	[_objectivePos] remoteExec ["remote_call_incoming"];
	[[_objectivePos] call KPLIB_fnc_getNearestBluforObjective] spawn spawn_air;
};