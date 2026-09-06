onSupplyCrateSpawned = {
	params ["_supplyCrate", "_spawner", "_offset"];

	format ["OnSupplyCrateSpawned(%1, %2, %3)", _supplyCrate, _spawner, _offset];

	// Call ACE function stuff to carry for the spawner

	// Moved over to init on class
	[_supplyCrate, true, _offset, 0, true] call ace_dragging_fnc_setCarryable;
	
	[_supplyCrate, true, _offset, 0, true] call ace_dragging_fnc_setDraggable;

	if(_spawner == player) then {
		[_spawner, _supplyCrate] call ace_dragging_fnc_startCarry;
	};

	
	
};