/* Server-issued, once-only incremental exposure. Execute on the unit owner.
   A transfer can drop an in-flight increment; it cannot replay accumulated heat. */
if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {};
if (!isRemoteExecuted && {!isServer}) exitWith {};
params [["_unit", objNull, [objNull]], ["_id", "", [""]], ["_ammo", "", [""]], ["_at", -1, [0]], ["_origin", [], [[]]], ["_dose", [], [[]]], ["_source", objNull, [objNull]]];
if (count _id > 128 || {_id == ""} || {!finite _at}) exitWith {};
if (count _origin != 3 || {_origin findIf {!(_x isEqualType 0) || {!finite _x}} >= 0}) exitWith {};
if (count _dose != 2 || {_dose findIf {!(_x isEqualType 0) || {!finite _x} || {_x < 0} || {_x > 24}} >= 0}) exitWith {};
private _reason = "";
if (!(localNamespace getVariable ["KPLIB_blastReady", false]) || {!(missionNamespace getVariable ["KPLIB_munitions_blast_enabled", true])}) then {_reason = "disabled/not ready"};
if (CBA_missionTime - _at > 10 || {_at > CBA_missionTime + 0.5}) then {_reason = "expired/future event"};
if (isNull _unit || {!local _unit} || {!alive _unit} || {!(_unit isKindOf "CAManBase")}) then {_reason = "missing/nonlocal/dead/invalid recipient"};
if (_reason == "" && {!isDamageAllowed _unit || {!(_unit getVariable ["ace_medical_allowDamage", true])}}) then {_reason = "damage protection"};
if (_reason != "") exitWith {[_unit, _id, "REJECTED", [_reason, _dose]] call KPLIB_fnc_blastTrace};
private _profile = [_ammo] call KPLIB_fnc_blastProfile;
if (!(_profile get "eligible") || {getPosASL _unit distance _origin > (_profile get "radius") + 5}) exitWith {
    [_unit, _id, "REJECTED", ["ammo eligibility/recipient range", _dose]] call KPLIB_fnc_blastTrace;
};
private _seen = (_unit getVariable ["KPLIB_blastApplied", []]) select {CBA_missionTime - (_x select 1) < 10};
if (_seen findIf {_x select 0 == _id} >= 0 || {count _seen >= 128}) exitWith {
    [_unit, _id, "REJECTED", ["duplicate/delivery capacity", _dose]] call KPLIB_fnc_blastTrace;
};
_seen pushBack [_id, CBA_missionTime];
_unit setVariable ["KPLIB_blastApplied", _seen];
private _parts = ["Head", "Body", "LeftArm", "RightArm", "LeftLeg", "RightLeg"];
private _weights = [0.15, 0.5, 0.075, 0.075, 0.1, 0.1];
private _ledger = _unit getVariable ["KPLIB_blastLedger", createHashMap];
private _debug = CBA_missionTime < (localNamespace getVariable ["KPLIB_munitionsUntil", -1]);
private _medicalState = {
    private _wounds = _unit getVariable ["ace_medical_openWounds", createHashMap];
    private _rows = 0;
    if (_wounds isEqualType createHashMap) then {{_rows = _rows + count _x} forEach values _wounds};
    [+(_unit getVariable ["ace_medical_bodyPartDamage", []]), _rows, alive _unit, _unit getVariable ["ACE_isUnconscious", false]]
};
{
    private _total = _x;
    private _kind = if (_forEachIndex == 0) then {_ammo} else {localNamespace getVariable ["KPLIB_blastBurnType", ""]};
    if (_total > 0 && {_kind != ""}) then {
        private _amount = _weights apply {_x * _total};
        private _result = [_ledger, "MODEL", [_ammo, "burn"] select (_forEachIndex == 1), _amount, CBA_missionTime, _at] call KPLIB_fnc_blastAccount;
        private _extra = _result select 0;
        private _before = if (_debug) then {call _medicalState} else {[]};
        localNamespace setVariable ["KPLIB_blastApplying", true];
        {
            if (_x > 0) then {
                [_unit, _x, _parts select _forEachIndex, _kind, _source, [], false] call ace_medical_fnc_addDamageToUnit;
            };
        } forEach _extra;
        localNamespace setVariable ["KPLIB_blastApplying", false];
        if (_debug) then {
            [_unit, _id, "MEDICAL RESULT", [_kind, "requested", _amount, "credited", _result select 1, "supplement", _extra, "before", _before, "after", call _medicalState]] call KPLIB_fnc_blastTrace;
        };
        [objNull, "BLAST MEDICAL", getPosASL _unit, [_id, _kind, "requested", _amount, "supplement", _extra, "credited", _result select 1], _unit] call KPLIB_fnc_munitionsEvent;
    };
} forEach _dose;
_unit setVariable ["KPLIB_blastLedger", _ledger];
