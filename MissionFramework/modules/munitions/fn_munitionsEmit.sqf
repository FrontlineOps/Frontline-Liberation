/* Owner-local bounded native particle queue. Never a remote damage endpoint. */
if (isRemoteExecuted) exitWith {0};
if (canSuspend) exitWith {[KPLIB_fnc_munitionsEmit, _this] call CBA_fnc_directCall};
params ["_origin", "_ammo", "_directions", "_types", "_speed", "_parents", "_kind", ["_burst", []], ["_anchor", []]];
if (count _origin != 3 || {_origin findIf {!(_x isEqualType 0) || {!finite _x}} >= 0}
    || {count _directions > 512} || {_directions isEqualTo []} || {_types isEqualTo []}
    || {!finite _speed} || {_speed <= 0}) exitWith {0};
private _queue = localNamespace getVariable ["KPLIB_munitionsParticleQueue", []];
private _metrics = localNamespace getVariable ["KPLIB_munitionsParticleMetrics", [0,0,0,0]];
private _bucket = localNamespace getVariable ["KPLIB_munitionsParticleTokens", [CBA_missionTime,768]];
private _capacity = 768;
private _tokens = ((_bucket select 1) + (CBA_missionTime - (_bucket select 0)) * _capacity / 2) min _capacity;
private _admitted = (count _directions) min floor _tokens;
private _requested = count _directions;
private _pending = localNamespace getVariable ["KPLIB_munitionsBudgetPending", createHashMap];
if (count _queue + count _pending >= 16 || {!isServer && {localNamespace getVariable ["KPLIB_munitionsBudgetToken", ""] == ""}}) then {_admitted = 0};
_metrics set [0, (_metrics select 0) + count _directions];
_metrics set [2, (_metrics select 2) + count _directions - _admitted];
localNamespace setVariable ["KPLIB_munitionsParticleMetrics", _metrics];
localNamespace setVariable ["KPLIB_munitionsParticleTokens", [CBA_missionTime, _tokens - _admitted]];
if (_admitted > 0) then {
    // Randomize creation order too: a partial queue or debug's first 128 slots
    // must sample the whole sphere, not only the lower latitude bands.
    _directions = ([_directions] call CBA_fnc_shuffle) select [0, _admitted];
    private _serial = 1 + (localNamespace getVariable ["KPLIB_munitionsBudgetSerial", 0]);
    localNamespace setVariable ["KPLIB_munitionsBudgetSerial", _serial];
    _pending set [_serial, [+_origin, _ammo, _directions, 0, _types, _speed, _parents, _kind, CBA_missionTime, 0, _burst, _anchor, _serial]];
    localNamespace setVariable ["KPLIB_munitionsBudgetPending", _pending];
    private _args = ["REQUEST", _serial, _admitted, localNamespace getVariable ["KPLIB_munitionsBudgetToken", ""]];
    if (isServer) then {
        private _KPLIB_munitionsBudgetContext = true;
        _args call KPLIB_fnc_munitionsBudgetServer;
    } else {_args remoteExecCall ["KPLIB_fnc_munitionsBudgetServer", 2]};
};
[objNull, _kind + " ADMISSION", _origin, [_ammo, "requested/local admission", [_requested,_admitted], "server grant required; bounded queue; no target aiming"]] call KPLIB_fnc_munitionsEvent;
_admitted
