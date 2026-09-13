/* Check before aiming and again at release. Friendly blast clearance, backblast and nearby geometry. */
params ["_unit", "_positionASL", "_profile", ["_target", objNull]];
private _kind = _profile get "kind";
private _origin = eyePos _unit;
if (lineIntersects [_origin, _origin vectorAdd ((vectorNormalized (_positionASL vectorDiff _origin)) vectorMultiply 8), _unit, _target]) exitWith {"Muzzle obstruction"};
if (_kind == "RIFLE") then {
    private _hits = lineIntersectsSurfaces [_origin, _positionASL, _unit, objNull, true, 1, "FIRE", "GEOM"];
    if (_hits isNotEqualTo [] && {(_hits select 0 select 2) != _target}
        && {(_hits select 0 select 3) != _target}) then {_kind = "BLOCKED"};
};
if (_kind == "BLOCKED") exitWith {"Fire corridor blocked"};
if (_kind in ["RPG", "GL"]) then {
    private _radius = (_profile get "blast") * 4 + KPLIB_aiCombat_blastMargin;
    private _near = (ASLToAGL _positionASL) nearEntities [["CAManBase", "LandVehicle", "Air"], _radius];
    if (_near findIf {alive _x && {_x != _target} && {
        side _x == civilian || {(side group _unit) getFriend (side _x) >= 0.6}
    }} >= 0) exitWith {_kind = "UNSAFE"};
};
if (_kind == "UNSAFE") exitWith {"Friendly or civilian in blast area"};
if (_kind == "RPG") then {
    private _back = (vectorNormalized (_origin vectorDiff _positionASL)) vectorMultiply KPLIB_aiCombat_backblastRange;
    if (lineIntersects [_origin, _origin vectorAdd _back, _unit, objNull]) exitWith {_kind = "BACKBLAST"};
    private _near = _unit nearEntities ["CAManBase", KPLIB_aiCombat_backblastRange];
    if (_near findIf {_x != _unit && {alive _x} && {
        (vectorNormalized ((eyePos _x) vectorDiff _origin)) vectorDotProduct (vectorNormalized _back) > 0.7
    }} >= 0) then {_kind = "BACKBLAST"};
};
if (_kind == "BACKBLAST") exitWith {"Backblast blocked or occupied"};
""
