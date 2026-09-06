/* Returns the FOB position only when both actor and asset can use its depot. */
params ["_object", "_caller"];
private _result = [];
private _nearest = 1e10;
{
    if (_caller distance2D _x < GRLIB_fob_range * 0.8
        && {_object distance2D _x < GRLIB_fob_range}
        && {_caller distance2D _x < _nearest}
        && {nearestObjects [_x, [KP_liberation_recycle_building], GRLIB_fob_range]
            findIf {alive _x} >= 0}) then {
        _result = _x;
        _nearest = _caller distance2D _x;
    };
} forEach ((missionNamespace getVariable ["GRLIB_all_fobs", []]) + [getMarkerPos "startbase_marker"]);
_result
