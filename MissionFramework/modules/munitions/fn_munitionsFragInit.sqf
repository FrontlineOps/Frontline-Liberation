/* Mission particle scheduler runs on each native projectile owner. */
if (isRemoteExecuted || {localNamespace getVariable ["KPLIB_munitionsFragHooked", false]}) exitWith {};
localNamespace setVariable ["KPLIB_munitionsFragHooked", true];
localNamespace setVariable ["KPLIB_munitionsParticleQueue", []];
localNamespace setVariable ["KPLIB_munitionsDebrisQueue", []];
localNamespace setVariable ["KPLIB_munitionsBackfaceQueue", []];
localNamespace setVariable ["KPLIB_munitionsParticleMetrics", [0,0,0,0]];
localNamespace setVariable ["KPLIB_munitionsFragStatus", "MISSION: validated bursts, exact native origin"];
localNamespace setVariable ["KPLIB_munitionsFragSpatialStatus", "MISSION game budgets; target-independent spatial RNG"];
localNamespace setVariable ["KPLIB_munitionsBudgetPending", createHashMap];
localNamespace setVariable ["KPLIB_munitionsBudgetReceipts", createHashMap];
localNamespace setVariable ["KPLIB_munitionsBudgetLive", []];
localNamespace setVariable ["KPLIB_munitionsBudgetSerial", 0];
if (isServer) then {
    localNamespace setVariable ["KPLIB_munitionsBudgetPeers", createHashMapFromArray [[2, ["", 0, createHashMap]]]];
    localNamespace setVariable ["KPLIB_munitionsBudgetUsed", 0];
    addMissionEventHandler ["PlayerDisconnected", {
        params ["", "", "", "", "_owner"];
        private _KPLIB_munitionsBudgetContext = true;
        ["DROP", _owner] call KPLIB_fnc_munitionsBudgetServer;
    }];
};
[KPLIB_fnc_munitionsBudgetTick, 0.1] call CBA_fnc_addPerFrameHandler;
[KPLIB_fnc_munitionsParticleTick, 0.02] call CBA_fnc_addPerFrameHandler;
