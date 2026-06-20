mechanized_battlegroup_remote = {
	params ["_objective"];
	[_objective, false, true] spawn spawn_battlegroup;
};