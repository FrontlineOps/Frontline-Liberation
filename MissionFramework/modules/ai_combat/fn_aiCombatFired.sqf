/* Native owner event. One launch-direction correction for a validated active
   explosive/illumination job; native speed, inventory, flight and damage remain.
   No pursuit, additional projectiles or per-projectile controller. */
params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile"];
if (isRemoteExecuted || {!local _unit} || {!isNull objectParent _unit}) exitWith {};
if (isServer) then {
    private _registry = localNamespace getVariable ["KPLIB_aiCombat_registry", createHashMap];
    private _state = _registry getOrDefault [netId _unit, createHashMap];
    if (count _state > 0) then {
        private _cancelled = _state getOrDefault ["cancelled", []];
        if (!isPlayer _unit && {count _cancelled == 2} && {_ammo == (_cancelled select 0)}
            && {CBA_missionTime < (_cancelled select 1)} && {count (_state get "job") == 0}) then {
            deleteVehicle _projectile;
        };
        _state set ["shots", (_state get "shots") + 1];
        _state set ["lastShot", [CBA_missionTime, _weapon, _muzzle, _ammo]];
        private _job = _state get "job";
        if (count _job > 0) then {
            private _profile = _job get "profile";
            if (_weapon == (_profile get "weapon") && {_muzzle == (_profile get "muzzle")}
                && {_magazine == (_profile get "magazine")}) then {
                _job set ["fired", true];
                [_job get "fire", _mode] call KPLIB_fnc_combatFireFired;
                private _kind = _profile get "kind";
                if (_kind in ["RPG", "GL", "FLARE"] && {!isNull _projectile} && {local _projectile}) then {
                    private _target = _job get "target";
                    private _position = if (_kind == "FLARE") then {_job get "position"} else {(getPosASL _target) vectorAdd [0, 0, 0.15]};
                    // Aim rockets at the lower body; grenades at the ground beside the target.
                    if (_kind == "RPG") then {_position = (getPosASL _target) vectorAdd ((aimPos _target vectorDiff getPosASL _target) vectorMultiply 0.5)};
                    private _safe = [_unit, _position, _profile, _target] call KPLIB_fnc_aiCombatSafe;
                    private _visible = _kind == "FLARE" || {[_unit, _target] call KPLIB_fnc_aiCombatVisible};
                    private _solution = _job get "solution";
                    if (_safe != "" || {!_visible} || {[_unit] call KPLIB_fnc_aiCombatEligible != ""}
                        || {_kind != "FLARE" && {_solution isEqualTo []}}) then {
                        deleteVehicle _projectile;
                        _job set ["release", "Unsafe release stopped; round spent"];
                    } else {
                        private _aimPosition = if (_kind == "FLARE") then {_position} else {_solution select 0};
                        private _direction = vectorNormalized (_aimPosition vectorDiff getPosASL _projectile);
                        private _spread = 0.0002 + (1 - (_unit skillFinal "aimingAccuracy")) * 0.006;
                        private _right = vectorNormalized (_direction vectorCrossProduct [0, 0, 1]);
                        private _up = vectorNormalized (_right vectorCrossProduct _direction);
                        _direction = vectorNormalized (_direction vectorAdd (_right vectorMultiply (random (2 * _spread) - _spread))
                            vectorAdd (_up vectorMultiply (random (2 * _spread) - _spread)));
                        private _speed = vectorMagnitude velocity _projectile;
                        private _origin = getPosASL _projectile;
                        if (lineIntersects [_origin, _origin vectorAdd (_direction vectorMultiply 8), _unit, _target]) then {
                            deleteVehicle _projectile;
                            _job set ["release", "Launch arc obstructed; round spent"];
                        } else {
                            _projectile setVectorDirAndUp [_direction, vectorNormalized (_right vectorCrossProduct _direction)];
                            _projectile setVelocity (_direction vectorMultiply _speed);
                            _job set ["release", "Launch elevation assisted; native flight"];
                            _state set ["lastAssist", [_kind, _speed, _direction, CBA_missionTime]];
                        };
                    };
                };
                if (_profile get "kind" in ["RPG", "GL"]) then {_state set ["explosiveAt", CBA_missionTime]};
                if (_profile get "kind" == "FLARE") then {
                    private _flares = localNamespace getVariable "KPLIB_aiCombat_flaresActive";
                    if (count _flares < 32) then {
                        _flares pushBack [+(_job get "position"), CBA_missionTime + (60 min (_profile get "ttl")), _projectile];
                    };
                };
            };
        };
    };
};
if (!KPLIB_aiCombat_enabled || {!KPLIB_aiCombat_hearing}) exitWith {};
// One evidence message per shooter per 1.5s. This local variable is only a
// traffic optimization; the receiving server independently rate-limits.
if (CBA_missionTime < (_unit getVariable ["KPLIB_aiCombat_nextSound", -1])) exitWith {};
_unit setVariable ["KPLIB_aiCombat_nextSound", CBA_missionTime + 1.5];
private _evidence = [_unit, _weapon, _muzzle, _ammo, _projectile, _magazine];
if (isServer) then {
    _evidence call KPLIB_fnc_aiCombatSound;
} else {
    _evidence remoteExecCall ["KPLIB_fnc_aiCombatSound", 2];
};
