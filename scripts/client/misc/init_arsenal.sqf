if (missionNamespace getVariable ["KPLIB_autoFactionActive", false]) exitWith {
    private _faction = toLower getText (configFile >> "CfgVehicles" >> (typeOf player) >> "faction");
    private _opforFactions = ((missionNamespace getVariable ["KPLIB_autoFactionCatalogs", createHashMap]) getOrDefault ["opfor", createHashMap]) getOrDefault ["factions", []];
    private _data = if (_faction in (_opforFactions apply {toLower _x})) then {
        missionNamespace getVariable ["KPLIB_autoFactionOpforArsenalData", createHashMap]
    } else {
        missionNamespace getVariable ["KPLIB_autoFactionPlayerArsenalData", createHashMap]
    };

    private _weapons = _data getOrDefault ["weapons", []];
    private _magazines = _data getOrDefault ["magazines", []];
    private _items = _data getOrDefault ["items", []];
    private _backpacks = _data getOrDefault ["backpacks", []];
    [missionNamespace, _weapons] call BIS_fnc_addVirtualWeaponCargo;
    [missionNamespace, _magazines] call BIS_fnc_addVirtualMagazineCargo;
    [missionNamespace, _items] call BIS_fnc_addVirtualItemCargo;
    [missionNamespace, _backpacks] call BIS_fnc_addVirtualBackpackCargo;

    private _allowed = _weapons + _magazines + _items + _backpacks;
    if (KP_liberation_ace && KP_liberation_arsenal_type) then {
        [player, _allowed, false] call ace_arsenal_fnc_addVirtualItems;
    };
    KP_liberation_allowed_items = _allowed apply {toLower _x};
};
