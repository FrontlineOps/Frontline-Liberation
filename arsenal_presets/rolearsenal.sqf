// Function Parms
// [0] = Arsenal Object
// [1] = Player 
// Usage:
// [_box, _player] call roleArsenal;

[] call compileFinal preprocessFileLineNumbers "arsenal_presets\rolearsenal_config_TheUSMC2023.sqf";
[] call compileFinal preprocessFileLineNumbers "arsenal_presets\determineRole.sqf";

roleArsenal = {
	params ["_box", "_player"];

	//diag_log "[Watergard] - Entered Role Restricted Arsenal Script";


	// Clear the inventory
	clearMagazineCargoGlobal _box;
	clearItemCargoGlobal _box;
	clearBackpackCargoGlobal _box;
	clearWeaponCargoGlobal _box;

	private _role = [_player] call RoleArsenal_DetermineRole;

	private _GearToAdd = [_role] call RoleArsenal_DetermineGear;

	diag_log [format ["[Watergard] - Entered Role Arsenal - %1", _role]];
	
	[_box, false] call ace_arsenal_fnc_removeBox;
	[_box, _GearToAdd, false] call ace_arsenal_fnc_initBox;
}