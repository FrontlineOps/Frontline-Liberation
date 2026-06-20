// THIS OCCURS IN THE SCHEDULED SPACE, SO THIS IS ASYNCHRONOUS.
private _initialTimeElapsed = 0;
GRLIB_last_battlegroup_time = 0;

BATTLESPACE_BATTLEGROUPS_ALLOWED = true;
publicVariable "BATTLESPACE_BATTLEGROUPS_ALLOWED";
waitUntil {

    sleep 1;
    if (([] call KPLIB_fnc_getPlayerCount) >= 35) then {
        _initialTimeElapsed = _initialTimeElapsed + 1;
    };

    (((count active_sectors) >= 1) ||
    (_initialTimeElapsed >= 3000))
};
diag_log format ["Battlegroup initial delay finished at %1, battlegroup timers beginning (%2, %3)", CBA_missionTime, count active_sectors, _initialTimeElapsed];
private _sleeptime = 0;
while {GRLIB_csat_aggressivity > 0.9 && GRLIB_endgame == 0} do {

    _sleeptime =  GRLIB_battlegroup_Interval;
    // Enforce a battlegroup at earliest 30m if someone procs a sector at 
    if(isNil "BATTLEGROUP_SPAWN_COUNT") then {
        BATTLEGROUP_SPAWN_COUNT = 0;
    };
    if(BATTLEGROUP_SPAWN_COUNT == 0) then {
        _sleeptime = 1800;
    };

    sleep _sleeptime;

    private _scalingFactor = ([] call KPLIB_fnc_getOpforFactor);
    private _scaledBattlegroupCap = (GRLIB_battlegroup_cap * _scalingFactor) + 65;
    _scaledBattlegroupCap = 100 max _scaledBattlegroupCap;
    _scaledBattlegroupCap = GRLIB_battlegroup_cap min _scaledBattlegroupCap;

    waitUntil {
        sleep 1;
        (([] call KPLIB_fnc_getPlayerCount) >= 40)
        && {([] call KPLIB_fnc_getOpforCap) < _scaledBattlegroupCap}
        && {diag_fps > 15.0}
        && (BATTLESPACE_BATTLEGROUPS_ALLOWED == true) 
        && ((diag_tickTime - GRLIB_last_battlegroup_time) >= 900) // Here just to make re-activating battlegroups not be instant spawn.
    };
    diag_log format ["Evaluating to spawn random battlegroup at %1, active sectors at %2, player count at %3", CBA_missionTime, count active_sectors, ([] call KPLIB_fnc_getPlayerCount)];
    private _bluforSector = "";
    // Use networked data to determine a more accurate frontline to enable higher distances and no attacks on backline blufor sectors
    // TODO: Take distances between sectors into account to select the closest blufor sector to OPFOR that still satisfies the player count requirements
    if(!isNil "NETWORKED_SECTORS_GET_DISTANCE_FROM_FRONTLINE") then {
        private _possibleSectors = [];

        {
            private _sector = _x;
            private _networkedSectorData = NETWORKED_SECTORS get _sector;

            if(isNil "_networkedSectorData") then {
                diag_log format ["Networked Sector Data unavailable for %1", _sector];
                continue;
            };

            private _links = _networkedSectorData get "Links";
            private _frontlineBlufor = false;
            {
                private _linkedSector = _x;

                
                
                private _cost = [_linkedSector, blufor_sectors] call NETWORKED_SECTORS_GET_DISTANCE_FROM_FRONTLINE;

                if(_cost == 0) exitWith { _frontlineBlufor = true };
            } forEach _links;
            
            private _currentCount = 0;
            if(_frontlineBlufor == true) then {

                
                {
                    if(_currentCount >= 5) exitWith {};
                    if((_x distance2D (getMarkerPos _sector)) <= 2500) then {
                        _currentCount = _currentCount + 1;
                    };
                } forEach (allPlayers - entities "HeadlessClient_F");
            };

            if(_currentCount >= 5) then {
                _possibleSectors pushBack _sector;
            };
        } forEach blufor_sectors;

        if((count _possibleSectors) > 0) then {
            _bluforSector = _possibleSectors select (round (random ((count _possibleSectors) - 1)));
        };
    };
    diag_log format ["Random Battlegroup advanced evaluation failed, falling back to pure random selection"];
    // Fallback
    if(_bluforSector == "") then {
        private _acceptableSectors = [];
        {
            private _sector = _x;
            private _currentCount = 0;
            {
                if(_currentCount >= 5) exitWith {};
                if((_x distance2D (getMarkerPos _sector)) <= 2500) then {
                    _currentCount = _currentCount + 1;
                };
            } forEach (allPlayers - entities "HeadlessClient_F");

            if(_currentCount >= 5) then { _acceptableSectors pushBack _sector; };
        } forEach blufor_sectors;

        if((count _acceptableSectors) > 0) then {
            _bluforSector = selectRandom _acceptableSectors;
        };
    };
    diag_log format ["Random Battlegroup point evaluated to be %1", _bluforSector];
    // TODO: Utilize NETWORKED_SECTORS_GET_LINK_UP_TO_DEPTH like SAMs to spawn the battlegroup.
    [_bluforSector, (random 100) < 45] spawn spawn_battlegroup;
};
