/* Owner-local native penetration events, including shaped-charge children.
   Fragments never register these hooks, preventing recursive fragment spall. */
if (isRemoteExecuted) exitWith {};
params [["_projectile", objNull, [objNull]]];
if (isNull _projectile || {!local _projectile}
    || {_projectile getVariable ["KPLIB_munitionsParticle", false]}
    || {_projectile getVariable ["KPLIB_munitionsSpall", false]}) exitWith {};
private _ammo = typeOf _projectile;
if (_ammo isKindOf ["ACE_frag_base", configFile >> "CfgAmmo"]
    || {_ammo isKindOf ["ACE_frag_spallBase", configFile >> "CfgAmmo"]}) exitWith {};
private _cfg = configOf _projectile;
private _simulation = toLower getText (_cfg >> "simulation");
if (getNumber (_cfg >> "hit") > 0 && {!(_projectile getVariable ["KPLIB_munitionsImpactHook", false])}) then {
    _projectile setVariable ["KPLIB_munitionsImpactHook", true];
    _projectile addEventHandler ["HitPart", {_this call KPLIB_fnc_munitionsImpact}];
    // Ordinary small arms keep their existing hooks without stop tracking.
    if (getNumber (_cfg >> "hit") >= 40
        && {_simulation in ["shotbullet", "shotshell", "shotrocket", "shotmissile"]}) then {
        _projectile addEventHandler ["HitPart", {["HIT", _this] call KPLIB_fnc_munitionsBackfaceEvent}];
        _projectile addEventHandler ["Penetrated", {["EXIT", _this] call KPLIB_fnc_munitionsBackfaceEvent}];
        _projectile addEventHandler ["Deflected", {["DEFLECT", _this] call KPLIB_fnc_munitionsBackfaceEvent}];
        _projectile addEventHandler ["Deleted", {["DELETE", _this] call KPLIB_fnc_munitionsBackfaceEvent}];
    };
};
if (getNumber (_cfg >> "hit") > 0 && {getNumber (_cfg >> "explosive") < 0.5}
    && {_simulation in ["shotbullet", "shotshell"]}) then {
    _projectile setVariable ["KPLIB_munitionsSpall", true];
    _projectile addEventHandler ["Penetrated", {_this call KPLIB_fnc_munitionsSpallHit}];
};
if (_projectile getVariable ["KPLIB_munitionsChildHook", false]) exitWith {};
private _submunition = _cfg >> "submunitionAmmo";
if ((isText _submunition && {getText _submunition != ""}) || {isArray _submunition && {getArray _submunition isNotEqualTo []}}) then {
    _projectile setVariable ["KPLIB_munitionsChildHook", true];
    _projectile addEventHandler ["SubmunitionCreated", {
        params ["", "_child"];
        [_child] call KPLIB_fnc_munitionsSpall;
    }];
};
