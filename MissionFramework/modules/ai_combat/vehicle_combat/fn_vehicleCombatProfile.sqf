/* Config metadata only; actual inventory and range settings are applied by Weapons.
   Roles are tactical categories, not real armor-penetration estimates. */
params ["_weapon", "_muzzle", "_magazine"];
private _cache = localNamespace getVariable "KPLIB_vehicleCombat_profiles";
private _key = str _this;
if (_key in _cache) exitWith {_cache get _key};
private _w = configFile >> "CfgWeapons" >> _weapon;
private _m = if (_muzzle == _weapon) then {_w} else {_w >> _muzzle};
private _mag = configFile >> "CfgMagazines" >> _magazine;
private _ammo = getText (_mag >> "ammo");
private _a = configFile >> "CfgAmmo" >> _ammo;
private _sim = toLower getText (_a >> "simulation");
private _profile = createHashMap;
if (_sim in ["shotbullet", "shotshell", "shotmissile", "shotrocket", "shotgrenade"]
    && {getNumber (_a >> "hit") > 0 || {getNumber (_a >> "indirectHit") > 0}}) then {
    private _modes = getArray (_m >> "modes");
    if (_modes isEqualTo []) then {_modes = ["this"]};
    private _mode = "";
    private _nativeRange = 0;
    private _minimum = 1e9;
    private _reload = 0.1;
    {
        private _c = if (_x == "this") then {_m} else {_m >> _x};
        // Player-only top-attack modes are not AI direct-fire range evidence.
        if (getNumber (_c >> "showToPlayer") == 0) then {
            _nativeRange = _nativeRange max getNumber (_c >> "maxRange");
            _minimum = _minimum min getNumber (_c >> "minRange");
        };
        if (_mode == "" && {getNumber (_c >> "showToPlayer") > 0 || {_x == "this"}}) then {
            _mode = _x;
            _reload = getNumber (_c >> "reloadTime");
        };
    } forEach _modes;
    if (_mode == "") then {_mode = _modes select 0};
    if (_mode == "this") then {_mode = _muzzle};
    private _hit = getNumber (_a >> "hit");
    private _caliber = getNumber (_a >> "caliber");
    private _indirect = getNumber (_a >> "indirectHit");
    private _radius = getNumber (_a >> "indirectHitRange");
    private _explosive = getNumber (_a >> "explosive");
    private _sub = getText (_a >> "submunitionAmmo");
    private _penetrator = false;
    if (_sub != "") then {
        private _s = configFile >> "CfgAmmo" >> _sub;
        _penetrator = getNumber (_s >> "caliber") > _caliber && {getNumber (_s >> "hit") > 0};
        _caliber = _caliber max getNumber (_s >> "caliber");
    };
    private _guided = _sim == "shotmissile";
    private _kind = if (_guided) then {"ATGM"} else {
        if (_penetrator) then {"HEAT"} else {
            if (_explosive >= 0.3 && {_indirect > 0} && {_radius >= 1}) then {"HE"} else {
                if (_sim == "shotshell" || {_caliber >= 4}) then {"AP"} else {"MG"}
            }
        }
    };
    private _speed = abs getNumber (_mag >> "initSpeed");
    private _override = getNumber (_m >> "initSpeed");
    if (_override > 0) then {_speed = _override};
    if (_override < 0) then {_speed = _speed * abs _override};
    if (_speed <= 0) then {_speed = getNumber (_a >> "typicalSpeed")};
    private _life = getNumber (_a >> "timeToLive");
    private _limit = if (_life > 0 && {_speed > 0}) then {_life * _speed * 0.65} else {1e9};
    if (_guided) then {
        _limit = 1e9;
        // Inherited maxControlRange=350 on ordinary shells is irrelevant.
        {
            private _r = getNumber (_a >> _x);
            if (_r > 0) then {_limit = _limit min _r};
        } forEach ["maxControlRange", "missileLockMaxDistance"];
        if (_nativeRange <= 0) then {_nativeRange = _limit min 4000};
    };
    if (_nativeRange <= 0) then {_nativeRange = getNumber (_m >> "maxRange")};
    if (_minimum == 1e9) then {_minimum = 0};
    _profile = createHashMapFromArray [
        ["weapon", _weapon], ["muzzle", _muzzle], ["mode", _mode], ["magazine", _magazine], ["ammo", _ammo],
        ["kind", _kind], ["hit", _hit], ["caliber", _caliber], ["radius", _radius], ["speed", _speed],
        ["minimum", _minimum max (if (_radius > 1) then {30 max (_radius * 3)} else {5})],
        ["nativeRange", _nativeRange], ["limit", _limit], ["reload", _reload max 0.1],
        ["airOnly", _guided && {getNumber (_a >> "airLock") >= 2}],
        ["fireModes", [_weapon, _muzzle] call KPLIB_fnc_combatFireModes]
    ];
};
if (count _cache >= 512) then {_cache deleteAt ((keys _cache) select 0)};
_cache set [_key, _profile];
_profile
