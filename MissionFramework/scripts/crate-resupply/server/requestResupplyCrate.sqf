requestResupplyCrate = {
	params ["_requester", "_crateName"];

	if (isNull _requester || {!isPlayer _requester}) exitWith {};
	if !([_requester] call setResupplyFlags) exitWith {};

	format ["RequestResupplyCrate (%1, %2)", _requester, _crateName] call resupplyLog;
	private _crateInfo = ResupplyCrates get _crateName;
	if (isNil {_crateInfo}) exitWith {
		format ["Rejected unknown crate definition %1 from %2", _crateName, _requester] call resupplyLog;
		"Unknown resupply crate" remoteExec ["hint", owner _requester];
	};

	private _squadFlag = _requester getVariable "resupplySquadGroupFlag";
	private _squadName = [_requester] call getResupplyGroupKey;
	private _squadRoles = _requester getVariable ["resupplySquadRoleFlags", []];
	private _allowedCrates = [_requester] call getCompatibleCratesForPlayer;

	private _category = _crateInfo getOrDefault ["Category", "Faction Supplies"];
	private _allowed = _crateName in (_allowedCrates getOrDefault [_category, []]);

	if(!_allowed) exitWith {
		format ["Someone tried to request a %1 crate despite not having permissions... Compatibles: %2; Squad Flag %3 Squad Name %4 Roles Assigned %5", _crateName, _allowedCrates, _squadFlag, _squadName, _squadRoles] call resupplyLog;
		format ["You're not allowed to grab %1", _crateName] remoteExec ["hint", owner _requester];
	};

	

	private _specialtyCost = _crateInfo getOrDefault ["SpecialtyCost", 0];

	private _isSpecialCrate = _specialtyCost > 0;

	private _currentAllocations = missionNamespace getVariable _squadName;

	if ( isNil { _currentAllocations } ) exitWith {
		format ["Someone tried to request a %1 crate, allocations are not set up for their squad... Compatibles: %2; Squad Flag %3 Squad Name %4 Roles Assigned %5", _crateName, _allowedCrates, _squadFlag, _squadName, _squadRoles] call resupplyLog;
		format ["You're not allowed to grab %1", _crateName] remoteExec ["hint", owner _requester];
	};
	private _currentSpecialtyResources = _currentAllocations get "SpecialtyResources";
	_allowed = true;
	if(_isSpecialCrate) then {
		if((_currentSpecialtyResources - _specialtyCost) < 0) exitWith {
			_allowed = false;
		};
	};

	if(!_allowed) exitWith {
		format ["Not enough specialty resources to grab this crate"] remoteExec ["hint", owner _requester];
	};

	private _currentCrates = _currentAllocations get "Crates";

	_currentCrates = 0 max _currentCrates;
	private _maxCrates = [group _requester] call getResupplyGroupCrateLimit;

	if ( _currentCrates >= _maxCrates ) exitWith {
		format ["Max crates for your squad has been reached"] remoteExec ["hint", owner _requester];
	};




	// Can spawn then.

	private _model = _crateInfo getOrDefault ["Model", "Box_NATO_Ammo_F"];

	private _offset = _crateInfo getOrDefault ["Offset", [0, 1, 1]];

	if ( isNil { _offset }) then {
		_offset = [0, 1, 1];
	};

	private _crate = createVehicle [_model, getPosATL _requester, [], 0, "CAN_COLLIDE"];

	
	[_crate, 300] remoteExec ["setMass", 0];
	[_crate, "HandleDamage", {false}] call CBA_fnc_addBISEventHandler;
	_crate setVariable ["resupplyCrateName", _crateName, true];
	_crate setVariable ["resupplySquadOwner", _squadName, true];
	_crate setVariable ["resupplySquadOwnerDisplay", groupId (group _requester), true];
	_crate setVariable ["resupplySquadFlag", _squadFlag, true];

	[_crate] call fillResupplyCrate;
	[_crate] call addCrateDeleteHandlers;

	_currentAllocations set ["Crates", _currentCrates + 1];

	private _currentCrateObjects = _currentAllocations get "CrateObjects";

	_currentCrateObjects pushBack _crate;

	_currentAllocations set ["CrateObjects", _currentCrateObjects];

	if(_isSpecialCrate) then {
		private _allocationDefinition = ResupplyCrateAllocations getOrDefault [_squadFlag, createHashMap];
		private _maxSpecialtyResources = _allocationDefinition getOrDefault ["SpecialtyAllocations", 0];

		private _missionTime = CBA_missionTime;

		format ["Mission Time is %1, setting Reset to %2", _missionTime, _missionTime + ResupplyDefaultSpecialtyCooldown] call resupplyLog;
		_currentAllocations set ["SpecialtyResources", _currentSpecialtyResources - _specialtyCost];
		_currentAllocations set ["ResetTime", _missionTime + ResupplyDefaultSpecialtyCooldown];

		

		
		[loopAndAddSpecialtyResources, [_squadName, _maxSpecialtyResources], ResupplyDefaultSpecialtyCooldown] call CBA_fnc_waitAndExecute;
		
	};

	missionNamespace setVariable [_squadName, _currentAllocations, true];

	

	[_crate, _requester, _offset] remoteExec ["onSupplyCrateSpawned", 0];

	
	
	

};
