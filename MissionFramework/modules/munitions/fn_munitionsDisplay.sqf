if (!hasInterface || {!isRemoteExecuted} || {remoteExecutedOwner != 2} || {isNull getAssignedCuratorLogic player}) exitWith {};
params ["_nonce", "_text", "_lines", ["_meta", []], ["_owner", -1]];
if !(_text isEqualType "" && {count _text <= 48128} && {[_lines,_meta] call KPLIB_fnc_munitionsPayload}) exitWith {};
disableSerialization;
private _new = _nonce != (uiNamespace getVariable ["KPLIB_munitionsReportNonce", -1]);
private _display = uiNamespace getVariable ["KPLIB_munitionsDisplay", displayNull];
if (_new || {isNull _display}) then {
    if (!isNull _display) then {_display closeDisplay 2};
    private _parent = findDisplay 312;
    if (isNull _parent) then {_parent = findDisplay 46};
    _display = _parent createDisplay "KPLIB_MunitionsReport";
    uiNamespace setVariable ["KPLIB_munitionsDisplay", _display];
};
if (_new) then {
    uiNamespace setVariable ["KPLIB_munitionsReportNonce", _nonce];
    uiNamespace setVariable ["KPLIB_munitionsReportText", ""];
};
private _combined = ((uiNamespace getVariable ["KPLIB_munitionsReportText", ""]) + toString [13,10] + _text) select [0,800000];
uiNamespace setVariable ["KPLIB_munitionsReportText", _combined];
// Status/physics messages do not erase a previously requested path capture.
if (_meta isNotEqualTo [] || {_lines isNotEqualTo []}) then {
    if (_nonce != (uiNamespace getVariable ["KPLIB_munitionsPathNonce", -1])) then {
        uiNamespace setVariable ["KPLIB_munitionsPathNonce", _nonce];
        uiNamespace setVariable ["KPLIB_munitionsOwnerPackets", []];
    };
    private _packets = uiNamespace getVariable ["KPLIB_munitionsOwnerPackets", []];
    private _index = _packets findIf {(_x select 0) isEqualTo _owner};
    if (_index < 0) then {_index = count _packets};
    if (_index < 16) then {
        private _tags = _meta param [1, []];
        private _stats = _meta param [2, [0,0,0,0,0,0,0,0,0,0,0,0,0]];
        _packets set [_index, [_owner,_lines,_tags,_stats]];
        private _merged = [_packets] call KPLIB_fnc_munitionsMerge;
        uiNamespace setVariable ["KPLIB_munitionsLines", _merged select 0];
        uiNamespace setVariable ["KPLIB_munitionsTags", _merged select 1];
        uiNamespace setVariable ["KPLIB_munitionsStats", _merged select 2];
        uiNamespace setVariable ["KPLIB_munitionsClientOmitted", _merged select 3];
        uiNamespace setVariable ["KPLIB_munitionsDisplayedPaths", _merged select 4];
        uiNamespace setVariable ["KPLIB_munitionsDrawUntil", diag_tickTime + 120];
    };
};
if (!isNull _display) then {(_display displayCtrl 7101) ctrlSetText _combined};
