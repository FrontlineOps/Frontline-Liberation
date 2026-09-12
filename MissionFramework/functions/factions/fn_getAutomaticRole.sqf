/* Existing automatic slot aliases; later matches retain their original precedence. */
if (isNil {localNamespace getVariable "KPLIB_automaticRoleAliases"}) then {
    private _aliases = [
        ["Odin", "Odin"],
        ["Guide", "Guide"],
        ["Company Commander", "CO"],
        ["Executive Officer", "XO"],
        ["TACP (Alpha)", "JFO"],
        ["TACP (Bravo)", "JFO"],
        ["TACP (Charlie)", "JFO"],
        ["TACP (Delta)", "JFO"],
        ["Platoon Commander", "PL"],
        ["RTO", "PLTO"],
        ["Platoon Sergeant", "PSgt"],
        ["Squad Leader", "SL"],
        ["Fireteam Leader", "TL"],
        ["Team Leader", "TL"],
        ["Medic", "Medic"],

        // Needs to be below medic to get proper kit. Otherwise it uses medic.
        ["Platoon Medic", "PMed"],
        ["Banshee Team Lead", "BNTL"],
        ["Banshee Medic", "BNM"],
        ["Banshee Pilot", "BansheePilot"],
        ["Grenadier", "Grenadier"],
        ["Rifleman", "Rifleman"],
        ["Automatic Rifleman", "ARifleman"],
        ["Scout/Marksman", "SMarksman"],
        ["Explosives Specialist", "ESpecialist"],
        ["Machine Gunner", "MGunner"],
        ["Ammo Bearer", "ATAmmoBearer"],
        ["Goblin Medic", "MGoblin"],
        ["Goblin Squad Leader", "SGoblin"],
        ["Goblin Combat Engineer", "CGoblin"],
        ["Goblin Team Leader", "TGoblin"],
        ["Harpy 1 Team Leader", "HAAL"],
        ["Asst. AA Specialist", "ASAA"],
        ["AA Specialist", "AAAS"],
        ["AT Specialist", "ATSpec"],
        ["Asst. AT Specialist", "AsstAT"],
        ["Asst. Machine Gunner", "MGAmmoBearer"],
        ["Wraith Team Leader", "WTL"],
        ["Wraith AT Specialist", "WATS"],
        ["Wraith Asst. AT Specialist", "WAATS"],
        ["Shade Team Leader", "ShadeTL"],
        ["Shade Mortarman","ShadeM"],
        ["Shadow Team Leader", "ShadowTL"],
        ["Shadow Echo", "ShadowE"],
        ["Scout/SO", "FoxSniper"],
        ["Scout/JO", "FoxSpotter"],
        ["Scout", "FoxScout"],
        ["Ogre Team Leader", "OgreTL"],
        ["Ogre Medic", "OgreMedic"],
        ["Combat Engineer", "CE"],
        ["Vehicle Driver", "ButcherDriver"],
        ["Vehicle Gunner", "ButcherGunner"],
        ["Vehicle Commander", "ButcherCommander"],
        ["Scout/Mortarman", "Mortarman"],
        ["Savage Gunner", "Savage"],
        ["Hermes", "Hermes"],
        ["Chevy", "Chevy"],
        ["Hades", "Hades"],
        ["Reaper", "Reaper"]
    ];
    localNamespace setVariable ["KPLIB_automaticRoleAliases", _aliases];
};
params ["_player"];

// Work out which role the player is playing
private _roleDesc = roleDescription _player;
private _playerRole = "";
{
    _x params ["_pattern", "_role"];

    if(_roleDesc find _pattern > -1) then {
        _playerRole = _role;
    };
} forEach (localNamespace getVariable "KPLIB_automaticRoleAliases");

// Allow admins to override for testing purposes
if ((count (missionNamespace getVariable ["DEBUG_ARSENAL_ROLE_OVERRIDE", ""])) > 0) then {
    _playerRole = (missionNamespace getVariable ["DEBUG_ARSENAL_ROLE_OVERRIDE", ""]);
};

_playerRole
