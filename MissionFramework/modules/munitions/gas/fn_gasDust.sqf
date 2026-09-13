/* Reuse existing native frame samples. No extra fluid solve or physical debris. */
if (!isServer || {isRemoteExecuted} || {isNil "_KPLIB_gasDustContext"}) exitWith {};
params ["_job", "_indices", "_samples"];
if (!(missionNamespace getVariable ["KPLIB_munitions_gas_dust", true])
    || {_job get "gasTime" <= 0} || {CBA_missionTime - (_job get "at") > 3}) exitWith {};
private _seen = _job getOrDefault ["gasDustCells", []];
if (count _seen >= 12) exitWith {};
private _surfaces = _job getOrDefault ["gasSurfaceCells", createHashMap];
private _rows = [];
{
    private _index = _indices select _forEachIndex;
    if (_index in _seen) then {continue};
    private _point = [_job, _index] call KPLIB_fnc_gasPosition;
    private _height = (_point select 2) - getTerrainHeightASL _point;
    if (_height < 0 || {_height > (_job get "gasCell") && {!(_index in _surfaces)}}) then {continue};
    private _velocity = _x select [7, 3];
    private _speed = vectorMagnitude _velocity;
    if (_speed < 0.5) then {continue};
    _velocity = _velocity vectorMultiply ((12 min _speed) / _speed);
    _rows pushBack [_point, _velocity];
    _seen pushBack _index;
    if (count _rows >= 4 || {count _seen >= 12}) exitWith {};
} forEach _samples;
if (_rows isEqualTo []) exitWith {};
_job set ["gasDustCells", _seen];
private _serial = 1 + (_job getOrDefault ["gasDustSerial", 0]);
_job set ["gasDustSerial", _serial];
private _owners = [];
{
    if (owner _x > 2 && {getPosASL _x distance (_job get "origin") <= 400 || {!isNull getAssignedCuratorLogic _x}}) then {
        _owners pushBackUnique owner _x;
    };
} forEach allPlayers;
private _payload = [(_job get "id") + ":dust:" + str _serial, CBA_missionTime, _rows];
{_payload remoteExecCall ["KPLIB_fnc_gasDustReceive", _x]} forEach _owners;
if (hasInterface) then {_payload call KPLIB_fnc_gasDustReceive};
