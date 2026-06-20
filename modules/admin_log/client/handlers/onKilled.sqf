[player, "Killed", {
	params ["_unit", "_killer"];
	if (!(side _unit isEqualTo side _killer) || _killer isEqualTo player) exitWith {};
	[
		format ["%1 (%2) killed %3 (%4)", name _killer, getPlayerUID _killer, name _unit, getPlayerUID _unit],
		"blueOnBlue"
	] remoteExec ["KC_ADMIN_LOG_EVENT", 2];
}, ""] call CBA_fnc_addBISEventHandler;



