/* Execute on the unit owner, only from the server. Each two-second check is
 * cancelled by reset, release, death, group change or locality loss. Arrival
 * uses 3D distance, not unitReady (which also means an order was abandoned).
 */
if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {false};
if (!isRemoteExecuted && {!isServer}) exitWith {false};
params ["_unit", "_token", "_slot", "_teleport", "_attempt"];
if (isNull _unit || {!local _unit} || {isPlayer _unit} || {captive _unit}
    || {!(_unit call KPLIB_fnc_isAlive)}
    || {_token isNotEqualTo (_unit getVariable ["KPLIB_garrisonToken", []])}) exitWith {false};
_unit enableAI "PATH";
_unit forceSpeed -1;
_unit setUnitPos "AUTO";
doStop _unit;
if (_slot isEqualTo []) exitWith {
    _unit setVariable ["KPLIB_garrisonToken", [], true];
    _unit setVariable ["KPLIB_garrisonState", "NO_POSITION"];
    _unit doFollow leader _unit;
    false
};
_slot params ["_building", "_index", "_target", "_floor", "_mode"];
_unit setVariable ["KPLIB_garrisonState", "MOVING"];
_unit setVariable ["KPLIB_garrisonTarget", _slot];
if (_mode == "WEAPON") then {
    _unit assignAsGunner _building;
    [_unit] orderGetIn true;
    if (_teleport) then {_unit moveInGunner _building};
} else {
    unassignVehicle _unit;
    [_unit] orderGetIn false;
    if (_teleport) then {
        _unit setVehiclePosition [_target, [], 0, "CAN_COLLIDE"];
    } else {
        _unit doMove _target;
    };
};
private _distance = (getPosASL _unit) vectorDistance (AGLToASL _target);
private _state = [_unit, group _unit, _token, _slot, _attempt, CBA_missionTime,
    CBA_missionTime, _distance, false, CBA_missionTime + (60 max (240 min (_distance / 1.2 + 60))), _teleport];
private _tick = {
    params ["_state", "_handle"];
    _state params ["_unit", "_group", "_token", "_slot", "_attempt", "_started", "_progressAt", "_best", "_reissued", "_deadline", "_teleport"];
    if (isNull _unit || {!local _unit} || {isPlayer _unit} || {captive _unit}
        || {!(_unit call KPLIB_fnc_isAlive)} || {group _unit != _group}
        || {_token isNotEqualTo (_unit getVariable ["KPLIB_garrisonToken", []])}) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
    };
    _slot params ["_building", "_index", "_target", "_floor", "_mode"];
    if (!isNull objectParent _unit && {objectParent _unit != _building}) exitWith {
        _unit setVariable ["KPLIB_garrisonToken", [], true];
        _unit setVariable ["KPLIB_garrisonState", "RELEASED"];
        [_handle] call CBA_fnc_removePerFrameHandler;
    };
    private _asl = AGLToASL _target;
    private _distance = (getPosASL _unit) vectorDistance _asl;
    private _arrived = if (_mode == "WEAPON") then {gunner _building == _unit} else {
        isNull objectParent _unit && {_mode == "GROUND" || {alive _building}}
        && {_teleport || {unitReady _unit}} && {_distance <= 1.5}
        && {abs ((getPosASL _unit select 2) - (_asl select 2)) < 0.8}
    };
    if (_arrived) exitWith {
        if (_mode != "WEAPON") then {
            _unit disableAI "PATH";
            _unit setUnitPos selectRandom ["UP", "UP", "MIDDLE"];
            if (!isNull _building) then {
                _unit doWatch AGLToASL (_target getPos [250, _building getDir _target]);
            };
        };
        _unit setVariable ["KPLIB_garrisonState", "HELD"];
        [_handle] call CBA_fnc_removePerFrameHandler;
    };
    if (_distance < _best - 0.75) then {
        _state set [6, CBA_missionTime];
        _state set [7, _distance];
        _state set [8, false];
        _progressAt = CBA_missionTime;
        _reissued = false;
    };
    private _stalled = CBA_missionTime - _progressAt;
    if (_stalled > 20 && {!_reissued} && {_mode != "WEAPON"}) then {
        _unit doMove _target;
        _state set [8, true];
    };
    if (_stalled > 45 || {CBA_missionTime > _deadline}
        || {_mode != "GROUND" && {!alive _building} && {CBA_missionTime - _started > 15}}) then {
        [_handle] call CBA_fnc_removePerFrameHandler;
        unassignVehicle _unit;
        [_unit] orderGetIn false;
        if (_attempt < 2) then {
            _unit setVariable ["KPLIB_garrisonState", "RETRY"];
            if (isServer) then {[_unit, _token] call KPLIB_fnc_garrisonRetry} else {
                [_unit, _token] remoteExecCall ["KPLIB_fnc_garrisonRetry", 2];
            };
        } else {
            // Remain mobile if all three destinations fail; never pin a unit
            // to the wrong floor or leave an unbounded movement callback.
            _unit setVariable ["KPLIB_garrisonToken", [], true];
            _unit setVariable ["KPLIB_garrisonState", "UNREACHABLE"];
            _unit doFollow leader _unit;
        };
    };
};
[_tick, 2, _state] call CBA_fnc_addPerFrameHandler;
true
