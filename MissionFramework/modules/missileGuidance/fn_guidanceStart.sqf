params [["_projectile", objNull, [objNull]]];
if (isRemoteExecuted || {isNull _projectile} || {!local _projectile}
    || {_projectile getVariable ["KPLIB_guidanceOwner", ""] != ""}) exitWith {-1};
private _parents = getShotParents _projectile;
private _shooter = _projectile getVariable ["KPLIB_guidanceShooter", _parents param [1, objNull]];
private _carrier = _projectile getVariable ["KPLIB_guidanceCarrier", _parents param [0, objNull]];
if (isNull _carrier && {!isNull _shooter}) then {_carrier = vehicle _shooter};
private _profile = [typeOf _projectile] call KPLIB_fnc_guidanceResolve;
([_profile, _shooter, _projectile] call KPLIB_fnc_guidanceBackend) params ["_backend", "_reason"];
_projectile setVariable ["KPLIB_guidanceOwner", _backend];
_projectile setVariable ["KPLIB_guidanceReason", _reason];
if (_backend != "CUSTOM") exitWith {-1};
private _active = localNamespace getVariable ["KPLIB_guidanceActive", createHashMap];
if (count _active >= (missionNamespace getVariable ["KPLIB_guidance_max_active", 128])) exitWith {
    _projectile setVariable ["KPLIB_guidanceOwner", "NATIVE"];
    _projectile setVariable ["KPLIB_guidanceReason", "Custom guidance capacity reached"];
    if (CBA_missionTime > (localNamespace getVariable ["KPLIB_guidanceLimitLog", -1])) then {
        ["Custom projectile capacity reached; native guidance retained", "GUIDANCE"] call KPLIB_fnc_log;
        localNamespace setVariable ["KPLIB_guidanceLimitLog", CBA_missionTime + 30];
    };
    -1
};
private _target = missileTarget _projectile;
if (!isNull _carrier && {local _carrier}) then {
    private _forced = _carrier getVariable ["forcedTarget", objNull];
    private _forcedAt = _carrier getVariable ["forcedTargetSetTime", -100];
    if (!isNull _forced && {abs (CBA_missionTime - _forcedAt) <= 2}) then {
        _target = _forced;
        _carrier setVariable ["forcedTarget", objNull];
    };
};
if (isNull _target && {!(_profile get "autoSeek")} && {(_profile get "family") != "LASER"}) exitWith {
    _projectile setVariable ["KPLIB_guidanceOwner", "NATIVE"];
    _projectile setVariable ["KPLIB_guidanceReason", "No designated target or autonomous acquisition capability"];
    -1
};
// Cancel the engine object seeker before taking ownership. No velocity/position rewrite.
_projectile setMissileTarget objNull;
if (!isNull missileTarget _projectile) exitWith {
    _projectile setVariable ["KPLIB_guidanceOwner", "NATIVE"];
    _projectile setVariable ["KPLIB_guidanceReason", "Native target could not be released"];
    -1
};
private _id = (localNamespace getVariable ["KPLIB_guidanceSequence", 0]) + 1;
localNamespace setVariable ["KPLIB_guidanceSequence", _id];
private _now = CBA_missionTime;
private _pos = getPosASL _projectile;
private _heading = vectorDir _projectile;
private _record = createHashMapFromArray [
    ["id", _id], ["missile", _projectile], ["type", _profile get "name"], ["profile", _profile],
    ["shooter", _shooter], ["carrier", _carrier], ["weapon", _projectile getVariable ["KPLIB_guidanceWeapon", ""]],
    ["originalTarget", _target], ["target", _target], ["launchPos", _pos],
    ["created", _now], ["lastTick", _now], ["nextSeeker", _now], ["nextSearch", _now],
    ["lastSeen", -1000], ["position", if (isNull _target) then {_pos vectorAdd (_heading vectorMultiply 1000)} else {aimPos _target}],
    ["velocity", [0,0,0]], ["acceleration", [0,0,0]], ["seekerDirection", _heading],
    ["locked", false], ["quality", 0], ["pitbull", false], ["support", objNull],
    ["phase", "LAUNCH"], ["phaseAt", _now], ["lastPosition", _pos],
    ["previousRelative", []], ["cmConsidered", []], ["warnTarget", objNull]
];
_active set [_id, _record];
localNamespace setVariable ["KPLIB_guidanceActive", _active];
_projectile setVariable ["KPLIB_guidanceId", _id];
if ((localNamespace getVariable ["KPLIB_guidancePFH", -1]) < 0) then {
    private _pfh = [{call KPLIB_fnc_guidanceTick}, 0] call CBA_fnc_addPerFrameHandler;
    localNamespace setVariable ["KPLIB_guidancePFH", _pfh];
    ["Flight dispatcher active", "GUIDANCE"] call KPLIB_fnc_log;
};
private _metrics = localNamespace getVariable "KPLIB_guidanceMetrics";
_metrics set ["started", (_metrics getOrDefault ["started", 0]) + 1];
_metrics set ["peak", (_metrics getOrDefault ["peak", 0]) max count _active];
if (missionNamespace getVariable ["KPLIB_guidance_debug", false]) then {
    [format ["%1 started %2 (%3)", _id, typeOf _projectile, _profile get "family"], "GUIDANCE"] call KPLIB_fnc_log;
};
_id
