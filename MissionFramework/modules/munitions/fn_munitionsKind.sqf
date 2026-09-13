/* Config inheritance identifies known ACE fragment families. Unknown addon
   bullets stay PROJECTILE; a guess must not become a claimed fragment count. */
params ["_ammo", ["_parent", -1]];
private _cache = localNamespace getVariable ["KPLIB_munitionsKinds", createHashMap];
private _kind = _cache get _ammo;
if (isNil "_kind") then {
    _kind = if (_ammo isKindOf ["ACE_frag_base", configFile >> "CfgAmmo"]) then {"FRAGMENT"} else {"PROJECTILE"};
    if (_ammo isKindOf ["ACE_frag_spallBase", configFile >> "CfgAmmo"]) then {_kind = "CHILD"};
    if (isClass (configFile >> "CfgAmmo" >> _ammo)) then {_cache set [_ammo, _kind]};
    localNamespace setVariable ["KPLIB_munitionsKinds", _cache];
};
if (_parent >= 0 && {_kind != "FRAGMENT"}) then {_kind = "CHILD"};
_kind
