/* Register before play, including JIP. Only the server changes shared settings. */
if (isRemoteExecuted || {localNamespace getVariable ["KPLIB_munitionsSettingsHook", false]}) exitWith {};
localNamespace setVariable ["KPLIB_munitionsSettingsHook", true];
["CBA_settingsInitialized", {
    [] call KPLIB_fnc_munitionsSettings;
}] call CBA_fnc_addEventHandler;
["CBA_SettingChanged", {
    params ["_setting"];
    if (_setting in ["ace_missileguidance_enabled", "ace_frag_enabled", "ace_frag_spallEnabled", "ace_frag_reflectionsEnabled"]
        && {!(localNamespace getVariable ["KPLIB_munitionsSettingsPending", false])}) then {
        localNamespace setVariable ["KPLIB_munitionsSettingsPending", true];
        [{
            localNamespace setVariable ["KPLIB_munitionsSettingsPending", false];
            [] call KPLIB_fnc_munitionsSettings;
        }, []] call CBA_fnc_execNextFrame;
    };
}] call CBA_fnc_addEventHandler;
