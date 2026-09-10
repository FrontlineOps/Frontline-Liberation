/* AIR_RESPONSE-only state. Persistent ammunition lives in the existing
   operation metadata; objects, callbacks and run geometry are server-local. */
BATTLESPACE_AIR_SAVE_AIRCRAFT = {
    params ["_id"];
    if (!isServer || {isRemoteExecuted}) exitWith {};
    private _force = BATTLESPACE_TASK_FORCES getOrDefault [_id, []];
    private _operation = BATTLESPACE_STRATEGIC_OPERATIONS getOrDefault [_id, createHashMap];
    if ((_force param [0, ""]) != "Air Response" || {count _operation == 0} || {_force param [11, false]}) exitWith {};
    private _objects = _force param [8, []];
    private _index = _objects findIf {alive _x && {_x isKindOf "Air"} && {!(_x getVariable ["KPLIB_captured", false])}};
    if (_index < 0) exitWith {};
    private _aircraft = _objects select _index;
    private _magazines = (magazinesAllTurrets [_aircraft, true]) apply {[_x select 0, _x select 1, _x select 2]};
    private _pylons = (getAllPylonsInfo _aircraft) apply {[_x select 0, _x select 3, _x select 4, _x select 2]};
    {
        _x params ["_number", "_magazine", "_ammo", "_turret"];
        private _match = _magazines findIf {(_x select 0) == _magazine && {(_x select 1) isEqualTo _turret} && {(_x select 2) == _ammo}};
        if (_match >= 0) then {_magazines deleteAt _match};
    } forEach _pylons;
    _operation set ["aircraftState", [typeOf _aircraft, fuel _aircraft, damage _aircraft, _magazines, _pylons]];
};

BATTLESPACE_AIR_RESTORE_AIRCRAFT = {
    params ["_aircraft", "_operation"];
    if (!isServer || {isRemoteExecuted} || {!local _aircraft}) exitWith {};
    private _saved = _operation getOrDefault ["aircraftState", []];
    if (count _saved != 5 || {(_saved select 0) != typeOf _aircraft}) exitWith {};
    _saved params ["_class", "_fuel", "_damage", "_magazines", "_pylons"];
    private _remove = [];
    {_remove pushBackUnique [_x select 0, _x select 1]} forEach magazinesAllTurrets [_aircraft, true];
    {_aircraft removeMagazinesTurret _x} forEach _remove;
    {
        _x params ["_number", "_magazine", "_ammo", "_turret"];
        _aircraft setPylonLoadout [_number, _magazine, true, _turret];
        _aircraft setAmmoOnPylon [_number, _ammo max 0];
    } forEach _pylons;
    {_aircraft addMagazineTurret [_x select 0, _x select 1, _x select 2]} forEach _magazines;
    _aircraft setFuel _fuel;
    _aircraft setDamage _damage;
};

BATTLESPACE_AIR_STOP = {
    params ["_id"];
    if (!isServer || {isRemoteExecuted}) exitWith {};
    private _runtime = localNamespace getVariable ["BATTLESPACE_AIR_RUNTIME", createHashMap];
    private _state = _runtime getOrDefault [_id, createHashMap];
    if (count _state == 0) exitWith {};
    [_state, "STOP"] call BATTLESPACE_AIR_SET_STAGE;
    _runtime deleteAt _id;
    private _aircraft = _state get "aircraft";
    if (!isNull _aircraft) then {_aircraft removeEventHandler ["Fired", _state get "firedEH"]};
    private _laser = _state getOrDefault ["laser", objNull];
    if (!isNull _laser) then {deleteVehicle _laser};
    {
        _x params ["_unit", "_autoCombat", "_autoTarget", "_speed", "_combat", "_lambs", "_aimingError"];
        if (!isNull _unit && {local _unit}) then {
            _unit enableAIFeature ["AUTOCOMBAT", _autoCombat];
            _unit enableAIFeature ["AUTOTARGET", _autoTarget];
            _unit enableAIFeature ["AIMINGERROR", _aimingError];
            _unit forceSpeed _speed;
            _unit setUnitCombatMode _combat;
            _unit setVariable ["lambs_danger_disableAI", _lambs];
            _unit doTarget objNull;
            _unit doWatch objNull;
        };
    } forEach (_state get "crewSettings");
    private _group = _state get "group";
    if (!isNull _group && {local _group}) then {
        _group setCombatMode (_state get "combatMode");
        _group setBehaviourStrong (_state get "behaviour");
        _group setVariable ["lambs_danger_disableGroupAI", _state get "lambsGroup"];
    };
};

