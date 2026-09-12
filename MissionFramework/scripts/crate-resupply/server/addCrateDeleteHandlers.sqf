addCrateDeleteHandlers = {
    params ["_crate"];

    [_crate, "Deleted", {
        private _crate = _this select 0;

        format ["Handle deleted event %1", _crate] call resupplyLog;
		
        private _registry = localNamespace getVariable "KPLIB_resupplyRegistry";
        private _record = _registry getOrDefault [netId _crate, []];
        if (_record isEqualTo []) exitWith {};
        private _squadOwner = _record select 1;
        _registry deleteAt (netId _crate);

        private _squadAllocation = localNamespace getVariable _squadOwner;

        if(isNil { _squadAllocation }) exitWith {
            format ["A crate was deleted with squadOwner set to %1 but squad allocation does not exist in missionNamespace???", _squadOwner] call resupplyLog;
        };

        private _currentCrates = _squadAllocation get "Crates";

        if (isNil { _currentCrates } ) exitWith {
            format [" A crate was deleted with squadOwner set to %1, squad allocation exists, but crates is not defined. %2", _squadOwner, _squadAllocation] call resupplyLog;
        };

        private _currentCrateObjects = _squadAllocation get "CrateObjects";

        _currentCrateObjects = _currentCrateObjects - [_crate];

        _currentCrates = 0 max (_currentCrates - 1);

        _squadAllocation set ["Crates", _currentCrates];
        _squadAllocation set ["CrateObjects", _currentCrateObjects];

        missionNamespace setVariable [_squadOwner, _squadAllocation, true];

        format ["Deleted, set %1 to have %2", _squadOwner, _currentCrates] call resupplyLog;

    }] call CBA_fnc_addBISEventHandler;
};
