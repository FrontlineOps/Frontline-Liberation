//Don't commit IDs into here, this is for testing only.
//If this gets committed, its possible player's S64 will get leaked by unpacking the PBO.
//This file is on the server in Arma_3_Server\perms\perms.sqf.

karmaLibRotaryLogi = [
    "76561199191114264"
];

karmaLibRotaryCas = [
    "76561199191114264"
];

karmaLibFixedWing = [
    "76561199191114264"
];

karmaLibArmor = [
    "76561199191114264"
];

karmaLibCompanyCmd = [
    "76561199191114264"
];

karmaLibPltLead = [
    "76561199191114264"
];

karmaLibPltMed = [   
    "76561199191114264"
];

karmaLibSiren = [
    "76561199191114264"
];

karmaLibSL = [
    "76561199191114264"
];

karmaLibBuild = [
    "76561199191114264"
];

karmaLibPhantom = [
    "76561199191114264"
];

karmaLibBanshee = [
    "76561199191114264"
];

karmaLibMedicBlacklist = [
    "76561199191114264"
];

KOGFOR = [
    "76561199191114264"
];

{
    _x append KP_liberation_commander_actions;
} forEach [karmaLibRotaryLogi,
        karmaLibRotaryCas,
        karmaLibFixedWing,
        karmaLibArmor,
        karmaLibCompanyCmd,
        karmaLibPltLead,
        karmaLibPltMed,
        karmaLibSiren,
        karmaLibSL,
        karmaLibPhantom,
        karmaLibBanshee,
        karmaLibBuild,
        KOGFOR];

karmaLibBlacklisted = [];

publicVariable "karmaLibRotaryLogi";
publicVariable "karmaLibRotaryCas";
publicVariable "karmaLibFixedWing";
publicVariable "karmaLibArmor";
publicVariable "karmaLibCompanyCmd";
publicVariable "karmaLibPltLead";
publicVariable "karmaLibPltMed";
publicVariable "karmaLibSiren";
publicVariable "karmaLibSL";
publicVariable "karmaLibPhantom";
publicVariable "karmaLibBanshee";
publicVariable "karmaLibBuild";
publicVariable "karmaLibMedicBlacklist";
publicVariable "karmaLibBlacklisted";
publicVariable "KOGFOR";