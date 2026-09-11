/* Infantry-only filters and point attacks. Vehicle weapon choice, planning,
   release, ballistics and guidance retain the 4a218d8 implementations. */
BATTLESPACE_AIR_WEAPON_VS_POSITION = {
    params ["_weapon"];
    private _guidance = _weapon getOrDefault ["guidance", ""];
    _guidance == "NONE" || {_guidance == "GPS" && {_weapon getOrDefault ["kind", ""] == "BOMB"}}
};

BATTLESPACE_AIR_WEAPON_VS_INFANTRY = {
    params ["_weapon"];
    if (_weapon getOrDefault ["airOnly", false]) exitWith {false};
    private _kind = _weapon getOrDefault ["kind", ""];
    if (_kind == "GUN") exitWith {true};
    private _cfg = configFile >> "CfgAmmo" >> (_weapon getOrDefault ["ammo", ""]);
    _kind in ["ROCKET", "BOMB"] && {getNumber (_cfg >> "indirectHit") > 0}
        && {(_weapon getOrDefault ["blast", 0]) > 0}
        && {!((toUpper getText (_cfg >> "warheadName")) in ["HEAT", "TANDEMHEAT", "AP"])}
};

BATTLESPACE_AIR_CLASS_HAS_INFANTRY_WEAPON = {
    params ["_class"];
    private _cache = localNamespace getVariable ["BATTLESPACE_AIR_INFANTRY_CLASSES", createHashMap];
    // Guidance settings can change during a session; classify the active config.
    private _key = str [_class, missionNamespace getVariable ["ace_missileguidance_enabled", 0]];
    if (_key in _cache) exitWith {_cache get _key};
    private _cfg = configFile >> "CfgVehicles" >> _class;
    private _pending = [_cfg];
    private _magazines = [];
    while {_pending isNotEqualTo []} do {
        private _turret = _pending deleteAt 0;
        _magazines append getArray (_turret >> "magazines");
        _pending append ("isClass _x" configClasses (_turret >> "Turrets"));
    };
    {
        _magazines pushBack getText (_x >> "attachment");
    } forEach ("isClass _x" configClasses (_cfg >> "Components" >> "TransportPylonsComponent" >> "Pylons"));
    private _suitable = _magazines findIf {
        private _info = ["", "", _x, [-1]] call BATTLESPACE_AIR_WEAPON_INFO;
        count _info > 0 && {[_info] call BATTLESPACE_AIR_WEAPON_VS_INFANTRY}
    } >= 0;
    _cache set [_key, _suitable];
    localNamespace setVariable ["BATTLESPACE_AIR_INFANTRY_CLASSES", _cache];
    _suitable
};

BATTLESPACE_AIR_INFANTRY_FIRE_SAFE = {
    params ["_aircraft", "_target", "_weapon", "_aim"];
    if (!([_weapon] call BATTLESPACE_AIR_WEAPON_VS_INFANTRY)
        || {!([_target] call BATTLESPACE_AIR_INFANTRY_IS_TARGET)}) exitWith {false};
    private _margin = switch (_weapon get "kind") do {
        case "BOMB": {100};
        case "ROCKET": {60};
        default {25};
    };
    private _radius = _margin max (4 * (_weapon get "blast"));
    private _crewSide = side group driver _aircraft;
    // Local, release-time query; never scan all units every controller frame.
    ((ASLToATL _aim) nearEntities [["Man", "LandVehicle"], _radius]) findIf {
        private _unit = if (_x isKindOf "Man") then {_x} else {effectiveCommander _x};
        alive _x && {!isNull _unit} && {_x != _aircraft} && {side group _unit == civilian
            || {_crewSide getFriend (side group _unit) >= 0.6}}
    } < 0
};

BATTLESPACE_AIR_INFANTRY_PICK_WEAPON = {
    params ["_aircraft", "_target", "_loadout", ["_aim", []], ["_remembered", false]];
    if (_aim isEqualTo []) then {_aim = aimPos _target};
    private _best = createHashMap;
    private _bestScore = -1;
    {
        private _kind = _x get "kind";
        if (!([_x] call BATTLESPACE_AIR_WEAPON_VS_INFANTRY)) then {continue};
        if (_remembered && {!([_x] call BATTLESPACE_AIR_WEAPON_VS_POSITION)}) then {continue};
        if (!([_aircraft, _target, _x, _aim] call BATTLESPACE_AIR_INFANTRY_FIRE_SAFE)) then {continue};
        private _score = switch (_kind) do {
            case "MISSILE": {400};
            case "BOMB": {300};
            case "ROCKET": {200};
            default {100};
        };
        if (!_remembered && {_x get "guidance" == "NONE"} && {_kind == "BOMB"} && {abs speed _target > 15}) then {_score = 150};
        if (_kind == "BOMB" && {_aircraft isKindOf "Plane"}) then {_score = _score + 150};
        _score = _score + ((_x get "range") min 10000) / 10000;
        if (_score > _bestScore) then {
            _bestScore = _score;
            _best = _x;
        };
    } forEach _loadout;
    _best
};

BATTLESPACE_AIR_INFANTRY_SET_STAGE = {
    params ["_state", "_stage"];
    if (!isServer || {isRemoteExecuted}) exitWith {};
    if ((_state getOrDefault ["stage", ""]) == "RUN" && {_stage != "RUN"}
        && {_state getOrDefault ["infantryMemoryAttack", false]}) then {
        _state set ["infantryMemoryUsed", true];
        _state set ["infantryMemoryAttack", false];
    };
    [_state, _stage] call BATTLESPACE_AIR_SET_STAGE;
};

