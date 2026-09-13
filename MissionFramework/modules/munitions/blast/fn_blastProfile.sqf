/* Loaded game metadata only. No explosive-yield, armor or injury prediction. */
params [["_ammo", "", [""]]];
private _cache = localNamespace getVariable ["KPLIB_blastProfiles", createHashMap];
private _profile = _cache get _ammo;
if (!isNil "_profile") exitWith {_profile};
private _cfg = configFile >> "CfgAmmo" >> _ammo;
private _hit = getNumber (_cfg >> "indirectHit");
private _range = getNumber (_cfg >> "indirectHitRange");
private _helper = (toLower _ammo) find "ace_explosion_reflection_" == 0;
private _eligible = isClass _cfg && {getNumber (_cfg >> "explosive") >= 0.5}
    && {_hit > 0} && {_range > 0} && {!_helper};
private _thermal = false;
private _reason = "No thermobaric metadata; ordinary explosive exposure";
if (isNumber (_cfg >> "KPLIB_thermobaric")) then {
    _thermal = getNumber (_cfg >> "KPLIB_thermobaric") == 1;
    _reason = "Explicit loaded KPLIB_thermobaric config";
} else {
    if (missionNamespace getVariable ["KPLIB_munitions_thermal_labels", true]) then {
        private _labels = localNamespace getVariable ["KPLIB_blastLabels", createHashMap];
        private _label = toLower ((getText (_cfg >> "explosionEffects")) + " " + (_labels getOrDefault [_ammo, ""]));
        _thermal = ["thermobaric", "fuel-air", "fuel air"] findIf {_label find _x >= 0} >= 0;
        if (_thermal) then {_reason = "INFERENCE from loaded magazine/effect label; chemistry and filler metadata unavailable"};
    };
};
// Supplemental pressure tapers to zero for small game explosions. Native
// grenade damage remains; the mission does not multiply it with extra floors.
private _supplement = linearConversion [8, 80, _hit, 0, 1, true];
private _radius = (4 * _range) min (missionNamespace getVariable ["KPLIB_munitions_blast_max_radius", 120]);
_profile = createHashMapFromArray [
    ["ammo", _ammo], ["eligible", _eligible], ["hit", _hit], ["range", _range],
    ["radius", _radius max 0.1], ["thermal", _thermal && {_eligible}], ["reason", _reason],
    ["cell", ((_range / 4) max 0.75) min 2], ["fieldRadius", (2 * _range) min 12],
    ["supplementScale", _supplement],
    ["strength", ((_hit * (missionNamespace getVariable ["KPLIB_munitions_blast_gain", 0.08])) min 24) * _supplement]
];
if (isClass _cfg) then {_cache set [_ammo, _profile]};
localNamespace setVariable ["KPLIB_blastProfiles", _cache];
_profile
