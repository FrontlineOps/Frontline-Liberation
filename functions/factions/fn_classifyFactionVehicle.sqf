/*
    Classifies one public CfgVehicles class into Liberation asset buckets.
*/

params [
    ["_class", "", [""]]
];

private _cfg = configFile >> "CfgVehicles" >> _class;
if (_class isEqualTo "" || {!isClass _cfg} || {getNumber (_cfg >> "scope") < 2}) exitWith {[]};
if (_class isKindOf "Man") exitWith {["infantry"]};

private _classLower = toLower _class;
private _displayLower = toLower (getText (_cfg >> "displayName"));
private _vehicleClassLower = toLower (getText (_cfg >> "vehicleClass"));
private _subcategoryLower = toLower (getText (_cfg >> "editorSubcategory"));
private _text = [_classLower, _displayLower, _vehicleClassLower, _subcategoryLower] joinString " ";
private _tokens = " " + ((_text splitString " _-/().,[]") joinString " ") + " ";
private _categories = [];

private _hasText = {
    params ["_needle"];
    (_text find _needle) >= 0
};
private _hasToken = {
    params ["_needle"];
    (_tokens find (" " + _needle + " ")) >= 0
};

private _weapons = +(getArray (_cfg >> "weapons"));
{
    _weapons append (getArray (_x >> "weapons"));
} forEach ("isClass _x" configClasses (_cfg >> "Turrets"));

private _utilityWeapons = ["fakeweapon", "cmflarelauncher", "smokelauncher", "rockets_smoke", "laserdesignator_mounted"];
private _armed = (_weapons findIf {
    private _weapon = toLower _x;
    !(_weapon in _utilityWeapons) && {(_weapon find "horn") < 0} && {(_weapon find "laserdesignator") != 0}
}) >= 0;

private _isAA =
    (["aa"] call _hasToken) ||
    {["sam"] call _hasText} ||
    {["anti-air"] call _hasText} ||
    {["antiair"] call _hasText} ||
    {["stinger"] call _hasText} ||
    {["igla"] call _hasText} ||
    {["shilka"] call _hasText} ||
    {["tunguska"] call _hasText} ||
    {["zu23"] call _hasText} ||
    {["zsu"] call _hasText};

private _isATGM =
    (["atgm"] call _hasText) ||
    {["tow"] call _hasToken} ||
    {["kornet"] call _hasText} ||
    {["metis"] call _hasText} ||
    {["spike"] call _hasText} ||
    {["anti-tank"] call _hasText};

private _isArtillery =
    (getNumber (_cfg >> "artilleryScanner") > 0) ||
    {["artillery"] call _hasText} ||
    {["howitzer"] call _hasText} ||
    {["mortar"] call _hasText} ||
    {["mlrs"] call _hasText};

private _isMedical =
    (getNumber (_cfg >> "attendant") > 0) ||
    {["medical"] call _hasText} ||
    {["ambulance"] call _hasText} ||
    {["medevac"] call _hasText};

private _isLogistics =
    (getNumber (_cfg >> "transportAmmo") > 0) ||
    {getNumber (_cfg >> "transportFuel") > 0} ||
    {getNumber (_cfg >> "transportRepair") > 0} ||
    {["logistic"] call _hasText} ||
    {["supply"] call _hasText};

private _isRecon =
    (["recon"] call _hasText) ||
    {["scout"] call _hasText} ||
    {["command"] call _hasText};

if (_class isKindOf "ReammoBox_F") exitWith {["crate"]};
if (_class isKindOf "Slingload_01_Base_F" || {_class isKindOf "CargoNet_01_base_F"}) exitWith {["container"]};

if (_class isKindOf "StaticWeapon") exitWith {
    _categories pushBack "static";
    if (_isAA) then {_categories pushBack "aa"};
    if (_isATGM) then {_categories pushBack "atgm"};
    if (_isArtillery) then {_categories pushBack "artillery"};
    _categories
};

if (_class isKindOf "Helicopter") exitWith {
    if (_isMedical) then {_categories pushBack "medical"};
    if (_isLogistics || {!_armed} || {getNumber (_cfg >> "transportSoldier") >= 6}) then {
        _categories pushBack "rotaryLogistics";
    };
    if (_armed) then {_categories pushBack "rotaryCas"};
    if (getNumber (_cfg >> "transportSoldier") > 0) then {_categories pushBack "transport"};
    _categories
};

if (_class isKindOf "Plane") exitWith {["fixedWing"]};
if (_class isKindOf "Ship") exitWith {["boat"]};

if (_class isKindOf "LandVehicle") then {
    if (_isMedical) then {_categories pushBack "medical"};
    if (_isLogistics) then {_categories pushBack "groundLogistics"};
    if (_isRecon) then {_categories pushBack "recon"};
    if (_isArtillery) then {_categories pushBack "artillery"};
    if (_isATGM) then {_categories pushBack "atgm"};
    if (_isAA) then {_categories pushBack "aa"};

    if (_class isKindOf "Tank") then {
        if !(_isArtillery || {_isATGM} || {_isAA}) then {_categories pushBack "heavy"};
        if (getNumber (_cfg >> "transportSoldier") > 0) then {_categories pushBack "transport"};
    } else {
        if !(_isMedical || {_isLogistics}) then {_categories pushBack "light"};
        if (getNumber (_cfg >> "transportSoldier") > 0) then {_categories pushBack "transport"};
    };
};

_categories arrayIntersect _categories
