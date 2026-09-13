/* Campaign options are supplied by Frontline CBA settings. Only the two
   non-persistent save-wipe confirmations remain lobby parameters. */
if (isRemoteExecuted || {!(localNamespace getVariable ["KPLIB_settingsReady", false])}) exitWith {};
KP_liberation_ace = isClass (configFile >> "CfgPatches" >> "ace_common");
KP_load_params = 2;
GRLIB_param_wipe_savegame_1 = ["WipeSave1", 0] call BIS_fnc_getParamValue;
GRLIB_param_wipe_savegame_2 = ["WipeSave2", 0] call BIS_fnc_getParamValue;
if (isServer) then {
    KP_serverParamsFetched = true;
    publicVariable "KP_serverParamsFetched";
};

switch (KP_liberation_victoryCondition) do {
    case 1: {
        KP_liberation_victoryCheck = {
            (count (blufor_sectors select {_x in sectors_bigtown})) == (count sectors_bigtown)
            &&
            {
                (count (blufor_sectors select {_x in sectors_military})) == (count sectors_military)
            }
        };
    };
    case 2: {
        KP_liberation_victoryCheck = {
            (count (blufor_sectors select {_x in sectors_bigtown})) == (count sectors_bigtown)
            &&
            {
                (count (blufor_sectors select {!(_x in sectors_bigtown)})) >= ((count (sectors_allSectors - sectors_bigtown)) * 0.6)
            }
        };
    };
    case 3: {
        KP_liberation_victoryCheck = {
            (count (blufor_sectors select {_x in sectors_bigtown})) == (count sectors_bigtown)
            &&
            {
                (count (blufor_sectors select {!(_x in sectors_bigtown)})) >= ((count (sectors_allSectors - sectors_bigtown)) * 0.8)
            }
        };
    };
    case 4: {
        KP_liberation_victoryCheck = {
            (count blufor_sectors) == (count sectors_allSectors)
        };
    };
    default {
        KP_liberation_victoryCheck = {
            (count (blufor_sectors select {_x in sectors_bigtown})) == (count sectors_bigtown)
        };
    };
};


if (hasInterface) then {
    player createDiarySubject ["parameters", "Mission Settings"];
    player createDiaryRecord ["parameters", ["Frontline Settings", "Open Configure Addons and select a Frontline section. Gameplay settings are controlled by the host or server administrator. Options marked for restart take effect in the next mission; existing players and late joiners keep the active session values. Existing ZEN tools remain available."]];
};
