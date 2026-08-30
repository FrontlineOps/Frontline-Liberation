if (isServer) then {
    [] call compileFinal preprocessFileLineNumbers "modules\COPS\server.sqf";
    [] spawn KPLIB_COPS_SERVER_INIT;
};

if (hasInterface) then {
    [] call compileFinal preprocessFileLineNumbers "modules\COPS\client.sqf";
};
