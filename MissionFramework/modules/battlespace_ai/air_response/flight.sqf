/* One server-owned controller owns navigation and fire orders, with a bounded
   final-run flight assist. The engine simulates projectiles; no flight teleports. */
BATTLESPACE_AIR_ORDER = {
    if (!isServer || {isRemoteExecuted}) exitWith {};
    params ["_state", "_position", "_altitude", "_speed", ["_clearance", 100]];
    private _aircraft = _state get "aircraft";
    private _pilot = driver _aircraft;
    if (!local _aircraft || {!local _pilot} || {isPlayer _pilot}) exitWith {};
    private _group = group _pilot;
    private _settings = _state getOrDefault ["flightSettings", [-1,-1,-1]];
    if (abs (_altitude - (_settings select 0)) > 5 || {abs (_speed - (_settings select 1)) > 2} || {_clearance != (_settings select 2)}) then {
        _aircraft flyInHeight _clearance;
        _aircraft flyInHeightASL [_altitude, _altitude, _altitude];
        _pilot forceSpeed _speed;
        _state set ["flightSettings", [_altitude,_speed,_clearance]];
    };
    private _last = _state getOrDefault ["orderPosition", [1e9,1e9,0]];
    private _tolerance = if (_state get "stage" == "RUN") then {15} else {75};
    if (_last vectorDistance _position > _tolerance || {CBA_missionTime >= (_state getOrDefault ["nextOrderAt", 0])}) then {
        private _destination = +_position;
        if (_state get "stage" == "RUN"
            && {(_state getOrDefault ["weapon", createHashMap]) getOrDefault ["kind", ""] in ["GUN", "ROCKET"]}) then {
            // Fly through the firing leg. A destination on the target makes
            // the native helicopter pilot brake and raise the nose to stop.
            private _direction = _state get "runDirection";
            _destination = _destination vectorAdd ([sin _direction, cos _direction, 0] vectorMultiply 2000);
        };
        _destination set [2, _altitude - (getTerrainHeightASL _destination max 0)];
        if (count waypoints _group < 2) then {
            private _waypoint = _group addWaypoint [_destination, 0];
            _waypoint setWaypointType "MOVE";
            _waypoint setWaypointBehaviour "AWARE";
            _waypoint setWaypointCombatMode "BLUE";
            _waypoint setWaypointSpeed "FULL";
            _waypoint setWaypointCompletionRadius 50;
        } else {
            [_group, 1] setWaypointPosition [_destination, 0];
        };
        _group setCurrentWaypoint [_group, 1];
        _pilot doMove _destination;
        _state set ["orderPosition", +_position];
        _state set ["nextOrderAt", CBA_missionTime + 30];
    };
};

BATTLESPACE_AIR_SET_STAGE = {
    if (!isServer || {isRemoteExecuted}) exitWith {};
    params ["_state", "_stage"];
    if (_stage != (_state getOrDefault ["stage", ""]) && {_state getOrDefault ["angularAssist", false]}) then {
        private _aircraft = _state get "aircraft";
        if (!isNull _aircraft && {local _aircraft}) then {_aircraft setAngularVelocity [0,0,0]};
        _state set ["angularAssist", false];
    };
    _state set ["stage", _stage];
    _state set ["stageAt", CBA_missionTime];
    _state set ["nextOrderAt", 0];
    _state deleteAt "stableSince";
    _state deleteAt "aimDirection";
    if (_stage == "PLAN") then {_state deleteAt "solution"};
    if (missionNamespace getVariable ["BATTLESPACE_DEBUG_INDEPTH", false]) then {
        diag_log format ["[BATTLESPACE][AIR] %1 %2 %3 %4", _state get "id", _stage, (_state getOrDefault ["weapon", createHashMap]) getOrDefault ["kind", ""], (_state getOrDefault ["weapon", createHashMap]) getOrDefault ["guidance", ""]];
    };
};

