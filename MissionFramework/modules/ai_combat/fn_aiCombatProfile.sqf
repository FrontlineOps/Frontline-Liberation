/* Cache loaded metadata, never faction/era classname lists. Unknown or externally
   guided ammunition stays with its native controller. No config patching. */
params ["_weapon", "_muzzle", "_magazine"];
if (!isServer || {isRemoteExecuted}) exitWith {createHashMap};
private _cache = localNamespace getVariable "KPLIB_aiCombat_profiles";
private _key = toLower (_weapon + ":" + _muzzle + ":" + _magazine);
if (_key in _cache) exitWith {_cache get _key};
private _wc = configFile >> "CfgWeapons" >> _weapon;
private _mc = if (_muzzle == _weapon) then {_wc} else {_wc >> _muzzle};
private _mag = configFile >> "CfgMagazines" >> _magazine;
private _ac = configFile >> "CfgAmmo" >> getText (_mag >> "ammo");
private _simulation = toLower getText (_ac >> "simulation");
private _kind = "UNSUPPORTED";
private _speed = getNumber (_mag >> "initSpeed");
private _weaponSpeed = getNumber (_mc >> "initSpeed");
if (_weaponSpeed > 0) then {_speed = _weaponSpeed};
if (_weaponSpeed < 0) then {_speed = _speed * -_weaponSpeed};
// Native CUP/vanilla explosive and illumination releases use magazine speed;
// inherited rifle initSpeed is not their velocity override.
if (_simulation != "shotbullet") then {_speed = getNumber (_mag >> "initSpeed")};
private _blast = getNumber (_ac >> "indirectHitRange");
private _guided = getNumber (_ac >> "manualControl") > 0 || {getNumber (_ac >> "irLock") > 0}
    || {getNumber (_ac >> "laserLock") > 0} || {getNumber (_ac >> "nvLock") > 0}
    || {getNumber (_ac >> "ace_missileguidance" >> "enabled") > 0};
if (_simulation == "shotbullet" && {_speed >= 250}) then {_kind = "RIFLE"};
if (_simulation == "shotrocket" && {!_guided} && {_speed >= 30}
    && {getNumber (_ac >> "indirectHit") > 0} && {_blast >= 1}) then {_kind = "RPG"};
if (_simulation in ["shotshell", "shotgrenade"] && {!_guided} && {_speed >= 30} && {_speed <= 250}
    && {getNumber (_ac >> "indirectHit") > 0} && {_blast >= 1}) then {_kind = "GL"};
if (_simulation == "shotilluminating" && {_speed >= 30}) then {_kind = "FLARE"};
private _mode = "";
private _range = 0;
private _minimum = 0;
{
    private _cfg = if (_x == "this") then {_mc} else {_mc >> _x};
    private _maximum = getNumber (_cfg >> "maxRange");
    if (_maximum > _range) then {
        _range = _maximum;
        _minimum = getNumber (_cfg >> "minRange");
        _mode = _x;
    };
} forEach getArray (_mc >> "modes");
if (_mode == "") then {_mode = (getArray (_mc >> "modes")) param [0, "this"]};
private _cap = switch (_kind) do {
    case "RIFLE": {KPLIB_aiCombat_rifleRange};
    case "RPG": {KPLIB_aiCombat_launcherRange};
    case "GL": {KPLIB_aiCombat_grenadeRange};
    default {300};
};
private _nativeRange = _range;
_range = (_range * KPLIB_aiCombat_rangeMultiplier) min _cap;
private _ttl = getNumber (_ac >> "timeToLive");
if (_ttl > 0) then {_range = _range min ((_speed max getNumber (_ac >> "maxSpeed")) * _ttl * 0.8)};
if (_kind in ["GL", "FLARE"]) then {_range = _range min (0.8 * _speed * _speed / 9.81)};
_minimum = _minimum max (switch (_kind) do {
    case "RIFLE": {KPLIB_aiCombat_minRifleRange};
    case "FLARE": {0};
    default {50 max (_blast * 4 + KPLIB_aiCombat_blastMargin)}
});
private _profile = createHashMapFromArray [
    ["weapon", _weapon], ["muzzle", _muzzle], ["magazine", _magazine], ["ammo", configName _ac],
    ["kind", _kind], ["mode", _mode], ["range", _range], ["nativeRange", _nativeRange],
    ["minimum", _minimum], ["speed", _speed], ["blast", _blast], ["guided", _guided],
    ["ttl", _ttl], ["audible", getNumber (_ac >> "audibleFire")]
];
if (count _cache >= 512) then {_cache deleteAt ((keys _cache) select 0)};
_cache set [_key, _profile];
_profile
