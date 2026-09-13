params [["_unit", objNull, [objNull]]];
if (!isServer || {isRemoteExecuted} || {isNull _unit} || {!local _unit} || {!alive _unit}
    || {isPlayer _unit} || {!(_unit isKindOf "CAManBase")}) exitWith {false};
private _registry = localNamespace getVariable ["KPLIB_aiCombat_registry", createHashMap];
private _key = netId _unit;
if (_key in ["", "0:0"]) exitWith {false};
if (_key in _registry) exitWith {true};
_registry set [_key, createHashMapFromArray [
    ["unit", _unit], ["next", 0], ["reason", "Waiting"], ["target", objNull],
    ["job", createHashMap], ["shots", 0], ["lastShot", []], ["heard", []],
    ["nearMiss", -1000], ["explosiveAt", -1000], ["recent", []],
    ["profiles", []], ["soundWatchUntil", -1], ["candidateCursor", 0]
]];
(localNamespace getVariable "KPLIB_aiCombat_queue") pushBack _key;
true
