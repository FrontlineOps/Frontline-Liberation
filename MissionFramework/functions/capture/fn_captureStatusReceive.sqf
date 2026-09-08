/* CfgFunctions makes this available even when the JIP snapshot precedes init.sqf. */
if (!hasInterface || {isRemoteExecuted && {remoteExecutedOwner != 2}} || {!isRemoteExecuted && {!isServer}}) exitWith {false};
params [["_session", "", [""]], ["_revision", -1, [0]], ["_rows", [], [[]]]];
private _sameSession = _session == (uiNamespace getVariable ["KPLIB_captureStatusSession", ""]);
if (_session == "" || {_sameSession && {_revision <= (uiNamespace getVariable ["KPLIB_captureStatusRevision", -1])}}) exitWith {false};
if (_rows findIf {
    !(_x isEqualType [] && {count _x == 5}) || {
        _x params ["_key", "_position", "_label", "_status", "_remaining"];
        !(_key isEqualType "") || {!(_position isEqualType [])} || {!(count _position in [2, 3])}
        || {_position findIf {!(_x isEqualType 0)} >= 0} || {!(_label isEqualType "")}
        || {!(_status in ["CAPTURING", "CONTESTED", "STOPPED", "CAPTURED", "UPDATING"])}
        || {!(_remaining isEqualType 0)} || {_remaining < 0}
    }
} >= 0) exitWith {false};
uiNamespace setVariable ["KPLIB_captureStatusRevision", _revision];
uiNamespace setVariable ["KPLIB_captureStatusSession", _session];
uiNamespace setVariable ["KPLIB_captureStatusRows", _rows];
uiNamespace setVariable ["KPLIB_captureStatusReceivedAt", diag_tickTime];
true
