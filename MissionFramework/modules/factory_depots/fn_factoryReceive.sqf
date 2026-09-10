/* Read-only report, accepted only from the authoritative server. */
if (!hasInterface || {isRemoteExecuted && {remoteExecutedOwner != 2}}) exitWith {};
if !(missionNamespace getVariable ["KPLIB_factory_capture_report", true]) exitWith {};
params [["_sector", "", [""]], ["_totals", [], [[]]]];
if (!(_sector in sectors_factory) || {count _totals != 4}) exitWith {};
_totals params ["_count", "_supply", "_ammo", "_fuel"];
private _message = if (_count > 0) then {
    format ["%1 pallets: %2 supply / %3 ammo / %4 fuel.<br/>Haul them from the marked bays to FOB storage.", _count, _supply, _ammo, _fuel]
} else {"No loose depot stock remains to recover. Production is available through the usual factory controls."};
["lib_factory_secured", [markerText _sector, _message]] call BIS_fnc_showNotification;
