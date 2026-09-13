/* Game-budget policy, independent of entities, era and ACE skip/force switches.
   Loaded fragment classes are assets, not proof of a real fragment population. */
params [["_ammo", "", [""]]];
private _cache = localNamespace getVariable ["KPLIB_munitionsFragProfiles", createHashMap];
private _cached = _cache get _ammo;
if (!isNil "_cached") exitWith {_cached};
private _blast = [_ammo] call KPLIB_fnc_blastProfile;
private _cfg = configFile >> "CfgAmmo" >> _ammo;
private _types = getArray (_cfg >> "ace_frag_classes");
_types = _types select {
    _x isEqualType "" && {isClass (configFile >> "CfgAmmo" >> _x)}
        && {_x isKindOf ["ACE_frag_base", configFile >> "CfgAmmo"]}
};
private _fallback = _types isEqualTo [];
if (_fallback) then {
    _types = ["ACE_frag_tiny_HD", "ACE_frag_small_HD"] select {isClass (configFile >> "CfgAmmo" >> _x)};
};
private _hit = _blast get "hit";
// Small explosions use fewer, high-drag game particles; large explosions get
// a denser field. These coefficients are explicit balance choices, not SI data.
if (_hit <= 8) then {_types = ["ACE_frag_tiny_HD"] select {isClass (configFile >> "CfgAmmo" >> _x)}};
private _cap = (missionNamespace getVariable ["KPLIB_munitions_fragment_cap", 384]) max 1 min 512;
private _count = (round (8 + 0.4 * _hit)) min _cap;
if (!(_blast get "eligible") || {_types isEqualTo []} || {getNumber (_cfg >> "KPLIB_fragment_skip") == 1}) then {_count = 0};
private _speed = if (_types isEqualTo []) then {0} else {getNumber (configFile >> "CfgAmmo" >> (_types select 0) >> "typicalSpeed")};
_cached = [_count, _types, _speed, ["loaded ACE fragment assets", "generic game fragment assets; metadata absent"] select _fallback];
if (isClass _cfg) then {_cache set [_ammo, _cached]};
localNamespace setVariable ["KPLIB_munitionsFragProfiles", _cache];
_cached