BATTLESPACE_AIR_START = {
    params ["_id"];
    if (!isServer || {isRemoteExecuted}) exitWith {false};
    private _force = BATTLESPACE_TASK_FORCES getOrDefault [_id, []];
    if ((_force param [0, ""]) != "Air Response" || {_force param [11, false]}) exitWith {false};
    private _objects = _force param [8, []];
    private _index = _objects findIf {alive _x && {_x isKindOf "Air"} && {local _x} && {!(_x getVariable ["KPLIB_captured", false])}};
    if (_index < 0) exitWith {false};
    private _aircraft = _objects select _index;
    private _pilot = driver _aircraft;
    if (isNull _pilot || {!alive _pilot} || {!local _pilot} || {isPlayer _pilot} || {(crew _aircraft) findIf {isPlayer _x} >= 0}) exitWith {false};
    private _runtime = localNamespace getVariable ["BATTLESPACE_AIR_RUNTIME", createHashMap];
    private _old = _runtime getOrDefault [_id, createHashMap];
    if (count _old > 0 && {_old get "aircraft" isEqualTo _aircraft}) exitWith {true};
    if (count _old > 0) then {[_id] call BATTLESPACE_AIR_STOP};
    private _group = group _pilot;
    // These two bounded campaign responses stay server-owned. ACE must not move
    // their pilots halfway through a release or command-guided missile flight.
    _group setVariable ["acex_headless_blacklist", true, true];
    private _crewSettings = (crew _aircraft) apply {[_x, _x checkAIFeature "AUTOCOMBAT", _x checkAIFeature "AUTOTARGET", getForcedSpeed _x, unitCombatMode _x, _x getVariable ["lambs_danger_disableAI", false], _x checkAIFeature "AIMINGERROR"]};
    private _state = createHashMapFromArray [
        ["id", _id], ["aircraft", _aircraft], ["group", _group], ["crewSettings", _crewSettings],
        ["physX", toLower getText (configFile >> "CfgVehicles" >> typeOf _aircraft >> "simulation") in ["airplanex", "helicopterx", "helicopterrtd"]],
        ["combatMode", combatMode _group], ["behaviour", behaviour _pilot],
        ["lambsGroup", _group getVariable ["lambs_danger_disableGroupAI", false]],
        ["stage", "PLAN"], ["stageAt", CBA_missionTime], ["weapon", createHashMap],
        ["shots", 0], ["nextShotAt", 0], ["projectiles", []], ["target", objNull],
        ["nextSenseAt", 0], ["visible", false], ["nextSaveAt", 0], ["failedRuns", 0]
    ];
    _group setVariable ["BATTLESPACE_ROUTE_WAYPOINT_TOKEN", (_group getVariable ["BATTLESPACE_ROUTE_WAYPOINT_TOKEN", 0]) + 1];
    for "_i" from (count waypoints _group - 1) to 0 step -1 do {deleteWaypoint [_group, _i]};
    _group setBehaviourStrong "AWARE";
    _group setCombatMode "BLUE";
    _group setVariable ["lambs_danger_disableGroupAI", true];
    {
        _x disableAI "AUTOCOMBAT";
        _x disableAI "AUTOTARGET";
        _x disableAI "AIMINGERROR";
        _x setUnitCombatMode "BLUE";
        _x setVariable ["lambs_danger_disableAI", true];
    } forEach crew _aircraft;
    _state set ["designator", [_aircraft] call BATTLESPACE_AIR_DESIGNATOR];
    _state set ["firedEH", _aircraft addEventHandler ["Fired", {_this call BATTLESPACE_AIR_FIRED}]];
    _runtime set [_id, _state];
    localNamespace setVariable ["BATTLESPACE_AIR_RUNTIME", _runtime];
    true
};

