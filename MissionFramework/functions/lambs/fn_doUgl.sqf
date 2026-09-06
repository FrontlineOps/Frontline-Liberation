/*
 * Author: nkenny
 * Adapted from LAMBS Danger.fsm.
 * Source: addons/main/functions/UnitAction/fnc_doUGL.sqf
 * Upstream commit: 63122df5d9403a52f10bf50198ac75a49f0a3d6b
 * Adapted 2026-08-27 for mission-local state variables.
 * License: see NOTICE.md and LICENSE.LAMBS in this directory.
 */

params [
    ["_units", objNull, [grpNull, objNull, []]],
    ["_pos", [], [[]]],
    ["_type", "shotIlluminating", [""]]
];

if (_units isEqualType objNull) then {_units = [_units]};
if (_units isEqualType grpNull) then {_units = units _units};

private _flare = "";
private _muzzle = "";
private _unitIndex = _units findIf {
    if (local _x && {!isPlayer _x}) then {
        private _weapon = primaryWeapon _x;
        if (_weapon isNotEqualTo "") then {
            _muzzle = (getArray (configFile >> "CfgWeapons" >> _weapon >> "muzzles") - ["SAFE", "this"]) param [0, ""];
            if (_muzzle isNotEqualTo "") then {
                private _findFlares = getArray (configFile >> "CfgWeapons" >> _weapon >> _muzzle >> "magazines");
                private _magazineWells = getArray (configFile >> "CfgWeapons" >> _weapon >> _muzzle >> "magazineWell");
                {
                    {
                        _findFlares append getArray _x;
                    } forEach configProperties [configFile >> "CfgMagazineWells" >> _x];
                } forEach _magazineWells;

                _findFlares = (_findFlares apply {toLower _x}) arrayIntersect ((magazines _x) apply {toLower _x});
                if (_findFlares isEqualTo []) exitWith {false};
                private _flareIndex = _findFlares findIf {
                    private _ammo = getText (configFile >> "CfgMagazines" >> _x >> "ammo");
                    private _simulation = getText (configFile >> "CfgAmmo" >> _ammo >> "simulation");
                    (_simulation find _type) != -1
                };
                if (_flareIndex == -1) exitWith {false};
                _flare = _findFlares select _flareIndex;
            };
        };
    };
    _flare isNotEqualTo ""
};

if (_unitIndex == -1) exitWith {_units};
private _unit = _units deleteAt _unitIndex;

doStop _unit;
_unit setUnitPosWeak "MIDDLE";
_unit setVariable ["KPLIB_lambs_forceMove", true];
_unit setVariable ["KPLIB_lambs_currentTask", "Shoot UGL"];
_unit setVariable ["KPLIB_lambs_currentTarget", objNull];

private _flarePos = [_pos, (_unit getPos [80, getDir leader _unit]) vectorAdd [0, 0, 200]] select (_pos isEqualTo []);
private _dummy = "CBA_buildingPos" createVehicle _flarePos;
_dummy setPos _flarePos;
_unit reveal _dummy;

_unit addMagazine (currentMagazine _unit);
_unit removeMagazine _flare;
_unit addWeaponItem [currentWeapon _unit, _flare];
_unit doTarget _dummy;

[{
    params ["_unit", "_muzzle", "_dummy"];
    _unit selectWeapon _muzzle;
    _unit forceWeaponFire [_muzzle, weaponState _unit select 2];
    _unit doWatch objNull;
    _unit doFollow (leader _unit);
    _unit setVariable ["KPLIB_lambs_forceMove", nil];
    deleteVehicle _dummy;
}, [_unit, _muzzle, _dummy], 2] call CBA_fnc_waitAndExecute;

_units