// Plan a usable straight leg before entering a bomb release envelope. The
// margin gives the aircraft five seconds to settle on the planned course.
BATTLESPACE_AIR_MINIMUM_RUN = {
    params ["_weapon", "_entry", "_aim", "_altitude", "_speed", "_direction"];
    if (_weapon get "kind" != "BOMB") exitWith {1500};
    if (_weapon get "guidance" == "GPS") exitWith {
        // Glide bombs use the same inner height/range envelope as release.
        (((_altitude - (_aim select 2)) * 0.6) + _speed * 5) max 1500
    };
    private _axis = [sin _direction, cos _direction, 0];
    private _trial = +_entry;
    _trial set [2, _altitude];
    private _prediction = [_trial, _axis vectorMultiply (_speed + (_weapon get "speed")), _axis, _weapon, _aim, [0,0,0]] call BATTLESPACE_AIR_PREDICT;
    ((((_prediction select 1) vectorDiff _trial) vectorDotProduct _axis) + _speed * 5) max 1500
};

BATTLESPACE_AIR_PLAN_RUN = {
    if (!isServer || {isRemoteExecuted}) exitWith {};
    params ["_state", "_target"];
    private _aircraft = _state get "aircraft";
    private _weapon = _state get "weapon";
    private _kind = _weapon get "kind";
    private _plane = _aircraft isKindOf "Plane";
    private _targetPosition = aimPos _target;
    private _direction = (getPosASL _aircraft) getDir _targetPosition;
    private _height = if (_kind == "BOMB") then {BATTLESPACE_AIR_BOMB_HEIGHT} else {if (_plane) then {BATTLESPACE_AIR_JET_ATTACK_HEIGHT} else {BATTLESPACE_AIR_HELI_ATTACK_HEIGHT}};
    private _speed = if (_plane) then {160} else {50};
    _speed = _speed min (getNumber (configFile >> "CfgVehicles" >> typeOf _aircraft >> "maxSpeed") / 3.6 * 0.8);
    private _lead = velocity _target vectorMultiply (if (_kind == "BOMB") then {sqrt (2 * _height / 9.80665)} else {3});
    private _aim = _targetPosition vectorAdd _lead;
    private _runLength = if (_kind == "BOMB") then {(_speed * sqrt (2 * _height / 9.80665) + 3500) max 5500} else {if (_plane) then {3500} else {2300}};
    private _entry = _aim getPos [_runLength, _direction + 180];
    private _exit = _aim getPos [[1200, 2500] select _plane, _direction];
    private _terrain = (getTerrainHeightASL _aim) max 0;
    // A constant barometric altitude over the entire run, with native clearance
    // still enabled. Mountain relief cannot turn the planned run into a dive.
    for "_i" from 0 to 12 do {
        _terrain = _terrain max getTerrainHeightASL (_entry vectorAdd ((_exit vectorDiff _entry) vectorMultiply (_i / 12)));
    };
    _state set ["entry", _entry];
    _state set ["exit", _exit];
    _state set ["runDirection", _direction];
    _state set ["runTarget", _targetPosition];
    _state set ["altitude", _terrain + _height];
    _state set ["attackSpeed", _speed];
    _state set ["shotsAtEntry", _state get "shots"];
    private _aligned = (vectorDir _aircraft) vectorDotProduct ((getPosASL _aircraft) vectorFromTo _aim) > 0.85;
    private _minimumRun = [_weapon, _entry, _aim, _terrain + _height, _speed, _direction] call BATTLESPACE_AIR_MINIMUM_RUN;
    _state set ["minimumRun", _minimumRun];
    private _alreadyInbound = _aligned && {_aircraft distance2D _aim > _minimumRun} && {_aircraft distance2D _aim < _runLength};
    [_state, ["INGRESS", "RUN"] select _alreadyInbound] call BATTLESPACE_AIR_SET_STAGE;
};

