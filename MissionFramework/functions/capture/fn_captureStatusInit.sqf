/* Server owns transient display state; existing capture workers own the rules. */
if (!isServer || {isRemoteExecuted}) exitWith {};
if (localNamespace getVariable ["KPLIB_captureStatusInitialized", false]) exitWith {};
localNamespace setVariable ["KPLIB_captureStatusInitialized", true];
localNamespace setVariable ["KPLIB_captureStatusEntries", createHashMap];
localNamespace setVariable ["KPLIB_captureStatusRevision", 0];
localNamespace setVariable ["KPLIB_captureStatusSession", str [systemTimeUTC, diag_tickTime]];
[] call KPLIB_fnc_captureStatusPublish;
[{
    [] call KPLIB_fnc_captureStatusPublish;
}, 1] call CBA_fnc_addPerFrameHandler;
