/* Cached config evidence. Backend ownership is resolved separately for each shot. */
params [["_ammo", "", [""]]];
private _cache = localNamespace getVariable ["KPLIB_guidanceConfig", createHashMap];
private _key = toLower _ammo;
private _cached = _cache get _key;
if (!isNil "_cached") exitWith {_cached};
private _cfg = configFile >> "CfgAmmo" >> _ammo;
private _simulation = toLower getText (_cfg >> "simulation");
private _family = "BALLISTIC";
private _reason = "Unguided ammunition";
private _backend = "NATIVE";
private _lock = getNumber (_cfg >> "weaponLockSystem");
if (isText (_cfg >> "weaponLockSystem")) then {
    _lock = 0;
    {_lock = _lock + parseNumber _x} forEach ((getText (_cfg >> "weaponLockSystem")) splitString "+ ");
};
private _missile = _simulation == "shotmissile";
private _steerable = _missile && {getNumber (_cfg >> "sideAirFriction") > 0} && {getNumber (_cfg >> "maneuvrability") > 0};
private _manual = getNumber (_cfg >> "manualControl") > 0;
private _laser = getNumber (_cfg >> "laserLock") > 0;
private _ir = getNumber (_cfg >> "irLock") > 0;
private _radar = (floor (_lock / 8) mod 2) == 1;
private _coordinate = getNumber (_cfg >> "artilleryLock") > 0;
private _sensors = "true" configClasses (_cfg >> "Components" >> "SensorsManagerComponent" >> "Components");
private _activeRadar = _sensors findIf {toLower getText (_x >> "componentType") == "activeradarsensorcomponent"} >= 0;
private _infrared = _sensors findIf {toLower getText (_x >> "componentType") == "irsensorcomponent"} >= 0;
private _visual = _sensors findIf {toLower getText (_x >> "componentType") == "visualsensorcomponent"} >= 0;
private _dataLink = _sensors findIf {toLower getText (_x >> "componentType") == "datalinksensorcomponent"} >= 0;
// Match ACE's onFired eligibility: an inherited guidance class alone is insufficient.
private _aceCfg = _cfg >> "ace_missileguidance";
private _ace = getNumber (_aceCfg >> "enabled") == 1
    && {("configName _x == 'ace_missileguidance'" configClasses _cfg) isNotEqualTo []};
private _aceFamily = toUpper getText (_aceCfg >> "defaultSeekerType");
private _radarSensor = _sensors select {toLower getText (_x >> "componentType") == "activeradarsensorcomponent"};
private _radarMinimum = 0;
private _radarNoise = 0;
if (_radarSensor isNotEqualTo []) then {
    _radarMinimum = getNumber ((_radarSensor select 0) >> "minSpeedThreshold");
    _radarNoise = getNumber ((_radarSensor select 0) >> "maxGroundNoiseDistance");
};

if (_simulation in ["shotcm", "shotcmflare"]) then {
    _family = "COUNTERMEASURE";
    _reason = "Countermeasure observation only";
};
if (_missile || {_simulation in ["shotrocket", "shotbomb", "shotshell"]}) then {
    if (_coordinate) then {
        _family = "GPS";
        _reason = "Native coordinate/ballistic-computer controller";
    };
    if (_manual) then {
        _family = "COMMAND";
        _reason = "Native operator input or addon controller";
    };
    if (_radar && {!_manual}) then {_family = "RADAR"; _reason = "Radar support type is not explicit"};
    if ((_ir || {_infrared}) && {!_visual} && {!_radar} && {!_laser} && {!_manual} && {!_coordinate}) then {
        _family = "IR";
        if (_steerable) then {
            _backend = "CUSTOM";
            _reason = "Native infrared seeker and aerodynamic control";
        };
    };
    if (_activeRadar && {!_manual} && {!_coordinate}) then {
        _family = "ARH";
        if (_steerable) then {
            _backend = "CUSTOM";
            _reason = "Explicit active radar sensor";
        };
    };
    if (_laser && {!_manual} && {!_coordinate}) then {
        _family = "LASER";
        if (_steerable) then {
            _backend = "CUSTOM";
            _reason = "Native laser seeker";
        };
    };
    if (_visual && {!_infrared} && {!_laser} && {!_manual}) then {_family = "OPTICAL"; _reason = "Native optical/flight-mode controller"};
};

