/* Local application only. Server commits and authenticated server snapshots
   are the only callers. Content/catalog generation remains in normal init. */
// HC-originated RPCs can report isRemoteExecuted=false. Require the private
// scope of an authorized local caller as well; network arguments cannot set it.
if (isRemoteExecuted || {isNil "_KPLIB_settingsApplyContext"}) exitWith {false};
params ["_revision", "_values"];
if (_revision <= (localNamespace getVariable ["KPLIB_settingsRevision", -1])) exitWith {false};
private _rows = localNamespace getVariable "KPLIB_settingsCatalog";
private _old = localNamespace getVariable ["KPLIB_settingsValues", []];
private _changed = [];
{
    private _runtime = _x select 0;
    if (_old isEqualTo [] || {(_values select _forEachIndex) isNotEqualTo (_old select _forEachIndex)}) then {
        _changed pushBack _runtime;
    };
    missionNamespace setVariable [_runtime, _values select _forEachIndex];
} forEach _rows;
[] call KPLIB_fnc_settingsDerive;
localNamespace setVariable ["KPLIB_settingsValues", +_values];
localNamespace setVariable ["KPLIB_settingsRevision", _revision];
localNamespace setVariable ["KPLIB_settingsReady", true];

// Invalidate only metadata that actually embeds changed policy. Active jobs
// keep their existing profile; the next decision/explosion rebuilds lazily.
{
    _x params ["_keys", "_cache"];
    if (_changed findIf {_x in _keys} >= 0 && {!isNil {localNamespace getVariable _cache}}) then {
        localNamespace setVariable [_cache, createHashMap];
    };
} forEach [
    [["KPLIB_aiCombat_rifleRange", "KPLIB_aiCombat_launcherRange", "KPLIB_aiCombat_grenadeRange",
      "KPLIB_aiCombat_rangeMultiplier", "KPLIB_aiCombat_minRifleRange", "KPLIB_aiCombat_blastMargin"], "KPLIB_aiCombat_profiles"],
    [["KPLIB_munitions_fragment_cap", "KPLIB_munitions_fragment_multiplier"], "KPLIB_munitionsFragProfiles"],
    [["KPLIB_munitions_thermal_labels"], "KPLIB_blastProfiles"]
];
if (isServer) then {
    if (_changed findIf {_x in ["GRLIB_time_factor", "GRLIB_shorter_nights"]} >= 0) then {
        private _desiredMultiplier = GRLIB_time_factor * ([1, 4] select (GRLIB_shorter_nights && {daytime >= 20 || {daytime < 4}}));
        if (timeMultiplier != _desiredMultiplier) then {setTimeMultiplier _desiredMultiplier};
        diag_log format ["[FL SETTINGS] Time acceleration: base %1x, faster nights %2, effective %3x", GRLIB_time_factor, GRLIB_shorter_nights, _desiredMultiplier];
    };
    if ("KP_liberation_fog_param" in _changed && {!KP_liberation_fog_param}) then {5 setFog [0, 0, 0]};
};
if (_old isNotEqualTo [] && {hasInterface} && {!isNull player} && {typeOf player != "VirtualSpectator_F"}) then {
    if ("GRLIB_fatigue" in _changed) then {player enableStamina GRLIB_fatigue};
    if ("KPLIB_sway" in _changed) then {player setCustomAimCoef ([0.1, 1] select KPLIB_sway)};
};
true
