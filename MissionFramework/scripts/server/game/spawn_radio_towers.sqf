if (!isServer || {isRemoteExecuted}) exitWith {};

// The save contains tower identities and remaining timers; never spawn before it loads.
waitUntil {sleep 1; missionNamespace getVariable ["save_is_loaded", false]};
call KPLIB_RADIO_SERVER_INIT;
