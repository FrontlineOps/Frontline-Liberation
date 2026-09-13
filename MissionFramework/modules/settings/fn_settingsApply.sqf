/* Local application only. Server commits and authenticated server snapshots
   are the only callers. Content/catalog generation remains in normal init. */
// HC-originated RPCs can report isRemoteExecuted=false. Require the private
// scope of an authorized local caller as well; network arguments cannot set it.
if (isRemoteExecuted || {isNil "_KPLIB_settingsApplyContext"}) exitWith {false};
params ["_revision", "_values"];
if (_revision <= (localNamespace getVariable ["KPLIB_settingsRevision", -1])) exitWith {false};
private _rows = localNamespace getVariable "KPLIB_settingsCatalog";
{
    missionNamespace setVariable [_x select 0, _values select _forEachIndex];
} forEach _rows;
[] call KPLIB_fnc_settingsDerive;
localNamespace setVariable ["KPLIB_settingsValues", +_values];
localNamespace setVariable ["KPLIB_settingsRevision", _revision];
localNamespace setVariable ["KPLIB_settingsReady", true];
true
