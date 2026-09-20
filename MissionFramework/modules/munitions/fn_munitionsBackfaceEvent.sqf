/* Native projectile-owner events retain one candidate per actual contact.
   Deleted at near-zero speed confirms the game stop; disappearance alone does
   not. Shared maps retain penetration/ricochet rejection after deletion. */
if (isRemoteExecuted) exitWith {};
params ["_event", "_args"];
private _projectile = _args param [0, objNull];
if (isNull _projectile || {!local _projectile}
    || {!(_projectile getVariable ["KPLIB_munitionsImpactHook", false])}
    || {_projectile getVariable ["KPLIB_munitionsParticle", false]}) exitWith {};
private _previous = _projectile getVariable ["KPLIB_munitionsBackfaceContact", createHashMap];
if (_event != "HIT") exitWith {
    if (count _previous == 0 || {_previous get "state" != "waiting"}) exitWith {};
    switch (_event) do {
        case "EXIT": {
            if ((_args select 1) isEqualTo (_previous get "object")
                && {(_args select 3) distance (_previous get "entry") < 0.2}) then {
                _previous set ["state", "penetrated"];
            };
        };
        case "DEFLECT": {_previous set ["state", "deflected"]};
        case "DELETE": {
            private _stopped = CBA_missionTime - (_previous get "at") <= 0.25
                && {vectorMagnitude velocity _projectile <= 1}
                && {getPosASL _projectile distance (_previous get "entry") <= 0.75};
            _previous set ["state", ["unconfirmed deletion", "stopped"] select _stopped];
        };
    };
};
_args params ["", "_object", "", "_position", "_velocity", "_normal", "", "", "_surface"];
// Duplicate callbacks cannot replace the candidate or renew its deadline.
if (count _previous > 0 && {(_previous get "object") isEqualTo _object}
    && {_position distance (_previous get "entry") < 0.1}
    && {diag_frameNo == _previous get "frame"}) exitWith {};
if (count _previous > 0) then {
    if (_previous get "state" == "waiting") then {_previous set ["state", "later contact"]};
};
if (isNull _object || {!alive _object} || {!isDamageAllowed _object}
    || {_object getVariable ["KPLIB_pressure_ignore", false]}) exitWith {};
private _structure = _object isKindOf "House" || {_object isKindOf "Building"};
private _armored = _object isKindOf "LandVehicle" && {getNumber (configOf _object >> "armor") >= 100};
if (!_structure && {!_armored}) exitWith {};
if (count _position != 3 || {count _velocity != 3} || {count _normal != 3}
    || {(_position + _velocity + _normal) findIf {!(_x isEqualType 0) || {!finite _x}} >= 0}
    || {vectorMagnitude _normal < 0.5}) exitWith {};
private _cfg = configOf _projectile;
private _hit = getNumber (_cfg >> "hit");
private _speed = vectorMagnitude _velocity;
private _material = [_surface] call KPLIB_fnc_munitionsMaterial;
// Conservative effect eligibility, not a material failure threshold.
private _supported = _material in ["MASONRY", "METAL"];
if (!_supported || {_hit < 40} || {_speed < 50}
    || {!(toLower getText (_cfg >> "simulation") in ["shotbullet", "shotshell", "shotrocket", "shotmissile"])}
    || {getNumber (_cfg >> "explosive") >= 0.5 && {!(_projectile getShotInfo 5)}}) exitWith {};
_normal = vectorNormalized _normal;
if ((vectorNormalized _velocity) vectorDotProduct _normal > -0.35) exitWith {};
private _count = _projectile getVariable ["KPLIB_munitionsBackfaceCount", 0];
private _queue = localNamespace getVariable ["KPLIB_munitionsBackfaceQueue", []];
if (_count >= 4 || {count _queue >= 16}) exitWith {
    [objNull, "BACKFACE OMITTED", _position, [typeOf _projectile, "contact/queue capacity"]] call KPLIB_fnc_munitionsEvent;
};
private _candidate = createHashMapFromArray [
    ["object", _object], ["entry", +_position], ["normal", _normal], ["surface", _surface],
    ["ammo", typeOf _projectile], ["parents", getShotParents _projectile], ["projectile", _projectile],
    ["at", CBA_missionTime], ["frame", diag_frameNo], ["state", "waiting"],
    ["count", round linearConversion [40, 200, _hit, 4, 12, true]], ["speed", (_speed * 0.15) min 120],
    ["anchor", [_object, getPosWorld _object, vectorDir _object, vectorUp _object]]
];
_projectile setVariable ["KPLIB_munitionsBackfaceCount", _count + 1];
_projectile setVariable ["KPLIB_munitionsBackfaceContact", _candidate];
_queue pushBack _candidate;
localNamespace setVariable ["KPLIB_munitionsBackfaceQueue", _queue];
