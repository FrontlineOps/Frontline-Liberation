/* CBA owns replication/JIP. Priority 2 is server-forced; store=false keeps
   these overrides in this mission session rather than the user's profile. */
if (isRemoteExecuted || {isNil "CBA_settings_fnc_set"}) exitWith {};
private _available = [];
private _changed = [];
// ACE 3.21 retains this as a runtime switch, no longer a registered CBA setting.
// Apply it locally on server, clients and JIP without inventing a CBA entry.
if (isClass (configFile >> "CfgPatches" >> "ace_missileguidance")
    && {isNil {["ace_missileguidance_enabled", "default"] call CBA_settings_fnc_get}}) then {
    _available pushBack "missile guidance (runtime switch)";
    if (missionNamespace getVariable ["ace_missileguidance_enabled", 0] != 0) then {
        missionNamespace setVariable ["ace_missileguidance_enabled", 0];
        _changed pushBack "ace_missileguidance_enabled";
    };
};
{
    _x params ["_key", "_value", "_label"];
    private _default = [_key, "default"] call CBA_settings_fnc_get;
    if (!isNil "_default") then {
        _available pushBack _label;
        if (isServer) then {
            private _before = missionNamespace getVariable [_key, _default];
            [_key, _value, 2, "server", false] call CBA_settings_fnc_set;
            if (_before isNotEqualTo _value) then {_changed pushBack _key};
        };
    };
} forEach [
    ["ace_missileguidance_enabled", 0, "missile guidance"],
    ["ace_frag_enabled", false, "fragmentation"],
    ["ace_frag_spallEnabled", false, "spalling"],
    ["ace_frag_reflectionsEnabled", false, "explosion reflections"]
];
if (_changed isNotEqualTo []) then {
    diag_log format ["[FL MUNITIONS] WARNING: mission ownership forced competing ACE settings OFF for this session: %1. ACE medical remains active.", _changed];
};
if (_available isNotEqualTo [] && {!(localNamespace getVariable ["KPLIB_munitionsSettingsNotice", false])}) then {
    localNamespace setVariable ["KPLIB_munitionsSettingsNotice", true];
    private _message = format ["Frontline: ACE %1 disabled for this mission; Frontline owns these effects. ACE medical remains active.", _available joinString ", "];
    diag_log ("[FL MUNITIONS] " + _message);
    if (hasInterface) then {
        [{!isNull player && {time > 0}}, {systemChat (_this select 0)}, [_message]] call CBA_fnc_waitUntilAndExecute;
    };
};
