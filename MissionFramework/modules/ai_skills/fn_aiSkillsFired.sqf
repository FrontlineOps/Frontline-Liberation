/* Aiming practice applies only to a real visible hostile target. No new target
   search, reveal, combat order, ammo changes or per-shooter script is created. */
params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo"];
if (!isServer || {isRemoteExecuted} || {!KPLIB_aiSkills_enabled}
    || {!KPLIB_aiSkills_boostEnabled} || {!([_unit] call KPLIB_fnc_aiSkillsEligible)}) exitWith {};
if (!(_ammo isKindOf ["BulletBase", configFile >> "CfgAmmo"])) exitWith {};
private _state = (localNamespace getVariable "KPLIB_aiSkills_registry") getOrDefault [netId _unit, createHashMap];
if (count _state == 0) exitWith {};
private _now = CBA_missionTime;
if (_now - (_state get "lastShot") < KPLIB_aiSkills_boostShotInterval) exitWith {};
private _target = getAttackTarget _unit;
if (isNull _target) then {_target = getAttackTarget (vehicle _unit)};
if (isNull _target || {!alive _target} || {captive _target}
    || {(side group _unit) getFriend (side _target) >= 0.6}
    || {_unit distance _target < KPLIB_aiSkills_boostMinDistance}) exitWith {};
if (!((_unit targetKnowledge _target) param [1, false])) exitWith {};
// Ignore the shooter's own platform so its cabin/turret cannot block this ray.
if ([vehicle _unit, "VIEW", _target] checkVisibility [eyePos _unit, aimPos _target] < 0.5) exitWith {};
private _position = getPosATL _target;
if (_target isNotEqualTo (_state get "boostTarget")
    || {_now - (_state get "lastShot") > KPLIB_aiSkills_boostExpiry}
    || {_position distance2D (_state get "boostPosition") > KPLIB_aiSkills_boostTargetMovement}) then {
    _state set ["boostShots", 0];
    _state set ["boostPosition", _position];
};
_state set ["boostTarget", _target];
_state set ["boostShots", KPLIB_aiSkills_boostShots min ((_state get "boostShots") + 1)];
_state set ["lastShot", _now];
