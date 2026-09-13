/* One stopped-contact job per particle callback, sharing its soft budget.
   Geometry is sampled locally; no victim search or remote damage request. */
if (isRemoteExecuted) exitWith {};
params ["_started"];
private _queue = localNamespace getVariable ["KPLIB_munitionsBackfaceQueue", []];
if (_queue isEqualTo [] || {diag_tickTime - _started >= 0.001}) exitWith {};
private _job = _queue deleteAt 0;
private _state = _job get "state";
private _age = CBA_missionTime - (_job get "at");
if (_age > 0.25) then {_state = "expired"};
if (_state == "waiting" && {diag_frameNo > _job get "frame"}) then {
    private _projectile = _job get "projectile";
    if (isNull _projectile || {!local _projectile}) then {
        _state = "unconfirmed disappearance/locality";
    } else {
        if (vectorMagnitude velocity _projectile > 1) then {_state = "continuing"};
    };
};
if (_state == "waiting") exitWith {
    _queue pushBack _job;
    localNamespace setVariable ["KPLIB_munitionsBackfaceQueue", _queue];
};
_job set ["state", _state];
localNamespace setVariable ["KPLIB_munitionsBackfaceQueue", _queue];
private _object = _job get "object";
private _entry = _job get "entry";
private _anchor = _job get "anchor";
if (isNull _object || {!alive _object} || {!isDamageAllowed _object}
    || {_object getVariable ["KPLIB_pressure_ignore", false]}) then {_state = "object unavailable/protected"};
if (_state == "stopped" && {getPosWorld _object distance (_anchor select 1) > 0.1
    || {vectorDir _object vectorDotProduct (_anchor select 2) < 0.999}
    || {vectorUp _object vectorDotProduct (_anchor select 3) < 0.999}}) then {_state = "object moved"};
private _admitted = 0;
private _rear = [];
if (_state == "stopped") then {
    _rear = [_object, _entry, _job get "normal"] call KPLIB_fnc_munitionsBackfaceSurface;
    if (_rear isEqualTo []) then {
        _state = "no nearby opposing FIRE surface";
    } else {
        _rear params ["_position", "_normal", "_surface"];
        private _directions = [_job get "count"] call KPLIB_fnc_munitionsFragDirections;
        _directions = _directions apply {
            if (_x vectorDotProduct _normal < 0) then {_x vectorMultiply -1} else {_x}
        };
        private _types = ["ACE_frag_tiny_HD", "ACE_frag_small_HD"] select {isClass (configFile >> "CfgAmmo" >> _x)};
        private _origin = _position vectorAdd (_normal vectorMultiply 0.02);
        _admitted = [_origin, _job get "ammo", _directions, _types, _job get "speed", _job get "parents", "BACKFACE SPALL", [], _anchor] call KPLIB_fnc_munitionsEmit;
        _state = "stopped; rear-face proxies admitted";
    };
};
[objNull, "BACKFACE RESULT", _entry, [_job get "ammo", _state, "entry material", _job get "surface", "rear surface", _rear, "admitted", _admitted, "game approximation; native collision"], _object] call KPLIB_fnc_munitionsEvent;
