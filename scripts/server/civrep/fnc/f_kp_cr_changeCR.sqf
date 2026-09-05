params ["_amount", ["_negative", false]];

if (!isServer) exitWith {};

waitUntil {!CR_Mutex};

CR_Mutex = true;

if (KP_liberation_civrep_debug > 0) then {[format ["changeCR called - Parameters [%1, %2]", _amount, _negative], "CIVREP"] call KPLIB_fnc_log;};

if (_negative) then {
    KP_liberation_civ_rep = KP_liberation_civ_rep - _amount;
} else {
    KP_liberation_civ_rep = KP_liberation_civ_rep + _amount;
};

KP_liberation_civ_rep = -100 max (KP_liberation_civ_rep min 0);

if (KP_liberation_civ_rep == -100) then {

    private _sectors = [blufor_sectors, 0] call NETWORKED_SECTORS_GET_SECTORS_UP_TO_COST;
    private _goodSector = false;
    private _bluforSector = "";
    private _loops = 0;
    private _maxLoops = 10;

    while {!_goodSector && count _sectors > 0 && _loops <= _maxLoops} do {
        _sector = (selectRandom _sectors)#1;
        _loops = _loops + 1;
        _bluforSector = [_sector, blufor_sectors] call NETWORKED_SECTORS_traverseGraphAndFindFirstBluforSector;

        if ((_bluforSector in sectors_bigtown || _bluforSector in sectors_capture || _bluforSector in sectors_factory) && markerText _bluforSector != "Lighthouse" && count ([markerPos _bluforSector, 1] call KPLIB_fnc_getNearbyPlayers) == 0) then {
            _goodSector = true;
        };
        //diag_log format ["Civ Sector Flip: %1 (%2) - %3", markerText _sector, _sector, _goodSector];
        diag_log format ["Civ Sector (blufor) Flip: %1 (%2) - %3", markerText _bluforSector, _bluforSector, _goodSector];
    };
    
    if (_bluforSector in sectors_bigtown + sectors_capture + sectors_factory) then {
        [_bluforSector] remoteExec ["toggle_sector_remote", 2];
        ["lib_admin_notification", ["Civilian sector lost", format ["%1 was lost due to revolting civilians!", markerText _bluforSector], "\A3\ui_f\data\gui\cfg\Debriefing\endDefault_ca.paa"]] remoteExec ["bis_fnc_shownotification"];
    };

    KP_liberation_civ_rep = -34;
};

// Set correct resistance standing
//private _resistanceEnemy = [0, 1] select (KP_liberation_civ_rep < 25);
//private _resistanceFriendly = [0, 1] select (KP_liberation_civ_rep >= -25);

private _resistanceEnemy = 1;
private _resistanceFriendly = 0;

GRLIB_side_resistance setFriend [GRLIB_side_enemy, _resistanceEnemy];
GRLIB_side_enemy setFriend [GRLIB_side_resistance, _resistanceEnemy];
GRLIB_side_resistance setFriend [GRLIB_side_friendly, _resistanceFriendly];
GRLIB_side_friendly setFriend [GRLIB_side_resistance, _resistanceFriendly];

if (KP_liberation_civrep_debug > 0) then {[format ["changeCR finished - New value: %1", KP_liberation_civ_rep], "CIVREP"] call KPLIB_fnc_log;};
if (KP_liberation_civrep_debug > 0) then {[format ["%1 getFriend %2: %3 - %1 getFriend %4: %5", GRLIB_side_resistance, GRLIB_side_enemy, (GRLIB_side_resistance getFriend GRLIB_side_enemy), GRLIB_side_friendly, (GRLIB_side_resistance getFriend GRLIB_side_friendly)], "CIVREP"] call KPLIB_fnc_log;};

CR_Mutex = false;