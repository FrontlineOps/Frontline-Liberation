/* Once-only owner-local explosive surface sampling, independent of the gas
   solver and diagnostic capture. No client-supplied remote burst endpoint. */
if (isRemoteExecuted) exitWith {};
params [["_projectile", objNull, [objNull]], ["_origin", [], [[]]]];
if (isNull _projectile || {!local _projectile} || {!(_projectile getShotInfo 5)}
    || {!(_projectile getVariable ["KPLIB_blastObserved", false])}
    || {_projectile getVariable ["KPLIB_munitionsDebrisStarted", false]}) exitWith {};
_projectile setVariable ["KPLIB_munitionsDebrisStarted", true];
if (count _origin != 3 || {_origin findIf {!(_x isEqualType 0) || {!finite _x}} >= 0}
    || {_origin select 2 < (getTerrainHeightASL _origin) - 0.1}) exitWith {};
private _ammo = typeOf _projectile;
private _profile = [_ammo] call KPLIB_fnc_blastProfile;
private _strength = _profile get "strength";
if (_strength <= 0) exitWith {};
private _queue = localNamespace getVariable ["KPLIB_munitionsDebrisQueue", []];
if (count _queue >= 8) exitWith {
    [objNull, "STRUCTURAL DEBRIS OMITTED", _origin, [_ammo, "surface-work capacity"]] call KPLIB_fnc_munitionsEvent;
};
private _directions = [16] call KPLIB_fnc_munitionsFragDirections;
private _contact = _projectile getVariable ["KPLIB_munitionsSurfaceContact", []];
if (_contact isNotEqualTo [] && {CBA_missionTime - (_contact select 0) > 0.25 || {(_contact select 2) distance _origin > 2}}) then {_contact = []};
private _sampleOrigin = +_origin;
if (_contact isNotEqualTo [] && {vectorMagnitude (_contact select 3) >= 0.5}) then {
    _sampleOrigin = (_contact select 2) vectorAdd ((vectorNormalized (_contact select 3)) vectorMultiply 0.04);
};
_sampleOrigin set [2, (_sampleOrigin select 2) max ((getTerrainHeightASL _sampleOrigin) + 0.02)];
_queue pushBack createHashMapFromArray [
    ["ammo", _ammo], ["origin", _sampleOrigin], ["parents", getShotParents _projectile],
    ["at", CBA_missionTime], ["directions", _directions], ["index", 0], ["contact", _contact],
    ["radius", ((_profile get "range") max 2) min 12],
    ["remaining", round linearConversion [0, 24, _strength, 8, 64, true]],
    ["surfaces", []], ["created", 0]
];
localNamespace setVariable ["KPLIB_munitionsDebrisQueue", _queue];
