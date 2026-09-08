/* Invoked after CBA initialization settles or when the server gains locality.
   Registry/state stay in localNamespace, never in client-writable object vars. */
params [["_unit", objNull, [objNull]]];
if (!isServer || {isRemoteExecuted} || {isNull _unit} || {!local _unit}
    || {!alive _unit} || {!(_unit isKindOf "CAManBase")} || {isPlayer _unit}) exitWith {false};
private _registry = localNamespace getVariable ["KPLIB_aiSkills_registry", createHashMap];
private _key = netId _unit;
if (_key == "0:0" || {_key == ""}) exitWith {false};
if (_key in _registry) exitWith {true};
private _original = KPLIB_aiSkills_names apply {_unit skill _x};
private _state = createHashMapFromArray [
    ["unit", _unit], ["original", _original], ["base", +_original],
    ["variation", random 2 - 1], ["profile", ""], ["active", false],
    ["nextUpdate", 0], ["nextTerrain", 0], ["terrain", 0],
    ["suppression", 0], ["lastThreat", -1000], ["lastDecay", CBA_missionTime],
    ["boostTarget", objNull], ["boostPosition", []], ["boostShots", 0], ["lastShot", -1000],
    ["factors", [0, 0, 1, 1]]
];
_registry set [_key, _state];
(localNamespace getVariable "KPLIB_aiSkills_queue") pushBack _key;
true
