/* The existing owner-local Fired adapters supply confirmed, matching rounds. */
if (isRemoteExecuted) exitWith {};
params ["_fire", "_mode"];
private _plan = _fire getOrDefault ["plan", []];
if (_plan isEqualTo [] || {_plan select 0 != _mode}
    || {CBA_missionTime - (_fire getOrDefault ["attempt", -100]) > 0.3}) exitWith {};
private _remaining = 0 max ((_fire get "remaining") - 1);
_fire set ["remaining", _remaining];
_fire set ["shots", 1 + (_fire getOrDefault ["shots", 0])];
_fire set ["lastShot", CBA_missionTime];
_fire set ["next", CBA_missionTime + (if (_remaining == 0) then {_plan select 3} else {_plan select 1})];
