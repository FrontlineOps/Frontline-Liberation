if (!isServer || {isRemoteExecuted} || {localNamespace getVariable ["KPLIB_aiCombat_blocked", "Not initialized"] != ""}) exitWith {};
private _start = diag_tickTime;
private _now = CBA_missionTime;
private _registry = localNamespace getVariable "KPLIB_aiCombat_registry";
private _queue = localNamespace getVariable "KPLIB_aiCombat_queue";
private _active = localNamespace getVariable "KPLIB_aiCombat_active";
{[_x] call KPLIB_fnc_aiCombatUpdate} forEach _active;
localNamespace setVariable ["KPLIB_aiCombat_active", _active select {count (_x get "job") > 0}];
private _sounds = localNamespace getVariable "KPLIB_aiCombat_sounds";
localNamespace setVariable ["KPLIB_aiCombat_sounds", _sounds select {_now - (_x select 3) < KPLIB_aiCombat_soundMemory}];
private _flares = (localNamespace getVariable "KPLIB_aiCombat_flaresActive") select {_now < (_x select 1) && {!isNull (_x select 2)}};
{_x set [0, getPosASL (_x select 2)]} forEach _flares;
localNamespace setVariable ["KPLIB_aiCombat_flaresActive", _flares];
private _cursor = localNamespace getVariable ["KPLIB_aiCombat_cursor", 0];
for "_step" from 1 to ((count _queue) min floor KPLIB_aiCombat_batchSize) do {
    if (_queue isEqualTo []) exitWith {};
    if (_cursor >= count _queue) then {_cursor = 0};
    private _key = _queue select _cursor;
    private _state = _registry get _key;
    private _unit = _state get "unit";
    if (isNull _unit || {!alive _unit} || {!local _unit}) then {
        [_state, "Removed or locality lost"] call KPLIB_fnc_aiCombatFinish;
        _registry deleteAt _key;
        _queue deleteAt _cursor;
        continue;
    };
    _cursor = _cursor + 1;
    if (_state get "soundWatchUntil" > 0 && {_now > (_state get "soundWatchUntil")}) then {
        if (count (_state get "job") == 0 && {isNull getAttackTarget _unit}) then {_unit doWatch objNull};
        _state set ["soundWatchUntil", -1];
    };
    if (count (_state get "job") > 0 || {_now < (_state get "next")}) then {continue};
    _state set ["next", _now + 3];
    private _reason = [_unit] call KPLIB_fnc_aiCombatEligible;
    _state set ["reason", _reason];
    if (_reason != "") then {continue};
    [_state] call KPLIB_fnc_aiCombatHear;
    if (count (localNamespace getVariable "KPLIB_aiCombat_active") >= KPLIB_aiCombat_maxActive) then {
        _state set ["reason", "Active aim budget full"];
        continue;
    };
    private _target = getAttackTarget _unit;
    if (!([_unit, _target, true] call KPLIB_fnc_aiCombatVisible)) then {
        _target = objNull;
        // Engine spatial shortlist; examine at most four targets per decision.
        private _candidates = (_unit nearEntities ["CAManBase", KPLIB_aiCombat_rifleRange]) select {
            alive _x && {!captive _x} && {(side group _unit) getFriend (side group _x) < 0.6}
        };
        if (_candidates isNotEqualTo []) then {
            private _index = (_state get "candidateCursor") mod count _candidates;
            for "_scan" from 1 to (4 min count _candidates) do {
                private _candidate = _candidates select _index;
                _index = (_index + 1) mod count _candidates;
                if ([_unit, _candidate, true] call KPLIB_fnc_aiCombatVisible) exitWith {_target = _candidate};
            };
            _state set ["candidateCursor", _index];
        };
    };
    _state set ["target", _target];
    private _heard = _state get "heard";
    private _soundRecent = count _heard > 0 && {_now - (_heard select 1) < KPLIB_aiCombat_soundMemory};
    if (isNull _target && {!_soundRecent}) then {
        _state set ["reason", "No visible infantry or recent sound"];
        continue
    };
    private _profiles = [_unit] call KPLIB_fnc_aiCombatWeapons;
    _state set ["profiles", _profiles apply {format ["%1 %2: %3-%4m | %5", _x get "kind", _x get "muzzle", round (_x get "minimum"), round (_x get "range"), _x get "magazine"]}];
    private _groups = localNamespace getVariable "KPLIB_aiCombat_groups";
    private _groupState = _groups getOrDefault [str group _unit, [group _unit, -1000, -1000]];
    private _flare = createHashMap;
    if (KPLIB_aiCombat_flares && {sunOrMoon < 0.2} && {(getArray (configFile >> "CfgWeapons" >> hmd _unit >> "visionMode")) findIf {toLower _x in ["nvg", "ti"]} < 0}
        && {_now - (_groupState select 2) > KPLIB_aiCombat_flareCooldown}
        && {(localNamespace getVariable "KPLIB_aiCombat_flaresActive") findIf {_unit distance2D (_x select 0) < KPLIB_aiCombat_flareRadius} < 0}) then {
        private _index = _profiles findIf {(_x get "kind") == "FLARE"};
        if (_index >= 0) then {_flare = _profiles select _index};
    };
    if (count _flare > 0) then {
        private _towards = if (!isNull _target) then {getPosASL _target} else {_heard select 0};
        private _direction = vectorNormalized ([_towards select 0, _towards select 1, 0] vectorDiff [getPosASL _unit select 0, getPosASL _unit select 1, 0]);
        private _position = (getPosASL _unit) vectorAdd ((_direction vectorMultiply 100) vectorAdd [0, 0, 200]);
        [_state, _flare, objNull, _position] call KPLIB_fnc_aiCombatStart;
        continue;
    };
    if (isNull _target) then {
        _state set ["reason", "Sound only: no visual firing solution"];
        continue
    };
    if (vectorMagnitude velocity _unit > 2) then {
        _state set ["reason", "Moving: native combat"];
        continue
    };
    if (getSuppression _unit > 0.7) then {
        _state set ["reason", "Suppressed: native combat"];
        continue
    };
    private _range = _unit distance _target;
    private _selected = createHashMap;
    private _rank = -1;
    {
        private _kind = _x get "kind";
        if (!(_kind in ["RPG", "GL", "RIFLE"]) || {_range < (_x get "minimum")} || {_range > (_x get "range")}) then {continue};
        if (_kind in ["RPG", "GL"] && {_now - (_state get "explosiveAt") < KPLIB_aiCombat_explosiveCooldown
            || {_now - (_groupState select 1) < KPLIB_aiCombat_groupExplosiveCooldown}}) then {continue};
        private _score = switch (_kind) do {
            case "GL": {3};
            case "RPG": {2};
            default {1}
        };
        if (_score > _rank) then {
            private _safe = [_unit, aimPos _target, _x, _target] call KPLIB_fnc_aiCombatSafe;
            if (_safe == "") then {
                _selected = _x;
                _rank = _score
            } else {
                _state set ["reason", _safe]
            };
        };
    } forEach _profiles;
    if (count _selected > 0) then {
        [_state, _selected, _target] call KPLIB_fnc_aiCombatStart;
    } else {
        if (_state get "reason" == "") then {_state set ["reason", "No supported carried round in range / cooldown"]};
    };
};
localNamespace setVariable ["KPLIB_aiCombat_cursor", _cursor];
if (_now > (localNamespace getVariable ["KPLIB_aiCombat_pruneAt", 0])) then {
    localNamespace setVariable ["KPLIB_aiCombat_pruneAt", _now + 30];
    private _groups = localNamespace getVariable "KPLIB_aiCombat_groups";
    {if (isNull (_y select 0)) then {_groups deleteAt _x}} forEach _groups;
};
localNamespace setVariable ["KPLIB_aiCombat_lastTickMs", (diag_tickTime - _start) * 1000];
