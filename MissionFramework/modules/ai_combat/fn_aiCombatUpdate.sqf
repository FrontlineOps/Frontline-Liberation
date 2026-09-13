/* Bounded native aiming orders. The engine needs repeated fire requests to
   retain a launcher while a rifle is carried. Native inventory and animations. */
params ["_state"];
if (!isServer || {isRemoteExecuted}) exitWith {};
private _unit = _state get "unit";
private _job = _state get "job";
if (count _job == 0) exitWith {};
private _reason = [_unit] call KPLIB_fnc_aiCombatEligible;
if (_reason != "") exitWith {[_state, _reason] call KPLIB_fnc_aiCombatFinish};
if (group _unit != (_job get "group")) exitWith {[_state, "Group changed"] call KPLIB_fnc_aiCombatFinish};
private _now = CBA_missionTime;
if (_job get "fired" && {(_job get "profile") get "kind" != "RIFLE"}) exitWith {[_state, _job getOrDefault ["release", "Shot confirmed"]] call KPLIB_fnc_aiCombatFinish};
if (_now > (_job get "deadline")) exitWith {[_state, "Aim/reload timeout"] call KPLIB_fnc_aiCombatFinish};
private _profile = _job get "profile";
private _kind = _profile get "kind";
private _target = _job get "target";
private _position = _job get "position";
if (_kind != "FLARE") then {
    if (!([_unit, _target] call KPLIB_fnc_aiCombatVisible)) exitWith {_reason = "Sight lost"};
    _position = aimPos _target;
    if (_kind in ["RPG", "GL"]) then {_position = (getPosASL _target) vectorAdd [0, 0, 0.15]};
    // Aim rockets at the lower body; grenades at the ground beside the target.
    if (_kind == "RPG") then {_position = (getPosASL _target) vectorAdd ((aimPos _target vectorDiff getPosASL _target) vectorMultiply 0.5)};
    private _range = _unit distance _target;
    if (_range < (_profile get "minimum") || {_range > (_profile get "range")}) exitWith {_reason = "Target outside weapon range"};
};
if (_kind == "FLARE" && {(!KPLIB_aiCombat_flares) || {sunOrMoon >= 0.2}}) then {_reason = "Illumination no longer needed"};
if (_reason != "") exitWith {[_state, _reason] call KPLIB_fnc_aiCombatFinish};
if (vectorMagnitude velocity _unit > 3) exitWith {[_state, "Moving"] call KPLIB_fnc_aiCombatFinish};
_reason = [_unit, _position, _profile, _target] call KPLIB_fnc_aiCombatSafe;
if (_reason != "") exitWith {[_state, _reason] call KPLIB_fnc_aiCombatFinish};
private _weapon = _profile get "weapon";
private _muzzle = _profile get "muzzle";
private _aimPosition = _position;
if (_kind in ["RPG", "GL"]) then {
    if (!(_job get "solved")) exitWith {_reason = "Solving trajectory"};
    private _solution = _job get "solution";
    if (_solution isEqualTo []) exitWith {_reason = "No reachable low arc"};
    if (_position vectorDistance (_job get "position") > 8) exitWith {_reason = "Target moved: reacquire arc"};
    _aimPosition = _solution select 0;
    _unit doTarget _target;
    _unit doWatch _target;
};
if (_reason == "Solving trajectory") exitWith {};
if (_reason != "") exitWith {[_state, _reason] call KPLIB_fnc_aiCombatFinish};
private _fireQueue = localNamespace getVariable "KPLIB_combatFire_queue";
private _fireKey = netId _unit;
if (_fireKey in _fireQueue) then {(_fireQueue get _fireKey) set [3, _now + 1.25]};
private _loaded = _unit weaponState _muzzle;
if (_kind == "RIFLE" && {_loaded param [4, 0] <= 0} && {_loaded param [6, 1] <= 0}
    && {_now > _job getOrDefault ["loadAt", -1]}) then {
    _unit reload [_muzzle, _profile get "magazine"];
    _job set ["loadAt", _now + 2];
};
_job set ["loaded", _loaded];
if ((_loaded param [3, ""]) != (_profile get "magazine") || {(_loaded param [4, 0]) < 1}
    || {(_loaded param [6, 1]) > 0} || {(_loaded param [5, 1]) > 0}) exitWith {};
if (_kind == "RIFLE") then {_unit doWatch _target};
if (_kind == "FLARE") then {_unit doWatch (ASLToAGL _position)};
private _aim = vectorNormalized (_aimPosition vectorDiff eyePos _unit);
private _selected = currentWeapon _unit == _weapon && {currentMuzzle _unit == _muzzle};
private _direction = _unit weaponDirection currentWeapon _unit;
// The current weapon's barrel direction is valid for rifles; the UGL shares
// its parent model. Launcher draw animations temporarily swing the barrel.
private _flatAim = vectorNormalized [_aim select 0, _aim select 1, 0];
private _flatGun = vectorNormalized [_direction select 0, _direction select 1, 0];
private _aligned = _flatAim vectorDotProduct _flatGun > 0.999;
if (_kind == "RIFLE") then {_aligned = _aligned && {_aim vectorDotProduct _direction > 0.985}};
if (_kind in ["RPG", "GL", "FLARE"]) then {
    // Native AI weapon selection/UGL elevation is unreliable across configs.
    // Require safe azimuth here; Fired applies the solved elevation once.
    private _body = vectorDir _unit;
    _aligned = _flatAim vectorDotProduct (vectorNormalized [_body select 0, _body select 1, 0]) > 0.985;
};
_job set ["alignment", [_aligned, _selected, _direction]];
if (!_aligned || {_now - (_job get "started") < 2} || {_now < (_job get "nextFire")}) exitWith {};
if (_kind == "RIFLE") exitWith {
    (localNamespace getVariable "KPLIB_combatFire_queue") set [netId _unit, [false, _state, _job get "fire", _now + 1.25]];
};
if ((_job get "attempts") >= (if (_kind == "RPG") then {80} else {12})) exitWith {[_state, "Native muzzle did not fire"] call KPLIB_fnc_aiCombatFinish};
_job set ["attempts", (_job get "attempts") + 1];
_job set ["nextFire", _now + (if (_kind == "RPG") then {0.25} else {1.5})];
if (_kind == "RPG") then {_unit selectWeapon _muzzle};
_unit forceWeaponFire [_muzzle, _profile get "mode"];
