/* All machines observe local shots; the server validates and solves exposure.
   ACE wounds run on the unit owner through its existing wound-handler pipeline. */
if (isRemoteExecuted || {localNamespace getVariable ["KPLIB_blastInitialized", false]}) exitWith {};
localNamespace setVariable ["KPLIB_blastInitialized", true];
localNamespace setVariable ["KPLIB_blastReady", false];
localNamespace setVariable ["KPLIB_blastProfiles", createHashMap];
localNamespace setVariable ["KPLIB_blastJobs", []];
localNamespace setVariable ["KPLIB_blastHistory", []];
localNamespace setVariable ["KPLIB_blastShots", createHashMap];
localNamespace setVariable ["KPLIB_blastPending", []];
localNamespace setVariable ["KPLIB_blastMetrics", createHashMapFromArray [["accepted", 0], ["rejected", 0], ["dropped", 0], ["cells", 0], ["maxTickMs", 0]]];
localNamespace setVariable ["KPLIB_munitionsEffectsReady", true];
// Clamp authoring mistakes before they can affect hot-path budgets.
{
    _x params ["_key", "_default", "_min", "_max"];
    private _value = missionNamespace getVariable [_key, _default];
    if (!(_value isEqualType 0) || {!finite _value}) then {_value = _default};
    missionNamespace setVariable [_key, (_value max _min) min _max];
} forEach [
    ["KPLIB_munitions_fragment_cap", 384, 1, 512],
    ["KPLIB_munitions_blast_gain", 0.08, 0, 0.25],
    ["KPLIB_munitions_pressure_gain", 8, 0, 20],
    ["KPLIB_munitions_blast_max_radius", 120, 5, 200],
    ["KPLIB_munitions_blast_max_jobs", 8, 1, 16],
    ["KPLIB_munitions_blast_cells", 256, 32, 512],
    ["KPLIB_munitions_blast_cells_per_tick", 12, 1, 24],
    ["KPLIB_munitions_blast_targets", 48, 1, 64],
    ["KPLIB_munitions_thermal_duration", 2, 0.5, 5],
    ["KPLIB_munitions_gas_radius", 24, 3, 32],
    ["KPLIB_munitions_gas_energy_per_hit", 2000, 1, 10000],
    ["KPLIB_munitions_gas_damage_gain", 1, 0, 3],
    ["KPLIB_munitions_gas_asset_limit", 8, 1, 16],
    ["KPLIB_munitions_gas_vehicle_gain", 1, 0, 4],
    ["KPLIB_munitions_gas_building_gain", 1, 0, 4]
];
// Initialization runs scheduled once; no configuration-wide scan during a shot.
[] spawn {
    waitUntil {sleep 0.1; !isNil "ace_medical_damage_damageTypeDetails" || {CBA_missionTime > 30}};
    if (isNil "ace_medical_damage_damageTypeDetails" || {isNil "ace_medical_fnc_addDamageToUnit"}) exitWith {
        diag_log "[Frontline Munitions] Blast exposure unavailable: ACE medical integration missing. Native damage retained.";
    };
    private _details = ace_medical_damage_damageTypeDetails getOrDefault ["explosive", []];
    if (count _details < 3 || {!((_details select 2) isEqualType [])} || {(_details select 2) isEqualTo []}) exitWith {
        diag_log "[Frontline Munitions] Unsupported ACE explosive wound-handler layout. Native damage retained.";
    };
    private _burnType = "";
    {
        private _entry = ace_medical_damage_damageTypeDetails get _x;
        if (count _entry >= 3 && {(_entry select 2) isNotEqualTo []}) then {
            // Grenades, shells and addon damage types need the same accounting.
            // The handler itself passes kinetic/unrelated inputs through unchanged.
            // Clone shared defaults before insertion; retain every existing handler.
            private _chain = +(_entry select 2);
            if (_chain findIf {_x select 0 == "KPLIB_blastWound"} < 0) then {
                // Account after ACE's armor/vehicle conversions, before wounds.
                _chain insert [(count _chain) - 1, [["KPLIB_blastWound", KPLIB_fnc_blastWound]]];
            };
            _entry set [2, _chain];
            if (_x in ["burn", "burning"]) then {_burnType = _x};
        };
    } forEach keys ace_medical_damage_damageTypeDetails;
    localNamespace setVariable ["KPLIB_blastBurnType", _burnType];
    private _labels = createHashMap;
    private _configs = "isClass _x" configClasses (configFile >> "CfgMagazines");
    {
        private _ammo = getText (_x >> "ammo");
        private _label = getText (_x >> "displayName") + " " + getText (_x >> "descriptionShort");
        if (_ammo != "") then {_labels set [_ammo, (_labels getOrDefault [_ammo, ""]) + " " + _label]};
        if (_forEachIndex mod 128 == 0) then {sleep 0.001};
    } forEach _configs;
    localNamespace setVariable ["KPLIB_blastLabels", _labels];
    localNamespace setVariable ["KPLIB_blastProfiles", createHashMap];
    localNamespace setVariable ["KPLIB_blastReady", true];

};

addMissionEventHandler ["ProjectileCreated", {
    params ["_projectile"];
    if (local _projectile) then {[KPLIB_fnc_blastObserve, [_projectile]] call CBA_fnc_execNextFrame};
}];
{
    [_x, "Fired", {[_this param [6, objNull]] call KPLIB_fnc_blastObserve}] call CBA_fnc_addClassEventHandler;
} forEach ["CAManBase", "LandVehicle", "Air", "Ship", "StaticWeapon"];
if (isServer) then {[KPLIB_fnc_blastTick, 0.02] call CBA_fnc_addPerFrameHandler};
