/* ACE box inventories are local to each viewer, including role changes and JIP. */
params ["_box", "_unit"];
if (!hasInterface || {isNull _box} || {isNull _unit} || {side group _unit != GRLIB_side_friendly}) exitWith {};
if !(localNamespace getVariable ["KPLIB_manualFactions", false]) then {
    clearMagazineCargoGlobal _box;
    clearItemCargoGlobal _box;
    clearBackpackCargoGlobal _box;
    clearWeaponCargoGlobal _box;
};
[_box, false] call ace_arsenal_fnc_removeBox;
[_box, [_unit] call KPLIB_fnc_getRoleGear, false] call ace_arsenal_fnc_initBox;
