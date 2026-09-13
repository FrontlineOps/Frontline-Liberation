if (isRemoteExecuted) exitWith {};
// A scheduled caller can otherwise yield between reading a free slot and
// publishing its stamp while ProjectileCreated registers that same object.
// This bounded admission path must complete atomically on the projectile owner.
if (canSuspend) exitWith {
    isNil {_this call KPLIB_fnc_munitionsTrack};
};
params [["_projectile", objNull, [objNull]], ["_parentId", -1, [0]]];
if (isNull _projectile || {!local _projectile} || {CBA_missionTime >= (localNamespace getVariable ["KPLIB_munitionsUntil", -1])}) exitWith {};
private _session = localNamespace getVariable "KPLIB_munitionsSession";
private _stamp = _projectile getVariable ["KPLIB_munitionsStamp", [-2, -1]];
if ((_stamp select 0) == _session) exitWith {
    if ((_stamp select 1) >= 0) then {
        private _shot = (localNamespace getVariable "KPLIB_munitionsShots") select (_stamp select 1);
        if ((_shot get "projectile") isNotEqualTo _projectile) exitWith {};
        // Creation can precede native placement. The explicit creator/next-frame
        // retry fills that missing start without registering duplicate handlers.
        private _placed = getPosASL _projectile;
        if ((_shot get "points") isEqualTo [] && {_placed isNotEqualTo [0,0,0]}) then {
            [_shot, _placed] call KPLIB_fnc_munitionsPoint;
        };
        if (_parentId >= 0) then {
            _shot set ["parent", _parentId];
            _shot set ["kind", [typeOf _projectile, _parentId] call KPLIB_fnc_munitionsKind];
        };
    };
};
private _position = getPosASL _projectile;
private _visualBurst = _projectile getVariable ["KPLIB_munitionsVisualBurst", []];
private _burstPosition = if (_visualBurst isEqualTo []) then {_position} else {_visualBurst select 0};
private _burstAt = if (_visualBurst isEqualTo []) then {CBA_missionTime} else {_visualBurst select 1};
if (!(localNamespace getVariable ["KPLIB_munitionsLive", false]) && {_position distance (localNamespace getVariable "KPLIB_munitionsCenter") > 750}) exitWith {};
private _shots = localNamespace getVariable "KPLIB_munitionsShots";
private _kind = [typeOf _projectile, _parentId] call KPLIB_fnc_munitionsKind;
if (_projectile getVariable ["KPLIB_munitionsParticleKind", ""] == "SPALL") then {_kind = "CHILD"};
private _category = [0,1] select (_kind == "FRAGMENT" || {_projectile getVariable ["KPLIB_munitionsParticle", false]});
private _live = localNamespace getVariable ["KPLIB_munitionsLive", false];
private _capacity = ([64, [128,2048] select _live] select _category);
private _metrics = localNamespace getVariable ["KPLIB_munitionsCaptureMetrics", [0,0,0,0,0]];
private _counts = localNamespace getVariable ["KPLIB_munitionsCaptureCounts", [0,0]];
_metrics set [_category, 1 + (_metrics select _category)];
localNamespace setVariable ["KPLIB_munitionsCaptureMetrics", _metrics];
private _slot = count _shots;
if ((_counts select _category) >= _capacity && {_live}) then {
    private _oldest = 1e12;
    private _bursts = localNamespace getVariable ["KPLIB_munitionsBursts", []];
    private _incoming = _bursts findIf {
        abs (_burstAt - (_x select 1)) <= 0.5 && {_burstPosition distance (_x select 2) <= 2}
    };
    private _incomingId = if (_incoming < 0) then {-2} else {(_bursts select _incoming) select 0};
    {
        if ((_x get "ended") && {(_x getOrDefault ["captureCategory", [0,1] select ((_x get "kind") == "FRAGMENT")]) == _category}
            && {(_x getOrDefault ["historyBurst", -1]) != _incomingId}
            && {(_x get "at") < _oldest}) then {
            _oldest = _x get "at";
            _slot = _forEachIndex;
        };
    } forEach _shots;
};
if (_slot == count _shots && {(_counts select _category) >= _capacity}) exitWith {
    _projectile setVariable ["KPLIB_munitionsStamp", [_session, -1]];
    _metrics set [_category + 2, 1 + (_metrics select (_category + 2))];
    localNamespace setVariable ["KPLIB_munitionsDropped", 1 + (localNamespace getVariable "KPLIB_munitionsDropped")];
};
if (_slot == count _shots) then {
    _counts set [_category, 1 + (_counts select _category)];
} else {
    localNamespace setVariable ["KPLIB_munitionsEvicted", 1 + (localNamespace getVariable ["KPLIB_munitionsEvicted", 0])];
    // Retire visibility for the old burst together instead of thinning it as
    // individual finished slots are reused. Actual projectiles are untouched.
    private _oldBurst = (_shots select _slot) getOrDefault ["historyBurst", -1];
    private _bursts = localNamespace getVariable ["KPLIB_munitionsBursts", []];
    private _burstIndex = _bursts findIf {(_x select 0) == _oldBurst};
    if (_burstIndex >= 0) then {
        _bursts deleteAt _burstIndex;
        localNamespace setVariable ["KPLIB_munitionsBurstEvicted", 1 + (localNamespace getVariable ["KPLIB_munitionsBurstEvicted", 0])];
    };
};
localNamespace setVariable ["KPLIB_munitionsCaptureCounts", _counts];
private _id = localNamespace getVariable ["KPLIB_munitionsNextShot", 0];
localNamespace setVariable ["KPLIB_munitionsNextShot", _id + 1];
_projectile setVariable ["KPLIB_munitionsStamp", [_session, _slot, _id]];
private _handlers = [];
_handlers pushBack ["HitPart", _projectile addEventHandler ["HitPart", {
    params ["_projectile", "_target", "", "_position", "_velocity", "_normal", "", "", "_surface"];
    [_projectile, "HIT", _position, [typeOf _target, _surface, vectorMagnitude _velocity, _normal], _target] call KPLIB_fnc_munitionsEvent;
}]];
_handlers pushBack ["Penetrated", _projectile addEventHandler ["Penetrated", {
    params ["_projectile", "_target", "_surface", "_entry", "_exit", "_velocity"];
    [_projectile, "PENETRATED", _exit, [typeOf _target, _surface, _entry, vectorMagnitude _velocity], _target] call KPLIB_fnc_munitionsEvent;
}]];
_handlers pushBack ["Deflected", _projectile addEventHandler ["Deflected", {
    params ["_projectile"];
    [_projectile, "DEFLECTED", getPosASL _projectile] call KPLIB_fnc_munitionsEvent;
}]];
_handlers pushBack ["Deleted", _projectile addEventHandler ["Deleted", {
    params ["_projectile"];
    // The object still exposes its final native position inside Deleted.
    [_projectile, "DELETED", getPosASL _projectile] call KPLIB_fnc_munitionsEvent;
}]];
_handlers pushBack ["SubmunitionCreated", _projectile addEventHandler ["SubmunitionCreated", {
    params ["_projectile", "_child"];
    private _stamp = _projectile getVariable ["KPLIB_munitionsStamp", [-1, -1]];
    [_child, _stamp param [2, _stamp select 1]] call KPLIB_fnc_munitionsTrack;
    [_projectile, "SUBMUNITION", getPosASL _child, [typeOf _child, _child getVariable ["KPLIB_munitionsStamp", []], "mission penetration hook", _child getVariable ["KPLIB_munitionsSpall", false]]] call KPLIB_fnc_munitionsEvent;
}]];
_shots set [_slot, createHashMapFromArray [
    ["id", _id], ["parent", _parentId], ["projectile", _projectile], ["ammo", typeOf _projectile],
    ["at", CBA_missionTime], ["speed", vectorMagnitude velocity _projectile], ["parents", (getShotParents _projectile) apply {typeOf _x}],
    ["visualBurst", _visualBurst], ["effect", _projectile getVariable ["KPLIB_munitionsParticleKind", ""]],
    ["points", [[],[+_position]] select (_position isNotEqualTo [0,0,0])], ["handlers", _handlers], ["state", ""], ["stateKey", []], ["ended", false],
    ["kind", _kind], ["captureCategory", _category], ["pointOmissions", 0], ["anchors", []],
    ["hasEndpoint", false], ["terminalKind", ""], ["nextState", 0]
]];
private _active = localNamespace getVariable ["KPLIB_munitionsActiveTraces", []];
_active pushBack (_shots select _slot);
localNamespace setVariable ["KPLIB_munitionsActiveTraces", _active];
[_shots select _slot, _position] call KPLIB_fnc_munitionsBurst;
