/* Bounded RPT output on each observer; no text network stream or report dialog. */
if (isRemoteExecuted) exitWith {};
if (!(localNamespace getVariable ["KPLIB_munitionsLive", false])
    || {CBA_missionTime >= (localNamespace getVariable ["KPLIB_munitionsUntil", -1])}) exitWith {
    localNamespace setVariable ["KPLIB_munitionsLogQueue", []];
};
params [["_rows", [], [[]]]];
private _queue = localNamespace getVariable ["KPLIB_munitionsLogQueue", []];
if (_rows isEqualTo [] && {CBA_missionTime >= (localNamespace getVariable ["KPLIB_munitionsLogAt", -1])}) then {
    localNamespace setVariable ["KPLIB_munitionsLogAt", CBA_missionTime + 10];
    private _report = [] call KPLIB_fnc_munitionsReport;
    // Pressure stages have their own ring so abundant fragment impact text
    // cannot hide medical evidence. Drain it through the same bounded RPT queue.
    _rows = (localNamespace getVariable ["KPLIB_blastTrace", []]) apply {format ["PRESSURE TRACE %1", _x]};
    _rows append ((_report select 0) splitString toString [13,10]);
    localNamespace setVariable ["KPLIB_blastTrace", []];
    localNamespace setVariable ["KPLIB_munitionsEvents", []];
};
private _omitted = 0;
{
    private _line = _x;
    if !(_line isEqualType "") then {_line = str _line};
    for "_offset" from 0 to ((count _line - 1) max 0) step 800 do {
        if (count _queue < 512) then {
            _queue pushBack (_line select [_offset,800]);
        } else {_omitted = _omitted + 1};
    };
} forEach (_rows select [0,256]);
if (_omitted > 0 || {count _rows > 256}) then {
    diag_log format ["[FL MUNITIONS] RPT budget omitted %1 chunks / %2 rows", _omitted, (count _rows - 256) max 0];
};
for "_i" from 1 to (8 min count _queue) do {diag_log ("[FL MUNITIONS] " + (_queue deleteAt 0))};
localNamespace setVariable ["KPLIB_munitionsLogQueue", _queue];
