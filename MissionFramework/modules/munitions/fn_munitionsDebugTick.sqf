/* Client cache maintenance/picking cadence is separate from per-frame drawing. */
if (!hasInterface || {isRemoteExecuted} || {!(uiNamespace getVariable ["KPLIB_munitionsDebug", false])}) exitWith {};
if (isNull getAssignedCuratorLogic player || {diag_tickTime > (uiNamespace getVariable ["KPLIB_munitionsDebugLease", -1])}) exitWith {
    uiNamespace setVariable ["KPLIB_munitionsDebug", false];
    uiNamespace setVariable ["KPLIB_munitionsLivePackets", createHashMap];
    uiNamespace setVariable ["KPLIB_munitionsLiveFields", []];
    {
        uiNamespace setVariable [_x, []];
    } forEach ["KPLIB_munitionsMergeInputs", "KPLIB_munitionsMergeResult", "KPLIB_munitionsRenderInput", "KPLIB_munitionsRenderCache", "KPLIB_munitionsLiveHeads", "KPLIB_munitionsLines", "KPLIB_munitionsTags"];
    uiNamespace setVariable ["KPLIB_munitionsDisplayedPaths", 0];
    ["KPLIB_traceHud", "", 0.75, 0.14] call KPLIB_fnc_munitionsHud;
    ["KPLIB_gasHud", "", 0.06, 0.22] call KPLIB_fnc_munitionsHud;
};
if (diag_tickTime >= (uiNamespace getVariable ["KPLIB_munitionsDebugPing", -1])) then {
    uiNamespace setVariable ["KPLIB_munitionsDebugPing", diag_tickTime + 5];
    ["DEBUG_PING"] remoteExecCall ["KPLIB_fnc_munitionsRequest", 2];
};
if (isNull curatorCamera) exitWith {};
private _packets = uiNamespace getVariable ["KPLIB_munitionsLivePackets", createHashMap];
private _heads = [];
{
    if (diag_tickTime - ((_packets get _x) select 1) > 3) then {_packets deleteAt _x};
} forEach keys _packets;
if ((localNamespace getVariable ["KPLIB_munitionsSession", -2]) == (uiNamespace getVariable ["KPLIB_munitionsDebugSession", -1])
    && {CBA_missionTime < (localNamespace getVariable ["KPLIB_munitionsUntil", -1])}) then {
    private _shots = [] call KPLIB_fnc_munitionsRecent;
    private _paths = [_shots] call KPLIB_fnc_munitionsLivePaths;
    {
        private _points = _x get "points";
        if (!(_x get "ended") && {_points isNotEqualTo []}) then {
            _heads pushBack [_x get "projectile", _points select (count _points - 1), _x get "kind"];
        };
    } forEach _shots;
    private _meta = _paths select 1;
    _packets set [clientOwner, [diag_tickTime, diag_tickTime, [clientOwner, _paths select 0, _meta select 1, _meta select 2]]];
};
private _inputs = (values _packets) apply {_x select 2};
private _merged = uiNamespace getVariable ["KPLIB_munitionsMergeResult", []];
if (_merged isEqualTo [] || {_inputs isNotEqualTo (uiNamespace getVariable ["KPLIB_munitionsMergeInputs", []])}) then {
    _merged = [_inputs, 8192] call KPLIB_fnc_munitionsMerge;
    uiNamespace setVariable ["KPLIB_munitionsMergeInputs", _inputs];
    uiNamespace setVariable ["KPLIB_munitionsMergeResult", _merged];
};
_merged params ["_lines", "_tags", "_stats", "_omitted", "_displayed"];
uiNamespace setVariable ["KPLIB_munitionsLivePackets", _packets];
uiNamespace setVariable ["KPLIB_munitionsLiveHeads", _heads];
uiNamespace setVariable ["KPLIB_munitionsLines", _lines];
uiNamespace setVariable ["KPLIB_munitionsTags", _tags];
uiNamespace setVariable ["KPLIB_munitionsStats", _stats];
uiNamespace setVariable ["KPLIB_munitionsClientOmitted", _omitted];
uiNamespace setVariable ["KPLIB_munitionsDisplayedPaths", _displayed];
private _fields = (uiNamespace getVariable ["KPLIB_munitionsLiveFields", []]) select {diag_tickTime - (_x select 2) < 20};
uiNamespace setVariable ["KPLIB_munitionsLiveFields", _fields];
