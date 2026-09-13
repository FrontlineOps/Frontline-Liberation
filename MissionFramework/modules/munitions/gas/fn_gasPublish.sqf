/* Called at most twice/second by the server scheduler. Subscribers are bound to
   the original player object and lose access on expiry, disconnect or de-Zeus. */
if (!isServer || {isRemoteExecuted}) exitWith {};
params [["_live", false, [true]]];
if (_live) exitWith {
    private _followers = localNamespace getVariable ["KPLIB_munitionsLiveFollowers", createHashMap];
    if (count _followers == 0) exitWith {};
    private _jobs = +(localNamespace getVariable ["KPLIB_blastHistory", []]);
    _jobs append (localNamespace getVariable ["KPLIB_blastJobs", []]);
    _jobs = _jobs select {CBA_missionTime - (_x get "at") < 20};
    private _sent = localNamespace getVariable ["KPLIB_munitionsLiveFieldSent", createHashMap];
    private _ids = _jobs apply {_x get "id"};
    {if !(_x in _ids) then {_sent deleteAt _x}} forEach keys _sent;
    private _cursor = localNamespace getVariable ["KPLIB_munitionsLiveFieldCursor", 0];
    private _published = false;
    for "_i" from 1 to count _jobs do {
        if (_published) exitWith {};
        private _job = _jobs select (_cursor mod count _jobs);
        _cursor = _cursor + 1;
        private _id = _job get "id";
        private _revision = [count (_job getOrDefault ["gasFrames", []]), _job get "phase", _job get "truncated"];
        if ((_sent getOrDefault [_id, []]) isEqualTo _revision) then {continue};
        private _fields = [false, [_job]] call KPLIB_fnc_blastView;
        private _session = localNamespace getVariable "KPLIB_munitionsLiveSession";
        {
            (_followers get _x) params ["_caller", "_until"];
            if (!isNull _caller && {isPlayer _caller} && {owner _caller == _x}
                && {!isNull getAssignedCuratorLogic _caller} && {CBA_missionTime < _until}) then {
                [_session, _fields] remoteExecCall ["KPLIB_fnc_munitionsLiveField", _x];
            };
        } forEach keys _followers;
        _sent set [_id, _revision];
        if (_job get "phase" == "DONE" && {!(_job getOrDefault ["debugLogged", false])}) then {
            _job set ["debugLogged", true];
            private _rows = [format ["FIELD %1 %2: completed diagnostic (truncated=%3)", _id, (_job get "profile") get "ammo", _job get "truncated"]];
            _rows append ([_job] call KPLIB_fnc_gasJobReport);
            [_rows] call KPLIB_fnc_munitionsLog;
        };
        _published = true;
    };
    localNamespace setVariable ["KPLIB_munitionsLiveFieldSent", _sent];
    localNamespace setVariable ["KPLIB_munitionsLiveFieldCursor", _cursor];
};
private _followers = localNamespace getVariable ["KPLIB_gasFollowers", createHashMap];
if (count _followers == 0) exitWith {};
private _fields = [true] call KPLIB_fnc_blastView;
{
    private _recipient = _x;
    (_followers get _recipient) params ["_caller", "_until", "_last"];
    if (isNull _caller || {!isPlayer _caller} || {owner _caller != _recipient} || {isNull getAssignedCuratorLogic _caller} || {CBA_missionTime >= _until}) then {
        _followers deleteAt _recipient;
    } else {
        if (_fields isNotEqualTo [] && {((_fields select 0) select 0) != _last}) then {
            [_fields, true] remoteExecCall ["KPLIB_fnc_blastView", _recipient];
            _followers set [_recipient, [_caller, _until, (_fields select 0) select 0]];
        };
    };
} forEach keys _followers;
