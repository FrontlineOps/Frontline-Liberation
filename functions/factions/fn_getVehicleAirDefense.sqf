/*
    Cached config-only air-defense capabilities, built per machine at faction
    generation. Includes nested turrets and only ammunition actually carried.
*/
params [["_class", "", [""]]];

private _cache = localNamespace getVariable ["KPLIB_airDefenseConfigCache", createHashMap];
private _cached = _cache get _class;
if (!isNil "_cached") exitWith {_cached};
private _result = createHashMapFromArray [
    ["role", ""], ["radar", false], ["needsRadar", false],
    ["missileAmmo", []], ["missileMagazines", []], ["missileWeapons", []]
];
private _cfg = configFile >> "CfgVehicles" >> _class;
if (!isClass _cfg || {getNumber (_cfg >> "scope") < 2}
    || {!(_class isKindOf "LandVehicle" || {_class isKindOf "StaticWeapon"})}) exitWith {_result};

private _activeRadar = false;
private _dataLink = false;
{
    private _type = toLower getText (_x >> "componentType");
    if (_type == "activeradarsensorcomponent" && {getNumber (_x >> "AirTarget" >> "maxRange") > 0}) then {
        _activeRadar = true;
    };
    if (_type == "datalinksensorcomponent") then {_dataLink = true};
} forEach ("true" configClasses (_cfg >> "Components" >> "SensorsManagerComponent" >> "Components"));

private _missileAmmo = [];
private _missileMagazines = [];
private _missileWeapons = [];
private _radarMissile = false;
private _hasGun = false;
private _hasOtherWeapon = false;
private _walk = {
    params ["_seat"];
    private _seatMissiles = [];
    {
        if (toLower _x == "fakeweapon") then {continue};
        private _ammo = getText (configFile >> "CfgMagazines" >> _x >> "ammo");
        private _ac = configFile >> "CfgAmmo" >> _ammo;
        private _simulation = toLower getText (_ac >> "simulation");
        private _airLock = getNumber (_ac >> "airLock");
        private _radarLock = (floor (getNumber (_ac >> "weaponLockSystem") / 8) mod 2) == 1;
        // airLock=1 also appears on ATGMs. Require air-only targeting or a
        // radar-guided air-capable missile, not airLock alone.
        if (_simulation == "shotmissile" && {_airLock >= 2 || {_airLock > 0 && {_radarLock}}}) then {
            _missileAmmo pushBackUnique _ammo;
            _missileMagazines pushBackUnique _x;
            _seatMissiles pushBackUnique _x;
            if (_radarLock) then {_radarMissile = true};
        } else {
            if (_simulation in ["shotbullet", "shotshell"] && {getNumber (_ac >> "hit") > 0}) then {
                _hasGun = true;
            };
            if (_simulation in ["shotbullet", "shotshell", "shotmissile", "shotrocket"] && {getNumber (_ac >> "hit") > 0}) then {
                _hasOtherWeapon = true;
            };
        };
    } forEach getArray (_seat >> "magazines");
    {
        private _weapon = _x;
        private _wc = configFile >> "CfgWeapons" >> _weapon;
        private _magazines = getArray (_wc >> "magazines");
        {
            if (_x != "this") then {_magazines append getArray (_wc >> _x >> "magazines")};
        } forEach getArray (_wc >> "muzzles");
        if ((_magazines arrayIntersect _seatMissiles) isNotEqualTo []) then {_missileWeapons pushBackUnique _weapon};
    } forEach getArray (_seat >> "weapons");
    {[_x] call _walk} forEach ("true" configClasses (_seat >> "Turrets"));
};
[_cfg] call _walk;

private _text = toLower format ["%1 %2 %3", _class, getText (_cfg >> "displayName"), getText (_cfg >> "editorSubcategory")];
private _tokens = " " + ((_text splitString " _-/().,[]") joinString " ") + " ";
private _aaLabel = ([" aa ", " anti air ", " antiair ", " spaag ", " shilka ", " tunguska ", " zu23 ", " zsu "] findIf {(_tokens find _x) >= 0}) >= 0;
private _role = "";
if (_missileAmmo isNotEqualTo [] && {_missileWeapons isNotEqualTo []}) then {
    _role = ["samShorad", "samTel"] select (_radarMissile || {_activeRadar});
} else {
    if (_hasGun && {_aaLabel || {_activeRadar}}) then {
        _role = "aaGun";
    } else {
        if (_activeRadar && {!_hasOtherWeapon}) then {_role = "samRadar"};
    };
};
_result set ["role", _role];
_result set ["radar", _activeRadar];
// Modern remote-target launchers without onboard search need a same-side radar.
// Legacy mod-specific controllers retain their own native dependencies.
_result set ["needsRadar", _role == "samTel" && {_radarMissile} && {!_activeRadar} && {_dataLink}];
_result set ["missileAmmo", _missileAmmo];
_result set ["missileMagazines", _missileMagazines];
_result set ["missileWeapons", _missileWeapons];
_cache set [_class, _result];
localNamespace setVariable ["KPLIB_airDefenseConfigCache", _cache];
_result
