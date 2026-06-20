directed_battlegroup_remote = {
	params ["_spawn", "_objective", "_isMechanized"];

	format ["%1 | %2 | %3", str _spawn, str _isMechanized, str _objective] remoteExec ["systemChat", remoteExecutedOwner];
	[_spawn, !_isMechanized, true, _objective] spawn spawn_battlegroup;
};