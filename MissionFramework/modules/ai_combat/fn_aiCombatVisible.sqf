params ["_unit", "_target", ["_acquire", false]];
if (isNull _target || {!alive _target} || {!(_target isKindOf "CAManBase")}
    || {!isNull objectParent _target} || {captive _target}
    || {(side group _unit) getFriend (side group _target) >= 0.6}) exitWith {false};
private _range = _unit distance _target;
private _lightRange = KPLIB_aiCombat_rifleRange;
if (sunOrMoon < 0.2 && {(getArray (configFile >> "CfgWeapons" >> hmd _unit >> "visionMode")) findIf {toLower _x in ["nvg", "ti"]} < 0}) then {
    _lightRange = 150;
    private _lit = (localNamespace getVariable "KPLIB_aiCombat_flaresActive") findIf {
        CBA_missionTime < (_x select 1) && {_target distance2D (_x select 0) < KPLIB_aiCombat_flareRadius}
    };
    if (_lit >= 0) then {_lightRange = 600};
};
if (_range > _lightRange || {_range > KPLIB_aiCombat_rifleRange}) exitWith {false};
if (_acquire && {_unit knowsAbout _target < 1}) then {
    private _direction = vectorNormalized ((eyePos _target) vectorDiff eyePos _unit);
    if ((eyeDirection _unit) vectorDotProduct _direction < 0.5) exitWith {_lightRange = 0};
};
_lightRange > 0 && {[_unit, "VIEW", _target] checkVisibility [eyePos _unit, aimPos _target] >= 0.5}
