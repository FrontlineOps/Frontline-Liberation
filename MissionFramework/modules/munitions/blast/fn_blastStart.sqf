if (!isServer || {isRemoteExecuted}
    || {!(localNamespace getVariable ["KPLIB_blastReady", false])}
    || {!(missionNamespace getVariable ["KPLIB_munitions_blast_enabled", true])}) exitWith {};
params ["_id", "_profile", "_source", "_position", ["_observedAt", CBA_missionTime]];
if (_position select 2 < 0 && {surfaceIsWater _position}) exitWith {};
private _jobs = localNamespace getVariable "KPLIB_blastJobs";
private _metrics = localNamespace getVariable "KPLIB_blastMetrics";
if (count _jobs >= KPLIB_munitions_blast_max_jobs) exitWith {_metrics set ["dropped", 1 + (_metrics get "dropped")]};
private _origin = +_position;
_origin set [2, ((_origin select 2) max getTerrainHeightASL _origin) + 0.12];
private _radius = _profile get "radius";
private _targets = ((ASLToAGL _origin) nearEntities ["CAManBase", _radius]) select {alive _x};
_targets = [_targets, [], {getPosASL _x distance _origin}, "ASCEND"] call BIS_fnc_sortBy;
private _overflow = (count _targets - KPLIB_munitions_blast_targets) max 0;
_targets = _targets select [0, KPLIB_munitions_blast_targets];
private _captured = CBA_missionTime < (localNamespace getVariable ["KPLIB_munitionsUntil", -1])
    && {localNamespace getVariable ["KPLIB_munitionsLive", false]
        || {_origin distance (localNamespace getVariable ["KPLIB_munitionsCenter", [0,0,0]]) <= 750}};
private _record = missionNamespace getVariable ["KPLIB_munitions_gas_record", true];
private _assets = [_origin,_profile] call KPLIB_fnc_gasAssetsFind;
if (_targets isEqualTo [] && {(_assets select 0) isEqualTo []} && {!_captured} && {!_record}) exitWith {};
private _closed = 0;
private _probe = ((_profile get "range") max 2) min 6;
{
    private _end = _origin vectorAdd (_x vectorMultiply _probe);
    if (!([_origin, _end] call KPLIB_fnc_blastClear)) then {_closed = _closed + 1};
} forEach [[1,0,0],[-1,0,0],[0,1,0],[0,-1,0],[0,0,1]];
private _nodes = [[_origin, 0, _closed / 5, -1, [0,0,0]]];
private _job = createHashMapFromArray [
    ["id", _id], ["profile", _profile], ["source", _source], ["origin", _origin],
    ["at", _observedAt], ["phase", "PRIMARY"], ["nodes", _nodes], ["cursor", 0],
    ["visited", createHashMapFromArray [[str [0,0,0], true]]], ["truncated", false],
    ["targets", _targets], ["targetOverflow", _overflow], ["targetIndex", 0],
    ["gasAssets",_assets select 0], ["gasAssetOverflow",_assets select 1], ["gasAssetIndex",0],
    ["exposures", []], ["dose", createHashMap], ["last", createHashMap],
    ["confinement", _closed / 5], ["needField", _closed > 0 || {_captured} || {_record}], ["thermalAt", -1], ["next", 0]
];
if (!([_job] call KPLIB_fnc_gasBlastStart)) then {
    {_x set ["status","No native gas field: asset pressure omitted"]} forEach (_job get "gasAssets");
};
_jobs pushBack _job;
_metrics set ["accepted", 1 + (_metrics get "accepted")];
[objNull, "BLAST START", _origin, [_id, _profile get "ammo", _job get "backend", _job get "gasReason", count _targets, _overflow, _closed / 5]] call KPLIB_fnc_munitionsEvent;
