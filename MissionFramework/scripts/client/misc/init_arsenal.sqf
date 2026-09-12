if (side group player != GRLIB_side_friendly) exitWith {};
if ((localNamespace getVariable ["KPLIB_manualFactions", false])) exitWith {[] call KPLIB_fnc_refreshVirtualArsenal};

if (missionNamespace getVariable ["KPLIB_autoFactionActive", false]) exitWith {
    private _data = missionNamespace getVariable ["KPLIB_autoFactionPlayerArsenalData", createHashMap];

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
