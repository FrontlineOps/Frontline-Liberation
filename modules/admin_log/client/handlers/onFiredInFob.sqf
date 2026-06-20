lastReport = 0;
player addEventHandler ["Fired", {
	params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_gunner"];
	if (time - lastReport < 5) exitWith {};
	private _nearestFob = [player getVariable ["KPLIB_fobDist", 101], player getVariable ["KPLIB_fobName", "undefined"]];
	if (_nearestFob#0 > 125) exitWith {};
	if (count ((player nearEntities ["Man", 250]) select {side _x != side player}) > 0) exitWith {}; 
	[
		format ["%1 (%2) fired %3: %4m from %5", name _unit, getPlayerUID _unit, getText (configfile >> "CfgWeapons" >> _weapon >> "displayName"), floor (_nearestFob#0), _nearestFob#1],
		"firedInFob"
	] remoteExec ["KC_ADMIN_LOG_EVENT", 2];
	lastReport = time;
}];