BATTLESPACE_AIR_DESIGNATOR = {
    params ["_aircraft"];
    private _hasLaser = false;
    {
        private _turret = _x;
        private _operator = if (_turret isEqualTo [-1]) then {driver _aircraft} else {_aircraft turretUnit _turret};
        if (isNull _operator || {!alive _operator}) then {continue};
        {
            private _state = weaponState [_aircraft, _turret, _x];
            private _ammo = getText (configFile >> "CfgMagazines" >> (_state param [3, ""]) >> "ammo");
            if ((_state param [4, 0]) > 0 && {toLower getText (configFile >> "CfgAmmo" >> _ammo >> "simulation") == "laserdesignate"}) exitWith {_hasLaser = true};
        } forEach (_aircraft weaponsTurret _turret);
        if (_hasLaser) exitWith {};
    } forEach ([[-1]] + allTurrets _aircraft);
    _hasLaser
};

BATTLESPACE_AIR_ALIGN_FIXED_WEAPON = {
    params ["_state", "_launchDirection", "_solution"];
    if (!isServer || {isRemoteExecuted}) exitWith {false};
    private _aircraft = _state get "aircraft";
    private _weapon = _state get "weapon";
    _state deleteAt "aimDirection";
    if (!local _aircraft || {isPlayer driver _aircraft} || {!((_weapon get "turret") isEqualTo [-1])}) exitWith {false};
    if (_state get "stage" != "RUN" || {getPosATL _aircraft select 2 < 100}) exitWith {false};
    private _error = (_solution select 1) vectorDiff (_solution select 3);
    private _range = (getPosASL _aircraft) vectorDistance (_solution select 3);
    if (_range > 2200 || {_range < 400}) exitWith {false};
    private _wantedLaunch = vectorNormalized (_launchDirection vectorDiff (_error vectorMultiply (2 / (_range max 1))));
    private _direction = vectorDir _aircraft;
    private _wanted = vectorNormalized (_direction vectorAdd (_wantedLaunch vectorDiff _launchDirection));
    private _pitchLimit = [25,50] select (_aircraft isKindOf "Plane");
    if ((_wanted select 2) < -sin _pitchLimit) then {
        // Keep correcting within the safe envelope instead of dropping all
        // aiming assistance when a steep correction first reaches its limit.
        private _horizontal = +_wanted;
        _horizontal set [2, 0];
        _wanted = (vectorNormalized _horizontal) vectorMultiply cos _pitchLimit;
        _wanted set [2, -sin _pitchLimit];
    };
    _state set ["aimDirection", _wanted];
    _state set ["aimExpiresAt", CBA_missionTime + 0.25];
    true
};

