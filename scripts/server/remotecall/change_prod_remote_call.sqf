if (!isServer || {canSuspend}) exitWith {};
params [["_sector", "", [""]], ["_production", -1, [0]]];
private _caller = ["PRODUCTION"] call KPLIB_fnc_permissionRequest;
if (isNull _caller || {!(_sector in blufor_sectors)} || {!(_production in [0, 1, 2, 3])}) exitWith {};
private _atFob = ([_caller] call KPLIB_fnc_buildFobPosition) isNotEqualTo [];
private _atProduction = (KP_liberation_production findIf {_caller distance2D getMarkerPos (_x select 1) <= 100}) != -1;
if (!_atFob && {!_atProduction}) exitWith {};
private _index = KP_liberation_production findIf {(_x select 1) == _sector};
if (_index < 0) exitWith {};
private _record = KP_liberation_production select _index;
if ((_record select 3) isEqualTo []) exitWith {};
if (_production != 3 && {!(_record select (4 + _production))}) exitWith {
    [localize "STR_PRODUCTION_FACFALSE"] remoteExecCall ["hint", owner _caller];
};
if ((_record select 7) == _production) exitWith {};
_record set [7, _production];
_record set [8, [] call KC_DETERMINE_PRODUCTION_INTERVAL];
[format ["Production changed at %1 to %2", _sector, _production], "PRODUCTION"] call KPLIB_fnc_log;
