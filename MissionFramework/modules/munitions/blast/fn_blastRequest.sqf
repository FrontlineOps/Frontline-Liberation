/* No client-supplied ammo, target or damage. A burst must consume a shot which
   the server observed while its projectile existed and belonged to that sender. */
if (!isServer || {!(localNamespace getVariable ["KPLIB_munitionsEffectsReady", false])}) exitWith {};
params [["_action", "", [""]], ["_serial", -1, [0]], ["_projectile", objNull, [objNull]], ["_position", [], [[]]]];
private _sender = if (isRemoteExecuted) then {remoteExecutedOwner} else {2};
private _metrics = localNamespace getVariable "KPLIB_blastMetrics";
if (!finite _serial || {_serial < 0} || {_serial != floor _serial}) exitWith {};
private _shots = localNamespace getVariable "KPLIB_blastShots";
private _key = str [_sender, _serial];
if (_action == "SHOT") exitWith {
    if (count _shots >= 128 || {_key in _shots}) exitWith {_metrics set ["dropped", 1 + (_metrics get "dropped")]};
    if (isNull _projectile || {owner _projectile != _sender && {!(_sender == 2 && {local _projectile})}}) exitWith {_metrics set ["rejected", 1 + (_metrics get "rejected")]};
    if (_projectile getVariable ["KPLIB_blastServerRegistered", false]) exitWith {};
    private _profile = [typeOf _projectile] call KPLIB_fnc_blastProfile;
    if !(_profile get "eligible") exitWith {};
    private _parents = getShotParents _projectile;
    private _source = _parents param [1, objNull];
    private _launcher = _parents param [0, objNull];
    if (_sender != 2 && {isNull _launcher || {owner _launcher != _sender && {isNull _source || {owner _source != _sender}}}}) exitWith {};
    // An observed projectile may have travelled one frame before registration.
    private _speed = vectorMagnitude velocity _projectile;
    if (_sender != 2 && {_projectile distance _launcher > (30 + _speed * 0.5)}) exitWith {};
    private _ttl = (getNumber (configOf _projectile >> "timeToLive") max 10) min 600;
    _projectile setVariable ["KPLIB_blastServerRegistered", true];
    _shots set [_key, [_projectile, _profile, _source, getPosASL _projectile, CBA_missionTime, _speed, CBA_missionTime + _ttl, _sender]];
};
if (_action != "BURST") exitWith {};
private _shot = _shots getOrDefault [_key, []];
if (_shot isEqualTo []) exitWith {_metrics set ["rejected", 1 + (_metrics get "rejected")]};
// Consume before further processing: a bad report cannot be retried into damage.
_shots deleteAt _key;
if (count _position != 3 || {_position findIf {!(_x isEqualType 0) || {!finite _x} || {abs _x > 1000000}} >= 0}) exitWith {};
_shot params ["_observed", "_profile", "_source", "_last", "_at", "_speed", "_until"];
if (!isNull _observed) then {
    if (owner _observed != _sender && {!(_sender == 2 && {local _observed})}) exitWith {_at = -100};
    _last = getPosASL _observed;
    _speed = vectorMagnitude velocity _observed;
    _at = CBA_missionTime;
};
private _elapsed = CBA_missionTime - _at;
if (_elapsed > 0.5 || {CBA_missionTime > _until} || {_last distance _position > (3 + (_speed min 2500) * (_elapsed max 0.05))}) exitWith {
    _metrics set ["rejected", 1 + (_metrics get "rejected")];
};
// Leave the remote execution context before entering server-only simulation.
private _pending = localNamespace getVariable "KPLIB_blastPending";
if (count _pending >= 16) exitWith {_metrics set ["dropped", 1 + (_metrics get "dropped")]};
// Use the server's recent observation time, never a client timestamp. Queue
// delay must not restart the medical-credit or total work deadline.
_pending pushBack [_key, _profile, _source, +_position, _at];
