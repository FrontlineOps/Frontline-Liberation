/* Perception runs before scripted firing eligibility. Sound grants attention,
   never a target; existing orders remain available after the contact expires.
   Every AI group reacts to hostile fire it perceives; only close contact
   changes rules of engagement, and an unassigned hold-fire group keeps its hold. */
params ["_state", ["_target", objNull]];
private _unit = _state get "unit";
if ([_unit, true] call KPLIB_fnc_aiCombatEligible != "") exitWith {};
private _group = group _unit;
if ((units _group) findIf {isPlayer _x || {!isNull remoteControlled _x}} >= 0) exitWith {};
private _assigned = _group getVariable ["TASKFORCEID", ""] != ""
    || {_group getVariable ["KPLIB_lambs_currentTactic", ""] != ""};
if (count (_state get "job") > 0 || {_unit getVariable ["KPLIB_lambs_forceMove", false]}) exitWith {};
private _visible = !isNull _target && {[_unit, _target, true] call KPLIB_fnc_aiCombatVisible};
private _heard = _state get "heard";
private _recent = _heard isNotEqualTo [] && {CBA_missionTime - (_heard select 1) < KPLIB_aiCombat_soundMemory};
private _nearMiss = CBA_missionTime - (_state get "nearMiss") < 5;
// A posture raised only by nearby gunfire relaxes once that contact expires with no known enemy.
if (_group getVariable ["KPLIB_aiCombat_soundCombat", false] && {!_visible} && {!_nearMiss}
    && {CBA_missionTime >= (_group getVariable ["KPLIB_aiCombat_contactUntil", -1])}
    && {isNull getAttackTarget _unit} && {isNull (_unit findNearestEnemy _unit)}) then {
    _group setVariable ["KPLIB_aiCombat_soundCombat", nil];
    if (behaviour _unit == "COMBAT") then {_group setBehaviour "AWARE"};
};
if (!_visible && {!_recent} && {!_nearMiss}) exitWith {};
private _close = _visible || {_nearMiss} || {_recent && {(_heard select 4) <= 150}};
if (_close) then {
    private _until = if (_visible || {_nearMiss}) then {CBA_missionTime + KPLIB_aiCombat_soundMemory} else {(_heard select 1) + KPLIB_aiCombat_soundMemory};
    private _wasActive = CBA_missionTime < (_unit getVariable ["KPLIB_aiCombat_contactUntil", -1]);
    _unit setVariable ["KPLIB_aiCombat_contactUntil", _until max (_unit getVariable ["KPLIB_aiCombat_contactUntil", -1])];
    _group setVariable ["KPLIB_aiCombat_contactUntil", _until max (_group getVariable ["KPLIB_aiCombat_contactUntil", -1])];
    if (!_wasActive && {KPLIB_aiCombat_debug}) then {
        [format ["%1 interrupting assignment for %2", typeOf _unit, ["nearby fire", "visual contact"] select _visible], "AI COMBAT"] call KPLIB_fnc_log;
    };
};
private _engage = _close && {_assigned || {combatMode _group in ["YELLOW", "RED"]}};
if (_engage) then {
    _group enableAttack true;
    if (combatMode _group != "RED") then {_group setCombatMode "YELLOW"};
    if (!(unitCombatMode _unit in ["YELLOW", "RED"])) then {_unit setUnitCombatMode "YELLOW"};
    _unit enableAI "AUTOCOMBAT";
};
if (_close) then {
    if (_visible || {_nearMiss}) then {_group setVariable ["KPLIB_aiCombat_soundCombat", nil]};
    if (behaviour _unit != "COMBAT") then {
        _group setBehaviour "COMBAT";
        if (!_visible && {!_nearMiss}) then {_group setVariable ["KPLIB_aiCombat_soundCombat", true]};
    };
} else {
    if (behaviour _unit in ["SAFE", "CARELESS"]) then {_group setBehaviour "AWARE"};
};
if (_visible && {_engage}) then {
    _unit doTarget _target;
    _unit doFire _target;
} else {
    if (_recent && {isNull getAttackTarget _unit} && {_unit checkAIFeature "WEAPONAIM"}) then {
        _unit doWatch (ASLToAGL (_heard select 0));
        _state set ["soundWatchUntil", CBA_missionTime + 5];
    };
};
