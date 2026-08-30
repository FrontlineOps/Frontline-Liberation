if (isServer) then {
    [] call compileFinal preprocessFileLineNumbers "modules\intelligence\server.sqf";
    [] call KPLIB_INTEL_SERVER_INIT;
};

if (hasInterface) then {
    [] call compileFinal preprocessFileLineNumbers "modules\intelligence\client.sqf";
};
