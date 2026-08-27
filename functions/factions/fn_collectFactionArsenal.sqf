/*
    Builds a restricted arsenal from faction unit loadouts and faction crates.
    ACE, ACM and TFAR are optional and detected from loaded config metadata.
*/

params [
    ["_catalog", createHashMap, [createHashMap]],
    ["_sideId", 1, [0]]
];

private _weapons = [];
private _magazines = [];
private _items = [];
private _backpacks = [];

private _addClass = {
    params ["_class"];
    if !(_class isEqualType "") exitWith {};
    if (_class isEqualTo "") exitWith {};

    if (isClass (configFile >> "CfgMagazines" >> _class)) exitWith {
        _magazines pushBackUnique _class;
    };

    private _vehicleCfg = configFile >> "CfgVehicles" >> _class;
    if (isClass _vehicleCfg && {_class isKindOf "Bag_Base"}) exitWith {
        _backpacks pushBackUnique _class;
    };

    if (isClass (configFile >> "CfgGlasses" >> _class)) exitWith {
        _items pushBackUnique _class;
    };

    private _weaponCfg = configFile >> "CfgWeapons" >> _class;
    if !(isClass _weaponCfg) exitWith {};

    private _type = getNumber (_weaponCfg >> "type");
    if (_type in [1, 2, 4, 4096]) then {
        _weapons pushBackUnique _class;
    } else {
        _items pushBackUnique _class;
    };
};

private _walkLoadout = {
    params ["_value"];
    if (_value isEqualType "") exitWith {
        [_value] call _addClass;
    };
    if (_value isEqualType []) then {
        {
            [_x] call _walkLoadout;
        } forEach _value;
    };
};

{
    private _unitCfg = configFile >> "CfgVehicles" >> _x;
    if !(isClass _unitCfg) then {continue};

    [getUnitLoadout _x] call _walkLoadout;
    [getText (_unitCfg >> "uniformClass")] call _addClass;
    {
        [_x] call _addClass;
    } forEach (
        getArray (_unitCfg >> "weapons") +
        getArray (_unitCfg >> "respawnWeapons") +
        getArray (_unitCfg >> "magazines") +
        getArray (_unitCfg >> "respawnMagazines") +
        getArray (_unitCfg >> "linkedItems") +
        getArray (_unitCfg >> "respawnLinkedItems")
    );
} forEach (_catalog getOrDefault ["units", []]);

{
    private _cargo = [_x] call KPLIB_fnc_getConfigCargo;
    {
        private _bucket = _cargo get _x;
        {
            [_x] call _addClass;
        } forEach keys _bucket;
    } forEach ["Weapons", "Magazines", "Items", "Backpacks"];
} forEach (_catalog getOrDefault ["crates", []]);

/* Add magazines and default attachments declared by discovered weapons. */
{
    private _weaponCfg = configFile >> "CfgWeapons" >> _x;
    {
        [_x] call _addClass;
    } forEach getArray (_weaponCfg >> "magazines");

    {
        private _linked = getText (_x >> "item");
        [_linked] call _addClass;
    } forEach (configProperties [_weaponCfg >> "LinkedItems", "isClass _x", true]);
} forEach +_weapons;

if (isNil "KPLIB_autoFactionCompatibilityItems") then {
    private _aceMedical = [];
    private _aceTools = [];
    private _tfarRadios = [];

    if (isClass (configFile >> "CfgPatches" >> "ace_common")) then {
        {
            private _cfg = _x;
            if (getNumber (_cfg >> "scope") < 1) then {continue};
            if (getNumber (_cfg >> "ACE_isMedicalItem") > 0) then {_aceMedical pushBackUnique (configName _cfg)};
            if (getNumber (_cfg >> "ACE_isTool") > 0) then {_aceTools pushBackUnique (configName _cfg)};
        } forEach ("isClass _x" configClasses (configFile >> "CfgWeapons"));
    };

    private _tfarLoaded =
        isClass (configFile >> "CfgPatches" >> "tfar_core") ||
        {isClass (configFile >> "CfgPatches" >> "task_force_radio")};
    if (_tfarLoaded) then {
        {
            private _cfg = _x;
            if (getNumber (_cfg >> "scope") < 1) then {continue};
            if (
                getNumber (_cfg >> "tf_radio") > 0 ||
                {getText (_cfg >> "tf_dialog") != ""} ||
                {getText (_cfg >> "tf_subtype") != ""}
            ) then {
                _tfarRadios pushBackUnique (configName _cfg);
            };
        } forEach ("isClass _x" configClasses (configFile >> "CfgWeapons"));

        {
            private _cfg = _x;
            if (getNumber (_cfg >> "scope") >= 1 && {getNumber (_cfg >> "tf_hasLRradio") > 0}) then {
                _tfarRadios pushBackUnique (configName _cfg);
            };
        } forEach ("isClass _x" configClasses (configFile >> "CfgVehicles"));
    };

    KPLIB_autoFactionCompatibilityItems = createHashMapFromArray [
        ["aceMedical", _aceMedical],
        ["aceTools", _aceTools],
        ["tfarRadios", _tfarRadios]
    ];
};

private _compatibility = KPLIB_autoFactionCompatibilityItems;
if (missionNamespace getVariable ["KP_liberation_autoFaction_includeAceMedical", true]) then {
    {[_x] call _addClass} forEach (_compatibility get "aceMedical");
};
if (missionNamespace getVariable ["KP_liberation_autoFaction_includeAceTools", true]) then {
    {[_x] call _addClass} forEach (_compatibility get "aceTools");
};
if (missionNamespace getVariable ["KP_liberation_autoFaction_includeTfarRadios", true]) then {
    {[_x] call _addClass} forEach (_compatibility get "tfarRadios");

    private _sideSuffix = ["East", "West", "Independent", "West"] select (_sideId max 0 min 3);
    {
        private _radio = missionNamespace getVariable [_x + _sideSuffix, ""];
        [_radio] call _addClass;
    } forEach [
        "TFAR_defaultRadio_Rifleman_",
        "TFAR_defaultRadio_Personal_",
        "TFAR_defaultRadio_Backpack_",
        "TFAR_defaultRadio_Airborne_"
    ];
};

{
    [_x] call _addClass;
} forEach (missionNamespace getVariable ["KP_liberation_autoFaction_arsenalExtraItems", []]);

private _blacklist = (missionNamespace getVariable ["KP_liberation_autoFaction_arsenalBlacklist", []]) apply {toLower _x};
private _filter = {
    params ["_classes"];
    private _filtered = _classes select {!((toLower _x) in _blacklist)};
    _filtered sort true;
    _filtered
};

_weapons = [_weapons] call _filter;
_magazines = [_magazines] call _filter;
_items = [_items] call _filter;
_backpacks = [_backpacks] call _filter;

createHashMapFromArray [
    ["weapons", _weapons],
    ["magazines", _magazines],
    ["items", _items],
    ["backpacks", _backpacks],
    ["all", _weapons + _magazines + _items + _backpacks]
]
