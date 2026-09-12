requestResupplyCrateRefill = {
    params [["_crate", objNull, [objNull]], ["_refiller", objNull, [objNull]]];
    if !([_refiller, "refill", _crate] call KPLIB_fnc_validateResupplyRequest) exitWith {};

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
    private _squadDefinition = (localNamespace getVariable "KPLIB_resupplyAllocations") getOrDefault [_playerSquadFlag, createHashMap];
    private _globalResupplier = _squadDefinition getOrDefault ["Resupplier", false];
    if (_crateSquadOwner != _playerSquadName && {!_globalResupplier}) exitWith {
        _cannotResupplyStr remoteExec ["hint", owner _refiller];
    };

    private _crateName = _crate getVariable "resupplyCrateName";
    private _crateInfo = (localNamespace getVariable "KPLIB_resupplyDefinitions") get _crateName;
    if (isNil {_crateInfo}) exitWith {
        _cannotResupplyStr remoteExec ["hint", owner _refiller];
    };

    private _specialtyCost = _crateInfo getOrDefault ["SpecialtyCost", 0];
    if (_specialtyCost <= 0) exitWith {
        [_crate] call (localNamespace getVariable "KPLIB_fillResupplyCrate");
        [_playerSquadName, _crateName] call (localNamespace getVariable "KPLIB_startCrateCooldown");
        format ["%1 Refilled", _crateName] remoteExec ["hint", owner _refiller];
    };

    private _currentAllocations = localNamespace getVariable _crateSquadOwner;
    if (isNil {_currentAllocations}) exitWith {
        _cannotResupplyStr remoteExec ["hint", owner _refiller];
    };

    private _currentSpecialtyResources = _currentAllocations getOrDefault ["SpecialtyResources", 0];
    if ((_currentSpecialtyResources - _specialtyCost) < 0) exitWith {
        "Not enough specialty resources to refill this crate" remoteExec ["hint", owner _refiller];
    };

    [_crate] call (localNamespace getVariable "KPLIB_fillResupplyCrate");
    [_playerSquadName, _crateName] call (localNamespace getVariable "KPLIB_startCrateCooldown");

    private _missionTime = CBA_missionTime;
    _currentAllocations set ["SpecialtyResources", _currentSpecialtyResources - _specialtyCost];
    _currentAllocations set ["ResetTime", _missionTime + (localNamespace getVariable "KPLIB_ResupplyDefaultSpecialtyCooldown")];
    localNamespace setVariable [_crateSquadOwner, _currentAllocations];
    missionNamespace setVariable [_crateSquadOwner, _currentAllocations, true];

    private _maxSpecialtyResources = _currentAllocations getOrDefault ["SpecialtyLimit", 0];
    [_crateSquadOwner, _maxSpecialtyResources] call (localNamespace getVariable "KPLIB_scheduleSpecialtyRecharge");

    format ["%1 Refilled", _crateName] remoteExec ["hint", owner _refiller];
};