BATTLESPACE_AIR_FLY_ATTACK = {
    params ["_state", ["_observedPositionAttack", false]];
    if (!isServer || {isRemoteExecuted}) exitWith {};
    private _aircraft = _state get "aircraft";
    private _bomb = _aircraft isKindOf "Plane" && {(_state getOrDefault ["weapon", createHashMap]) getOrDefault ["kind", ""] == "BOMB"};
    private _turning = _bomb && {_state get "stage" == "TURN"};
    if (_state get "stage" != "RUN" && {!_turning}) exitWith {};
    if (!local _aircraft || {!alive _aircraft} || {!local driver _aircraft} || {crew _aircraft findIf {isPlayer _x} >= 0}
        || {_aircraft getVariable ["KPLIB_captured", false]} || {!(_state get "visible") && {!_observedPositionAttack} && {!_turning}}) exitWith {
        if (local _aircraft && {_state getOrDefault ["angularAssist", false]}) then {
            _aircraft setAngularVelocity [0,0,0];
            _state set ["angularAssist", false];
        };
    };
    private _headingError = 0;
    if (_bomb) then {
        private _position = getPosASL _aircraft;
        private _point = _state get "runTarget";
        if (!_turning) then {_point = _state getOrDefault ["orderPosition", _point]};
        _headingError = (((_position getDir _point) - (getDir _aircraft) + 540) mod 360) - 180;
        private _heading = getDir _aircraft + (if (_turning) then {(_headingError max -60) min 60} else {_headingError});
        private _pitch = (((_state get "altitude") - (_position select 2)) atan2 2000) max -5 min 5;
        _state set ["aimDirection", [sin _heading * cos _pitch, cos _heading * cos _pitch, sin _pitch]];
        _state set ["aimExpiresAt", CBA_missionTime + 0.25];
    };
    private _wanted = _state getOrDefault ["aimDirection", []];
    if (_wanted isEqualTo [] || {CBA_missionTime > (_state getOrDefault ["aimExpiresAt", 0])}) exitWith {
        if (_state getOrDefault ["angularAssist", false]) then {
            _aircraft setAngularVelocity [0,0,0];
            _state set ["angularAssist", false];
        };
    };
    private _direction = vectorDir _aircraft;
    private _elapsed = (CBA_missionTime - (_state getOrDefault ["lastAlignmentAt", CBA_missionTime - 0.02])) min 0.05;
    _state set ["lastAlignmentAt", CBA_missionTime];
    private _angle = acos ((-1 max (_direction vectorDotProduct _wanted)) min 1);
    private _alignmentRate = if (_turning) then {((9.80665 * tan 45) / ((vectorMagnitude velocity _aircraft) max 80)) * 180 / pi} else {18};
    private _fraction = (_alignmentRate * _elapsed / (_angle max 0.001)) min 1;
    private _next = vectorNormalized (_direction vectorAdd ((_wanted vectorDiff _direction) vectorMultiply _fraction));
    private _up = vectorUp _aircraft;
    private _levelUp = vectorNormalized ((_next vectorCrossProduct [0,0,1]) vectorCrossProduct _next);
    if (_turning) then {
        private _bank = (_headingError * 0.5) max -45 min 45;
        private _right = _next vectorCrossProduct _levelUp;
        _levelUp = (_levelUp vectorMultiply cos _bank) vectorAdd (_right vectorMultiply sin _bank);
    };
    private _upAngle = acos ((-1 max (_up vectorDotProduct _levelUp)) min 1);
    private _upFraction = (8 * _elapsed / (_upAngle max 0.001)) min 1;
    _up = vectorNormalized (_up vectorAdd ((_levelUp vectorDiff _up) vectorMultiply _upFraction));
    private _velocity = velocity _aircraft;
    private _desiredVelocity = if (_aircraft isKindOf "Plane") then {
        (if (_bomb && {!_turning}) then {_wanted} else {_next}) vectorMultiply (if (_turning) then {110} else {_state get "attackSpeed"})
    } else {
        // Rotorcraft can keep translating while pitching their fixed weapons.
        private _horizontal = +_next;
        _horizontal set [2,0];
        (vectorNormalized _horizontal) vectorMultiply (_state get "attackSpeed")
    };
    private _change = _desiredVelocity vectorDiff _velocity;
    private _limit = (if (_turning) then {tan 45} else {2.5}) * 9.80665 * _elapsed;
    if (vectorMagnitude _change > _limit) then {_change = (vectorNormalized _change) vectorMultiply _limit};
    private _nextVelocity = _velocity vectorAdd _change;
    private _ahead = getPosASL _aircraft vectorAdd (_nextVelocity vectorMultiply 2);
    if ((_ahead select 2) - (getTerrainHeightASL _ahead max 0) < 80) exitWith {
        _state set ["failedRuns", (_state get "failedRuns") + 1];
        [_state, "EGRESS"] call BATTLESPACE_AIR_SET_STAGE;
        false
    };
    // Bombers also need a coordinated turn onto the release course. Turn rate
    // and lateral acceleration follow a 45-degree bank; the firing leg retains
    // the 18-degree/s and 2.5g limits. Native navigation owns ingress, egress,
    // search and return. Neither aircraft position nor ammunition is rewritten.
    if (_state get "physX") then {
        // Native angular control also works for the legacy Su-25 airplane
        // simulation. Repeated pose writes interfere with its flight response.
        private _turn = _direction vectorCrossProduct _wanted;
        private _roll = (vectorUp _aircraft) vectorCrossProduct _levelUp;
        private _angular = (_turn vectorAdd (_direction vectorMultiply (_roll vectorDotProduct _direction))) vectorMultiply 2;
        private _angularLimit = _alignmentRate * pi / 180;
        if (vectorMagnitude _angular > _angularLimit) then {_angular = vectorNormalized _angular vectorMultiply _angularLimit};
        _aircraft setAngularVelocity (_angular vectorMultiply -1);
        _state set ["angularAssist", true];
    } else {
        _aircraft setVectorDirAndUp [_next, _up];
    };
    _aircraft setVelocity _nextVelocity;
    true
};

