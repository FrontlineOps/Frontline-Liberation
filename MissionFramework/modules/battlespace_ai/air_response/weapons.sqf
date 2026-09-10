/* Loadout queries and firing solutions. Positions in the solver are ASL.
   These functions never spawn ammunition or alter a projectile's flight physics. */
BATTLESPACE_AIR_WEAPON_INFO = {
    params ["_weapon", "_muzzle", "_magazine", "_turret"];
    private _mag = configFile >> "CfgMagazines" >> _magazine;
    private _ammo = getText (_mag >> "ammo");
    private _cfg = configFile >> "CfgAmmo" >> _ammo;
    private _simulation = toLower getText (_cfg >> "simulation");
    if !(_simulation in ["shotbullet", "shotshell", "shotrocket", "shotmissile", "shotbomb"]) exitWith {createHashMap};
    private _kind = "GUN";
    private _guidance = "NONE";
    private _manual = getNumber (_cfg >> "manualControl") > 0;
    private _laser = getNumber (_cfg >> "laserLock") > 0;
    private _airOnly = getNumber (_cfg >> "airLock") == 2;
    private _powered = getNumber (_cfg >> "thrust") > 0 && {getNumber (_cfg >> "thrustTime") > 0};
    if (_simulation in ["shotrocket", "shotmissile", "shotbomb"]) then {
        _kind = if (_powered) then {"ROCKET"} else {"BOMB"};
        if (_manual || {_laser} || {getNumber (_cfg >> "missileLockCone") > 0 && {getNumber (_cfg >> "maneuvrability") > 0}}) then {
            if (_powered) then {_kind = "MISSILE"};
            _guidance = "SEEKER";
            if (_laser) then {_guidance = "LASER"};
            if (_manual && {!_laser}) then {_guidance = ["COMMAND", "GPS"] select (_kind == "BOMB")};
        };
    };
    private _aceCfg = _cfg >> "ace_missileguidance";
    private _ace = "";
    if (getNumber (_aceCfg >> "enabled") == 1 && {(missionNamespace getVariable ["ace_missileguidance_enabled", 0]) >= 2}
        && {("configName _x == 'ace_missileguidance'" configClasses _cfg) isNotEqualTo []}) then {
        _ace = getText (_aceCfg >> "defaultSeekerType");
        if (_ace == "GPS") then {_guidance = "GPS"};
        if (_ace in ["MCLOS", "SACLOS"]) then {_guidance = "COMMAND"; _kind = "MISSILE"};
        if (_ace == "SALH") then {_guidance = "LASER"};
    };

    private _weaponCfg = configFile >> "CfgWeapons" >> _weapon;
    private _muzzleCfg = if (_weapon == _muzzle) then {_weaponCfg} else {_weaponCfg >> _muzzle};
    private _modes = getArray (_muzzleCfg >> "modes");
    private _mode = _modes param [0, "this"];
    if (_mode == "this") then {_mode = _muzzle};
    private _range = getNumber (_muzzleCfg >> "maxRange");
    private _minimum = getNumber (_muzzleCfg >> "minRange");
    {
        private _modeCfg = if (_x == "this") then {_muzzleCfg} else {_muzzleCfg >> _x};
        _range = _range max getNumber (_modeCfg >> "maxRange");
    } forEach _modes;
    private _lockRange = getNumber (_cfg >> "missileLockMaxDistance");
    private _controlRange = getNumber (_cfg >> "maxControlRange");
    if (_kind == "MISSILE") then {
        if (_lockRange > 0) then {_range = if (_range > 10) then {_range min _lockRange} else {_lockRange}};
        if (_guidance == "COMMAND" && {_controlRange > 0}) then {_range = if (_range > 10) then {_range min _controlRange} else {_controlRange}};
    };
    if (_range <= 10) then {_range = switch (_kind) do {case "GUN": {1200}; case "ROCKET": {2000}; case "BOMB": {5000}; default {2000}}};
    if (_ace != "" && {getNumber (_aceCfg >> "seekerMaxRange") > 0}) then {_range = _range min getNumber (_aceCfg >> "seekerMaxRange")};
    _minimum = _minimum max getNumber (_cfg >> "missileLockMinDistance") max getNumber (_cfg >> "fuseDistance");
    private _gravity = if (isNumber (_cfg >> "coefGravity")) then {getNumber (_cfg >> "coefGravity")} else {1};
    private _speed = getNumber (_mag >> "initSpeed");
    private _weaponSpeed = getNumber (_muzzleCfg >> "initSpeed");
    if (_weaponSpeed > 0) then {_speed = _weaponSpeed};
    if (_weaponSpeed < 0) then {_speed = _speed * abs _weaponSpeed};
    createHashMapFromArray [
        ["weapon", _weapon], ["muzzle", _muzzle], ["mode", _mode], ["magazine", _magazine],
        ["ammo", _ammo], ["turret", +_turret], ["kind", _kind], ["guidance", _guidance],
        ["airOnly", _airOnly], ["airCapable", getNumber (_cfg >> "airLock") > 0],
        ["range", _range], ["minimum", _minimum], ["cone", getNumber (_cfg >> "missileLockCone")],
        ["speed", _speed], ["drag", getNumber (_cfg >> "airFriction")],
        ["sideDrag", getNumber (_cfg >> "sideAirFriction")], ["gravity", _gravity],
        ["thrust", getNumber (_cfg >> "thrust")], ["burn", getNumber (_cfg >> "thrustTime")],
        ["delay", getNumber (_cfg >> "initTime")], ["life", getNumber (_cfg >> "timeToLive")],
        ["blast", getNumber (_cfg >> "indirectHitRange")], ["simulation", _simulation],
        ["bodyStability", getNumber (_cfg >> "maneuvrability") / 4], ["ace", _ace]
    ]
};

