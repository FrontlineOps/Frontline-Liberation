/* Read-only ASL cursor inspection; no actor, owner or state supplied by client. */
params [["_positionASL", [], [[]]]];
if (!isServer || {!isRemoteExecuted}) exitWith {};
private _owner = remoteExecutedOwner;
if (allCurators findIf {
    private _operator = getAssignedCuratorUnit _x;
    !isNull _operator && {isPlayer _operator} && {alive _operator} && {owner _operator == _owner}
} < 0) exitWith {};
if (count _positionASL != 3 || {_positionASL findIf {!(_x isEqualType 0) || {!finite _x}} >= 0}) exitWith {};
if (CBA_missionTime < (localNamespace getVariable ["KPLIB_aiCombat_nextInspect", -1])) exitWith {};
localNamespace setVariable ["KPLIB_aiCombat_nextInspect", CBA_missionTime + 0.5];
private _lines = ["FRONTLINE AI / COMBAT & HEARING"];
private _registry = localNamespace getVariable ["KPLIB_aiCombat_registry", createHashMap];
private _unit = objNull;
private _nearest = 50;
{
    private _distance = (getPosASL _x) vectorDistance _positionASL;
    if (alive _x && {!isPlayer _x} && {_distance <= _nearest} && {netId _x in _registry}) then {
        _unit = _x;
        _nearest = _distance;
    };
} forEach ((ASLToAGL _positionASL) nearEntities ["CAManBase", 50]);
_lines pushBack format ["Enabled %1 | Registered %2 | Aiming %3/%4", KPLIB_aiCombat_enabled, count _registry, count (localNamespace getVariable ["KPLIB_aiCombat_active", []]), KPLIB_aiCombat_maxActive];
_lines pushBack format ["Last callback %1 ms | Pending sound sources %2", (localNamespace getVariable ["KPLIB_aiCombat_lastTickMs", 0]) toFixed 2, count (localNamespace getVariable ["KPLIB_aiCombat_sounds", []])];
if (isNull _unit) then {
    _lines pushBack "No registered living server AI within 50 m of cursor.";
    _lines pushBack (localNamespace getVariable ["KPLIB_aiCombat_blocked", "Not initialized"]);
} else {
    private _state = _registry get (netId _unit);
    private _target = _state get "target";
    _lines append [typeOf _unit, _state get "reason"];
    _lines pushBack (if (isNull _target) then {"No visual target"} else {
        format ["Target %1 | Range %2 m | Knowledge %3", typeOf _target, round (_unit distance _target), (_unit knowsAbout _target) toFixed 1]
    });
    private _heard = _state get "heard";
    if (_heard isEqualTo []) then {_lines pushBack "No custom gunfire heard"} else {
        _lines pushBack format ["Heard %1, %2s ago | %3m range / ~%4m uncertainty", ["unsuppressed", "suppressed"] select (_heard select 2), round (CBA_missionTime - (_heard select 1)), _heard select 4, _heard select 3];
    };
    _lines pushBack format ["Near miss %1 | Real fired events %2", if (_state get "nearMiss" < 0) then {"none"} else {format ["%1s ago", round (CBA_missionTime - (_state get "nearMiss"))]}, _state get "shots"];
    private _last = _state get "lastShot";
    if (_last isNotEqualTo []) then {_lines pushBack format ["Last shot %1 / %2 (%3s ago)", _last select 2, _last select 3, round (CBA_missionTime - (_last select 0))]};
    private _assist = _state getOrDefault ["lastAssist", []];
    if (_assist isNotEqualTo []) then {
        _lines pushBack format ["Last assisted %1: %2 m/s retained, %3s ago", _assist select 0, round (_assist select 1), round (CBA_missionTime - (_assist select 3))];
    };
    private _job = _state get "job";
    if (count _job > 0) then {
        private _profile = _job get "profile";
        _lines pushBack format ["Aim %1 / %2 | Attempts %3", _profile get "kind", _profile get "magazine", _job get "attempts"];
        private _fire = _job getOrDefault ["fire", createHashMap];
        private _plan = _fire getOrDefault ["plan", []];
        if (_plan isNotEqualTo []) then {
            _lines pushBack format ["Burst %1 / %2 | %3 rounds left | Confirmed %4", _plan select 4, _plan select 0, _fire getOrDefault ["remaining", 0], _fire getOrDefault ["shots", 0]];
        };
        _lines pushBack format ["Alignment %1", _job getOrDefault ["alignment", []]];
        _lines pushBack format ["Muzzle state %1", weaponState _unit];
        private _solution = _job get "solution";
        if (_solution isNotEqualTo []) then {_lines pushBack format ["Estimated arc %1 deg / %2s flight", (_solution select 1) toFixed 1, (_solution select 2) toFixed 1]};
    };
    // Existing registry is used for read-only inspection; no controller call.
    _lines pushBack "Recent decisions:";
    {_lines pushBack format ["%1s %2: %3", round (CBA_missionTime - (_x select 0)), _x select 1, _x select 2]} forEach (_state get "recent");
    _lines pushBack "Carried profiles (last combat decision):";
    _lines append ((_state get "profiles") select [0, 5]);
};
_lines pushBack "Sound grants no target identity. Assisted launch; native flight/damage.";
[((_lines select [0, 24]) apply {_x select [0, 390]})] remoteExecCall ["KPLIB_fnc_aiSkillsReceive", _owner];
