params [["_id", -1, [0]], ["_reason", "finished", [""]], ["_backend", "RELEASED", [""]]];
if (isRemoteExecuted) exitWith {};
private _active = localNamespace getVariable ["KPLIB_guidanceActive", createHashMap];
private _record = _active getOrDefault [_id, createHashMap];
if (count _record == 0) exitWith {};
_active deleteAt _id;
private _missile = _record get "missile";
if (!isNull _missile) then {
    _missile setVariable ["KPLIB_guidanceOwner", _backend];
    _missile setVariable ["KPLIB_guidanceReason", _reason];
};
private _metrics = localNamespace getVariable "KPLIB_guidanceMetrics";
_metrics set ["retired", (_metrics getOrDefault ["retired", 0]) + 1];
if (missionNamespace getVariable ["KPLIB_guidance_debug", false]) then {
    [format ["%1 retired: %2", _id, _reason], "GUIDANCE"] call KPLIB_fnc_log;
};
if (count _active == 0) then {
    private _pfh = localNamespace getVariable ["KPLIB_guidancePFH", -1];
    if (_pfh >= 0) then {[_pfh] call CBA_fnc_removePerFrameHandler};
    localNamespace setVariable ["KPLIB_guidancePFH", -1];
    localNamespace setVariable ["KPLIB_guidanceSpatial", createHashMap];
    [format ["Flight dispatcher idle; started %1, retired %2, peak %3", _metrics get "started", _metrics get "retired", _metrics get "peak"], "GUIDANCE"] call KPLIB_fnc_log;
};
