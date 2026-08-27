
// Entries further on will override earlier matches. (Only really applicable to Butcher)
RoleArsenal_SubstrToRole = [
	["Odin", "Odin"],
	["Guide", "Guide"],
	["Company Commander", "CO"], //USED
	["Executive Officer", "XO"], //USED
	["TACP (Alpha)", "JFO"],
	["TACP (Bravo)", "JFO"],
	["TACP (Charlie)", "JFO"],
	["TACP (Delta)", "JFO"],
	["Platoon Commander", "PL"], //USED
	["RTO", "PLTO"],
	["Platoon Sergeant", "PSgt"], //USED
	["Squad Leader", "SL"], //USED
	["Fireteam Leader", "TL"], //USED
	["Team Leader", "TL"], //USED
	["Medic", "Medic"], //USED

	// Needs to be below medic to get proper kit. Otherwise it uses medic.
	["Platoon Medic", "PMed"], //USED
	["Banshee Team Lead", "BNTL"],
	["Banshee Medic", "BNM"],
	["Banshee Pilot", "BansheePilot"],
	["Grenadier", "Grenadier"], //USED
	["Rifleman", "Rifleman"], //USED
	["Automatic Rifleman", "ARifleman"], //USED
	["Scout/Marksman", "SMarksman"], //USED
	["Explosives Specialist", "ESpecialist"],
	["Machine Gunner", "MGunner"], //USED
	["Ammo Bearer", "ATAmmoBearer"], //USED
	["Goblin Medic", "MGoblin"],
	["Goblin Squad Leader", "SGoblin"],
	["Goblin Combat Engineer", "CGoblin"],
	["Goblin Team Leader", "TGoblin"],
	["Harpy 1 Team Leader", "HAAL"],
	["Asst. AA Specialist", "ASAA"], 
	["AA Specialist", "AAAS"],
	["AT Specialist", "ATSpec"], //USED
	["Asst. AT Specialist", "AsstAT"], //USED
	["Asst. Machine Gunner", "MGAmmoBearer"], //USED
	["Wraith Team Leader", "WTL"],
	["Wraith AT Specialist", "WATS"],
	["Wraith Asst. AT Specialist", "WAATS"],
	["Shade Team Leader", "ShadeTL"],
	["Shade Mortarman","ShadeM"],
	["Shadow Team Leader", "ShadowTL"],
	["Shadow Echo", "ShadowE"],
	["Scout/SO", "FoxSniper"], //USED
	["Scout/JO", "FoxSpotter"], //USED
	["Scout", "FoxScout"], //USED
	["Ogre Team Leader", "OgreTL"],
	["Ogre Medic", "OgreMedic"],
	["Combat Engineer", "CE"], //USED
	["Vehicle Driver", "ButcherDriver"],
	["Vehicle Gunner", "ButcherGunner"],
	["Vehicle Commander", "ButcherCommander"],
	["Scout/Mortarman", "Mortarman"], //USED
	["Savage Gunner", "Savage"],
	["Hermes", "Hermes"],
	["Chevy", "Chevy"],
	["Hades", "Hades"], //USED
	["Reaper", "Reaper"]
];
RoleArsenal_DetermineRole = {
	params ["_player"];

	// Work out which role the player is playing
	private _roleDesc = roleDescription _player;
	private _playerRole = "";
	{
		_x params ["_pattern", "_role"];

		if(_roleDesc find _pattern > -1) then {
			_playerRole = _role;
		};
	} forEach RoleArsenal_SubstrToRole;
	
	// Allow admins to override for testing purposes
	if ((count DEBUG_ARSENAL_ROLE_OVERRIDE) > 0) then {
		_playerRole = DEBUG_ARSENAL_ROLE_OVERRIDE;
	};

	_playerRole
};
