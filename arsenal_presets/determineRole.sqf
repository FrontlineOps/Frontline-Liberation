
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

RoleArsenal_DetermineGear = {
	params ["_role"];

	private _GearToAdd = [];
	switch (_role) do {
	
	// ---------------------------------- COMPANYHQ ----------------------------------
	  case "Odin": {
		_GearToAdd = RA_Drip + RA_InfWeaps + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_InfGear + RA_Boonies + RA_CO + RA_Grenadier + RA_SL + RA_Phantom + RA_ARifleman + RA_JFO + RA_PL + PMed + RA_Reaper + RA_Stalker + RA_ShemaghMasks + RA_Baseballcaps + RA_TierStuff + RA_LongRangeBackpacks;
	  };
	  case "CO": {
	    _GearToAdd = RA_Drip + RA_InfWeaps + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_InfGear + RA_Boonies + RA_LongRangeBackpacks + RA_Baseballcaps + RA_TierStuff + RA_CO;
	  };
	   case "Guide": {
	    _GearToAdd = RA_InfGear + RA_Boonies + RA_LongRangeBackpacks + RA_Baseballcaps + RA_TierStuff;
	  };
	  case "XO": {
	    _GearToAdd = RA_Drip + RA_InfWeaps + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_InfGear + RA_Boonies + RA_LongRangeBackpacks + RA_Baseballcaps + RA_TierStuff + RA_XO;
	  };
	  case "JFO": {
	    _GearToAdd = RA_Drip + RA_InfWeaps + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_InfGear + RA_ShemaghMasks + RA_Baseballcaps + RA_TierStuff + RA_LongRangeBackpacks + RA_JFO;
	// ---------------------------------ShadowISR ------------------------------------
	  };
	  case "ShadowTL":{
	    _GearToAdd = RA_Drip + RA_InfWeaps + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_InfGear + RA_Boonies + RA_ShemaghMasks + RA_Baseballcaps + RA_TierStuff + RA_LongRangeBackpacks + RA_Shadow;
	  };
	  case "ShadowE":{
	    _GearToAdd = RA_Drip + RA_InfWeaps + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_InfGear + RA_Boonies + RA_ShemaghMasks + RA_Baseballcaps + RA_TierStuff + RA_LongRangeBackpacks + RA_Shadow;
	  };

	// ---------------------------------- PLATOONHQ ----------------------------------
	  case "PL": {
	    _GearToAdd = RA_Drip + RA_InfWeaps + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_InfGear + RA_ShemaghMasks + RA_TierStuff + RA_LongRangeBackpacks + RA_PL;
	  };
	  case "PLTO": {
	    _GearToAdd = RA_Drip + RA_InfWeaps + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_InfGear + RA_ShemaghMasks + RA_TierStuff + RA_LongRangeBackpacks + RA_PL;
	  };
	  case "PSgt": {
	    _GearToAdd = RA_Drip + RA_InfWeaps + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_InfWeapsAttachments + RA_InfGear + RA_ShemaghMasks + RA_TierStuff + RA_LongRangeBackpacks + RA_PSgt;
	  };
	  case "PMed": {
		_GearToAdd = RA_Drip + RA_InfWeaps + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_InfGear + RA_LongRangeBackpacks + RA_ShemaghMasks + RA_TierStuff + RA_PLMed;
	  };
	// ---------------------------------- BANSHEE ----------------------------------
	  case "BNTL": {
		_GearToAdd = RA_Drip + RA_InfWeaps + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_InfGear + RA_ShemaghMasks + RA_Boonies + RA_InfWeapsAmmo + RA_BansheeM + RA_BansheeTL + RA_LongRangeBackpacks;
	  };
	  case "BNM": {
		_GearToAdd = RA_Drip + RA_InfWeaps + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_InfGear + RA_ShemaghMasks + RA_Boonies + RA_InfWeapsAmmo + RA_BansheeM + RA_InfBackpacks;
	  };
	   case "BansheePilot": {
		_GearToAdd = RA_Drip + RA_InfGear + RA_LongRangeBackpacks + RA_Stalker;
	  };
	// ---------------------------------- INFANTRY ----------------------------------
	  case "SL": {
	    _GearToAdd = RA_Drip + RA_InfWeaps + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_InfGear + RA_ShemaghMasks + RA_LongRangeBackpacks + RA_TierStuff + RA_SL;
	  };
	  case "TL": {
	    _GearToAdd = RA_Drip + RA_InfWeaps + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_ShemaghMasks + RA_InfGear + RA_LongRangeBackpacks + RA_TierStuff + RA_TL;
	  };
	  case "Medic": {
	    _GearToAdd = RA_Drip + RA_InfWeaps + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_InfGear + RA_TierStuff + RA_Medic;
	  };
	  case "Grenadier": {
	    _GearToAdd = RA_Drip + RA_InfWeaps + RA_InfGear + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_InfGear + RA_ShemaghMasks + RA_TierStuff + RA_Grenadier;
	  };
	  case "ARifleman": {
	    _GearToAdd = RA_Drip + RA_InfGear + RA_ShemaghMasks + RA_TierStuff + RA_ARifleman;
	  };
	  case "SMarksman": {
	    _GearToAdd = RA_Drip + RA_InfGear + RA_InfWeaps + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_ShemaghMasks + RA_TierStuff + RA_DMarksman;
	  };
	  case "Rifleman": {
	    _GearToAdd = RA_Drip + RA_InfWeaps + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_InfGear + RA_TierStuff + RA_Rifleman;
	  };
	  case "ESpecialist": {
	    _GearToAdd = RA_Drip + RA_InfWeaps + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_InfGear + RA_TierStuff + RA_ESpecialist;
	  };
	// ---------------------------------- HARPY ------------------------------------
	 case "HAAL": {
	    _GearToAdd = RA_Drip + RA_InfWeaps + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_ShemaghMasks + RA_InfGear + RA_LongRangeBackpacks + RA_TierStuff + RA_TL;
	  };
	  case "AAAS": {
	    _GearToAdd = RA_Drip + RA_InfWeaps + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_ShemaghMasks + RA_TierStuff + RA_InfGear + RA_ATSpec;
	  };
	  case "ASAA": {
	    _GearToAdd = RA_Drip + RA_InfWeaps + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_ShemaghMasks + RA_TierStuff + RA_InfGear + RA_ATSpec;
	  };
	// ---------------------------------- WEAPONS ----------------------------------
	  case "MGunner": {
	    _GearToAdd = RA_Drip + RA_InfGear + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_ShemaghMasks + RA_TierStuff + RA_MGunner;
	  };
	  case "AsstAT": {
	    _GearToAdd = RA_Drip + RA_InfWeaps + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_ShemaghMasks + RA_TierStuff + RA_InfGear + RA_ATSpec;
	  };
	  case "ATSpec": {
	    _GearToAdd = RA_Drip + RA_InfWeaps + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_ShemaghMasks + RA_TierStuff + RA_InfGear + RA_ATSpec;
	  };
	  case "ATAmmoBearer": {
	    _GearToAdd = RA_Drip + RA_InfWeaps + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_ShemaghMasks + RA_InfGear + RA_TierStuff + RA_ATAmmoBearer;
	  };
	  case "MGAmmoBearer": {
	    _GearToAdd = RA_Drip + RA_InfWeaps + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_ShemaghMasks + RA_InfGear + RA_TierStuff + RA_MGAmmoBearer;
	  };

	// ---------------------------------- Fox -----------------------------------
	case "FoxSniper": {
	    _GearToAdd = RA_Drip + RA_InfHelmets + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_InfGear + RA_Boonies + RA_ShemaghMasks + RA_Baseballcaps + RA_LongRangeBackpacks + RA_Phantom;
	  };
	case "FoxSpotter": {
	    _GearToAdd = RA_Drip + RA_InfWeaps + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_InfGear + RA_Boonies + RA_ShemaghMasks + RA_Baseballcaps + RA_LongRangeBackpacks + RA_Phantom + RA_Rifleman;
	  };
	case "FoxScout": {
	    _GearToAdd = RA_Drip + RA_InfWeaps + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_InfGear + RA_Boonies + RA_ShemaghMasks + RA_Baseballcaps + RA_LongRangeBackpacks + RA_Phantom + RA_Rifleman;
	  };
	
	// ---------------------------------- OGRE ----------------------------------
	  // Ogres can pull all mags
	  case "OgreTL": {
	    _GearToAdd = RA_Drip + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_InfGear + RA_Boonies + RA_Baseballcaps + RA_TierStuff + RA_LongRangeBackpacks + RA_OgreTL;
	  };
	  case "OgreMedic": {
	    _GearToAdd = RA_Drip + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_InfGear + RA_Baseballcaps + RA_Boonies + RA_LongRangeBackpacks + RA_TierStuff + RA_OgreMedic;
	  };
	  case "CE": {
	    _GearToAdd = RA_Drip + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_InfGear + RA_Boonies + RA_Baseballcaps + RA_LongRangeBackpacks + RA_TierStuff + RA_OgreEngi;
	  };

	// ---------------------------------- BUTCHER ----------------------------------
	  case "ButcherCommander": {
	    _GearToAdd = RA_Drip + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_InfGear + RA_ButcherCommander + RA_LongRangeBackpacks;
	  };
	  case "ButcherGunner": {
	    _GearToAdd = RA_Drip + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_InfGear + RA_ButcherDriver;
	  };
	  case "ButcherDriver": {
	    _GearToAdd = RA_Drip + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_InfGear + RA_ButcherGunner;
	  };
	  
	// ---------------------------------- Mortarmen  ----------------------------------
	  case "Mortarman": {
	    _GearToAdd = RA_Drip + RA_InfWeaps + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_InfGear + RA_Boonies + RA_Baseballcaps + RA_LongRangeBackpacks + RA_SavageTL;
	  };
	  case "Savage": {
	    _GearToAdd = RA_Drip + RA_InfWeaps + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_InfGear + RA_Boonies + RA_Baseballcaps + RA_InfBackpacks + RA_LongRangeBackpacks + RA_Savage;
	  };

	//----------------------------------- SHADE -----------------------------------
	 case "ShadeTL": {
	    _GearToAdd = RA_Drip + RA_InfWeaps + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_InfGear + RA_Boonies + RA_Baseballcaps + RA_LongRangeBackpacks + RA_ShadeTL;
	  };
	 case "ShadeM": {
	    _GearToAdd = RA_Drip + RA_InfWeaps + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_InfGear + RA_Boonies + RA_Baseballcaps + RA_InfBackpacks + RA_LongRangeBackpacks + RA_ShadeM;
	  };
	// ---------------------------------- WRAITH ----------------------------------
	 case "WTL": {
	    _GearToAdd = RA_Drip + RA_InfWeaps + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_ShemaghMasks + RA_InfGear + RA_LongRangeBackpacks + RA_TierStuff + RA_TL;
	  };
	 case "WATS": {
	    _GearToAdd = RA_Drip + RA_InfWeaps + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_InfGear + RA_ShemaghMasks + RA_TierStuff + RA_InfGear + RA_ATSpec;
	  };
	 case "WAATS": {
	    _GearToAdd = RA_Drip + RA_InfWeaps + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_InfGear + RA_ShemaghMasks + RA_TierStuff + RA_InfGear + RA_ATSpec;
	  };
	   // ---------------------------------- LUCKY ------------------------------------
	  case "CGoblin": {
		_GearToAdd = RA_Drip + RA_InfWeaps + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_InfGear + RA_ShemaghMasks + RA_Goblin;
	  };
	  case "MGoblin": {
		_GearToAdd = RA_Drip + RA_InfWeaps + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_InfGear + RA_Goblin + RA_Medic;
	  };
	  case "SGoblin": {
		_GearToAdd = RA_Drip + RA_InfWeaps + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_InfGear + RA_ShemaghMasks + RA_LongRangeBackpacks + RA_Goblin;
	  };
	  case "TGoblin": {
		_GearToAdd = RA_Drip + RA_InfWeaps + RA_InfWeapsSites + RA_InfWeapsAttachments + RA_InfGear + RA_ShemaghMasks + RA_LongRangeBackpacks + RA_Goblin;
	  };
	// ---------------------------------- PILOTS ----------------------------------
	  case "Hermes": {
	    _GearToAdd = RA_Drip + RA_LongRangeBackpacks + RA_Baseballcaps + RA_Stalker;
	  };
	  case "Hades": {
	    _GearToAdd = RA_Drip + RA_LongRangeBackpacks + RA_Baseballcaps + RA_Demon;
	  };
	  case "Reaper": {
	    _GearToAdd = RA_Drip + RA_LongRangeBackpacks + RA_Reaper;
	  };
	  case "Chevy": {
	    _GearToAdd = RA_Drip + RA_LongRangeBackpacks + RA_Boonies + RA_Baseballcaps + RA_Reaper + RA_Stalker;
	  };
	  default {
	    _GearToAdd = ["ACE_Banana"];
	  };
	};

	// Ensure all roles have access to default gear
	_GearToAdd = _GearToAdd + RA_DefaultGear;

	_GearToAdd
};