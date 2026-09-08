// Called only by the server, executed by the unit's owner (server/client/HC).
KPLIB_INTEL_LOCAL_DETAIN = {
    params [["_unit", objNull, [objNull]]];
    if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {};
    if (!isRemoteExecuted && {!isServer}) exitWith {};
    if (isNull _unit || {!local _unit} || {isPlayer _unit}) exitWith {};
    removeAllWeapons _unit;
    _unit setCaptive true;
    _unit disableAI "PATH";
    doStop _unit;
    if (missionNamespace getVariable ["KP_liberation_ace", false]) then {
        ["ace_captives_setSurrendered", [_unit, true], _unit] call CBA_fnc_targetEvent;
    };
};

if (isServer) then {
    [] call compileFinal preprocessFileLineNumbers "modules\intelligence\server.sqf";
    [] call KPLIB_INTEL_SERVER_INIT;
};

if (hasInterface) then {
    [] call compileFinal preprocessFileLineNumbers "modules\intelligence\client.sqf";
};
