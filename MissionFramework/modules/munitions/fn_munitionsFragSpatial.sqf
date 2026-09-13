/* The mission owns generation. ACE supplies only the native ammo assets. */
if (isRemoteExecuted) exitWith {0};
params ["_origin", "_ammo", "_budget", "_speed", "_types", ["_parents", [objNull,objNull]]];
if (!(_budget isEqualType 0) || {!finite _budget} || {_budget < 1} || {_budget > 512}
    || {!(_speed isEqualType 0)} || {!finite _speed} || {_speed <= 0} || {!(_types isEqualType [])}) exitWith {0};
private _valid = _types select {
    _x isEqualType "" && {isClass (configFile >> "CfgAmmo" >> _x)}
        && {_x isKindOf ["ACE_frag_base", configFile >> "CfgAmmo"]}
};
if (_valid isEqualTo []) exitWith {0};
[_origin, _ammo, [_budget] call KPLIB_fnc_munitionsFragDirections, _valid, _speed, _parents, "FRAGMENT"] call KPLIB_fnc_munitionsEmit
