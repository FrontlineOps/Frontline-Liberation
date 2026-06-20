params ["_player"];

if (isServer) then {
	[
		format [
			"%1 (%2) killed a civilian", 
			name _player, 
			getPlayerUID _player
			],
		"killedCivilian"
	] call KC_ADMIN_LOG_EVENT;
} else {
	[
		format [
			"%1 (%2) killed a civilian", 
			name _player, 
			getPlayerUID _player
			],
		"killedCivilian"
	] remoteExec ["KC_ADMIN_LOG_EVENT", 2];
};