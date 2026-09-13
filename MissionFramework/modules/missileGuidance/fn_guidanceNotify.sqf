/* Only a compact radar warning crosses the network. No targeting/damage requests. */
params ["_record", "_target"];
if (isRemoteExecuted || {isNull _target} || {!(_target isKindOf "Air")}) exitWith {};
private _missile = _record get "missile";
if (isNull _missile || {!local _missile}) exitWith {};
[_missile, _target] remoteExecCall ["KPLIB_fnc_guidanceReceive", 2];
