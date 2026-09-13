/* Server builds a bounded replay snapshot. Only an authenticated curator request
   sends it; receiving it creates UI data only, never simulation or damage. */
if (isServer && {!isRemoteExecuted}) exitWith {
    params [["_completedOnly", false, [true]], ["_selected", [], [[]]]];
    private _jobs = +(localNamespace getVariable ["KPLIB_blastHistory", []]);
    if (!_completedOnly) then {_jobs append (localNamespace getVariable ["KPLIB_blastJobs", []])};
    if (_selected isNotEqualTo []) then {_jobs = _selected};
    private _result = [];
    {
        private _profile = _x get "profile";
        private _job = _x;
        if (_job getOrDefault ["backend", "LEGACY"] == "GAS") then {
            private _nodes = (_job get "gasProbes") apply {[[_job, _x] call KPLIB_fnc_gasPosition,0,0]};
            _result pushBack [_job get "id", _profile get "ammo", _profile get "thermal", _job get "gasRadius", _job get "gasEnd", _job get "gasCell", _nodes, _job get "truncated", "GAS", +(_job get "gasFrames"), _job get "gasBasis", _job get "gasReason", [_job get "gasN",_job get "gasRequestedCell",+(_job get "gasProbes")]];
        } else {
            private _nodes = (_job get "nodes") apply {[_x select 0, _x select 1, _x select 2]};
            _result pushBack [_job get "id", _profile get "ammo", _profile get "thermal", _profile get "fieldRadius", KPLIB_munitions_thermal_duration, _profile get "cell", _nodes select [0,128], _job get "truncated", "LEGACY", [], "Normalized game field", _job getOrDefault ["gasReason", ""]];
        };
    } forEach (_jobs select [((count _jobs) - 1) max 0, 1]);
    _result
};
if (!hasInterface || {!isRemoteExecuted} || {remoteExecutedOwner != 2} || {isNull getAssignedCuratorLogic player}) exitWith {};
params [["_fields", [], [[]]], ["_quiet", false, [true]]];
if (count _fields > 1) exitWith {};
if (_fields isEqualTo []) exitWith {if (!_quiet) then {systemChat "No retained field yet. Fire an explosive round, allow up to eight seconds, then replay. Inspect physical solver backend for fallback and budget details."}};
if !([_fields] call KPLIB_fnc_gasPayload) exitWith {};
uiNamespace setVariable ["KPLIB_blastReplay", _fields];
uiNamespace setVariable ["KPLIB_blastReplayAt", diag_tickTime];
uiNamespace setVariable ["KPLIB_blastReplayPaused", -1];
if (!_quiet) then {systemChat "Field replay repeats for 120 seconds in Zeus. GAS: red/blue = excess/negative pressure, orange = heated tracer; eight-second slow playback. Ambient samples are hidden by default; aim at a probe for its values. Dots are fixed samples, not fragments. Grid limits are shown in the overlay. GAME INPUT and damage conversion are uncalibrated. LEGACY denotes the fallback. Inspect physical solver backend for source and budget details."};
