// TODO Refactor and create function
params [
    ["_spawn_markerInit", ""],
    ["_infOnly", false],
    ["_paradropDisabled", false],
    ["_desiredObjective", []]
];

private _spawn_marker = "";
private _objectivePos = [];
private _attempts = 0;

if (GRLIB_endgame == 1) exitWith {};
// false = 0, true = 1
// [mechanized, motorized]
// minimum distance from blufor, maximum distance from blufor, return nearest spawnpoint to a blufor sector?, return nearest spawnpint to the position, ignore water?, random selection of top 10 closest

if(_spawn_markerInit != "") then {
    _objectivePos = [markerPos _spawn_markerInit] call KPLIB_fnc_getNearestBluforObjective; 

    private _randomClosest = true;

    if(!(_desiredObjective isEqualTo [])) then {
        _randomClosest = false;
    };
    _spawn_marker = [[4000, 3000] select _infOnly, [12000, 12000] select _infOnly, false, markerPos _spawn_markerInit, false, _randomClosest] call KPLIB_fnc_getOpforSpawnPoint;
};

if(!(_desiredObjective isEqualTo [])) then {
    _objectivePos = [markerPos _desiredObjective] call KPLIB_fnc_getNearestBluforObjective;
};
while { ((_objectivePos isEqualTo []) && _attempts < 10)} do {

    _attempts = _attempts + 1;

    _spawn_marker = [[4000, 3000] select _infOnly, [12000, 12000] select _infOnly, false, markerPos _spawn_markerInit, false, true] call KPLIB_fnc_getOpforSpawnPoint;
    _objectivePos = [markerPos _spawn_marker] call KPLIB_fnc_getNearestBluforObjective; 
};


if(_objectivePos isEqualTo []) exitWith {
    diag_log format ["Could not find a valid blufor objective to attack for a new battlegroup at %1", _spawn_marker];
};

diag_log format ["Battlegroup will attack %1 spawning from %2", [_objectivePos] call KPLIB_fnc_getLocationName, _spawn_marker];

if !(_spawn_marker isEqualTo "") then {


    private _selected_opfor_battlegroup = [];
    private _scalingFactor = ([] call KPLIB_fnc_getOpforFactor);
    // Target Size is capped to whatever number is to the right of the min
    private _target_size = (GRLIB_battlegroup_size * _scalingFactor * (sqrt GRLIB_csat_aggressivity)) min 2;

    private _battlegroup_compositions = nil;
    
    private _paradrop = (random 100) <= 50;


    if(_paradropDisabled) then {

        _paradrop = false;
    };

   
    if(_paradrop) then {
        private _count = 1;
        // ~38 players
        if(_scalingFactor >= 0.65) then {
            _count = 2;
        };
        // ~60 players at 0.80 opfor factor
        if(_scalingFactor >= 0.80) then {
            _count = 3;
        };
        for "_i" from 1 to _count do {
            [_objectivePos, 4, 6] call send_paratroopers;
        };
        [_objectivePos] remoteExec ["remote_call_incoming"];
    } else {
        // Adjust motorized or mechanized battlegroup sizes independent of messing with difficulty settings here
        // This is important as compositions utilize a ratio of target_size
        // Depending on how you want motorized or mechanized compositions, you may end up spawning too many vehicles which end up carrying infantry so it gets too much.
        // Adjust the amount of vehicles that would spawn here
        if(_infOnly) then {
            _battlegroup_compositions = opfor_motorized_battlegroup_compositions;
            _target_size = round (_target_size * 0.5);
        } else {
            _battlegroup_compositions = opfor_mechanized_battlegroup_compositions;
            _target_size = round (_target_size * 0.75);

            
        };
        [_spawn_marker] remoteExec ["remote_call_battlegroup"];

        if (worldName in KP_liberation_battlegroup_clearance) then {
            [markerPos _spawn_marker, 15] call KPLIB_fnc_createClearance;
        };
        
        private _bluforcount = ([] call KPLIB_fnc_getPlayerCount);
        private _readiness = combat_readiness;
        private _selected_composition = nil;

        // Lower the type of battlegroup that will spawn.
        if (_bluforcount <= 40) then {
            _readiness = 40 min _readiness;
        };

        {
            private _compositionInfo = _x;


            private _readinessRequired = _compositionInfo select 0;
            private _composition = _compositionInfo select 1;

            if(_readinessRequired <= _readiness) then {
                _selected_composition = _composition;
            };

        } forEach _battlegroup_compositions;

        diag_log format ["Combat Readiness at %1, targeted size of battlegroup %2, Selected Composition for mechanized battlegroup: %3", combat_readiness, _target_size, _selected_composition];

        {
            
            private _category = _x;
            private _categoryInfo = _y;

            private _classNameMap = [_category] call compositionEnumToClassNames;

            private _spawnsTroops = [_category] call compositionEnumIsInfantryTransport;

            private _dismountsAtTheEnd = [_category] call compositionEnumWouldDismountTransport;


            private _ratio = _categoryInfo getOrDefault ["Ratio", 0];
            private _min = _categoryInfo getOrDefault ["Min", 0];
            private _max = _categoryInfo getOrDefault ["Max", 0];

            private _ceil = _categoryInfo getOrDefault ["Ceil", false];
            private _floor = _categoryInfo getOrDefault ["Floor", false];

            
            private _spawnAmount = (_target_size * _ratio);

            if(_ceil) then {
                _spawnAmount = ceil _spawnAmount;
            } else {
                if(_floor) then {
                    _spawnAmount = floor _spawnAmount;
                } else {
                    _spawnAmount = round _spawnAmount;
                };
            };

            if(_max > 0) then {
                _spawnAmount = _max min _spawnAmount;
            };

            if(_min > 0) then {
                _spawnAmount = _min max _spawnAmount;
            };

            diag_log format ["  %1 will spawn %2 vehicles", _category, _spawnAmount];

            if(_spawnAmount <= 0) then {
                continue;
            };

            

            private _spawnClassesToUse = nil;

            {
            
                private _readinessRequired = _x select 0;
                private _classes = _x select 1;

                if(_readinessRequired <= combat_readiness) then {
                    _spawnClassesToUse = _classes;
                };
            } forEach _classNameMap;

            diag_log format ["    Category %1 will use classes %2", _category, _spawnClassesToUse];

            for "_i" from 1 to _spawnAmount do {
                

                

                _vehicle = [markerpos _spawn_marker, selectRandom _spawnClassesToUse] call KPLIB_fnc_spawnVehicle;

                
                sleep 0.5;

                _nextgrp = group ((crew _vehicle) select 0);
                [_nextgrp, _objectivePos] spawn battlegroup_ai;


                if(_spawnsTroops) then {
                    [_vehicle, _dismountsAtTheEnd, _objectivePos] spawn troup_transport;
                };

            


                
            };

        } forEach _selected_composition;

        
    };

    [[_objectivePos] call KPLIB_fnc_getNearestBluforObjective] spawn spawn_air;
    
        
    


    
 


    sleep 3;

    combat_readiness = combat_readiness - (10 max (round (random 25)));
    stats_hostile_battlegroups = stats_hostile_battlegroups + 1;

    

    
};
