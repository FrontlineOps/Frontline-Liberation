/*
    Runs where the unit is local, after starter gear or inventory enforcement.
    ACRE radios live in inventory; TFAR and vanilla radios use assigned items.
    Existing radios, including allocated IDs, are preserved.
*/
params [["_unit", player, [objNull]]];
if (isNull _unit || {!local _unit}) exitWith {false};

private _carried = items _unit + assignedItems _unit;
if (isClass (configFile >> "CfgPatches" >> "acre_main")) exitWith {
    private _hasRadio = _carried findIf {
        getNumber (configFile >> "CfgWeapons" >> _x >> "acre_isRadio") == 1
    } >= 0;
    if (_hasRadio) exitWith {true};

    private _radio = missionNamespace getVariable ["KP_liberation_acre_defaultRadio", "ACRE_PRC343"];
    if !(_radio isEqualType "") exitWith {false};
    private _cfg = configFile >> "CfgWeapons" >> _radio;
    if (
        getNumber (_cfg >> "acre_isRadio") != 1 ||
        {getNumber (_cfg >> "acre_hasUnique") != 1} ||
        {getNumber (_cfg >> "acre_uniqueId") != 0} ||
        {!(_unit canAdd _radio)}
    ) exitWith {false};

    _unit addItem _radio;
    true
};

private _tfarLoaded = isClass (configFile >> "CfgPatches" >> "tfar_core") ||
    {isClass (configFile >> "CfgPatches" >> "task_force_radio")};
private _hasRadio = _carried findIf {
    private _cfg = configFile >> "CfgWeapons" >> _x;
    if (_tfarLoaded) then {
        getNumber (_cfg >> "tf_radio") > 0 ||
        {getText (_cfg >> "tf_dialog") != ""} ||
        {getText (_cfg >> "tf_subtype") != ""}
    } else {
        toLower _x == "itemradio"
    }
} >= 0;
if (_hasRadio) exitWith {true};

private _radio = (["ItemRadio", "TFAR_anprc152"] select (_tfarLoaded));
if !(isClass (configFile >> "CfgWeapons" >> _radio)) exitWith {false};
_unit linkItem _radio;
true