BATTLESPACE_AIR_INFANTRY_PLAN_RUN = {
    if (!isServer || {isRemoteExecuted}) exitWith {};
    params ["_state", "_targetPosition", "_targetVelocity"];
    private _aircraft = _state get "aircraft";
    private _weapon = _state get "weapon";
    private _kind = _weapon get "kind";
    private _plane = _aircraft isKindOf "Plane";
    private _direction = (getPosASL _aircraft) getDir _targetPosition;
    private _height = if (_kind == "BOMB") then {BATTLESPACE_AIR_BOMB_HEIGHT} else {if (_plane) then {BATTLESPACE_AIR_JET_ATTACK_HEIGHT} else {BATTLESPACE_AIR_HELI_ATTACK_HEIGHT}};
    private _speed = if (_plane) then {160} else {50};
    _speed = _speed min (getNumber (configFile >> "CfgVehicles" >> typeOf _aircraft >> "maxSpeed") / 3.6 * 0.8);
    private _lead = _targetVelocity vectorMultiply (if (_kind == "BOMB") then {sqrt (2 * _height / 9.80665)} else {3});
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
    private _alreadyInbound = _aligned && {_aircraft distance2D _aim > 1500} && {_aircraft distance2D _aim < _runLength};
    [_state, ["INGRESS", "RUN"] select _alreadyInbound] call BATTLESPACE_AIR_INFANTRY_SET_STAGE;
};

BATTLESPACE_AIR_INFANTRY_FLY_ATTACK = {
    params ["_state"];
    if (!isServer || {isRemoteExecuted}) exitWith {false};
    private _observed = [_state, _state get "target"] call BATTLESPACE_AIR_INFANTRY_OBSERVATION;
    private _authorized = _observed isNotEqualTo [] && {!(_state getOrDefault ["infantryMemoryUsed", false])};
    private _wasRun = _state get "stage" == "RUN";
    private _result = [_state, _authorized] call BATTLESPACE_AIR_FLY_ATTACK;
    // The shared terrain-avoidance exit uses the original vehicle stage helper.
    // A hidden infantry pass also ends when that safety exit aborts its run.
    if (_wasRun && {_state get "stage" != "RUN"}) then {
        _state set ["infantryMemoryUsed", true];
        _state set ["infantryMemoryAttack", false];
    };
    if (isNil "_result") then {false} else {_result}
};

BATTLESPACE_AIR_INFANTRY_FIRE = {
    params ["_state", "_target", "_aim"];
    if (!isServer || {isRemoteExecuted}) exitWith {false};
    private _aircraft = _state get "aircraft";
    private _weapon = _state get "weapon";
    private _turret = _weapon get "turret";
    if (_state get "stage" != "RUN" || {_target isNotEqualTo (_state get "target")}
        || {_aircraft getVariable ["KPLIB_captured", false]}
        || {crew _aircraft findIf {isPlayer _x} >= 0}) exitWith {false};
    private _remembered = _target isKindOf "Man" && {!(_state getOrDefault ["visible", false])};
    if (_remembered) then {
        private _observed = [_state, _target] call BATTLESPACE_AIR_INFANTRY_OBSERVATION;
        _remembered = _observed isNotEqualTo [] && {!(_state getOrDefault ["infantryMemoryUsed", false])}
            && {[_weapon] call BATTLESPACE_AIR_WEAPON_VS_POSITION} && {_aim vectorDistance _observed < 1};
    };
    if (_target isKindOf "Man" && {!(_state getOrDefault ["visible", false])} && {!_remembered}) exitWith {false};
    if !([_aircraft, _target, _weapon, _aim] call BATTLESPACE_AIR_INFANTRY_FIRE_SAFE) exitWith {false};
    private _operator = if (_turret isEqualTo [-1]) then {driver _aircraft} else {_aircraft turretUnit _turret};
    if (!local _aircraft || {isNull _operator} || {!local _operator} || {!alive _operator} || {isPlayer _operator}) exitWith {false};
    private _loaded = weaponState [_aircraft, _turret, _weapon get "weapon", _weapon get "muzzle"];
    if ((_loaded param [4, 0]) <= 0 || {(_loaded param [5, 1]) > 0} || {(_loaded param [6, 1]) > 0}) exitWith {false};
    private _firingTarget = if (_remembered) then {objNull} else {_target};
    if (_weapon get "guidance" == "LASER") then {_firingTarget = _state getOrDefault ["laser", objNull]};
    if (isNull _firingTarget && {!_remembered}) exitWith {false};
    _operator selectWeapon [_weapon get "weapon", _weapon get "muzzle", _weapon get "mode"];
    // Fixed unguided weapons use the computed firing solution. A simultaneous
    // engine target/zeroing correction would apply ballistic compensation twice.
    _operator doTarget (if (_turret isEqualTo [-1] && {_weapon get "guidance" == "NONE"}) then {objNull} else {_firingTarget});
    if (_remembered) then {_operator doWatch (ASLToATL _aim)};
    _state set ["pendingShot", [_weapon, _target, +_aim, CBA_missionTime]];
    _operator forceWeaponFire [_weapon get "muzzle", _weapon get "mode"];
    true
};
