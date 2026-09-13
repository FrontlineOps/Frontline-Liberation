/* Every machine registers the same controls. CBA owns requested settings;
   the server owns a separate, validated active-session snapshot. */
if (isRemoteExecuted || {localNamespace getVariable ["KPLIB_settingsRegistered", false]}) exitWith {};
localNamespace setVariable ["KPLIB_settingsRegistered", true];
localNamespace setVariable ["KPLIB_settingsReady", false];
localNamespace setVariable ["KPLIB_settingsRevision", -1];
localNamespace setVariable ["KPLIB_settingsValues", []];
localNamespace setVariable ["KPLIB_settingsScheduled", false];
private _rows = [];
private _add = {
    params ["_runtime", "_type", "_title", "_tip", "_category", "_data", "_live"];
    private _key = "KPLIB_cfg_" + _runtime;
    private _default = switch (_type) do {
        case "SLIDER": {_data select 2};
        case "LIST": {(_data select 0) select (_data select 2)};
        default {_data};
    };
    _rows pushBack [_runtime, _key, _type, _data, _live, _title, _category, _default];
    [_key, _type, [_title, _tip], _category, _data, 1, {}, !_live] call CBA_fnc_addSetting;
};
#include "sections\campaign.sqf"
#include "sections\bases_logistics.sqf"
#include "sections\ai.sqf"
#include "sections\enemy_operations.sqf"
#include "sections\enemy_support.sqf"
#include "sections\intelligence_civilians.sqf"
#include "sections\munitions_guidance.sqf"
#include "sections\cleanup_diagnostics.sqf"
#include "sections\player_zeus.sqf"
localNamespace setVariable ["KPLIB_settingsCatalog", _rows];
private _lookup = createHashMap;
{_lookup set [_x select 0, _forEachIndex]} forEach _rows;
localNamespace setVariable ["KPLIB_settingsLookup", _lookup];
["CBA_settingsInitialized", {
    if (isServer) then {
        private _KPLIB_settingsCommitContext = true;
        [] call KPLIB_fnc_settingsCommit;
    };
}] call CBA_fnc_addEventHandler;
["CBA_SettingChanged", {
    params ["_key"];
    if (!isServer || {_key find "KPLIB_cfg_" != 0}
        || {!(localNamespace getVariable ["KPLIB_settingsReady", false])}
        || {localNamespace getVariable ["KPLIB_settingsScheduled", false]}) exitWith {};
    localNamespace setVariable ["KPLIB_settingsScheduled", true];
    [{
        localNamespace setVariable ["KPLIB_settingsScheduled", false];
        private _KPLIB_settingsCommitContext = true;
        [] call KPLIB_fnc_settingsCommit;
    }, []] call CBA_fnc_execNextFrame;
}] call CBA_fnc_addEventHandler;
