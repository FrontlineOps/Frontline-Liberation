/* Frontline faction selection, arsenal options and authored data.
   Edit faction configuration here; it is not registered in CBA settings.
   Original mission configuration: https://github.com/KillahPotatoes/KP-Liberation */

// AUTO generates catalogs from the faction arrays below. MANUAL uses
// kp_liberation_manual_factions.sqf. Existing faction validation is retained.
KP_liberation_faction_source = "AUTO";

// CfgFactionClasses names. Multiple entries merge split factions.
KP_liberation_autoFaction_blufor = ["TTU_FE_CUP_Fac_USMC_09_DST"];
KP_liberation_autoFaction_opfor = ["TTU_FE_CUP_Fac_TKA_12", "TTU_FE_CUP_Fac_TKASF_12"];
KP_liberation_autoFaction_resistance = ["TTU_FE_CUP_Fac_TKL_12"];
KP_liberation_autoFaction_civilians = ["CUP_C_TK"];

// Arsenal and resupply options.
KP_liberation_arsenal_type = true;
KP_liberation_autoFaction_includeAceMedical = true;
KP_liberation_autoFaction_includeAceTools = true;
KP_liberation_autoFaction_includeAcreRadios = true;
KP_liberation_autoFaction_includeTfarRadios = true;
KP_liberation_autoFaction_resupplyCrateLimit = 16;

KPLIB_factionOptionalEquipment = [["ace_", "ace_main"], ["acm_", "acm_core"], ["acre_", "acre_main"], ["tfar_", "tfar_core"]];

KP_liberation_autoFaction_bluforExtras = [];

KP_liberation_autoFaction_opforExtras = [];

KP_liberation_autoFaction_resistanceExtras = [];

KP_liberation_autoFaction_civiliansExtras = [];

KP_liberation_acre_defaultRadio = "ACRE_PRC343";

KP_liberation_autoFaction_arsenalExtraItems = [];

KP_liberation_autoFaction_arsenalBlacklist = [];

KP_liberation_autoFaction_priceDefaults = createHashMapFromArray [
    ["light",          [75,  25,  50]],
    ["recon",         [100,  50,  75]],
    ["medical",       [100,   0,  75]],
    ["groundLogistics",[125,  0, 125]],
    ["artillery",     [500, 600, 150]],
    ["atgm",          [300, 350, 100]],
    ["aa",            [500, 600, 150]],
    ["heavy",         [700, 750, 250]],
    ["rotaryLogistics",[350,  0, 300]],
    ["rotaryCas",     [650, 700, 400]],
    ["fixedWing",    [1000,1000, 500]],
    ["static",        [125, 150,   0]]
];