BATTLESPACE_AIR_LOADOUT = {
    params ["_aircraft"];
    private _result = [];
    {
        private _turret = _x;
        private _operator = if (_turret isEqualTo [-1]) then {driver _aircraft} else {_aircraft turretUnit _turret};
        if (isNull _operator || {!alive _operator}) then {continue};
        {
            private _weapon = _x;
            private _muzzles = getArray (configFile >> "CfgWeapons" >> _weapon >> "muzzles");
            if (_muzzles isEqualTo []) then {_muzzles = ["this"]};
            {
                private _muzzle = if (_x == "this") then {_weapon} else {_x};
                private _state = weaponState [_aircraft, _turret, _weapon, _muzzle];
                if ((_state param [4, 0]) <= 0) then {continue};
                private _info = [_weapon, _muzzle, _state param [3, ""], _turret] call BATTLESPACE_AIR_WEAPON_INFO;
                if (count _info > 0) then {_result pushBack _info};
            } forEach _muzzles;
        } forEach (_aircraft weaponsTurret _turret);
    } forEach ([[-1]] + allTurrets _aircraft);
    _result
};

BATTLESPACE_AIR_PICK_WEAPON = {
    params ["_aircraft", "_target", "_loadout"];
    private _airTarget = _target isKindOf "Air" && {getPosATL _target select 2 > 20};
    private _best = createHashMap;
    private _bestScore = -1;
    {
        private _kind = _x get "kind";
        if (_airTarget && {!(_x get "airCapable") || {_kind in ["BOMB", "ROCKET"]}}) then {continue};
        if (!_airTarget && {_x get "airOnly"}) then {continue};
        private _score = switch (_kind) do {case "MISSILE": {400}; case "BOMB": {300}; case "ROCKET": {200}; default {100}};
        if (_x get "guidance" == "NONE" && {_kind == "BOMB"} && {abs speed _target > 15}) then {_score = 150};
        if (_kind == "BOMB" && {_aircraft isKindOf "Plane"}) then {_score = _score + 150};
        _score = _score + ((_x get "range") min 10000) / 10000;
        if (_score > _bestScore) then {_bestScore = _score; _best = _x};
    } forEach _loadout;
    _best
};

BATTLESPACE_AIR_SHOT_ORIGIN = {
    params ["_aircraft", "_weapon"];
    private _position = getPosASL _aircraft;
    private _direction = _aircraft weaponDirection (_weapon get "muzzle");
    if (vectorMagnitude _direction < 0.5) then {_direction = vectorDir _aircraft};
    // Native pylon transforms include model-specific offsets and cant (Arma 2.20).
    private _pylons = getAllPylonsInfo _aircraft;
    private _index = _pylons findIf {(_x param [3, ""]) == (_weapon get "magazine") && {(_x param [4, 0]) > 0}};
    if (_index >= 0) then {
        private _transform = (_pylons select _index) param [6, []];
        if (count _transform == 3 && {(_transform select 0) isNotEqualTo [0,0,0]}) then {
            _position = _aircraft modelToWorldWorld (_transform select 0);
            _direction = _aircraft vectorModelToWorld (_transform select 1);
        };
    };
    [_position, vectorNormalized _direction]
};

