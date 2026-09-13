/* One owner-local clock for bounded active bursts; no world scans. */
if (isRemoteExecuted || {hasInterface && {!isServer}}) exitWith {};
if (localNamespace getVariable ["KPLIB_combatFire_initialized", false]) exitWith {};
localNamespace setVariable ["KPLIB_combatFire_initialized", true];
localNamespace setVariable ["KPLIB_combatFire_queue", createHashMap];
localNamespace setVariable ["KPLIB_combatFire_modes", createHashMap];
localNamespace setVariable ["KPLIB_combatFire_handler", [{
    private _KPLIB_combatFireContext = true;
    [] call KPLIB_fnc_combatFireTick;
}, 0] call CBA_fnc_addPerFrameHandler];
