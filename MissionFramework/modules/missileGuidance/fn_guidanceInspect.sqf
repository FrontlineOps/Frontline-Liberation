/* Local diagnostic: [ammoClass, optionalShooter] call KPLIB_fnc_guidanceInspect. */
if (isRemoteExecuted) exitWith {createHashMap};
params [["_ammo", "", [""]], ["_shooter", objNull, [objNull]]];
private _profile = [_ammo] call KPLIB_fnc_guidanceResolve;
private _owner = [_profile, _shooter] call KPLIB_fnc_guidanceBackend;
createHashMapFromArray [
    ["ammo", _profile get "ammo"], ["family", _profile get "family"],
    ["controller", _owner select 0], ["reason", _owner select 1],
    ["range", _profile get "range"], ["life", _profile get "life"],
    ["active", count (localNamespace getVariable ["KPLIB_guidanceActive", createHashMap])],
    ["metrics", +(localNamespace getVariable ["KPLIB_guidanceMetrics", createHashMap])]
]
