/* Read the actual unit/vehicle state; never install or return a HandleDamage callback. */
params [["_object", objNull, [objNull]], ["_inventory", false, [true]]];
if (isNull _object) exitWith {["Object no longer exists"]};
private _cfg = configOf _object;
private _rows = [
    format ["OBJECT %1 | owner=%2 local=%3 | alive=%4 damage=%5 canMove=%6", typeOf _object, owner _object, local _object, alive _object, damage _object, canMove _object],
    format ["  ASL=%1 | addons=%2", getPosASL _object, configSourceAddonList _cfg],
    format ["  armor=%1 armorStructural=%2 explosionShielding=%3", getNumber (_cfg >> "armor"), getNumber (_cfg >> "armorStructural"), getNumber (_cfg >> "explosionShielding")],
    format ["  Actual hitpoints [names, selections, damage]: %1", getAllHitPointsDamage _object]
];
if (!(_object isKindOf "CAManBase")) then {
    _rows pushBack format ["  Last pressure game floors [event,at,[component,requested,before,after/reason]]: %1",_object getVariable ["KPLIB_gasAssetLast",[]]];
};
if (_object isKindOf "CAManBase") then {
    private _trauma = _object getVariable ["KPLIB_blastTraumaSnapshot", []];
    if (_trauma isNotEqualTo []) then {
        private _scores = [_trauma select 3, CBA_missionTime - (_trauma select 2)] call KPLIB_fnc_blastTraumaDecay;
        _rows pushBack format ["  Blast recovery: disorientation=%1 instability=%2 events=%3 last=%4 s ago; source reading=%5", _scores select 0, _scores select 1, _trauma select 4, CBA_missionTime - (_trauma select 5), _trauma select 6];
    };
    if (isClass (configFile >> "CfgPatches" >> "ACM_core")) then {
        _rows pushBack format ["  ACM: knockout=%1 lying=%2 airway reflex=%3 oxygen=%4; physiology and treatment remain ACM-owned", _object getVariable ["ACM_core_KnockOut_State", false], _object getVariable ["ACM_core_Lying_State", false], _object getVariable ["ACM_airway_AirwayReflex_State", false], _object getVariable ["ACM_breathing_OxygenSaturation", "unavailable"]];
    };
    _rows pushBack format ["  Last debug pressure trace (owner-local, may be stale): %1", _object getVariable ["KPLIB_blastLastTrace", []]];
    _rows pushBack format ["  lifeState=%1 unconscious=%2 | uniform=%3 vest=%4 helmet=%5", lifeState _object, _object getVariable ["ACE_isUnconscious", false], uniform _object, vest _object, headgear _object];
    {
        _rows pushBack format ["  %1 = %2", _x, (str (_object getVariable [_x, "UNAVAILABLE"])) select [0, 1800]];
    } forEach ["ace_medical_damageThreshold", "ace_medical_bodyPartDamage", "ace_medical_openWounds", "ace_medical_bloodVolume", "ace_medical_pain", "ace_medical_heartRate", "ace_medical_inCardiacArrest"];
    {
        private _item = _x;
        private _gear = configFile >> "CfgWeapons" >> _x >> "ItemInfo" >> "HitpointsProtectionInfo";
        {
            _rows pushBack format ["  Protection %1: %2 armor=%3 passThrough=%4", _item, getText (_x >> "hitpointName"), getNumber (_x >> "armor"), getNumber (_x >> "passThrough")];
        } forEach ("true" configClasses _gear);
    } forEach [vest _object, headgear _object];
    if ((_object getVariable ["ace_medical_bodyPartDamage", []]) isNotEqualTo []) then {
        _rows pushBack "  ACE body-part order: head, body, left arm, right arm, left leg, right leg. Native damage=0 does not imply no wounds. useLimbDamage=0 excludes limb trauma from the summed fatal-damage path.";
    };
};
if (_inventory) then {
    private _magazines = if (_object isKindOf "CAManBase") then {magazines _object} else {(magazinesAllTurrets _object) apply {_x select 0}};
    private _ammo = [];
    {
        private _class = getText (configFile >> "CfgMagazines" >> _x >> "ammo");
        if (_class != "") then {_ammo pushBackUnique _class};
    } forEach _magazines;
    _rows pushBack format ["  Loaded magazines: %1", _magazines];
    _rows pushBack format ["  Weapon state: %1", weaponState _object];
    private _visited = +_ammo;
    {
        private _entry = configFile >> "CfgAmmo" >> _x >> "submunitionAmmo";
        if (isText _entry) then {_visited pushBackUnique getText _entry};
        if (isArray _entry) then {
            {if (_x isEqualType "") then {_visited pushBackUnique _x}} forEach getArray _entry;
        };
    } forEach _ammo;
    {
        _rows append ([_x] call KPLIB_fnc_munitionsAmmo);
    } forEach (_visited select [0, 16]);
    if (count _visited > 16) then {_rows pushBack "Ammo detail capped at 16 classes. Capture the specific shot for its actual class."};
};
_rows
