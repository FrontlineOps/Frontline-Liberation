params ["_job"];
private _assets = _job getOrDefault ["gasAssets",[]];
private _rows = [format ["  PRESSURE ASSETS: %1 retained, %2 outside object quota. Six exterior face samples; stationary frozen-grid history only.",count _assets,_job getOrDefault ["gasAssetOverflow",0]],
    "  GAME damage floors use normalized peak/positive impulse and loaded game armor; not physical failure thresholds. Higher existing damage is retained. Identical floors do not accumulate fatigue."];
{
    _rows pushBack format ["    %1 initialASL=%2 surfaceDistance=%3 status=%4 omittedComponents=%5",_x get "class",_x get "position",_x get "distance",_x get "status",_x getOrDefault ["componentOmissions",0]];
    if (_forEachIndex < 4) then {
        _rows pushBack format ["      faces [cell(-1=unavailable),surfaceASL,peakPa,positivePa.s,normalizedResponse]=%1",_x get "faces"];
        _rows pushBack format ["      requested [component index,name,damage floor,observed baseline]=%1",_x get "floors"];
    };
} forEach _assets;
if (count _assets > 4) then {_rows pushBack "  Detailed face/floor rows limited to first four objects. Inspect individual objects / their owners for actual application."};
_rows
