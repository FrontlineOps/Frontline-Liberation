/* Config values are engine inputs, not a claim of measured real-world lethality. */
params [["_ammo", "", [""]]];
private _cfg = configFile >> "CfgAmmo" >> _ammo;
if (!isClass _cfg) exitWith {["Unknown CfgAmmo: " + _ammo]};
private _rows = [format ["AMMO %1 | parent %2 | addons %3", configName _cfg, configName inheritsFrom _cfg, configSourceAddonList _cfg]];
{
    private _entry = _cfg >> _x;
    private _value = "UNSPECIFIED";
    if (isNumber _entry) then {_value = str getNumber _entry};
    if (isText _entry) then {_value = getText _entry};
    if (isArray _entry) then {_value = str getArray _entry};
    _rows pushBack format ["  %1 = %2", _x, _value];
} forEach [
    "simulation", "hit", "indirectHit", "indirectHitRange", "explosive", "caliber", "typicalSpeed", "airFriction", "deflecting",
    "fuseDistance", "explosionTime", "timeToLive", "submunitionAmmo", "triggerOnImpact", "deleteParentWhenTriggered",
    "ace_frag_skip", "ace_frag_force", "ace_frag_charge", "ace_frag_metal", "ace_frag_classes", "ace_frag_gurney_c", "ace_frag_gurney_k",
    "ACE_bulletMass", "ACE_bulletLength", "ACE_caliber", "ACE_ballisticCoefficients", "ACE_dragModel"
];
private _fragments = [_ammo] call KPLIB_fnc_munitionsFragProfile;
_rows pushBack format ["  Mission fragments: requested=%1 classes=%2 speed input=%3 source=%4. Game budget; no ACE generator invoked.", _fragments select 0, _fragments select 1, _fragments select 2, _fragments select 3];
private _profile = [_ammo] call KPLIB_fnc_guidanceResolve;
private _blast = [_ammo] call KPLIB_fnc_blastProfile;
_rows pushBack format ["  Blast model: eligible=%1 thermal=%2 radius=%3 normalized strength=%4 small-source scale=%5 reason=%6", _blast get "eligible", _blast get "thermal", _blast get "radius", _blast get "strength", _blast get "supplementScale", _blast get "reason"];
_rows pushBack format ["  Guidance config: backend=%1 family=%2 reason=%3", _profile get "backend", _profile get "family", _profile get "reason"];
_rows pushBack "  caliber is Arma's penetration coefficient; ACE_caliber is diameter metadata. hit/indirectHit are game units, not joules or pressure. No script-readable armor thickness map.";
_rows append ([_ammo] call KPLIB_fnc_gasMetadata);
_rows
