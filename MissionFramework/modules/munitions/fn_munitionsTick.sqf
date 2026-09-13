if (isRemoteExecuted) exitWith {};
if (CBA_missionTime >= (localNamespace getVariable ["KPLIB_munitionsUntil", -1])) exitWith {
    // Local expiry follows exactly the same cleanup as the trusted server command.
    private _pfh = localNamespace getVariable ["KPLIB_munitionsPFH", -1];
    if (_pfh >= 0) then {[_pfh] call CBA_fnc_removePerFrameHandler};
    localNamespace setVariable ["KPLIB_munitionsPFH", -1];
    {
        private _p = _x get "projectile";
        if (!isNull _p) then {{_p removeEventHandler _x} forEach (_x get "handlers")};
    } forEach (localNamespace getVariable ["KPLIB_munitionsShots", []]);
    localNamespace setVariable ["KPLIB_munitionsActiveTraces", []];
    localNamespace setVariable ["KPLIB_munitionsLivePathCache", []];
};
{
    if (_x get "ended") then {continue};
    private _projectile = _x get "projectile";
    if (isNull _projectile || {!local _projectile}) then {
        if (!isNull _projectile) then {
            {_projectile removeEventHandler _x} forEach (_x get "handlers");
        };
        _x set ["ended", true];
        _x set ["endedAt", CBA_missionTime];
        _x set ["state", (_x get "state") + " / deleted or ownership left this machine"];
        continue;
    };
    [_x, getPosASL _projectile, false, true] call KPLIB_fnc_munitionsPoint;
    if ((_x getOrDefault ["captureCategory", 0]) == 1 || {CBA_missionTime < (_x getOrDefault ["nextState", 0])}) then {continue};
    _x set ["nextState", CBA_missionTime + 0.1];
    private _state = [
        _projectile getVariable ["KPLIB_guidanceOwner", "NATIVE/unclassified"],
        _projectile getVariable ["KPLIB_guidanceReason", ""]
    ];
    _state pushBack ["mission penetration hook", _projectile getVariable ["KPLIB_munitionsSpall", false]];
    private _active = localNamespace getVariable ["KPLIB_guidanceActive", createHashMap];
    private _guidanceId = _projectile getVariable ["KPLIB_guidanceId", -1];
    private _record = _active getOrDefault [_guidanceId, createHashMap];
    if (count _record > 0) then {
        {_state pushBack [_x, _record getOrDefault [_x, "unavailable"]]} forEach ["phase", "locked", "quality", "lastSeen", "support", "missDistance"];
    };
    private _key = [_state select 0, _record getOrDefault ["phase", ""], _record getOrDefault ["locked", false], _record getOrDefault ["support", objNull]];
    _x set ["state", str _state];
    if (_key isNotEqualTo (_x get "stateKey")) then {
        _x set ["stateKey", _key];
        [_projectile, "GUIDANCE", getPosASL _projectile, _state] call KPLIB_fnc_munitionsEvent;
    };
} forEach (localNamespace getVariable ["KPLIB_munitionsActiveTraces", []]);
localNamespace setVariable ["KPLIB_munitionsActiveTraces", (localNamespace getVariable ["KPLIB_munitionsActiveTraces", []]) select {!(_x get "ended")}];
