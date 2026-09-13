params ["_unit", "_target"];
if (isNull _target || {!alive _target} || {captive _target} || {_target == vehicle _unit}) exitWith {false};
if (!(_target isKindOf "CAManBase" || {_target isKindOf "LandVehicle"})) exitWith {false};
if (_target isKindOf "CAManBase" && {!isNull objectParent _target}) exitWith {false};
if (side _target == civilian || {(side group _unit) getFriend (side _target) >= 0.6}) exitWith {false};
if (_unit knowsAbout _target < 1) exitWith {false};
private _from = eyePos _unit;
private _to = aimPos _target;
if (terrainIntersectASL [_from, _to]) exitWith {false};
if (([vehicle _unit, "VIEW", _target] checkVisibility [_from, _to]) < 0.5) exitWith {false};
// Native knowledge supplies detection/optics/weather limits; geometry must still be clear now.
true
