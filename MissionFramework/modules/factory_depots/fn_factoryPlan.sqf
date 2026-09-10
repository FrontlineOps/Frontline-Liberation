/* Scheduled validation of authored stock bays inside the objective.
   A blocked site stays unissued instead of moving its reward outside the
   compound. Geometry queries never run on a frame handler. */
if (!isServer || {isRemoteExecuted} || {!canSuspend}) exitWith {[]};
params ["_sector"];
private _origin = markerPos _sector;
private _authored = (localNamespace getVariable ["KPLIB_factorySites", []]) select {(_x select 0) == toLower worldName && {(_x select 1) == _sector}};
private _preferred = [];
// Dedicated-server terrain geometry may finish loading after the first query.
// Warm nearby models and retry the authored footprint across scheduled frames.
{boundingBoxReal _x} forEach ((nearestTerrainObjects [_origin, ["HOUSE", "BUILDING"], 60, true, true]) select [0, 32]);
for "_attempt" from 0 to 2 do {
    {
        private _layout = _x select [2];
        if ((_layout select 0) distance2D _origin < 200 && {_layout call KPLIB_fnc_factoryClear}) exitWith {_preferred = _layout};
    } forEach _authored;
    if (!(_preferred isEqualTo []) || {_authored isEqualTo []}) exitWith {};
    sleep 0.1;
};
_preferred
