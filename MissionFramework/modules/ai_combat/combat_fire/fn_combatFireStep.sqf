/* Called after the subsystem's current safety, aim and native reload checks.
   At most one trigger per actor per frame: never catch up with a salvo. */
if (isRemoteExecuted || {isNil "_KPLIB_combatFireContext"}) exitWith {};
params ["_unit", "_profile", "_fire", "_distance", ["_single", false]];
private _now = CBA_missionTime;
if (_now < _fire getOrDefault ["next", 0]) exitWith {};
if (_fire getOrDefault ["remaining", 0] <= 0) then {
    private _plan = [_profile get "fireModes", _distance, _single] call KPLIB_fnc_combatFirePlan;
    // Guided launchers retain the previously selected native guidance mode.
    if (_single) then {
        private _index = (_profile get "fireModes") findIf {_x select 0 == _profile get "mode" && {_x select 2 == 1}};
        if (_index >= 0) then {
            private _mode = (_profile get "fireModes") select _index;
            _plan = [_mode select 0, _mode select 4, 1, _mode select 4, _mode select 0];
        } else {_plan = []};
    };
    _fire set ["plan", _plan];
    if (_plan isNotEqualTo []) then {_fire set ["remaining", _plan select 2]};
};
private _plan = _fire getOrDefault ["plan", []];
if (_plan isEqualTo []) exitWith {_fire set ["unsupported", true]};
_fire set ["attempt", _now];
_fire set ["next", _now + (_plan select 1)];
_unit forceWeaponFire [_profile get "muzzle", _plan select 0];
