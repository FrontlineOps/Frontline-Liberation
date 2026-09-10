/* Optional ACE guidance adapter. The installed ACE guidanceTick event exposes
   its running argument array; this is an internal ACE interface, shape-checked
   here and verified in native fixtures. Never patch ACE functions or create a
   second guidance worker. ACE retains servos, wire limits and aerodynamics. */
BATTLESPACE_AIR_ACE_GUIDANCE = {
    if (!isServer || {isRemoteExecuted} || {count _this < 7}) exitWith {};
    private _fired = _this param [0, []];
    private _projectile = _fired param [6, objNull];
    if (isNull _projectile || {!local _projectile}) exitWith {};
    private _key = _projectile getVariable ["BATTLESPACE_AIR_SHOT_ID", -1];
    if (_key < 0) exitWith {};
    private _shots = localNamespace getVariable ["BATTLESPACE_AIR_GUIDED_SHOTS", createHashMap];
    private _record = _shots getOrDefault [_key, []];
    if (count _record != 7 || {(_record select 0) isNotEqualTo _projectile}) exitWith {};
    _record params ["", "_id", "_target", "_aim", "_weapon", "_expires", "_initialized"];
    private _launch = _this select 1;
    private _stateParams = _this select 4;
    if (count _launch < 7 || {count _stateParams < 6}) exitWith {};
    private _seeker = _launch select 2;
    if (_seeker == "GPS" && {_weapon get "guidance" == "GPS"}) exitWith {
        if (!_initialized) then {
            (_stateParams select 1) set [0, [+_aim, -1, -1]];
            if ((_launch select 3) == "JDAM") then {(_stateParams select 2) set [0, [+_aim, -1, -1]]};
            _record set [6, true];
        };
    };
    if (_seeker != "MCLOS" || {_weapon get "guidance" != "COMMAND"}) exitWith {};
    // ACE's dedicated-server launch path can leave the player-only crosshair
    // offset nil. A crewed AI launcher uses the zero offset in ACE's own model.
    if ((_launch select 3) == "WIRE" && {count (_stateParams select 2) >= 8}) then {
        (_stateParams select 2) set [3, [0,0,0]];
    };
    private _runtime = localNamespace getVariable ["BATTLESPACE_AIR_RUNTIME", createHashMap];
    private _state = _runtime getOrDefault [_id, createHashMap];
    private _operation = BATTLESPACE_STRATEGIC_OPERATIONS getOrDefault [_id, createHashMap];
    private _input = [0,0,0];
    private _canGuide = count _state > 0 && {alive _target}
        && {(_operation getOrDefault ["phase", "RETURNING"]) != "RETURNING"}
        && {_state get "target" isEqualTo _target} && {_state get "visible"};
    if (_canGuide) then {
        private _aircraft = _state get "aircraft";
        private _gunner = _aircraft turretUnit (_weapon get "turret");
        if ((_weapon get "turret") isEqualTo [-1]) then {_gunner = driver _aircraft};
        _canGuide = alive _aircraft && {alive _gunner} && {local _aircraft} && {local _gunner}
            && {!(_aircraft getVariable ["KPLIB_captured", false])}
            && {_aircraft distance _target < (_weapon get "range")}
            && {_aircraft distance _projectile < (_weapon get "range")}
            && {(_aircraft weaponDirection (_weapon get "muzzle")) vectorDotProduct ((getPosASL _aircraft) vectorFromTo (aimPos _target)) > cos 30};
        if (_canGuide) then {
            private _remaining = _projectile distance _target;
            private _leadTime = (_remaining / ((vectorMagnitude velocity _projectile) max 50)) min 6;
            private _wanted = (aimPos _target) vectorAdd ((velocity _target) vectorMultiply _leadTime);
            private _velocity = velocity _projectile;
            private _flight = vectorNormalized _velocity;
            private _wantedVelocity = ((getPosASL _projectile) vectorFromTo _wanted) vectorMultiply (vectorMagnitude _velocity);
            private _acceleration = (_wantedVelocity vectorDiff _velocity) vectorAdd [0,0,9.80665 * (_weapon get "gravity")];
            private _normal = _acceleration vectorDiff (_flight vectorMultiply (_acceleration vectorDotProduct _flight));
            // Aerodynamic lift needs an angle between the missile body and its
            // velocity. Pointing the body directly at a ground target falls short.
            private _slip = (vectorNormalized _normal) vectorMultiply sqrt ((vectorMagnitude _normal) / ((_weapon get "sideDrag") max 0.01));
            private _direction = _projectile vectorWorldToModel (_velocity vectorAdd _slip);
            private _yaw = (_direction select 0) atan2 (_direction select 1);
            private _pitch = (_direction select 2) atan2 (_direction select 1);
            _input = [(-1 max (_yaw / 5)) min 1, 0, (-1 max (_pitch / 5)) min 1];
        };
    };
    // Supply per-projectile operator inputs. ACE's stock AI MCLOS fallback only
    // holds its launch line; its normal player-input path uses these controls.
    _stateParams set [1, []];
    _projectile setVariable ["ace_missileguidance_source", _projectile];
    _projectile setVariable ["ace_missileguidance_MCLOS_direction", _input];
};

if (isServer) then {
    localNamespace setVariable ["BATTLESPACE_AIR_GUIDED_SHOTS", createHashMap];
    localNamespace setVariable ["BATTLESPACE_AIR_SHOT_SEQUENCE", 0];
    ["ace_missileguidance_guidanceTick", {_this call BATTLESPACE_AIR_ACE_GUIDANCE}] call CBA_fnc_addEventHandler;
};
