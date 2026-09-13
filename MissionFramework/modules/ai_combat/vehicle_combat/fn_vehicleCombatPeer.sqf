/* Private server-issued HC capability. Never broadcast on an object or in JIP. */
params [["_token", "", [""]]];
if (isServer || {hasInterface} || {!isRemoteExecuted} || {remoteExecutedOwner != 2}
    || {_token == ""} || {count _token > 128}) exitWith {};
localNamespace setVariable ["KPLIB_vehicleCombat_peerToken", _token];
