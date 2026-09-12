loopAndAddSpecialtyResources = {
    params ["_squadName", "_maxSpecialtyResources"];
    if (!isServer || {isRemoteExecuted && {remoteExecutedOwner != 2}}) exitWith {};

    format ["LoopAndAddSpecialtyResources(%1, %2)", _squadName, _maxSpecialtyResources];

    private _currentAllocations = localNamespace getVariable _squadName;
    if (isNil {_currentAllocations}) exitWith {};
    _currentAllocations set ["SpecialtyRechargeActive", false];

    private _currentSpecialtyResources = _currentAllocations getOrDefault ["SpecialtyResources", 0];

	

    if(_currentSpecialtyResources < _maxSpecialtyResources) then {
        _currentSpecialtyResources = _currentSpecialtyResources + 1;
        _currentAllocations set ["SpecialtyResources", _currentSpecialtyResources];

        missionNamespace setVariable [_squadName, _currentAllocations, true];

        if(_currentSpecialtyResources < _maxSpecialtyResources) then {
            [_squadName, _maxSpecialtyResources] call (localNamespace getVariable "KPLIB_scheduleSpecialtyRecharge");
        };
    };
};

localNamespace setVariable ["KPLIB_scheduleSpecialtyRecharge", {
    params ["_groupKey", "_maximum"];
    private _allocation = localNamespace getVariable _groupKey;
    if (_allocation getOrDefault ["SpecialtyRechargeActive", false]) exitWith {};
    _allocation set ["SpecialtyRechargeActive", true];
    [loopAndAddSpecialtyResources, [_groupKey, _maximum], (localNamespace getVariable "KPLIB_ResupplyDefaultSpecialtyCooldown")] call CBA_fnc_waitAndExecute;
}];