BATTLESPACE_AIR_LASER = {
    if (!isServer || {isRemoteExecuted}) exitWith {objNull};
    params ["_state", "_target", "_visible"];
    private _aircraft = _state get "aircraft";
    private _spot = _state getOrDefault ["laser", objNull];
    private _canLase = _visible && {_state getOrDefault ["designator", false]} && {alive _target};
    // The pilot camera's actual gimbal, or the crewed turret's forward hemisphere,
    // bounds self-designation. A camera alone is not a laser designator.
    private _relative = _aircraft vectorWorldToModel ((getPosASL _aircraft) vectorFromTo (aimPos _target));
    private _yaw = (_relative select 0) atan2 (_relative select 1);
    private _pitch = asin ((-1 max (_relative select 2)) min 1);
    if (hasPilotCamera _aircraft) then {
        private _camera = configFile >> "CfgVehicles" >> typeOf _aircraft >> "PilotCamera";
        // Pilot-camera angles use positive left yaw and downward elevation.
        _yaw = -_yaw;
        _pitch = -_pitch;
        _canLase = _canLase && {_yaw >= getNumber (_camera >> "minTurn")} && {_yaw <= getNumber (_camera >> "maxTurn")}
            && {_pitch >= getNumber (_camera >> "minElev")} && {_pitch <= getNumber (_camera >> "maxElev")};
    } else {
        _canLase = _canLase && {abs _yaw < 85} && {_pitch > -80} && {_pitch < 30};
    };
    if (!_canLase) exitWith {
        if (!isNull _spot) then {deleteVehicle _spot};
        _state set ["laser", objNull];
        objNull
    };
    if (isNull _spot) then {
        _spot = createVehicle ["LaserTargetE", ASLToATL aimPos _target, [], 0, "CAN_COLLIDE"];
        _state set ["laser", _spot];
    };
    _spot setPosASL aimPos _target;
    (group driver _aircraft) reveal [_spot, 4];
    _spot
};

BATTLESPACE_AIR_FIRE = {
    params ["_state", "_target", "_aim"];
    if (!isServer || {isRemoteExecuted}) exitWith {false};
    private _aircraft = _state get "aircraft";
    private _weapon = _state get "weapon";
    private _turret = _weapon get "turret";
    private _operator = if (_turret isEqualTo [-1]) then {driver _aircraft} else {_aircraft turretUnit _turret};
    if (!local _aircraft || {isNull _operator} || {!local _operator} || {!alive _operator} || {isPlayer _operator}) exitWith {false};
    private _loaded = weaponState [_aircraft, _turret, _weapon get "weapon", _weapon get "muzzle"];
    if ((_loaded param [4, 0]) <= 0 || {(_loaded param [5, 1]) > 0} || {(_loaded param [6, 1]) > 0}) exitWith {false};
    private _firingTarget = _target;
    if (_weapon get "guidance" == "LASER") then {_firingTarget = _state getOrDefault ["laser", objNull]};
    if (isNull _firingTarget) exitWith {false};
    _operator selectWeapon [_weapon get "weapon", _weapon get "muzzle", _weapon get "mode"];
    // Fixed unguided weapons use the computed firing solution. A simultaneous
    // engine target/zeroing correction would apply ballistic compensation twice.
    _operator doTarget (if (_turret isEqualTo [-1] && {_weapon get "guidance" == "NONE"}) then {objNull} else {_firingTarget});
    _state set ["pendingShot", [_weapon, _target, +_aim, CBA_missionTime]];
    _operator forceWeaponFire [_weapon get "muzzle", _weapon get "mode"];
    true
};

