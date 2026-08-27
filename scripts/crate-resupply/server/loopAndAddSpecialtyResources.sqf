loopAndAddSpecialtyResources = {
	params ["_squadName", "_maxSpecialtyResources"];

	format ["LoopAndAddSpecialtyResources(%1, %2)", _squadName, _maxSpecialtyResources];

	private _currentAllocations = missionNamespace getVariable _squadName;
	if (isNil {_currentAllocations}) exitWith {};

	private _currentSpecialtyResources = _currentAllocations getOrDefault ["SpecialtyResources", 0];

	

	if(_currentSpecialtyResources < _maxSpecialtyResources) then {
		_currentSpecialtyResources = _currentSpecialtyResources + 1;
		_currentAllocations set ["SpecialtyResources", _currentSpecialtyResources];

		missionNamespace setVariable [_squadName, _currentAllocations, true];

		if(_currentSpecialtyResources < _maxSpecialtyResources) then {
			[loopAndAddSpecialtyResources, [_squadName, _maxSpecialtyResources], ResupplyDefaultSpecialtyCooldown] call CBA_fnc_waitAndExecute;
		};
	};
};
