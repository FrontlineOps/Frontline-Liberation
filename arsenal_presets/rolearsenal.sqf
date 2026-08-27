// Function Parms
// [0] = Arsenal Object
// [1] = Player 
// Usage:
// [_box, _player] call roleArsenal;

[] call compileFinal preprocessFileLineNumbers "arsenal_presets\determineRole.sqf";

RA_FullArsenal = +(missionNamespace getVariable ["KPLIB_autoFactionPlayerArsenal", []]);
RA_AllAmmoTypes = +((missionNamespace getVariable ["KPLIB_autoFactionPlayerArsenalData", createHashMap]) getOrDefault ["magazines", []]);
RA_StartingUniforms = +(missionNamespace getVariable ["KPLIB_autoFactionPlayerUniforms", []]);
RA_StartingHeadwear = +(missionNamespace getVariable ["KPLIB_autoFactionPlayerHeadgear", []]);
RA_StartingGoggles = +(missionNamespace getVariable ["KPLIB_autoFactionPlayerGoggles", []]);
RA_StartingItems = +(missionNamespace getVariable ["KPLIB_autoFactionPlayerStartingItems", []]);

if (RA_FullArsenal isEqualTo [] || {RA_StartingUniforms isEqualTo []}) then {
    private _message = "Generated BLUFOR arsenal or starting uniforms are empty; automatic faction initialization cannot continue";
    [_message, "FACTIONS"] call KPLIB_fnc_log;
    throw _message;
};

RoleArsenal_DetermineGear = {
    +(missionNamespace getVariable ["KPLIB_autoFactionPlayerArsenal", []])
};

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
	private _faction = toLower getText (configFile >> "CfgVehicles" >> (typeOf _player) >> "faction");
	private _arsenals = missionNamespace getVariable ["KPLIB_autoFactionArsenalByFaction", createHashMap];
	_GearToAdd = +(_arsenals getOrDefault [_faction, missionNamespace getVariable ["KPLIB_autoFactionPlayerArsenal", []]]);

	diag_log [format ["[Watergard] - Entered Role Arsenal - %1", _role]];
	
	[_box, false] call ace_arsenal_fnc_removeBox;
	[_box, _GearToAdd, false] call ace_arsenal_fnc_initBox;
};
