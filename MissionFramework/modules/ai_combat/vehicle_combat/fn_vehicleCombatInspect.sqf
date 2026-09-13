/* Read-only, server authenticated ZEN request. Owner detail is logged locally. */
params [["_position", [], [[]]]];
if (!isServer || {!isRemoteExecuted}) exitWith {};
private _sender = remoteExecutedOwner;
if (allCurators findIf {
    private _u = getAssignedCuratorUnit _x;
    !isNull _u && {isPlayer _u} && {alive _u} && {owner _u == _sender}
} < 0) exitWith {};
if (count _position != 3 || {_position findIf {!(_x isEqualType 0) || {!finite _x}} >= 0}) exitWith {};
if (CBA_missionTime < localNamespace getVariable ["KPLIB_vehicleCombat_inspectAt", 0]) exitWith {};
localNamespace setVariable ["KPLIB_vehicleCombat_inspectAt", CBA_missionTime + 0.5];
private _near = (ASLToAGL _position) nearEntities [["Tank", "Wheeled_APC_F"], 50];
private _lines = ["FRONTLINE VEHICLE COMBAT", format ["Enabled %1 | Guns %2 m | MG %3 m | Range factor %4", KPLIB_vehicleCombat_enabled, KPLIB_vehicleCombat_gunRange, KPLIB_vehicleCombat_mgRange, KPLIB_vehicleCombat_rangeMultiplier]];
if (_near isEqualTo []) then {_lines pushBack "No tank/APC/IFV within 50 m of cursor"} else {
    private _v = _near select 0;
    private _distance = 1e9;
    {
        private _candidateDistance = getPosASL _x vectorDistance _position;
        if (_candidateDistance < _distance) then {
            _v = _x;
            _distance = _candidateDistance;
        };
    } forEach _near;
    _lines pushBack typeOf _v;
    {
        private _u = _v turretUnit _x;
        if (isNull _u) then {continue};
        _lines pushBack format ["Turret %1 | owner %2 | %3", _x, owner _u, [_u, false] call KPLIB_fnc_vehicleCombatEligible];
        private _s = (localNamespace getVariable "KPLIB_vehicleCombat_states") getOrDefault [netId _u, createHashMap];
        if (count _s > 0) then {
            _lines pushBack (_s get "reason");
            _lines pushBack format ["Target %1 | Alignment %2 | Actual shots %3", typeOf (_s get "target"), (_s getOrDefault ["alignment", 0]) toFixed 2, _s get "shots"];
            _lines pushBack format ["Last shot: %1", _s get "lastShot"];
            private _fire = _s getOrDefault ["fire", createHashMap];
            private _plan = _fire getOrDefault ["plan", []];
            if (_plan isNotEqualTo []) then {
                _lines pushBack format ["Burst %1 / %2 | %3 rounds left | Cycle %4 s", _plan select 4, _plan select 0, _fire getOrDefault ["remaining", 0], _plan select 1];
            };
            {_lines pushBack format ["%1 %2: %3-%4 m", _x get "kind", _x get "magazine", round (_x get "minimum"), round (_x get "range")]} forEach ((_s get "profiles") select [0, 4]);
        } else {
            _lines pushBack (if (local _u) then {"Awaiting eligible crew / registry scan"} else {"Headless-owned turret: shot diagnostics in owner's RPT"});
        };
    } forEach ((allTurrets _v) select [0, 3]);
};
[((_lines select [0,24]) apply {_x select [0,390]})] remoteExecCall ["KPLIB_fnc_aiSkillsReceive", _sender];