BATTLESPACE_AIR_FIRED = {
    params ["_aircraft", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile"];
    if (!isServer || {isRemoteExecuted} || {isNull _projectile} || {!local _projectile}) exitWith {};
    private _id = _aircraft getVariable ["TASKFORCEID", ""];
    private _runtime = localNamespace getVariable ["BATTLESPACE_AIR_RUNTIME", createHashMap];
    private _state = _runtime getOrDefault [_id, createHashMap];
    if (count _state == 0 || {_state get "aircraft" isNotEqualTo _aircraft}) exitWith {};
    private _pending = _state getOrDefault ["pendingShot", []];
    if (_pending isEqualTo []) exitWith {};
    _pending params ["_info", "_target", "_aim", "_requestedAt"];
    if (_ammo != (_info get "ammo") || {CBA_missionTime - _requestedAt > 0.5}) exitWith {};
    _state set ["shots", (_state get "shots") + 1];
    _state set ["lastShotAt", CBA_missionTime];
    private _guidance = _info get "guidance";
    if (_info get "ace" == "") then {
        switch (_guidance) do {
            case "SEEKER": {_projectile setMissileTarget _target};
            case "LASER": {_projectile setMissileTarget (_state getOrDefault ["laser", objNull])};
            case "GPS": {_projectile setMissileTargetPos (ASLToATL _aim)};
            case "COMMAND": {_projectile setMissileTargetPos (ASLToATL _aim)};
        };
    } else {
        private _key = (localNamespace getVariable ["BATTLESPACE_AIR_SHOT_SEQUENCE", 0]) + 1;
        localNamespace setVariable ["BATTLESPACE_AIR_SHOT_SEQUENCE", _key];
        _projectile setVariable ["BATTLESPACE_AIR_SHOT_ID", _key];
        (localNamespace getVariable "BATTLESPACE_AIR_GUIDED_SHOTS") set [_key, [_projectile, _id, _target, +_aim, _info, CBA_missionTime + 120, false]];
    };
    if (_guidance in ["LASER", "COMMAND"]) then {
        (_state get "projectiles") pushBack [_projectile, CBA_missionTime + ((_info get "life") min 120), _info, _target];
    };
    _state set ["nextShotAt", CBA_missionTime + (switch (_info get "kind") do {case "MISSILE": {15}; case "BOMB": {5}; case "ROCKET": {0.2}; default {0.1}})];
    [_id] call BATTLESPACE_AIR_SAVE_AIRCRAFT;
};

BATTLESPACE_AIR_GUIDE = {
    if (!isServer || {isRemoteExecuted}) exitWith {};
    params ["_state", "_target", "_visible"];
    private _aircraft = _state get "aircraft";
    private _projectiles = (_state get "projectiles") select {!isNull (_x select 0) && {CBA_missionTime < (_x select 1)}};
    _state set ["projectiles", _projectiles];
    private _needsLaser = ((_state getOrDefault ["weapon", createHashMap]) getOrDefault ["guidance", ""]) == "LASER"
        || {_projectiles findIf {(_x select 2) get "guidance" == "LASER"} >= 0};
    if (_needsLaser) then {[_state, _target, _visible] call BATTLESPACE_AIR_LASER};
    if (!_needsLaser) then {
        private _spot = _state getOrDefault ["laser", objNull];
        if (!isNull _spot) then {deleteVehicle _spot};
        _state set ["laser", objNull];
    };
    {
        _x params ["_projectile", "_expires", "_weapon", "_guidedTarget"];
        if (!local _projectile || {!alive _guidedTarget} || {_guidedTarget isNotEqualTo _target} || {!_visible}) then {continue};
        if (_aircraft distance _guidedTarget > (_weapon get "range")) then {continue};
        if (_weapon get "guidance" == "COMMAND" && {_weapon get "ace" == ""}) then {
            private _direction = _aircraft weaponDirection (_weapon get "muzzle");
            if ((_direction vectorDotProduct ((getPosASL _aircraft) vectorFromTo (aimPos _guidedTarget))) > cos 30) then {
                _projectile setMissileTargetPos (ASLToATL aimPos _guidedTarget);
            };
        };
        // Native laser guidance reacquires the spot; never force a seeker lock
        // again after launch (countermeasures and terrain must still matter).
    } forEach _projectiles;
};
