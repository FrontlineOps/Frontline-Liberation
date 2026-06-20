params [
    ["_objectivePos", ""],
    ["_squadLimit", 3],
    ["_sizeOfSquad", 9],
    ["_reinforcements", false],
    ["_reinforcementTownName", ""],
    ["_debug", false]
];

//sectors_airspawn-future 
//    no spawns more than 15k
//    no blufor within 5k


private _spawnsector = ([sectors_airspawn, [_objectivePos], {(markerpos _x) distance _input0}, "DESCEND"] call BIS_fnc_sortBy) select 0;
private _spawnClassesToUse = nil;

{
    private _readinessRequired = _x select 0;
    private _classes = _x select 1;

    if(_readinessRequired <= combat_readiness) then {
        _spawnClassesToUse = _classes;
    };
} forEach opfor_halo_air;

private _vehicle = [markerPos _spawnsector, selectRandom _spawnClassesToUse, false, true, true] call KPLIB_fnc_spawnVehicle;

_vehicle engineOn true;

private _spawnPos = getPos _vehicle;

_spawnPos = getPos _vehicle;

private _pilot_group = (group ((crew _vehicle) select 0));
(_pilot_group) setVariable ["acex_headless_blacklist", true];
(_pilot_group) setVariable ["Vcm_Disable",true, true];


private _vectorToObj =  _objectivePos vectorFromTo _spawnPos;

private _vectorRight = [_vectorToObj select 1, (_vectorToObj select 0) * -1, 0];

private _randomPos = _objectivePos vectorAdd [0, 0, 450];
//_randomPos = _randomPos vectorAdd (_vectorToObj vectorMultiply (250 + (random 500)));
//_randomPos = _randomPos vectorAdd (_vectorRight vectorMultiply (-500 + (random 1000)));
_randomPos = _randomPos vectorAdd (_vectorToObj vectorMultiply (250 + (random 250)));
_randomPos = _randomPos vectorAdd (_vectorRight vectorMultiply (-500 + (random 500)));
private _terrainHeight = getTerrainHeightASL _randomPos;

_spawnHeight = 500;

if (_vehicle isKindOf "Plane") then 
{
    _spawnHeight = 1500;
};

_vehicle setPosASL [_spawnPos select 0, _spawnPos select 1, _terrainHeight + _spawnHeight];

private _vectorDir =  _spawnPos vectorFromTo _randomPos;

private _dirTo = _spawnPos getDir _randomPos;


_vehicle setDir _dirTo;
_vehicle setVelocity [sin(_dirTo) * 60, cos(_dirTo) * 60, 0];
[_vehicle, false] remoteExec ["setCollisionLight", _vehicle];

{
    [_x, "FSM"] remoteExec ["disableAI", _x];
    [_x, "LIGHTS"] remoteExec ["disableAI", _x];
    
} forEach (crew _vehicle);



private _vectorDirNoZ = [_vectorDir select 0, _vectorDir select 1, 0];

// Covers diagonal corner to the opposite diagonal corner which is longer than straight left-right or up-down.
private _distanceToFly = worldSize * 1.42;

private _actualFlightPos = (_spawnPos vectorAdd (_vectorDirNoZ vectorMultiply _distanceToFly)) vectorAdd [0,0,450];


_waypoint = _pilot_group addWaypoint [_actualFlightPos, 0];
_waypoint setWaypointType "MOVE";
_waypoint setWaypointSpeed "NORMAL";
_waypoint setWaypointBehaviour "CARELESS";
_waypoint setWaypointCompletionRadius 1000;

_waypoint = _pilot_group addWaypoint [_randomPos, 100];
_waypoint setWaypointType "TR UNLOAD";
_waypoint setWaypointSpeed "NORMAL";
_waypoint setWaypointBehaviour "CARELESS";
_waypoint setWaypointCompletionRadius 1000;

_pilot_group setCurrentWaypoint [_pilot_group, 1];


