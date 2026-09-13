/* Mission particle scheduler runs on each native projectile owner. */
if (isRemoteExecuted || {localNamespace getVariable ["KPLIB_munitionsFragHooked", false]}) exitWith {};
localNamespace setVariable ["KPLIB_munitionsFragHooked", true];
localNamespace setVariable ["KPLIB_munitionsParticleQueue", []];
localNamespace setVariable ["KPLIB_munitionsDebrisQueue", []];
localNamespace setVariable ["KPLIB_munitionsBackfaceQueue", []];
localNamespace setVariable ["KPLIB_munitionsParticleMetrics", [0,0,0,0]];
localNamespace setVariable ["KPLIB_munitionsFragStatus", "MISSION: validated bursts, exact native origin"];
localNamespace setVariable ["KPLIB_munitionsFragSpatialStatus", "MISSION game budgets; target-independent spatial RNG"];
[KPLIB_fnc_munitionsParticleTick, 0.02] call CBA_fnc_addPerFrameHandler;
