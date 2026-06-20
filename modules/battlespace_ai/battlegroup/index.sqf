
BATTLESPACE_BATTLEGROUP_LOOP = {
	(_this select 0) params ["_nextTick", "_groups", "_state"];
	_state params ["_assignedTarget", "_nextArtilleryCall", "_artilleryAccuracy", ["_lastKnowAbouts", []]];

	if(_nextTick > diag_tickTime) exitWith {};
	private _knowAboutStale = false;

	if((count _lastKnowAbouts) > 0) then {
		{

			private _knowAboutData = _x;

			private _timestamp = _knowAboutData get "When";

			if(_timestamp < (diag_tickTime - 30)) exitWith {
				_knowAboutStale = true;
			};
		} forEach _lastKnowAbouts;
	} else {
		_knowAboutStale = true;
	};

	if(_knowAboutStale) exitWith {
		[_groups] remoteExec ["BATTLESPACE_REPORT_KNOWABOUT", 0];
		(_this select 0) set [0, diag_tickTime + 5];
	};


	
	// Every minute?
	(_this select 0) set [0, diag_tickTime + 60];
	// knowsAbout must be ran locally so we just have a faster tick after we tell group owners to query for knowsAbout and return the data to us.
	// Why not multiple loops? Desync as well as increased complexity due to potential of group owners being swapped around.
};