private _pfeh = [
    {
        
        private _args = _this select 0;
        private _handle = _this select 1;

        private _vehicle = _args select 0;
        private _terrainHeight = _args select 1;
        private _randomPos = _args select 2;
        private _actualFlightPos = _args select 3;

        if(!(alive _vehicle)) exitWith {
            [_handle] call CBA_fnc_removePerFrameHandler;
        };

    
        private _terminalPhase = _vehicle getVariable ["terminalFlight", false];
        private _earlyPhase = _vehicle getVariable ["earlyFlight", true];

        private _height = _terrainHeight + 500;

        if(_terminalPhase) then {
            doStop (crew _vehicle);
            (crew _vehicle) doMove _actualFlightPos;
            (group _vehicle) setSpeedMode "FULL";
        } else {
            doStop (crew _vehicle);
            (crew _vehicle) doMove _randomPos;
            if(_earlyPhase) then {
                (group _vehicle) setSpeedMode "FULL";
            } else {
                (group _vehicle) setSpeedMode "LIMITED";
            }
        };
        //[_vehicle, [_height, _height, _height]] remoteExec ["flyInHeightASL", _vehicle]; - Height. 
        //[_vehicle, _height] remoteExec ["flyInHeight", _vehicle]; - Height.

        
    },
    5,
    [_vehicle, _terrainHeight, _randomPos, _actualFlightPos]
] call CBA_fnc_addPerFrameHandler;
[
    {
        params ["_objectivePos", "_vehicle", "_reinforcements", "_reinforcementTownName", "_debug", "_randomPos"];


        private _inDistance = ((getPos _vehicle) distance2D _randomPos <= 5000);

        private  _alive = alive _vehicle;
        (_inDistance || !_alive);
    },
    {
        params ["_objectivePos", "_vehicle", "_reinforcements", "_reinforcementTownName", "_debug", "_randomPos"];
        

        if(alive _vehicle) then {
            _vehicle setVariable ["earlyPhase", false, true];
            if(!_reinforcements) then {
    
                if(
                    (alive _vehicle)
                ) then {
                    [_objectivePos] remoteExec ["remote_call_incoming_airdrop"];
                };
            } else {
                if(
                    (alive _vehicle) && !_debug
                ) then {
                    ["lib_reinforcements",[_reinforcementTownName]] remoteExec ["bis_fnc_shownotification"];
                };
            };
        };
    },
    [_objectivePos, _vehicle, _reinforcements, _reinforcementTownName, _debug, _randomPos]
] call CBA_fnc_waitUntilAndExecute;


[
    {
        params ["_objectivePos", "_vehicle", "_reinforcements", "_randomPos"];
        !(alive _vehicle) || (damage _vehicle > 0.2 ) || ((getPos _vehicle) distance2D _randomPos <= 1000)
    },
    {
        params ["_objectivePos", "_vehicle", "_reinforcements", "_randomPos", "_squadLimit", "_sizeOfSquad"];
        if(alive _vehicle) then {
            
            private _para_units = [];
            private _para_groups = [];


            // Each entry = their chance
            private _squadAdditions = [opfor_heavygunner, opfor_marksman, opfor_rpg, opfor_grenadier, opfor_aa, opfor_at];

            if(air_weight > 40) then {
                _squadAdditions append [opfor_aa, opfor_aa, opfor_aa];
            };

            if(armor_weight > 40) then {
                _squadAdditions append [opfor_rpg, opfor_rpg, opfor_rpg, opfor_rpg];
            };

            if(infantry_weight > 40) then {
                _squadAdditions append [opfor_heavygunner, opfor_sharpshooter, opfor_sniper];
            };


            [_objectivePos, _vehicle, _squadLimit, _sizeOfSquad, _squadAdditions, _reinforcements] call spawn_paratroopers;
        };
        
    },
    [_objectivePos, _vehicle, _reinforcements, _randomPos, _squadLimit, _sizeOfSquad]
    
] call CBA_fnc_waitUntilAndExecute;

[
    {
        params ["_vehicle", "_actualFlightPos"];
        (!(alive _vehicle)) ||
        (!(alive (driver _vehicle))) ||
        (((getPos _vehicle) distance2D _actualFlightPos) <= 1000)
    },
    {
        params ["_vehicle", "_actualFlightPos"];
        if((alive _vehicle) && (alive (driver _vehicle))) then {
            {
                deleteVehicle _x;
            } forEach crew _vehicle;
            deleteVehicle _vehicle;
        };
    },
    [_vehicle, _actualFlightPos]
] call CBA_fnc_waitUntilAndExecute;


