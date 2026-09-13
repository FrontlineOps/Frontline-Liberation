/* One global transient session, operated only by an authenticated assigned curator. */
if (!isServer || {!isRemoteExecuted}) exitWith {};
params [["_action", "", [""]], ["_position", [], [[]]], ["_object", objNull, [objNull]]];
if !(_action in ["START", "STOP", "REPORT", "INSPECT", "BLAST", "PHYSICS", "FOLLOW", "DEBUG_ON", "DEBUG_OFF", "DEBUG_PING"]) exitWith {};
private _sender = remoteExecutedOwner;
private _caller = (allPlayers select {owner _x == _sender && {isPlayer _x} && {!isNull getAssignedCuratorLogic _x}}) param [0, objNull];
if (isNull _caller) exitWith {};
private _limits = localNamespace getVariable ["KPLIB_munitionsRequestLimits", createHashMap];
private _connected = allPlayers apply {owner _x};
{if !(_x in _connected) then {_limits deleteAt _x}} forEach keys _limits;
if (_action != "DEBUG_OFF" && {CBA_missionTime < (_limits getOrDefault [_sender, -1])}) exitWith {};
private _delay = [2,0.25] select (_action in ["DEBUG_ON","DEBUG_OFF","DEBUG_PING"]);
_limits set [_sender, CBA_missionTime + _delay];
localNamespace setVariable ["KPLIB_munitionsRequestLimits", _limits];
if (_action in ["START", "INSPECT"] && {count _position != 3 || {_position findIf {!(_x isEqualType 0) || {!finite _x} || {abs _x > 1000000}} >= 0}}) exitWith {};
if (_action == "INSPECT" && {!isNull _object} && {_object distance _position > 50}) exitWith {};
private _nonce = 1 + (localNamespace getVariable ["KPLIB_munitionsNonce", 0]);
localNamespace setVariable ["KPLIB_munitionsNonce", _nonce];
if (_action in ["DEBUG_ON", "DEBUG_OFF", "DEBUG_PING"]) exitWith {
    private _followers = localNamespace getVariable ["KPLIB_munitionsLiveFollowers", createHashMap];
    private _session = localNamespace getVariable ["KPLIB_munitionsLiveSession", -1];
    if (_action == "DEBUG_OFF") then {
        _followers deleteAt _sender;
        [false, _session, "Munitions visual debug OFF."] remoteExecCall ["KPLIB_fnc_munitionsDebugState", _sender];
    } else {
        if (_action == "DEBUG_ON" || {_sender in _followers}) then {
            if (!(_sender in _followers) && {count _followers >= 4}) exitWith {
                [false, _session, "Munitions visual debug is already serving four curators."] remoteExecCall ["KPLIB_fnc_munitionsDebugState", _sender];
            };
            if (count _followers == 0) then {
                _session = _nonce;
                localNamespace setVariable ["KPLIB_munitionsLiveSession", _session];
                localNamespace setVariable ["KPLIB_munitionsLiveRenew", -1];
                localNamespace setVariable ["KPLIB_munitionsLiveFieldSent", createHashMap];
                localNamespace setVariable ["KPLIB_munitionsLivePending", createHashMap];
            };
            _followers set [_sender, [_caller, CBA_missionTime + 15]];
            if (_action == "DEBUG_ON") then {
                // A newly subscribed viewer also receives the retained fields.
                localNamespace setVariable ["KPLIB_munitionsLiveFieldSent", createHashMap];
            };
            private _message = ["", "Munitions visual debug ON: automatic live paths and explosions; hover for values. Detailed reports go to each machine's RPT."] select (_action == "DEBUG_ON");
            [_action != "DEBUG_OFF", _session, _message] remoteExecCall ["KPLIB_fnc_munitionsDebugState", _sender];
        };
    };
    localNamespace setVariable ["KPLIB_munitionsLiveFollowers", _followers];
};
if (_action == "FOLLOW") exitWith {
    private _followers = localNamespace getVariable ["KPLIB_gasFollowers", createHashMap];
    private _message = "Live field following stopped.";
    if (_sender in _followers) then {
        _followers deleteAt _sender;
    } else {
        if (count _followers < 16) then {
            _followers set [_sender, [_caller, CBA_missionTime + 120, ""]];
            _message = "Following the latest completed field for 120 seconds in Zeus. Each new field replaces the replay; rapid salvos may be skipped. No capture is required. A server-only FrontlineGas v2 extension enables GAS; absent backends are labeled LEGACY.";
        } else {
            _message = "Live replay subscriber limit reached (16). Use Replay latest blast / thermal fields.";
        };
    };
    localNamespace setVariable ["KPLIB_gasFollowers", _followers];
    [_nonce, _message, []] remoteExecCall ["KPLIB_fnc_munitionsDisplay", _sender];
};
if (_action == "PHYSICS") exitWith {
    [{
        params ["_recipient", "_caller", "_nonce"];
        if (isNull _caller || {owner _caller != _recipient} || {isNull getAssignedCuratorLogic _caller}) exitWith {};
        private _report = [] call KPLIB_fnc_gasNativeReport;
        [_nonce, _report, []] remoteExecCall ["KPLIB_fnc_munitionsDisplay", _recipient];
    }, [_sender, _caller, _nonce]] call CBA_fnc_execNextFrame;
};
if (_action == "BLAST") exitWith {
    [{
        params ["_recipient", "_caller"];
        if (isNull _caller || {owner _caller != _recipient} || {isNull getAssignedCuratorLogic _caller}) exitWith {};
        private _fields = [] call KPLIB_fnc_blastView;
        [_fields] remoteExecCall ["KPLIB_fnc_blastView", _recipient];
    }, [_sender, _caller]] call CBA_fnc_execNextFrame;
};
if (_action == "START") exitWith {
    [_nonce, _position, 120] remoteExecCall ["KPLIB_fnc_munitionsControl", 0];
    [_nonce, "Capture started on currently connected machines: 750 m, 120 seconds, 64 ordinary/child projectiles plus 128 known fragments per owner. Fire the test shots, then use Read capture. A later capture replaces this one.", []] remoteExecCall ["KPLIB_fnc_munitionsDisplay", _sender];
};
if (_action == "STOP") then {
    [_nonce, [], 0] remoteExecCall ["KPLIB_fnc_munitionsControl", 0];
};
private _owners = [2];
{_owners pushBackUnique owner _x} forEach allPlayers;
_owners = _owners select [0, 16];
if (_action == "INSPECT" && {!isNull _object}) then {_owners = [owner _object]};
localNamespace setVariable ["KPLIB_munitionsPending", [_nonce, _sender, CBA_missionTime + 12, +_owners, _caller]];
[_nonce, format ["Collecting %1 machine report(s). Missing replies after 12 seconds remain unverified; only the latest concurrent request is retained.", count _owners], []] remoteExecCall ["KPLIB_fnc_munitionsDisplay", _sender];
[_nonce, _object] remoteExecCall ["KPLIB_fnc_munitionsCollect", _owners];
