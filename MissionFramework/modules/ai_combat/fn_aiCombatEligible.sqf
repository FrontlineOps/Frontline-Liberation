/* Server owns all infantry orders. Return the first exclusion for diagnostics. */
params [["_unit", objNull, [objNull]]];
if (!isServer || {isRemoteExecuted}) exitWith {"Not a local server call"};
if (!KPLIB_aiCombat_enabled) exitWith {"Disabled"};
if (isNull _unit || {!alive _unit}) exitWith {"Dead or deleted"};
if (!local _unit || {isPlayer _unit} || {!isNull remoteControlled _unit}) exitWith {"Player or nonlocal AI"};
if (!(side group _unit in KPLIB_aiCombat_sides)) exitWith {"Side excluded"};
if (!isNull objectParent _unit) exitWith {"Mounted: vehicle combat"};
if (netId _unit in (localNamespace getVariable ["KPLIB_vehicleCombat_restores", createHashMap])) exitWith {"Vehicle controls being released"};
if (!simulationEnabled _unit) exitWith {"Simulation suspended"};
if (captive _unit || {lifeState _unit == "INCAPACITATED"}
    || {_unit getVariable ["ACE_isUnconscious", false]}
    || {_unit getVariable ["KPLIB_intelligencePrisoner", false]}
    || {_unit getVariable ["KPLIB_surrenderInProgress", false]}
    || {_unit getVariable ["ace_captives_isSurrendering", false]}) exitWith {"Captive or unconscious"};
private _mode = unitCombatMode _unit;
if (_mode == "") then {_mode = combatMode group _unit};
if (!(combatMode group _unit in ["YELLOW", "RED"]) || {!(_mode in ["YELLOW", "RED"])}) exitWith {"Hold fire"};
if (behaviour _unit == "STEALTH" || {_unit getVariable ["KPLIB_lambs_forceMove", false]}) exitWith {"Stealth or scripted movement"};
if (!(_unit checkAIFeature "ANIM") || {!(_unit checkAIFeature "WEAPONAIM")}) exitWith {"Animation or aiming disabled"};
""
