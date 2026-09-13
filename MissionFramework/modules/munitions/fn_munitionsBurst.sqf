/* Owner-local display association only. Nearby creation/impact observations
   share a deadline; this is not a claim of physical fragment parenthood. */
if (isRemoteExecuted || {!(localNamespace getVariable ["KPLIB_munitionsLive", false])}) exitWith {};
params ["_shot", "_position", ["_exploded", false]];
if ((_shot getOrDefault ["historyBurst", -1]) >= 0) exitWith {};
if (!_exploded && {(_shot getOrDefault ["kind", "PROJECTILE"]) != "FRAGMENT"}) exitWith {};
private _visualBurst = _shot getOrDefault ["visualBurst", []];
if (_visualBurst isNotEqualTo []) then {_position = _visualBurst select 0};
if (count _position != 3 || {_position isEqualTo [0,0,0]}
    || {_position findIf {!(_x isEqualType 0) || {!finite _x}} >= 0}) exitWith {};

private _now = CBA_missionTime;
private _at = if (_exploded) then {_now} else {_shot get "at"};
if (_visualBurst isNotEqualTo []) then {_at = _visualBurst select 1};
private _bursts = (localNamespace getVariable ["KPLIB_munitionsBursts", []]) select {
    (_x select 3) > _now
};
private _index = _bursts findIf {
    abs (_at - (_x select 1)) <= 0.5 && {_position distance (_x select 2) <= 2}
};
if (_index < 0) then {
    if (count _bursts >= 8) then {
        _bursts deleteAt 0;
        localNamespace setVariable ["KPLIB_munitionsBurstEvicted", 1 + (localNamespace getVariable ["KPLIB_munitionsBurstEvicted", 0])];
    };
    private _id = localNamespace getVariable ["KPLIB_munitionsNextBurst", 0];
    localNamespace setVariable ["KPLIB_munitionsNextBurst", _id + 1];
    _index = _bursts pushBack [_id, _at, +_position, _at + 60];
};
private _burst = _bursts select _index;
_shot set ["historyBurst", _burst select 0];
_shot set ["historyUntil", _burst select 3];
localNamespace setVariable ["KPLIB_munitionsBursts", _bursts];
