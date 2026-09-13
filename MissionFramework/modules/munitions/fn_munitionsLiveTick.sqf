/* Independent diagnostic scheduler: no network/report work in the gas budget. */
if (!isServer || {isRemoteExecuted}) exitWith {};
private _followers = localNamespace getVariable ["KPLIB_munitionsLiveFollowers", createHashMap];
{
    (_followers get _x) params ["_caller", "_until"];
    if (isNull _caller || {!isPlayer _caller} || {owner _caller != _x}
        || {isNull getAssignedCuratorLogic _caller} || {CBA_missionTime >= _until}) then {
        _followers deleteAt _x;
    };
} forEach keys _followers;
private _session = localNamespace getVariable ["KPLIB_munitionsLiveSession", -1];
private _owners = localNamespace getVariable ["KPLIB_munitionsLiveOwners", []];
if (count _followers == 0) exitWith {
    if (_owners isNotEqualTo []) then {
        [_session, [], 0, true] remoteExecCall ["KPLIB_fnc_munitionsControl", _owners];
    };
    localNamespace setVariable ["KPLIB_munitionsLiveOwners", []];
    localNamespace setVariable ["KPLIB_munitionsLivePending", createHashMap];
};
if (CBA_missionTime >= (localNamespace getVariable ["KPLIB_munitionsLiveRenew", -1])) then {
    localNamespace setVariable ["KPLIB_munitionsLiveRenew", CBA_missionTime + 5];
    private _connected = [2];
    {_connected pushBackUnique owner _x} forEach allPlayers;
    _connected = _connected select [0,16];
    private _removed = _owners - _connected;
    if (_removed isNotEqualTo []) then {[_session, [], 0, true] remoteExecCall ["KPLIB_fnc_munitionsControl", _removed]};
    _owners = _connected;
    localNamespace setVariable ["KPLIB_munitionsLiveOwners", _owners];
    [_session, [], 15, true] remoteExecCall ["KPLIB_fnc_munitionsControl", _owners];
};
private _pending = localNamespace getVariable ["KPLIB_munitionsLivePending", createHashMap];
{if !(_x in _owners) then {_pending deleteAt _x}} forEach keys _pending;
private _cursor = localNamespace getVariable ["KPLIB_munitionsLiveCursor", 0];
private _sequence = 1 + (localNamespace getVariable ["KPLIB_munitionsLiveSequence", 0]);
localNamespace setVariable ["KPLIB_munitionsLiveSequence", _sequence];
// Four owner polls per 250 ms: 4 Hz for <=4 owners, 1 Hz for sixteen.
for "_i" from 1 to (4 min count _owners) do {
    private _owner = _owners select (_cursor mod count _owners);
    _cursor = _cursor + 1;
    private _ticket = _pending getOrDefault [_owner, [-1,-1]];
    if (CBA_missionTime > (_ticket select 1)) then {
        _pending set [_owner, [_sequence, CBA_missionTime + 2]];
        [_session, _sequence] remoteExecCall ["KPLIB_fnc_munitionsLiveCollect", _owner];
    };
};
localNamespace setVariable ["KPLIB_munitionsLivePending", _pending];
localNamespace setVariable ["KPLIB_munitionsLiveCursor", _cursor];
[true] call KPLIB_fnc_gasPublish;
