/* Server-issued, nearby, short-lived local particles. No networked emitters. */
if (!hasInterface || {isRemoteExecuted && {remoteExecutedOwner != 2}}
    || {!isRemoteExecuted && {!isServer || {isNil "_KPLIB_gasDustContext"}}}
    || {!(missionNamespace getVariable ["KPLIB_munitions_gas_dust", true])}) exitWith {};
params [["_id", "", [""]], ["_at", -1, [0]], ["_rows", [], [[]]]];
if (_id == "" || {count _id > 128} || {!finite _at}
    || {_at > CBA_missionTime + 0.5} || {CBA_missionTime - _at > 2}
    || {count _rows > 4} || {_rows findIf {
        !(_x isEqualType []) || {count _x != 2} || {_x findIf {
            !(_x isEqualType []) || {count _x != 3} || {_x findIf {!(_x isEqualType 0) || {!finite _x}} >= 0}
        } >= 0} || {vectorMagnitude (_x select 1) > 12.1}
    } >= 0}) exitWith {};
private _seen = (localNamespace getVariable ["KPLIB_gasDustSeen", []]) select {CBA_missionTime - (_x select 1) < 5};
if (_seen findIf {_x select 0 == _id} >= 0 || {count _seen >= 128}) exitWith {};
_seen pushBack [_id, CBA_missionTime];
localNamespace setVariable ["KPLIB_gasDustSeen", _seen];
private _active = (localNamespace getVariable ["KPLIB_gasDustEmitters", []]) select {!isNull _x};
private _camera = AGLToASL (positionCameraToWorld [0,0,0]);
{
    _x params ["_point", "_velocity"];
    if (count _active >= 24) exitWith {};
    if (_camera distance _point > 250 || {_point select 2 < getTerrainHeightASL _point}) then {continue};
    private _emitter = "#particlesource" createVehicleLocal (ASLToAGL _point);
    _emitter setPosASL _point;
    _emitter setParticleParams [
        ["\A3\data_f\ParticleEffects\Universal\Universal",16,12,8,0], "", "Billboard",
        1, 1.5, [0,0,0], _velocity, 0, 1.2, 1, 0.4,
        [0.15,0.65,1.2], [[0.55,0.5,0.42,0],[0.55,0.5,0.42,0.22],[0.55,0.5,0.42,0]],
        [1], 0.1, 0.1, "", "", objNull
    ];
    _emitter setParticleRandom [0.2,[0.15,0.15,0.15],[0.2,0.2,0.2],0,0.1,[0,0,0,0],0,0];
    _emitter setDropInterval 0.025;
    _active pushBack _emitter;
    [{params ["_emitter"]; deleteVehicle _emitter}, [_emitter], 0.2] call CBA_fnc_waitAndExecute;
} forEach _rows;
localNamespace setVariable ["KPLIB_gasDustEmitters", _active];