private _range = getNumber (_cfg >> "missileLockMaxDistance");
if (_range <= 0) then {_range = 5000};
private _gimbal = getNumber (_cfg >> "missileKeepLockedCone");
if (_gimbal <= 0) then {_gimbal = getNumber (_cfg >> "missileLockCone")};
if (_gimbal <= 0) then {_gimbal = 45};
private _life = getNumber (_cfg >> "timeToLive");
if (_life <= 0) then {_life = 120};
private _blast = getNumber (_cfg >> "indirectHitRange");
private _maneuver = getNumber (_cfg >> "maneuvrability");
private _rate = (_maneuver * 2) max 5 min 60;
private _authority = _maneuver max 4 min 35;
private _profile = createHashMapFromArray [
    ["ammo", configName _cfg], ["name", configName _cfg], ["family", _family],
    ["backend", _backend], ["reason", _reason], ["simulation", _simulation],
    ["ace", _ace], ["aceFamily", _aceFamily], ["lock", _lock],
    ["range", _range], ["gimbal", (_gimbal * 0.5) max 1 min 180],
    ["acquireCone", (getNumber (_cfg >> "missileLockCone") * 0.5) max 1 min 180],
    ["minRange", getNumber (_cfg >> "missileLockMinDistance") max 0],
    ["maxTargetSpeed", getNumber (_cfg >> "missileLockMaxSpeed")],
    ["autoSeek", getNumber (_cfg >> "autoSeekTarget") > 0],
    ["pitchRate", _rate], ["yawRate", _rate], ["maxG", _authority], ["seekerRate", _rate * 3],
    ["cmResistance", getNumber (_cfg >> "cmImmunity") max 0 min 1],
    ["airOnly", getNumber (_cfg >> "airLock") >= 2],
    ["airCapable", getNumber (_cfg >> "airLock") > 0],
    ["life", _life], ["gravity", if (isNumber (_cfg >> "coefGravity")) then {getNumber (_cfg >> "coefGravity")} else {1}],
    ["sideDrag", getNumber (_cfg >> "sideAirFriction")],
    ["burn", getNumber (_cfg >> "thrustTime")], ["delay", getNumber (_cfg >> "initTime")],
    ["armingDistance", getNumber (_cfg >> "fuseDistance") max 15], ["armingTime", 0.25],
    ["fuzeRadius", if (getNumber (_cfg >> "airLock") >= 2) then {(_blast * 0.5) min 12} else {0}],
    ["loft", 0], ["datalink", _dataLink],
    ["pitbull", if (_dataLink) then {(_range * 0.35) min 4000} else {_range}],
    ["radarMinimum", _radarMinimum], ["radarNoise", _radarNoise],
    ["memory", missionNamespace getVariable ["KPLIB_guidance_track_memory", 1.5]],
    ["reacquire", missionNamespace getVariable ["KPLIB_guidance_reacquire_time", 6]]
];
// Submunition and specialized flight profiles retain their existing implementation.
if (getText (_cfg >> "submunitionAmmo") != "" || {getArray (_cfg >> "submunitionAmmo") isNotEqualTo []}
    || {getArray (_cfg >> "flightProfiles") isNotEqualTo []}) then {
    _profile set ["backend", "NATIVE"];
    _profile set ["reason", "Native flight profile/submunition controller"];
};
{
    _x params ["_class", "_values"];
    if (toLower _class == _key) exitWith {
        {
            _x params ["_property", "_value"];
            private _original = _profile get _property;
            if (_property in ["family", "backend", "range", "gimbal", "acquireCone", "minRange", "maxTargetSpeed",
                "pitchRate", "yawRate", "maxG", "seekerRate", "cmResistance", "armingDistance", "armingTime",
                "fuzeRadius", "loft", "pitbull", "memory", "reacquire"]
                && {!isNil "_original"} && {_value isEqualType _original}) then {_profile set [_property, _value]};
        } forEach _values;
    };
} forEach (missionNamespace getVariable ["KPLIB_guidance_overrides", []]);
if ((_profile get "backend") == "AUTO") then {
    _profile set ["backend", if (_steerable && {(_profile get "family") in ["IR", "ARH", "SARH", "RADIO", "LASER"]}) then {"CUSTOM"} else {"NATIVE"}];
};
// Never take an unknown simulation or a manual/coordinate steering channel.
if (!_steerable || {_manual} || {_coordinate} || {!((_profile get "family") in ["IR", "ARH", "SARH", "RADIO", "LASER"])}) then {
    _profile set ["backend", "NATIVE"];
};
if (!_steerable && {(_profile get "family") in ["IR", "ARH", "LASER"]}) then {
    _profile set ["reason", "Native simulation/control parameters required"];
};
if (!isClass _cfg) then {_profile set ["reason", "Unknown ammo class"]};
if (isClass _cfg) then {_cache set [_key, _profile]};
localNamespace setVariable ["KPLIB_guidanceConfig", _cache];
_profile
