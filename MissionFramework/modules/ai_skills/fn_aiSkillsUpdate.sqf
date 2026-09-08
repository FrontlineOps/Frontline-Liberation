/* One registered unit. Called by the bounded server worker; terrain sampling
   is budgeted separately. Nothing here controls group movement or firing. */
params ["_state"];
if (!isServer || {isRemoteExecuted}) exitWith {};
private _unit = _state get "unit";
if (isNull _unit || {!local _unit} || {!alive _unit} || {isPlayer _unit}) exitWith {};
private _original = _state get "original";
private _eligible = KPLIB_aiSkills_enabled && {[_unit] call KPLIB_fnc_aiSkillsEligible};
if (!_eligible) exitWith {
    if (_state get "active") then {
        {_unit setSkill [_x, _original select _forEachIndex]} forEach KPLIB_aiSkills_names;
        _state set ["active", false];
        _state set ["suppression", 0];
        _state set ["boostShots", 0];
        _state set ["boostTarget", objNull];
        _state set ["factors", [0, 0, 1, 1]];
        if (KPLIB_aiSkills_debug) then {
            [format ["Restored original skills for %1 (outside active AI scope)", netId _unit], "AI SKILLS"] call KPLIB_fnc_log;
        };
    };
};

private _profile = "MISSION";
{
    if ((_x select 0) isEqualTo side group _unit) exitWith {_profile = _x select 1};
} forEach KPLIB_aiSkills_sideProfiles;
{
    if (toLower (_x select 0) == toLower faction _unit) exitWith {_profile = _x select 1};
} forEach KPLIB_aiSkills_factionProfiles;
_profile = toUpper _profile;
private _profiles = localNamespace getVariable "KPLIB_aiSkills_profiles";
if (!(_profile in _profiles)) then {_profile = "MISSION"};
private _configured = _profiles get _profile;
private _base = [];
{
    private _value = if (_x < 0) then {_original select _forEachIndex} else {
        _x * (1 + (_state get "variation") * KPLIB_aiSkills_variation)
    };
    _base pushBack (0 max (1 min _value));
} forEach _configured;
if (KPLIB_aiSkills_debug && {_profile != (_state get "profile")}) then {
    [format ["Assigned %1 profile to %2", _profile, netId _unit], "AI SKILLS"] call KPLIB_fnc_log;
};
_state set ["profile", _profile];
_state set ["base", _base];
_state set ["active", true];

private _now = CBA_missionTime;
private _decayFrom = (_state get "lastDecay") max ((_state get "lastThreat") + KPLIB_aiSkills_suppressionHold);
private _pressure = 0 max ((_state get "suppression") - (0 max (_now - _decayFrom)) / (0.1 max KPLIB_aiSkills_suppressionRecovery));
_state set ["suppression", _pressure];
_state set ["lastDecay", _now];
private _suppression = if (KPLIB_aiSkills_suppressionEnabled) then {1 min (_pressure max getSuppression _unit)} else {0};

private _weather = 1;
if (KPLIB_aiSkills_weatherEnabled) then {
    private _light = 0 max (1 min sunOrMoon);
    // Native vision, including thermal optics and fog layers, remains intact.
    // Equipped NVGs bypass only this module's additional darkness multiplier.
    private _night = if (hmd _unit != "") then {1} else {
        KPLIB_aiSkills_nightFloor + (1 - KPLIB_aiSkills_nightFloor) * _light
    };
    _weather = _night * (1 - (1 - KPLIB_aiSkills_rainFloor) * rain)
        * (1 - (1 - KPLIB_aiSkills_fogFloor) * fog);
};

private _boost = 1;
private _target = _state get "boostTarget";
if (KPLIB_aiSkills_boostEnabled && {(_state get "boostShots") > 0}) then {
    private _attackTarget = getAttackTarget _unit;
    if (isNull _attackTarget) then {_attackTarget = getAttackTarget (vehicle _unit)};
    private _valid = !isNull _target && {alive _target} && {!captive _target}
        && {_attackTarget isEqualTo _target}
        && {(side group _unit) getFriend (side _target) < 0.6}
        && {_now - (_state get "lastShot") <= KPLIB_aiSkills_boostExpiry}
        && {_unit distance _target >= KPLIB_aiSkills_boostMinDistance}
        && {((_unit targetKnowledge _target) param [1, false])}
        && {[vehicle _unit, "VIEW", _target] checkVisibility [eyePos _unit, aimPos _target] >= 0.5}
        && {getPosATL _target distance2D (_state get "boostPosition") <= KPLIB_aiSkills_boostTargetMovement};
    if (_valid) then {
        _boost = 1 + (KPLIB_aiSkills_boostMaximum - 1)
            * (1 min ((_state get "boostShots") / (1 max KPLIB_aiSkills_boostShots)));
    } else {
        _state set ["boostShots", 0];
        _state set ["boostTarget", objNull];
    };
} else {
    _state set ["boostShots", 0];
};
private _factors = [_state get "terrain", _suppression, _weather, _boost];
_state set ["factors", _factors];
private _skills = [_base, _factors select 0, _suppression, _weather, _boost] call KPLIB_fnc_aiSkillsCompose;
{
    private _value = _skills select _forEachIndex;
    if (abs ((_unit skill _x) - _value) > 0.001) then {_unit setSkill [_x, _value]};
} forEach KPLIB_aiSkills_names;
