/* Frontline configuration bootstrap.
   Admin options: Configure Addons -> Frontline sections.
   Authored class lists, compositions and engine constants: config/.
   CBA settings are applied before this file; never reset them here. */
[] call compileFinal preprocessFileLineNumbers "config\core.sqf";
[] call compileFinal preprocessFileLineNumbers "config\factions.sqf";
[] call compileFinal preprocessFileLineNumbers "config\ai.sqf";
[] call compileFinal preprocessFileLineNumbers "config\strategy.sqf";
[] call compileFinal preprocessFileLineNumbers "config\assets.sqf";
localNamespace setVariable ["KPLIB_manualFactions", KP_liberation_faction_source == "MANUAL"];