BATTLESPACE_AIR_TICK = {
    params ["_id", "_state"];
    if (!isServer || {isRemoteExecuted}) exitWith {};
    private _force = BATTLESPACE_TASK_FORCES getOrDefault [_id, []];
    private _operation = BATTLESPACE_STRATEGIC_OPERATIONS getOrDefault [_id, createHashMap];
    private _aircraft = _state get "aircraft";
    private _pilot = driver _aircraft;
    if ((_force param [0, ""]) == "Air Response" && {alive _aircraft} && {alive _pilot}
        && {_aircraft in (_force param [8, []])} && {crew _aircraft findIf {isPlayer _x} < 0}
        && {!(_aircraft getVariable ["KPLIB_captured", false])} && {!local _pilot || {!local _aircraft}}) exitWith {
        // A non-ACE locality handoff must not leave a half-controlled attack on
        // another machine. Reclaim this already server-owned AI response before
        // issuing any more local flight, fire or restoration commands.
        _state set ["visible", false];
        [_state, objNull, false] call BATTLESPACE_AIR_GUIDE;
        if (CBA_missionTime >= (_state getOrDefault ["nextLocalityAt", 0])) then {
            (group _pilot) setGroupOwner 2;
            _state set ["nextLocalityAt", CBA_missionTime + 5];
        };
    };
    if (
        (_force param [0, ""]) != "Air Response" || {count _operation == 0}
        || {!(_aircraft in (_force param [8, []]))} || {!alive _aircraft} || {!canMove _aircraft}
        || {!local _aircraft} || {isNull _pilot} || {!alive _pilot} || {!local _pilot}
        || {_aircraft getVariable ["KPLIB_captured", false]} || {crew _aircraft findIf {isPlayer _x} >= 0}
    ) exitWith {[_id] call BATTLESPACE_AIR_STOP};
    if (_force param [11, false]) exitWith {};
    if (CBA_missionTime >= (_state get "nextSaveAt")) then {
        [_id] call BATTLESPACE_AIR_SAVE_AIRCRAFT;
        _state set ["nextSaveAt", CBA_missionTime + 1];
    };
    private _position = getPosASL _aircraft;
    private _plane = _aircraft isKindOf "Plane";
    private _phase = _operation getOrDefault ["phase", "INTERCEPT"];
    if (_phase == "RETURNING") exitWith {
        [_state, objNull, false] call BATTLESPACE_AIR_GUIDE;
        if (_state get "stage" != "RETURN") then {
            [_state, "RETURN"] call BATTLESPACE_AIR_SET_STAGE;
            {if (local _x) then {_x doTarget objNull; _x doWatch objNull}} forEach crew _aircraft;
        };
        private _destination = _force param [2, []];
        if (_destination isNotEqualTo []) then {
            private _last = _state getOrDefault ["lastReturnPosition", _position];
            private _a = +_last;
            private _b = +_position;
            _a set [2, 0];
            _b set [2, 0];
            private _segment = _b vectorDiff _a;
            private _fraction = 0 max (1 min (((_destination vectorDiff _a) vectorDotProduct _segment) / ((vectorMagnitudeSqr _segment) max 0.001)));
            if ((_a vectorAdd (_segment vectorMultiply _fraction)) distance2D _destination <= 250) then {_operation set ["airReturned", true]};
            _state set ["lastReturnPosition", +_position];
            [_state, _destination, (getTerrainHeightASL _destination max 0) + ([150,800] select _plane), [60,180] select _plane] call BATTLESPACE_AIR_ORDER;
        };
    };
    private _origin = BATTLESPACE_SECTOR_STATES getOrDefault [_operation getOrDefault ["originSector", ""], createHashMap];
    if ((_origin getOrDefault ["owner", ""]) != "OPFOR" || {CBA_missionTime >= (_operation getOrDefault ["expiresAt", CBA_missionTime])}
        || {fuel _aircraft < 0.12} || {damage _aircraft > 0.6}) exitWith {
        if !([_id, _force, _operation] call BATTLESPACE_AIR_RESPONSE_BEGIN_RETURN) then {[_id] call BATTLESPACE_AIR_STOP};
    };
    private _target = objectFromNetId (_operation getOrDefault ["targetNetId", ""]);
    private _valid = !isNull _target && {([_target] call BATTLESPACE_AIR_RESPONSE_CLASSIFY_CONTACT) == (_operation getOrDefault ["targetKind", ""])};
    if (!_valid) exitWith {
        _state set ["visible", false];
        [_state, objNull, false] call BATTLESPACE_AIR_GUIDE;
        if (_state get "stage" != "SEARCH") then {[_state, "SEARCH"] call BATTLESPACE_AIR_SET_STAGE};
        private _anchor = _operation getOrDefault ["contactPosition", _force select 1];
        private _search = _anchor getPos [1800, (floor (CBA_missionTime / 20) * 45) mod 360];
        [_state, _search, (getTerrainHeightASL _anchor max 0) + ([200,1000] select _plane), [40,160] select _plane] call BATTLESPACE_AIR_ORDER;
    };
    if (_target isNotEqualTo (_state get "target")) then {
        private _laser = _state getOrDefault ["laser", objNull];
        if (!isNull _laser) then {deleteVehicle _laser};
        _state set ["laser", objNull];
        _state set ["target", _target];
        [_state, "PLAN"] call BATTLESPACE_AIR_SET_STAGE;
    };
    private _aim = aimPos _target;
    private _distance = _position vectorDistance _aim;
    if (CBA_missionTime >= (_state get "nextSenseAt")) then {
        _state set ["visible", [_aircraft, _target] call BATTLESPACE_AIR_CLEAR_SIGHT];
        _state set ["nextSenseAt", CBA_missionTime + 0.5];
        if (_state get "visible") then {
            (group _pilot) reveal [_target, 4];
            {if (local _x) then {_x doTarget _target}} forEach crew _aircraft;
        };
    };
    private _visible = _state get "visible";
    [_state, _target, _visible] call BATTLESPACE_AIR_GUIDE;
    private _stage = _state get "stage";
    if (_stage in ["PLAN", "SEARCH"]) exitWith {
        private _weapon = [_aircraft, _target, [_aircraft] call BATTLESPACE_AIR_LOADOUT] call BATTLESPACE_AIR_PICK_WEAPON;
        if (count _weapon == 0 || {(_state get "failedRuns") >= 3}) exitWith {[_id, _force, _operation] call BATTLESPACE_AIR_RESPONSE_BEGIN_RETURN};
        if (_weapon get "guidance" == "LASER" && {!(_state get "designator")}) then {
            if (getNumber (configFile >> "CfgAmmo" >> (_weapon get "ammo") >> "irLock") > 0) then {
                _weapon set ["guidance", "SEEKER"];
            } else {
                _weapon set ["guidance", "NONE"];
            };
        };
        _state set ["weapon", _weapon];
        if (!_plane && {_weapon get "kind" == "MISSILE"} && {_weapon get "range" >= 1800} && {!(_target isKindOf "Air" && {getPosATL _target select 2 > 20})}) then {
            _state set ["standoffBearing", _aim getDir _position];
            _state set ["movingOut", false];
            _state set ["holding", false];
            [_state, "STANDOFF"] call BATTLESPACE_AIR_SET_STAGE;
        } else {
            if (_target isKindOf "Air" && {getPosATL _target select 2 > 20}) then {
                [_state, "INTERCEPT"] call BATTLESPACE_AIR_SET_STAGE;
            } else {
                [_state, _target] call BATTLESPACE_AIR_PLAN_RUN;
            };
        };
    };
    private _weapon = _state get "weapon";
    private _kind = _weapon get "kind";
    private _weaponState = weaponState [_aircraft, _weapon get "turret", _weapon get "weapon", _weapon get "muzzle"];
    if ((_weaponState param [3, ""]) != (_weapon get "magazine") && {_stage != "EGRESS"}) exitWith {
        [_state, "PLAN"] call BATTLESPACE_AIR_SET_STAGE;
    };
    if ((_weaponState param [4, 0]) <= 0 && {_stage != "EGRESS"}) exitWith {
        [_state, ["PLAN", "EGRESS"] select (_stage == "RUN" && {(_state get "shots") > (_state get "shotsAtEntry")})] call BATTLESPACE_AIR_SET_STAGE;
    };
    private _elapsed = CBA_missionTime - (_state get "stageAt");
    if (_elapsed > 180) exitWith {
        _state set ["failedRuns", (_state get "failedRuns") + 1];
        [_state, "PLAN"] call BATTLESPACE_AIR_SET_STAGE;
    };
    if (_stage == "INGRESS") exitWith {
        private _entry = _state get "entry";
        [_state, _entry, _state get "altitude", if (_plane) then {110} else {40}] call BATTLESPACE_AIR_ORDER;
        if (_position distance2D _entry < ([180,400] select _plane)) then {[_state, "TURN"] call BATTLESPACE_AIR_SET_STAGE};
    };
    if (_stage == "TURN") exitWith {
        private _towards = _position vectorFromTo [_aim select 0, _aim select 1, _position select 2];
        private _alignment = vectorDir _aircraft vectorDotProduct _towards;
        private _speed = if (_plane) then {if (_alignment > 0.8) then {_state get "attackSpeed"} else {110}} else {30};
        [_state, _aim, _state get "altitude", _speed] call BATTLESPACE_AIR_ORDER;
        if (_alignment > 0.995) then {
            private _direction = _position getDir _aim;
            _state set ["runDirection", _direction];
            _state set ["exit", _aim getPos [[1200,2500] select _plane, _direction]];
            [_state, "RUN"] call BATTLESPACE_AIR_SET_STAGE;
        };
    };
    if (_stage == "EGRESS") exitWith {
        [_state, _state get "exit", _state get "altitude", _state get "attackSpeed"] call BATTLESPACE_AIR_ORDER;
        if (_position distance2D (_state get "exit") < 400 || {_elapsed > 35}) then {[_state, "PLAN"] call BATTLESPACE_AIR_SET_STAGE};
    };
    if (_stage == "STANDOFF") then {
        private _outer = ((_weapon get "range") * 0.85) min BATTLESPACE_AIR_STANDOFF_MAX;
        private _inner = _outer * 0.75;
        private _movingOut = _state getOrDefault ["movingOut", false];
        if (!_movingOut && {_aircraft distance2D _target < _inner + 100} && {(_state get "projectiles") isEqualTo []}) then {
            _movingOut = true;
            _state set ["movingOut", true];
            _state set ["standoffBearing", (_aim getDir _position) + 5];
            _state set ["nextOrderAt", 0];
        };
        if (_movingOut && {_aircraft distance2D _target > _outer - 100}) then {
            _movingOut = false;
            _state set ["movingOut", false];
            _state set ["standoffBearing", _aim getDir _position];
            _state set ["nextOrderAt", 0];
        };
        private _range = [_inner, _outer] select _movingOut;
        private _point = _aim getPos [_range, _state get "standoffBearing"];
        private _altitude = ((getTerrainHeightASL _point) max (_aim select 2)) + BATTLESPACE_AIR_HELI_ATTACK_HEIGHT;
        if (_position distance2D _point > 100) then {
            _state set ["holding", false];
            [_state, _point, _altitude, if (_movingOut) then {25} else {12}] call BATTLESPACE_AIR_ORDER;
        } else {
            if !(_state getOrDefault ["holding", false]) then {
                doStop _pilot;
                _pilot forceSpeed -1;
                _state set ["holding", true];
            };
        };
        _pilot doWatch _target;
    };
    if (_stage == "INTERCEPT") then {
        private _intercept = _aim vectorAdd ((velocity _target) vectorMultiply 5);
        [_state, _intercept, (_aim select 2) + 100, [70,250] select _plane] call BATTLESPACE_AIR_ORDER;
        _pilot doWatch _target;
    };
    if (_stage == "RUN") then {
        private _altitude = _state get "altitude";
        if (_kind in ["GUN", "ROCKET"]) then {
            _altitude = ((_aim select 2) + (_aircraft distance2D _target) * 0.3) min _altitude;
        };
        private _flightAim = +_aim;
        private _previousSolution = _state getOrDefault ["solution", []];
        if (count _previousSolution == 4 && {_weapon get "guidance" == "NONE"}) then {
            private _horizontalVelocity = velocity _aircraft;
            _horizontalVelocity set [2, 0];
            private _axis = vectorNormalized _horizontalVelocity;
            private _error = (_previousSolution select 1) vectorDiff (_previousSolution select 3);
            _error set [2, 0];
            private _crossTrack = _error vectorDiff (_axis vectorMultiply (_error vectorDotProduct _axis));
            private _correction = _crossTrack vectorMultiply 2;
            if (vectorMagnitude _correction > 300) then {_correction = (vectorNormalized _correction) vectorMultiply 300};
            _flightAim = (_previousSolution select 3) vectorDiff _correction;
        };
        private _clearance = if (_kind in ["GUN", "ROCKET"]) then {[40,50] select _plane} else {[80,150] select _plane};
        [_state, _flightAim, _altitude, _state get "attackSpeed", _clearance] call BATTLESPACE_AIR_ORDER;
        _pilot doWatch _target;
        private _forward = [sin (_state get "runDirection"), cos (_state get "runDirection"), 0];
        private _past = (_position vectorDiff _aim) vectorDotProduct _forward;
        private _shots = (_state get "shots") - (_state get "shotsAtEntry");
        private _quota = switch (_kind) do {case "GUN": {20}; case "ROCKET": {6}; default {1}};
        private _breakOff = if (_kind in ["GUN", "ROCKET"]) then {[200,350] select _plane} else {[250,500] select _plane};
        if (_past > -_breakOff || {_shots >= _quota}) exitWith {
            if (_shots == 0) then {_state set ["failedRuns", (_state get "failedRuns") + 1]} else {_state set ["failedRuns", 0]};
            [_state, "EGRESS"] call BATTLESPACE_AIR_SET_STAGE;
        };
    };
    if (_state get "stage" == "EGRESS" || {!_visible} || {CBA_missionTime < (_state get "nextShotAt")}) exitWith {};
    if (_distance < ((_weapon get "minimum") max 250) || {_distance > (_weapon get "range")}) exitWith {_state deleteAt "stableSince"};
    if (_kind == "MISSILE") exitWith {
        private _direction = _aircraft weaponDirection (_weapon get "muzzle");
        private _cone = (((_weapon get "cone") / 2) max 5) min 20;
        private _aligned = _direction vectorDotProduct (_position vectorFromTo _aim) > cos _cone;
        if (!_aligned || {count (_state get "projectiles") >= 2}) exitWith {_state deleteAt "stableSince"};
        private _stable = _state getOrDefault ["stableSince", CBA_missionTime];
        _state set ["stableSince", _stable];
        if (CBA_missionTime - _stable >= 1.5) then {[_state, _target, _aim] call BATTLESPACE_AIR_FIRE};
    };
    if (_kind == "BOMB" && {(_position select 2) - (_aim select 2) < BATTLESPACE_AIR_BOMB_HEIGHT * 0.7}) exitWith {};
    if (_kind == "BOMB" && {_weapon get "guidance" == "GPS"}) exitWith {
        private _height = (_position select 2) - (_aim select 2);
        private _horizontal = _aircraft distance2D _target;
        private _levelAim = [_aim select 0, _aim select 1, _position select 2];
        // Coordinate-guided glide bombs do not follow a free-fall parabola.
        // Release inside a conservative forward glide envelope, then let the
        // installed weapon guidance fly to the fixed coordinates.
        if (_horizontal <= _height * 2.5 && {_horizontal >= _height * 0.6}
            && {(vectorDir _aircraft vectorDotProduct (_position vectorFromTo _levelAim)) > 0.985}
            && {abs ((vectorDir _aircraft vectorCrossProduct vectorUp _aircraft) select 2) < sin 20}) then {
            [_state, _target, _aim] call BATTLESPACE_AIR_FIRE;
        };
    };
    private _origin = [_aircraft, _weapon] call BATTLESPACE_AIR_SHOT_ORIGIN;
    _origin params ["_launchPosition", "_launchDirection"];
    private _launchVelocity = velocity _aircraft vectorAdd (_launchDirection vectorMultiply (_weapon get "speed"));
    private _solution = [_launchPosition, _launchVelocity, _launchDirection, _weapon, _aim, velocity _target] call BATTLESPACE_AIR_PREDICT;
    _state set ["solution", _solution];
    private _strafeRange = if (_kind == "ROCKET") then {[1000,2200] select _plane} else {[1000,1500] select _plane};
    private _tolerance = if (_kind == "BOMB") then {if (_weapon get "guidance" == "NONE") then {8} else {150}} else {12};
    private _wingsLevel = abs ((vectorDir _aircraft vectorCrossProduct vectorUp _aircraft) select 2) < sin 20;
    private _onTarget = (_solution select 0) <= _tolerance;
    if (_kind == "BOMB" && {_weapon get "guidance" == "NONE"}) then {
        private _direction = velocity _aircraft;
        _direction set [2, 0];
        _direction = vectorNormalized _direction;
        private _error = (_solution select 1) vectorDiff (_solution select 3);
        private _along = _error vectorDotProduct _direction;
        private _across = vectorMagnitude (_error vectorDiff (_direction vectorMultiply _along));
        _onTarget = abs _along <= 9 && {_across <= 25};
    };
    if (_onTarget && {_wingsLevel} && {_kind == "BOMB" || {_distance <= _strafeRange}}) then {
        [_state, _target, if (_weapon get "guidance" == "GPS") then {_aim} else {_solution select 3}] call BATTLESPACE_AIR_FIRE;
    };
    // Fire from the observed simulation pose before applying the next frame's
    // steering. Fired projectiles inherit the simulation's committed velocity.
    if (_kind in ["GUN", "ROCKET"]) then {[_state, _launchDirection, _solution] call BATTLESPACE_AIR_ALIGN_FIXED_WEAPON};
};

if (isServer) then {
    localNamespace setVariable ["BATTLESPACE_AIR_RUNTIME", createHashMap];
    [{
        private _runtime = localNamespace getVariable ["BATTLESPACE_AIR_RUNTIME", createHashMap];
        {
            if (CBA_missionTime >= (_y getOrDefault ["nextTickAt", 0])) then {
                _y set ["nextTickAt", CBA_missionTime + 0.1];
                [_x, _y] call BATTLESPACE_AIR_TICK;
            };
            [_y] call BATTLESPACE_AIR_FLY_ATTACK;
        } forEach _runtime;
        private _shots = localNamespace getVariable ["BATTLESPACE_AIR_GUIDED_SHOTS", createHashMap];
        if (CBA_missionTime >= (localNamespace getVariable ["BATTLESPACE_AIR_NEXT_PRUNE", 0])) then {
            {if (isNull (_y select 0) || {CBA_missionTime > (_y select 5)}) then {_shots deleteAt _x}} forEach _shots;
            localNamespace setVariable ["BATTLESPACE_AIR_NEXT_PRUNE", CBA_missionTime + 1];
        };
    }, 0] call CBA_fnc_addPerFrameHandler;
};
