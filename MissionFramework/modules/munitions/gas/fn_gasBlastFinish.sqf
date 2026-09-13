if (!isServer || {isRemoteExecuted}) exitWith {};
params ["_job"];
private _handle = _job getOrDefault ["gasHandle", -1];
if (_handle < 0) exitWith {};
private _stats = ["stats", [_handle]] call KPLIB_fnc_gasNative;
if (_stats select 0) then {_job set ["gasFinalStats", _stats select 1]};
private _released = ["release", [_handle]] call KPLIB_fnc_gasNative;
_job set ["gasReleaseOK", _released select 0];
_job set ["gasHandle", -1];
// Object references and temporary geometry buffers are not needed for replay.
_job deleteAt "gasInitialPositions";
_job deleteAt "gasFrameRows";
_job deleteAt "gasGeometryPositions";
