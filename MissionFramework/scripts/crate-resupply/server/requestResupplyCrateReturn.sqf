

requestResupplyCrateReturn = {
	params ["_crate", "_returner"];

	private _cannotReturnStr = "You cannot return this crate";
	if (isNull _crate || {isNull _returner} || {!isPlayer _returner}) exitWith {};
	if !([_returner] call setResupplyFlags) exitWith {
		_cannotReturnStr remoteExec ["hint", owner _returner];
	};

	private _crateName = _crate getVariable "resupplyCrateName";

	private _crateSquadOwner = _crate getVariable "resupplySquadOwner";

	if (isNil { _crateSquadOwner }) exitWith {
		_cannotReturnStr remoteExec ["hint", owner _returner];
	};

	private _playerSquadName = [_returner] call getResupplyGroupKey;
	if (_playerSquadName isEqualTo "") exitWith {
		_cannotReturnStr remoteExec ["hint", owner _returner];
	};


	if(_crateSquadOwner == _playerSquadName) then {

		deleteVehicle _crate;

		format ["%1 Returned", _crateName] remoteExec ["hint", owner _returner];
	} else {
		_cannotReturnStr remoteExec ["hint", owner _returner];
	};
};
