/* Client sound reports are untrusted. Validate ownership, equipped muzzle and
   compatible ammunition; only the server's shooter position can make a cue.
   Networked projectiles add parent proof. Local-only bullets cannot supply it;
   that fallback produces sound only, never target identity, damage or resources. */
params [["_unit", objNull, [objNull]], ["_weapon", "", [""]], ["_muzzle", "", [""]],
    ["_ammo", "", [""]], ["_projectile", objNull, [objNull]], ["_magazine", "", [""]]];
if (!isServer || {!KPLIB_aiCombat_enabled} || {!KPLIB_aiCombat_hearing}
    || {localNamespace getVariable ["KPLIB_aiCombat_blocked", "Not initialized"] != ""}) exitWith {false};
if ([_weapon, _muzzle, _ammo, _magazine] findIf {count _x > 160} >= 0) exitWith {false};
if (isNull _unit || {!alive _unit} || {!(_unit isKindOf "CAManBase")}) exitWith {false};
// Mounted fire must come from the shooter's own turret; FFV uses carried weapons.
private _vehicle = objectParent _unit;
private _turret = if (isNull _vehicle) then {[]} else {_vehicle unitTurret _unit};
private _mounted = !isNull _vehicle && {!(_weapon in weapons _unit)};
if (!(_weapon in ([weapons _unit, _vehicle weaponsTurret _turret] select _mounted))) exitWith {false};
if (isRemoteExecuted && {remoteExecutedOwner != owner _unit}) exitWith {false};
if (!isRemoteExecuted && {!local _unit}) exitWith {false};
private _valid = true;
if (isNull _projectile) then {
    _valid = isRemoteExecuted && {
        if (_mounted) then {((weaponState [_vehicle, _turret]) select [0, 2]) isEqualTo [_weapon, _muzzle]}
        else {_weapon == currentWeapon _unit && {_muzzle == currentMuzzle _unit}}
    };
} else {
    private _parents = getShotParents _projectile;
    _valid = typeOf _projectile == _ammo && {count _parents >= 2} && {(_parents select 1) == _unit}
        && {_projectile distance _unit <= 1800};
};
if (!_valid) exitWith {false};
// High-speed bullets may have travelled during RPC transit. No client position
// is accepted; the acoustic origin is the server's current shooter position.
private _wc = configFile >> "CfgWeapons" >> _weapon;
private _mc = if (_weapon == _muzzle) then {_wc} else {_wc >> _muzzle};
if (!isClass _mc) exitWith {false};
if (getText (configFile >> "CfgMagazines" >> _magazine >> "ammo") != _ammo
    || {!(toLower _magazine in ((compatibleMagazines [_weapon, _muzzle]) apply {toLower _x}))}) exitWith {false};
private _ac = configFile >> "CfgAmmo" >> _ammo;
if (!(toLower getText (_ac >> "simulation") in ["shotbullet", "shotrocket", "shotshell", "shotgrenade"])) exitWith {false};
private _sounds = localNamespace getVariable "KPLIB_aiCombat_sounds";
private _key = netId _unit;
private _previous = _sounds findIf {(_x select 6) == _key};
if (_previous >= 0 && {CBA_missionTime - ((_sounds select _previous) select 3) < 1.5}) exitWith {false};
private _audible = getNumber (_ac >> "audibleFire");
if (_audible <= 0) exitWith {false};
private _items = _unit weaponAccessories _weapon;
private _suppressor = _items param [0, ""];
private _coefficient = 1;
if (_suppressor != "" && {_muzzle == _weapon}) then {
    private _coef = configFile >> "CfgWeapons" >> _suppressor >> "ItemInfo" >> "AmmoCoef" >> "audibleFire";
    if (isNumber _coef) then {_coefficient = (getNumber _coef) max 0 min 1};
};
private _suppressed = _coefficient < 0.9;
private _range = KPLIB_aiCombat_hearingRange * sqrt (_audible / 40) * sqrt _coefficient;
if (_suppressed) then {_range = _range min KPLIB_aiCombat_suppressedRange};
_range = _range min (KPLIB_aiCombat_hearingRange * 1.5);
private _sound = [eyePos _unit, side group _unit, _range, CBA_missionTime, _suppressed, _ammo, _key];
if (_previous >= 0) then {_sounds set [_previous, _sound]} else {
    if (count _sounds >= 64) then {_sounds deleteAt 0};
    _sounds pushBack _sound;
};
true
