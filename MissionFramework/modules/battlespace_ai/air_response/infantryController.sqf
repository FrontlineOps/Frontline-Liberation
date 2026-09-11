/* Infantry engagement only; entered after the shared lifecycle/locality checks. */
BATTLESPACE_AIR_INFANTRY_TICK = {
    params ["_id", "_state", "_force", "_operation"];
    if (!isServer || {isRemoteExecuted} || {(_operation getOrDefault ["targetKind", ""]) != "INFANTRY"}) exitWith {};
    private _aircraft = _state get "aircraft";
    private _pilot = driver _aircraft;
    private _position = getPosASL _aircraft;
    private _plane = _aircraft isKindOf "Plane";
    private _target = objectFromNetId (_operation getOrDefault ["targetNetId", ""]);
    private _valid = [_target] call BATTLESPACE_AIR_INFANTRY_IS_TARGET;
    if (_valid) then {
        if (_target isNotEqualTo (_state get "target") || {CBA_missionTime >= (_state getOrDefault ["nextInfantryEvidenceAt", 0])}) then {
            private _record = (missionNamespace getVariable ["BATTLESPACE_CONTACT_MEMORY", createHashMap]) getOrDefault [str _target, []];
            private _reported = count _record >= 7 && {(_record select 5) isEqualTo _target}
                && {CBA_missionTime - (_record select 1) <= BATTLESPACE_AIR_INFANTRY_CONTACT_MAX_AGE};
            _state set ["infantryReported", _reported];
            _state set ["nextInfantryEvidenceAt", CBA_missionTime + 1];
            if (_reported && {!(_state get "visible") || {_target isNotEqualTo (_state get "target")}}) then {
                _operation set ["contactPosition", +(_record select 0)];
            };
        };
        _valid = (_state getOrDefault ["infantryReported", false])
            || {_target isEqualTo (_state get "target") && {_state get "visible"}}
            || {([_state, _target] call BATTLESPACE_AIR_INFANTRY_OBSERVATION) isNotEqualTo []};
    };
    if (!_valid) exitWith {
        private _anchor = _operation getOrDefault ["contactPosition", _force select 1];
        [_state, _operation, _anchor] call BATTLESPACE_AIR_INFANTRY_SEARCH;
    };
    if (_target isNotEqualTo (_state get "target")) then {
        private _laser = _state getOrDefault ["laser", objNull];
        if (!isNull _laser) then {deleteVehicle _laser};
        _state set ["laser", objNull];
        _state set ["target", _target];
        _state set ["visible", false];
        _state set ["nextSenseAt", 0];
        _state deleteAt "infantryObservation";
        _state set ["infantryMemoryAttack", false];
        _state set ["infantryMemoryUsed", false];
        [_state, "PLAN"] call BATTLESPACE_AIR_INFANTRY_SET_STAGE;
    };
    if (CBA_missionTime >= (_state get "nextSenseAt")) then {
        private _wasVisible = _state get "visible";
        _state set ["visible", [_aircraft, _target] call BATTLESPACE_AIR_CLEAR_SIGHT];
        _state set ["nextSenseAt", CBA_missionTime + 0.5];
        if (_state get "visible") then {
            private _observed = getPosATL _target;
            _observed set [2, 0];
            _operation set ["contactPosition", _observed];
            _state set ["infantryObservation", [_target, aimPos _target, CBA_missionTime]];
            _state set ["infantryMemoryUsed", false];
            (group _pilot) reveal [_target, 4];
            {if (local _x) then {_x doTarget _target}} forEach crew _aircraft;
        };
        if (_wasVisible && {!(_state get "visible")}) then {
            // Drop live object targeting and the previous moving-target solution.
            // The remaining pass uses a fixed observation, including for turrets.
            _state deleteAt "solution";
            _state deleteAt "aimDirection";
            {
                if (local _x) then {
                    _x doTarget objNull;
                    _x doWatch objNull;
                };
            } forEach crew _aircraft;
        };
    };
    private _visible = _state get "visible";
    private _observed = [_state, _target] call BATTLESPACE_AIR_INFANTRY_OBSERVATION;
    private _remembered = !_visible && {_observed isNotEqualTo []}
        && {!(_state getOrDefault ["infantryMemoryUsed", false])};
    _state set ["infantryMemoryAttack", _remembered];
    // A remembered position permits one area pass, never tracking through cover.
    // Reports can guide the search but cannot refresh this aircraft observation.
    if (!_visible && {!_remembered} && {!((_state get "stage") in ["INGRESS", "TURN", "EGRESS"])}) exitWith {
        [_state, _operation, _operation get "contactPosition"] call BATTLESPACE_AIR_INFANTRY_SEARCH;
    };
    private _aim = if (!_visible) then {
        if (_observed isEqualTo []) then {ATLToASL (_operation get "contactPosition")} else {_observed}
    } else {aimPos _target};
    private _targetVelocity = if (!_visible) then {[0,0,0]} else {velocity _target};
    private _distance = _position vectorDistance _aim;
    [_state, _target, _visible] call BATTLESPACE_AIR_GUIDE;
    private _stage = _state get "stage";
    if (_stage in ["PLAN", "SEARCH"]) exitWith {
        private _weapon = [_aircraft, _target, [_aircraft] call BATTLESPACE_AIR_LOADOUT, _aim, _remembered] call BATTLESPACE_AIR_INFANTRY_PICK_WEAPON;
        if (_remembered && {count _weapon == 0}) exitWith {[_state, _operation, _operation get "contactPosition"] call BATTLESPACE_AIR_INFANTRY_SEARCH};
        if (count _weapon == 0 || {(_state get "failedRuns") >= 3}) exitWith {[_id, _force, _operation] call BATTLESPACE_AIR_RESPONSE_BEGIN_RETURN};
        if (_weapon get "guidance" == "LASER" && {!(_state get "designator")}) then {
            if (getNumber (configFile >> "CfgAmmo" >> (_weapon get "ammo") >> "irLock") > 0) then {
                _weapon set ["guidance", "SEEKER"];
            } else {
                _weapon set ["guidance", "NONE"];
            };
        };
        _state set ["weapon", _weapon];
        [_state, _aim, _targetVelocity] call BATTLESPACE_AIR_INFANTRY_PLAN_RUN;
    };
    private _weapon = _state get "weapon";
    private _kind = _weapon get "kind";
    if (_remembered && {!([_weapon] call BATTLESPACE_AIR_WEAPON_VS_POSITION)} && {_stage != "EGRESS"}) exitWith {
        [_state, "PLAN"] call BATTLESPACE_AIR_INFANTRY_SET_STAGE;
    };
    private _weaponState = weaponState [_aircraft, _weapon get "turret", _weapon get "weapon", _weapon get "muzzle"];
    if ((_weaponState param [3, ""]) != (_weapon get "magazine") && {_stage != "EGRESS"}) exitWith {
        private _completed = _remembered && {_stage == "RUN"} && {(_state get "shots") > (_state get "shotsAtEntry")};
        [_state, ["PLAN", "EGRESS"] select _completed] call BATTLESPACE_AIR_INFANTRY_SET_STAGE;
    };
    if ((_weaponState param [4, 0]) <= 0 && {_stage != "EGRESS"}) exitWith {
        [_state, ["PLAN", "EGRESS"] select (_stage == "RUN" && {(_state get "shots") > (_state get "shotsAtEntry")})] call BATTLESPACE_AIR_INFANTRY_SET_STAGE;
    };
    private _elapsed = CBA_missionTime - (_state get "stageAt");
    if (_elapsed > 180) exitWith {
        _state set ["failedRuns", (_state get "failedRuns") + 1];
        [_state, "PLAN"] call BATTLESPACE_AIR_INFANTRY_SET_STAGE;
    };
    if (_stage == "INGRESS") exitWith {
        private _entry = _state get "entry";
        [_state, _entry, _state get "altitude", if (_plane) then {110} else {40}] call BATTLESPACE_AIR_ORDER;
        if (_position distance2D _entry < ([180,400] select _plane)) then {[_state, "TURN"] call BATTLESPACE_AIR_INFANTRY_SET_STAGE};
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
            [_state, "RUN"] call BATTLESPACE_AIR_INFANTRY_SET_STAGE;
        };
    };
    if (_stage == "EGRESS") exitWith {
        [_state, _state get "exit", _state get "altitude", _state get "attackSpeed"] call BATTLESPACE_AIR_ORDER;
        if (_position distance2D (_state get "exit") < 400 || {_elapsed > 35}) then {[_state, "PLAN"] call BATTLESPACE_AIR_INFANTRY_SET_STAGE};
    };
    if (_stage == "RUN") then {
        private _altitude = _state get "altitude";
        if (_kind in ["GUN", "ROCKET"]) then {
            private _horizontal = if (_remembered) then {_aircraft distance2D _aim} else {_aircraft distance2D _target};
            _altitude = ((_aim select 2) + _horizontal * 0.3) min _altitude;
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
        if (_remembered) then {_pilot doWatch (ASLToATL _aim)} else {_pilot doWatch _target};
        private _forward = [sin (_state get "runDirection"), cos (_state get "runDirection"), 0];
        private _past = (_position vectorDiff _aim) vectorDotProduct _forward;
        private _shots = (_state get "shots") - (_state get "shotsAtEntry");
        private _quota = switch (_kind) do {
            case "GUN": {20};
            case "ROCKET": {6};
            default {1};
        };
        private _breakOff = if (_kind in ["GUN", "ROCKET"]) then {[200,350] select _plane} else {[250,500] select _plane};
        if (_past > -_breakOff || {_shots >= _quota}) exitWith {
            if (_shots == 0) then {_state set ["failedRuns", (_state get "failedRuns") + 1]} else {_state set ["failedRuns", 0]};
            [_state, "EGRESS"] call BATTLESPACE_AIR_INFANTRY_SET_STAGE;
        };
    };
    if (_state get "stage" == "EGRESS" || {!_visible && {!_remembered}} || {CBA_missionTime < (_state get "nextShotAt")}) exitWith {};
    if (_distance < ((_weapon get "minimum") max 250) || {_distance > (_weapon get "range")}) exitWith {_state deleteAt "stableSince"};
    if (_kind == "BOMB" && {(_position select 2) - (_aim select 2) < BATTLESPACE_AIR_BOMB_HEIGHT * 0.7}) exitWith {};
    if (_kind == "BOMB" && {_weapon get "guidance" == "GPS"}) exitWith {
        private _height = (_position select 2) - (_aim select 2);
        private _horizontal = if (_remembered) then {_aircraft distance2D _aim} else {_aircraft distance2D _target};
        private _levelAim = [_aim select 0, _aim select 1, _position select 2];
        // Coordinate-guided glide bombs do not follow a free-fall parabola.
        // Release inside a conservative forward glide envelope, then let the
        // installed weapon guidance fly to the fixed coordinates.
        if (_horizontal <= _height * 2.5 && {_horizontal >= _height * 0.6}
            && {(vectorDir _aircraft vectorDotProduct (_position vectorFromTo _levelAim)) > 0.985}
            && {abs ((vectorDir _aircraft vectorCrossProduct vectorUp _aircraft) select 2) < sin 20}) then {
            [_state, _target, _aim] call BATTLESPACE_AIR_INFANTRY_FIRE;
        };
    };
    private _origin = [_aircraft, _weapon] call BATTLESPACE_AIR_SHOT_ORIGIN;
    _origin params ["_launchPosition", "_launchDirection"];
    private _launchVelocity = velocity _aircraft vectorAdd (_launchDirection vectorMultiply (_weapon get "speed"));
    private _solution = [_launchPosition, _launchVelocity, _launchDirection, _weapon, _aim, _targetVelocity] call BATTLESPACE_AIR_PREDICT;
    private _solutionInterval = ((CBA_missionTime - (_state getOrDefault ["lastSolutionAt", CBA_missionTime - 0.1])) max 0.1) min 0.3;
    _state set ["lastSolutionAt", CBA_missionTime];
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
        // At 160m/s a delayed 10Hz update can skip an 18m release window.
        // Infantry area bombing permits a bounded timing margin, not homing.
        private _alongTolerance = 9 max ((vectorMagnitude velocity _aircraft * _solutionInterval * 0.6) min 25);
        _onTarget = abs _along <= _alongTolerance && {_across <= 25};
    };
    if (_onTarget && {_wingsLevel} && {_kind == "BOMB" || {_distance <= _strafeRange}}) then {
        [_state, _target, if (_weapon get "guidance" == "GPS") then {_aim} else {_solution select 3}] call BATTLESPACE_AIR_INFANTRY_FIRE;
    };
    // Fire from the observed simulation pose before applying the next frame's
    // steering. Fired projectiles inherit the simulation's committed velocity.
    if (_kind in ["GUN", "ROCKET"]) then {[_state, _launchDirection, _solution] call BATTLESPACE_AIR_ALIGN_FIXED_WEAPON};
};
