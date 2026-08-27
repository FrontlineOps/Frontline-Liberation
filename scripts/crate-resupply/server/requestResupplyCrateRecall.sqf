requestResupplyCrateRecall = {
    params ["_source", "_recaller"];

    private _cannotRecallStr = "You cannot recall";
    if (isNull _recaller || {!isPlayer _recaller}) exitWith {};
    if !([_recaller] call setResupplyFlags) exitWith {
        _cannotRecallStr remoteExec ["hint", owner _recaller];
    };

    private _playerSquadName = [_recaller] call getResupplyGroupKey;
    if (_playerSquadName isEqualTo "") exitWith {
        _cannotRecallStr remoteExec ["hint", owner _recaller];
    };

    private _currentAllocations = missionNamespace getVariable _playerSquadName;
    if (isNil {_currentAllocations}) exitWith {
        _cannotRecallStr remoteExec ["hint", owner _recaller];
    };

    private _currentCrates = _currentAllocations getOrDefault ["Crates", 0];
    if (_currentCrates <= 0) exitWith {
        _cannotRecallStr remoteExec ["hint", owner _recaller];
    };

    private _isAbleToRecall = _currentAllocations getOrDefault ["CanReset", true];
    if (!_isAbleToRecall) exitWith {
        _cannotRecallStr remoteExec ["hint", owner _recaller];
    };

    private _currentCrateObjects = _currentAllocations getOrDefault ["CrateObjects", []];
    {
        if (!isNull _x) then {
            deleteVehicle _x;
        };
    } forEach _currentCrateObjects;

    _currentAllocations set ["Crates", 0];
    _currentAllocations set ["CrateObjects", []];
    _currentAllocations set ["CanReset", false];
    _currentAllocations set ["RecallResetTime", CBA_missionTime + ResupplyDefaultRecallCooldown];

    [{
        params ["_squadName"];
        private _allocations = missionNamespace getVariable _squadName;
        if (isNil {_allocations}) exitWith {};

        _allocations set ["CanReset", true];
        missionNamespace setVariable [_squadName, _allocations, true];
    }, [_playerSquadName], ResupplyDefaultRecallCooldown] call CBA_fnc_waitAndExecute;

    missionNamespace setVariable [_playerSquadName, _currentAllocations, true];
    "Crates Recalled" remoteExec ["hint", owner _recaller];
};
