requestResupplyFlags = {
    params [["_requester", objNull, [objNull]]];
    private _caller = call KPLIB_fnc_permissionCaller;
    if (isNull _caller || {_caller != _requester}) exitWith {};
    [_caller] call setResupplyFlags;
};
