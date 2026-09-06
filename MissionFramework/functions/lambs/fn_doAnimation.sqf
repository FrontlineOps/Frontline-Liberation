/*
 * Author: joko (Jonas); original animation helper by commy2/ACE3.
 * Adapted from LAMBS Danger.fsm.
 * Source: addons/main/functions/fnc_doAnimation.sqf
 * Upstream commit: 63122df5d9403a52f10bf50198ac75a49f0a3d6b
 * Adapted 2026-08-27 for mission-local remote execution.
 * License: see NOTICE.md and LICENSE.LAMBS in this directory.
 */

params [
    ["_unit", objNull, [objNull]],
    ["_animation", "", [""]],
    ["_priority", 0, [0]]
];

if (_animation == "") then {
    _animation = toLowerANSI (animationState _unit);
    private _stance = switch (_animation select [4, 4]) do {
        case "ppne": {"pne"};
        case "pknl": {"knl"};
        case "perc": {"erc"};
        default {
            ["erc", "knl", "pne"] select ((["STAND", "CROUCH", "PRONE"] find stance _unit) max 0)
        };
    };
    private _speed = ["stp", "run"] select (vectorMagnitude (velocity _unit) > 1);
    private _weaponIndex = (["", primaryWeapon _unit, secondaryWeapon _unit, handgunWeapon _unit, binocular _unit] find currentWeapon _unit) max 0;
    private _weapon = ["non", "rfl", "lnr", "pst", "bin"] select _weaponIndex;
    private _weaponPos = [["ras", "low"] select (weaponLowered _unit), "non"] select (currentWeapon _unit == "");
    private _previous = ["non", _animation select [(count _animation) - 1, 1]] select ((_animation select [(count _animation) - 2, 2]) in ["df", "db", "dl", "dr"]);
    _animation = format ["AmovP%1M%2S%3W%4D%5", _stance, _speed, _weaponPos, _weapon, _previous];
    _animation = ["", _animation] select isClass (configFile >> "CfgMovesMaleSdr" >> "States" >> _animation);
};

private _command = ["playMove", "playMoveNow"] select (_priority min 1);
if (isNull objectParent _unit) then {
    [_unit, _animation] remoteExec [_command, _unit];
} else {
    [_unit, _animation] remoteExec [_command, 0];
};

if (_priority >= 2) then {
    [{
        params ["_unit", "_animation"];
        if (animationState _unit != _animation) then {
            [_unit, _animation] remoteExec ["switchMove", 0];
        };
    }, [_unit, _animation], 0.1] call CBA_fnc_waitAndExecute;
};
