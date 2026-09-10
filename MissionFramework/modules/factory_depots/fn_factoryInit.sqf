/* Called after normal objects/storages load, on the server.
   Registry: sector -> [layout [ATL, direction], live crates, pending rows].
   An existing entry, including an empty one, consumes the initial cache.
   Campaign slot 22: [version 1, [[sector, layout, cargo rows], ...]]. */
if (!isServer || {isRemoteExecuted} || {localNamespace getVariable ["KPLIB_factoryReady", false]}) exitWith {};
params [["_saved", []], ["_loadedObjects", [], [[]]]];
localNamespace setVariable ["KPLIB_factoryRegistry", createHashMap];
localNamespace setVariable ["KPLIB_factorySites", call compileFinal preprocessFileLineNumbers "modules\factory_depots\sites.sqf"];
localNamespace setVariable ["KPLIB_factoryPlanning", false];
localNamespace setVariable ["KPLIB_factoryFailed", []];
[_saved, _loadedObjects] call KPLIB_fnc_factoryRestore;
localNamespace setVariable ["KPLIB_factoryReady", true];
// One sequential startup worker; no sector-unload deletion or replenishment.
[] spawn {
    {
        [_x] call KPLIB_fnc_factoryEnsure;
        sleep 0.05;
    } forEach sectors_factory;
    [] call KPLIB_fnc_factoryTick;
};
[{[] call KPLIB_fnc_factoryTick}, 30] call CBA_fnc_addPerFrameHandler;
true