BATTLESPACE_AIR_PREDICT = {
    params ["_position", "_velocity", "_direction", "_weapon", "_targetPosition", ["_targetVelocity", [0,0,0]]];
    private _kind = _weapon get "kind";
    private _rocket = _kind == "ROCKET";
    private _bomb = _kind == "BOMB";
    private _dt = if (_bomb) then {0.05} else {0.025};
    private _steps = if (_bomb) then {1200} else {240};
    private _drag = _weapon get "drag";
    if (_rocket || {_bomb && {_weapon get "simulation" == "shotmissile"}}) then {_drag = -0.002 * abs _drag};
    private _gravity = -9.80665 * (_weapon get "gravity");
    private _burn = _weapon get "burn";
    private _delay = _weapon get "delay";
    private _thrust = _weapon get "thrust";
    private _life = (_weapon get "life") max 0.1;
    private _sideDrag = _weapon get "sideDrag";
    private _axis = +_direction;
    private _bodyStability = _weapon get "bodyStability";
    // Native CUP FAB-250 trajectory calibration (1500m/180m/s), checked against
    // actual aircraft releases. These are prediction coefficients, never edits
    // to the munition. Other loadouts keep their configured RV coefficients.
    if (_bomb && {(_weapon get "ammo") == "CUP_FAB250"}) then {
        _drag = -0.000194;
        _sideDrag = 0.142;
        _bodyStability = 1.15;
    };
    private _p = +_position;
    private _v = +_velocity;
    private _elapsed = 0;
    private _best = [_p vectorDistance _targetPosition, +_p, 0, +_targetPosition];
    for "_i" from 1 to _steps do {
        if (_elapsed > _life) exitWith {};
        private _acceleration = (_v vectorMultiply (_drag * vectorMagnitude _v)) vectorAdd [0,0,_gravity];
        if (_rocket || {_bomb && {_weapon get "simulation" == "shotmissile"}}) then {
            private _axial = _v vectorDotProduct _axis;
            private _lateral = _v vectorDiff (_axis vectorMultiply _axial);
            _acceleration = (_axis vectorMultiply (_drag * _axial * abs _axial))
                vectorAdd (_lateral vectorMultiply (-_sideDrag * vectorMagnitude _lateral)) vectorAdd [0,0,_gravity];
        };
        if (_rocket && {_elapsed >= _delay} && {_elapsed < _delay + _burn}) then {
            _acceleration = _acceleration vectorAdd (_direction vectorMultiply _thrust);
        };
        private _next = _p vectorAdd (_v vectorMultiply _dt) vectorAdd (_acceleration vectorMultiply (0.5 * _dt * _dt));
        private _futureTarget = _targetPosition vectorAdd (_targetVelocity vectorMultiply (_elapsed + _dt));
        private _oldTarget = _targetPosition vectorAdd (_targetVelocity vectorMultiply _elapsed);
        if (_bomb && {(_p select 2) >= (_oldTarget select 2)} && {(_next select 2) <= (_futureTarget select 2)}) exitWith {
            private _above = (_p select 2) - (_oldTarget select 2);
            private _below = (_futureTarget select 2) - (_next select 2);
            private _fraction = _above / ((_above + _below) max 0.001);
            private _impact = _p vectorAdd ((_next vectorDiff _p) vectorMultiply _fraction);
            private _target = _oldTarget vectorAdd ((_futureTarget vectorDiff _oldTarget) vectorMultiply _fraction);
            _best = [_impact distance2D _target, _impact, _elapsed + _dt * _fraction, _target];
        };
        private _relative = _p vectorDiff _oldTarget;
        private _segment = (_next vectorDiff _futureTarget) vectorDiff _relative;
        private _fraction = 0 max (1 min (-(_relative vectorDotProduct _segment) / ((vectorMagnitudeSqr _segment) max 0.00001)));
        private _miss = vectorMagnitude (_relative vectorAdd (_segment vectorMultiply _fraction));
        if (_miss < (_best select 0)) then {
            _best = [_miss, _p vectorAdd ((_next vectorDiff _p) vectorMultiply _fraction), _elapsed + _dt * _fraction, _oldTarget vectorAdd ((_futureTarget vectorDiff _oldTarget) vectorMultiply _fraction)];
        };
        _elapsed = _elapsed + _dt;
        _v = _v vectorAdd (_acceleration vectorMultiply _dt);
        if (_bomb && {_bodyStability > 0}) then {
            _axis = vectorNormalized (_axis vectorAdd (((vectorNormalized _v) vectorDiff _axis) vectorMultiply ((_bodyStability * _dt) min 1)));
        };
        _p = _next;
        if ((_p select 2) < ((_targetPosition select 2) - 20) || {!_bomb && {_elapsed > (_best select 2) + 0.5}}) exitWith {};
    };
    _best
};

BATTLESPACE_AIR_CLEAR_SIGHT = {
    params ["_aircraft", "_target"];
    private _from = eyePos driver _aircraft;
    private _to = aimPos _target;
    private _length = _from vectorDistance _to;
    if (_length > BATTLESPACE_AIR_ENGAGEMENT_KEEP_RANGE) exitWith {false};
    if (terrainIntersectASL [_from, _to]) exitWith {false};
    // Terrain geometry at distant dedicated-server positions needs a local query.
    nearestTerrainObjects [getPosATL _target, ["HOUSE", "BUILDING", "TREE", "ROCK", "WALL"], 80, false, true];
    // Keep long-range visibility queries bounded to segments below 1km.
    private _segments = ceil (_length / 750) max 1;
    private _step = (_to vectorDiff _from) vectorMultiply (1 / _segments);
    private _clear = true;
    for "_i" from 1 to _segments do {
        private _end = _from vectorAdd _step;
        if ((lineIntersectsSurfaces [_from, _end, _aircraft, _target, true, 1, "VIEW", "FIRE"]) isNotEqualTo []
            || {[_aircraft, "VIEW", _target] checkVisibility [_from, _end] < 0.5}) exitWith {_clear = false};
        _from = _end;
    };
    _clear
};
