/*
    File: fn_doSave.sqf
    Author: KP Liberation Dev Team - https://github.com/KillahPotatoes
    Date: 2020-03-29
    Last Update: 2020-05-08
    License: MIT License - http://www.opensource.org/licenses/MIT

    Description:
        Save mission state to profileNamespace.

    Parameter(s):
        NONE

    Returns:
        Data was saved [BOOL]
*/

if (!isServer) exitWith {false};

if (!KPLIB_init) exitWith {
    ["Framework is not initalized, skipping save!", "SAVE"] call KPLIB_fnc_log;
    false
};

if (missionNamespace getVariable ["kp_liberation_saving", false]) exitWith {
    ["Saving already in progress, skipping save!", "SAVE"] call KPLIB_fnc_log;
    false
};

kp_liberation_saving = true;
private _saveStartedAt = diag_tickTime;

private _saveData = [] call KPLIB_fnc_getSaveData;

// Write data in the server profileNamespace
profileNamespace setVariable [GRLIB_save_key, str _saveData];
saveProfileNamespace;

KPLIB_lastSaveDuration = diag_tickTime - _saveStartedAt;
if (KP_liberation_savegame_debug > 0 || {KPLIB_lastSaveDuration >= 2}) then {
    [format ["Campaign save completed in %1 seconds", KPLIB_lastSaveDuration], "SAVE"] call KPLIB_fnc_log;
};

kp_liberation_saving = false;

true
