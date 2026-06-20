params ["_vehicle"];
private _vehicleClass = toLower (typeOf _vehicle);

// Cargo is always allowed
private _isCargo = (_vehicle getCargoIndex player) != -1;
if (_isCargo || _vehicle isKindOf "ParachuteBase") exitWith {};

private _bypass = false;
if (!isNil "bypass_perm_vehicles") then {
    
    if (typeOf _vehicle in bypass_perm_vehicles) exitWith {
        _bypass = true;
    };
};

if (_bypass == true) exitWith {};

private _role = [player] call RoleArsenal_DetermineRole;

if (_role == "Odin" || getPlayerUID player in KP_liberation_commander_actions) exitWith {};

if (_vehicleClass in KPLIB_typeReconClasses) then 
{
    // Only Phantom may drive Recon vehicles or Ogre may for e.g. vehicle recovery
    private _validReconDriver = (_role in ["FoxSniper", "FoxSpotter", "FoxScout", "OgreTL", "OgreMedic", "CE"]);
    if (!_validReconDriver && ((((fullcrew [(vehicle player), "driver"]) select 0) select 0) == player)) exitWith
    {
        moveOut player;
        hint "Only Phantom can use recon vehicles.";
    };
};

if (_vehicleClass in KPLIB_typeMedicalClasses) then 
{
    // Only Banshee may drive Medical vehicles
    private _validMedDriver = (_role in ["BNTL", "BNM", "OgreTL", "OgreMedic", "CE"]);
    if (!_validMedDriver && ((((fullcrew [(vehicle player), "driver"]) select 0) select 0) == player)) exitWith
    {
        moveOut player;
        hint "Only Banshee can use medical vehicles.";
    };
};

if (_vehicleClass in KPLIB_typeGroundLogiClasses) then 
{
    // Only Ogre may drive logistics vehicles
    private _validMedDriver = (_role in ["OgreTL", "OgreMedic", "CE", "SGoblin", "TGoblin", "CGoblin", "MGoblin"]);
    if (!_validMedDriver && ((((fullcrew [(vehicle player), "driver"]) select 0) select 0) == player)) exitWith
    {
        moveOut player;
        hint "Only Ogre can use logistics vehicles.";
    };
};

if (_vehicleClass in KPLIB_typeArtilleryClasses) then {
    // Only Artillerymen may operate artillery vehicles
    private _validArtyDriver = (_role in ["Mortarman", "Savage", "OgreTL", "OgreMedic", "CE"]);
    if (!_validArtyDriver) exitWith
    {
        moveOut player;
        hint "Only Artillerymen can use artillery vehicles.";
    };
};

if (_vehicleClass in KPLIB_typeATGMClasses) then {
    // Only Wraith may operate ATGM vehicles
    private _validATGMDriver = (_role in ["WTL", "WATS", "WAATS", "OgreTL", "OgreMedic", "CE"]);
    if (!_validATGMDriver) exitWith
    {
        moveOut player;
        hint "Only Wraith can use ATGM vehicles.";
    };
};

if (_vehicleClass in KPLIB_typeAAClasses) then {
    // Only Harpy may operate AA vehicles
    private _validAADriver = (_role in ["HAAL", "ASAA", "AAAS", "OgreTL", "OgreMedic", "CE"]);
    if (!_validAADriver) exitWith
    {
        moveOut player;
        hint "Only Harpy can use AA vehicles.";
    };
};

if (_vehicleClass in KPLIB_typeHeavyClasses) then 
{
    //if ((_role in ["SL", "PL", "PSgt"]) && ((((fullcrew [(vehicle player), "commander"]) select 0) select 0) == player)) exitWith {};
    private _validArmorCrew = (getPlayerUID player in karmaLibArmor) && (_role in ["ButcherDriver", "ButcherGunner", "ButcherCommander", "OgreTL", "OgreMedic", "CE"]);
    if (!_validArmorCrew) exitWith
    {
        moveOut player;
        hint "Only Butcher can use armored vehicles.";
    };
};

if (_vehicleClass in KPLIB_typeRotaryLogiClasses) then
{
    private _validRotaryCrew = (getPlayerUID player in karmaLibRotaryLogi) && (_role in ["Hermes", "BansheePilot"]);
    if (!_validRotaryCrew) exitWith
    {
        moveOut player;
        hint "Only Hermes can use rotary logistics vehicles.";
    };
};

if (_vehicleClass in KPLIB_typeRotaryCasClasses) then
{
    private _validRotaryCASCrew = (getPlayerUID player in karmaLibRotaryCas) && (_role in ["Hades"]);
    if (!(getPlayerUID player in karmaLibRotaryCas)) exitWith
    {
        moveOut player;
        hint "Only Hades can use rotary CAS vehicles.";
    };
};

if (_vehicleClass in KPLIB_typeFixedWingClasses) then
{
    private _validFixedWingCrew = (getPlayerUID player in karmaLibFixedWing) && (_role in ["Reaper", "Chevy"]);
    if (!(getPlayerUID player in karmaLibFixedWing)) exitWith
    {
        moveOut player;
        hint "Only Reaper/Chevy can use fixed wing vehicles.";
    };
};