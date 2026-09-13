/* Absolute revisioned snapshot; a new owner never replays old increments. */
if (!isServer || {isRemoteExecuted} || {isNil "_KPLIB_blastTraumaServerContext"}) exitWith {};
params ["_state"];
private _unit = _state get "unit";
if (isNull _unit) exitWith {};
// Private owner lease: do not publish on the unit or include in inspection/RPT.
// Reissue on transfer; some HC-to-server executions lose caller metadata.
if (owner _unit != (_state get "owner") || {(_state getOrDefault ["lease", ""]) == ""}) then {
    _state set ["lease", str ([1,2,3,4] apply {floor random 1000000000})];
};
private _revision = 1 + (localNamespace getVariable ["KPLIB_blastTraumaRevision", 0]);
localNamespace setVariable ["KPLIB_blastTraumaRevision", _revision];
_state set ["revision", _revision];
private _payload = [
    _unit, _state get "revision", CBA_missionTime, _state get "at",
    +(_state get "scores"), _state get "count", _state get "last",
    _state getOrDefault ["reading", []], _state get "reset", _state get "lease"
];
_unit setVariable ["KPLIB_blastTraumaSnapshot", _payload select [1,8]];
_state set ["owner", owner _unit];
if (local _unit) then {
    private _KPLIB_blastTraumaDeliveryContext = true;
    _payload call KPLIB_fnc_blastTraumaReceive;
} else {
    _payload remoteExecCall ["KPLIB_fnc_blastTraumaReceive", owner _unit];
};

