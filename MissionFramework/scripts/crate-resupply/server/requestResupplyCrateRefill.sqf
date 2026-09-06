requestResupplyCrateRefill = {
    params ["_crate", "_refiller"];

    private _cannotResupplyStr = "You cannot refill this crate";
    if (isNull _crate || {isNull _refiller} || {!isPlayer _refiller}) exitWith {};
    if !([_refiller] call setResupplyFlags) exitWith {
        _cannotResupplyStr remoteExec ["hint", owner _refiller];
    };

    private _crateSquadOwner = _crate getVariable "resupplySquadOwner";
    private _crateSquadFlag = _crate getVariable ["resupplySquadFlag", "AUTO"];
    if (isNil {_crateSquadOwner}) exitWith {
        _cannotResupplyStr remoteExec ["hint", owner _refiller];
    };

    private _playerSquadName = [_refiller] call getResupplyGroupKey;
    if (_playerSquadName isEqualTo "") exitWith {
        _cannotResupplyStr remoteExec ["hint", owner _refiller];
    };

    private _playerSquadFlag = _refiller getVariable ["resupplySquadGroupFlag", "AUTO"];
    private _squadDefinition = ResupplyCrateAllocations getOrDefault [_playerSquadFlag, createHashMap];
    private _globalResupplier = _squadDefinition getOrDefault ["Resupplier", false];
    if (_crateSquadOwner != _playerSquadName && {!_globalResupplier}) exitWith {
        _cannotResupplyStr remoteExec ["hint", owner _refiller];
    };

    private _crateName = _crate getVariable "resupplyCrateName";
    private _crateInfo = ResupplyCrates get _crateName;
    if (isNil {_crateInfo}) exitWith {
        _cannotResupplyStr remoteExec ["hint", owner _refiller];
    };

    private _specialtyCost = _crateInfo getOrDefault ["SpecialtyCost", 0];
    if (_specialtyCost <= 0) exitWith {
        [_crate] call fillResupplyCrate;
        format ["%1 Refilled", _crateName] remoteExec ["hint", owner _refiller];
    };

    private _currentAllocations = missionNamespace getVariable _crateSquadOwner;
    if (isNil {_currentAllocations}) exitWith {
        _cannotResupplyStr remoteExec ["hint", owner _refiller];
    };

    private _currentSpecialtyResources = _currentAllocations getOrDefault ["SpecialtyResources", 0];
    if ((_currentSpecialtyResources - _specialtyCost) < 0) exitWith {
        "Not enough specialty resources to refill this crate" remoteExec ["hint", owner _refiller];
    };

    [_crate] call fillResupplyCrate;

    private _missionTime = CBA_missionTime;
    _currentAllocations set ["SpecialtyResources", _currentSpecialtyResources - _specialtyCost];
    _currentAllocations set ["ResetTime", _missionTime + ResupplyDefaultSpecialtyCooldown];
    missionNamespace setVariable [_crateSquadOwner, _currentAllocations, true];

    private _allocationDefinition = ResupplyCrateAllocations getOrDefault [_crateSquadFlag, createHashMap];
    private _maxSpecialtyResources = _allocationDefinition getOrDefault ["SpecialtyAllocations", 0];
    [loopAndAddSpecialtyResources, [_crateSquadOwner, _maxSpecialtyResources], ResupplyDefaultSpecialtyCooldown] call CBA_fnc_waitAndExecute;

    format ["%1 Refilled", _crateName] remoteExec ["hint", owner _refiller];
};
