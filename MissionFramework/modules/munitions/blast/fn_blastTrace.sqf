/* Debug-only owner-local evidence. Separate bounded ring so fragment text cannot
   crowd out pressure accounting; never used as authoritative damage input. */
if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {};
if (CBA_missionTime >= (localNamespace getVariable ["KPLIB_munitionsUntil", -1])) exitWith {};
params ["_unit", "_id", "_stage", "_detail"];
private _rows = localNamespace getVariable ["KPLIB_blastTrace", []];
if (count _rows >= 64) then {
    _rows deleteAt 0;
    localNamespace setVariable ["KPLIB_blastTraceRetired", 1 + (localNamespace getVariable ["KPLIB_blastTraceRetired", 0])];
};
private _row = [CBA_missionTime, _id, typeOf _unit, owner _unit, _stage, (str _detail) select [0,1200]];
_rows pushBack _row;
localNamespace setVariable ["KPLIB_blastTrace", _rows];
if (!isNull _unit && {local _unit}) then {_unit setVariable ["KPLIB_blastLastTrace", _row]};
