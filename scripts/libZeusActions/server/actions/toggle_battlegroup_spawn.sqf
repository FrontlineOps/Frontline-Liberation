battlegroup_spawn_toggle_remote = {



	if(BATTLESPACE_BATTLEGROUPS_ALLOWED) then {
		BATTLESPACE_BATTLEGROUPS_ALLOWED = false;
	} else {
		GRLIB_last_battlegroup_time = diag_tickTime;
		BATTLESPACE_BATTLEGROUPS_ALLOWED = true;
	};

	publicVariable "BATTLESPACE_BATTLEGROUPS_ALLOWED";

	(format ["Battlegroup spawns toggled to %1", str BATTLESPACE_BATTLEGROUPS_ALLOWED]) remoteExec ["systemChat", remoteExecutedOwner];
	
};