/* Server acknowledgment only. A toggle never grants itself permission to view. */
if (!hasInterface || {!isRemoteExecuted} || {remoteExecutedOwner != 2}) exitWith {};
params [["_enabled", false, [true]], ["_session", -1, [0]], ["_message", "", [""]]];
if (!finite _session || {count _message > 256}) exitWith {};
if (_enabled && {isNull getAssignedCuratorLogic player}) exitWith {};
private _previous = uiNamespace getVariable ["KPLIB_munitionsDebugSession", -1];
uiNamespace setVariable ["KPLIB_munitionsDebug", _enabled];
uiNamespace setVariable ["KPLIB_munitionsDebugSession", _session];
uiNamespace setVariable ["KPLIB_munitionsDebugLease", diag_tickTime + 15];
if (!_enabled || {_previous != _session}) then {
    uiNamespace setVariable ["KPLIB_munitionsLivePackets", createHashMap];
    uiNamespace setVariable ["KPLIB_munitionsLiveFields", []];
    uiNamespace setVariable ["KPLIB_munitionsLines", []];
    uiNamespace setVariable ["KPLIB_munitionsTags", []];
    {
        uiNamespace setVariable [_x, []];
    } forEach ["KPLIB_munitionsMergeInputs", "KPLIB_munitionsMergeResult", "KPLIB_munitionsRenderInput", "KPLIB_munitionsRenderCache", "KPLIB_munitionsLiveHeads"];
    uiNamespace setVariable ["KPLIB_munitionsDisplayedPaths", 0];
    uiNamespace setVariable ["KPLIB_munitionsClientOmitted", 0];
    uiNamespace setVariable ["KPLIB_munitionsStats", [0,0,0,0,0,0,0,0,0,0,0,0,0]];
};
if (!_enabled) then {
    ["KPLIB_traceHud", "", 0.75, 0.14] call KPLIB_fnc_munitionsHud;
    ["KPLIB_gasHud", "", 0.06, 0.22] call KPLIB_fnc_munitionsHud;
};
if (_message != "") then {systemChat _message};
