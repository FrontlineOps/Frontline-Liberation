player addEventHandler ["GetInMan", {
	params ["_unit", "_role", "_vehicle", "_turret"];
	private _playerSideNumber;
	switch (true) do
	{
		case (side player == EAST) : {_playerSideNumber = 0;};
		case (side player == WEST) : {_playerSideNumber = 1;};
		case (side player == RESISTANCE) : {_playerSideNumber = 2;};
		case (side player == CIVILIAN) : {_playerSideNumber = 3;};
	};
	if (getNumber(configfile >> "CfgVehicles" >> typeOf _vehicle >> "side") == _playerSideNumber) exitWith {};
	[
		format ["%1 (%2) got into enemy vehicle: %3", name _unit, getPlayerUID _unit, getText (configFile >> "CfgVehicles" >> (typeOf _vehicle) >> "displayName")],
		"enteredEnemyVehicle"
	] remoteExec ["KC_ADMIN_LOG_EVENT", 2];
}];