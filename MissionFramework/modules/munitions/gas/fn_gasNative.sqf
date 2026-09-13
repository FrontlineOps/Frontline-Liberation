/* Local server-only native ABI. No client dependency and no remote entrypoint.
   Returns [success, parsed array, diagnostic]. Calls are explicit; registration
   alone does not load a DLL or run a fluid simulation on ammunition. */
if (!isServer || {isRemoteExecuted}) exitWith {[false, [], "Server-local invocation required"]};
params [["_command", "", [""]], ["_arguments", [], [[]]]];
if !(_command in ["version", "status", "create", "fill", "advance", "sample", "samples", "cells", "faces", "walls", "openings", "heat", "stats", "release"]) exitWith {[false, [], "Unknown command"]};
if (count _arguments > 17 || {_arguments findIf {!(_x isEqualType 0) || {!finite _x}} >= 0}) exitWith {[false, [], "Finite numeric arguments required"]};
if !(missionNamespace getVariable ["KPLIB_gasNativeInitialized", false]) then {
    missionNamespace setVariable ["KPLIB_gasNativeInitialized", true];
    // Versioned filename permits an upgrade while the old DLL is still loaded.
    private _library = "frontline_gas_v3";
    private _version = _library callExtension ["version", []];
    if (count _version != 3 || {_version select 1 != 0} || {_version select 2 != 0}) then {
        _library = "frontline_gas";
        _version = _library callExtension ["version", []];
    };
    private _ready = count _version == 3 && {_version select 1 == 0} && {_version select 2 == 0};
    private _schema = [];
    if (_ready) then {
        _schema = parseSimpleArray (_version select 0);
        _ready = _schema in [[2,4096,8,8], [3,4096,8,8]];
    };
    if (_ready) then {
        // Extensions can outlive a mission. Reset native state at first use in
        // each mission; native handles themselves are never recycled.
        private _reset = _library callExtension ["reset", []];
        _ready = _reset select 1 == 0 && {_reset select 2 == 0};
    };
    missionNamespace setVariable ["KPLIB_gasNativeReady", _ready];
    missionNamespace setVariable ["KPLIB_gasNativeSchema", _schema];
    localNamespace setVariable ["KPLIB_gasNativeLibrary", _library];
    missionNamespace setVariable ["KPLIB_gasNativeMetrics", [0, 0, "", ""]];
    if (_ready) then {
        addMissionEventHandler [["Ended", "MPEnded"] select isMultiplayer, {
            if (isServer) then {(localNamespace getVariable ["KPLIB_gasNativeLibrary", "frontline_gas"]) callExtension ["reset", []]};
        }];
    };
};
if !(missionNamespace getVariable ["KPLIB_gasNativeReady", false]) exitWith {[false, [], "Native backend unavailable or incompatible; no SQF hot-path fallback"]};
private _started = diag_tickTime;
private _reply = (localNamespace getVariable ["KPLIB_gasNativeLibrary", "frontline_gas"]) callExtension [_command, _arguments];
private _ok = count _reply == 3 && {_reply select 1 == 0} && {_reply select 2 == 0};
private _data = [];
private _reason = "";
if (_ok) then {
    _data = parseSimpleArray (_reply select 0);
} else {
    _reason = format ["%1 failed: %2", _command, _reply];
};
private _metrics = missionNamespace getVariable ["KPLIB_gasNativeMetrics", [0, 0, "", ""]];
_metrics set [0, 1 + (_metrics select 0)];
_metrics set [1, (_metrics select 1) + 1000 * (diag_tickTime - _started)];
_metrics set [2, _command];
if (!_ok) then {_metrics set [3, _reason]};
missionNamespace setVariable ["KPLIB_gasNativeMetrics", _metrics];
[_ok, _data, _reason]
