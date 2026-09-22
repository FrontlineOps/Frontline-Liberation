/* Local application only. Server commits and authenticated server snapshots
   are the only callers. Content/catalog generation remains in normal init. */
// HC-originated RPCs can report isRemoteExecuted=false. Require the private
// scope of an authorized local caller as well; network arguments cannot set it.
if (isRemoteExecuted || {isNil "_KPLIB_settingsApplyContext"}) exitWith {false};
params ["_revision", "_values"];
if (_revision <= (localNamespace getVariable ["KPLIB_settingsRevision", -1])) exitWith {false};
private _rows = localNamespace getVariable "KPLIB_settingsCatalog";
private _old = localNamespace getVariable ["KPLIB_settingsValues", []];
{
    missionNamespace setVariable [_x select 0, _values select _forEachIndex];
} forEach _rows;
[] call KPLIB_fnc_settingsDerive;

// Only these caches embed live policy. Existing jobs retain their profiles.
if (_old isNotEqualTo []) then {
    private _lookup = localNamespace getVariable "KPLIB_settingsLookup";
    {
        _x params ["_settings", "_cache"];
        if (!isNil {localNamespace getVariable _cache} && {
            _settings findIf {
                private _index = _lookup get _x;
                (_values select _index) isNotEqualTo (_old select _index)
            } >= 0
        }) then {
            localNamespace setVariable [_cache, createHashMap];
        };
    } forEach [
        [["KPLIB_aiCombat_rifleRange", "KPLIB_aiCombat_launcherRange", "KPLIB_aiCombat_grenadeRange",
          "KPLIB_aiCombat_rangeMultiplier", "KPLIB_aiCombat_minRifleRange", "KPLIB_aiCombat_blastMargin"], "KPLIB_aiCombat_profiles"],
        [["KPLIB_munitions_fragment_cap", "KPLIB_munitions_fragment_multiplier"], "KPLIB_munitionsFragProfiles"],
        [["KPLIB_munitions_thermal_labels"], "KPLIB_blastProfiles"]
    ];
};
localNamespace setVariable ["KPLIB_settingsValues", +_values];
localNamespace setVariable ["KPLIB_settingsRevision", _revision];
localNamespace setVariable ["KPLIB_settingsReady", true];
true
