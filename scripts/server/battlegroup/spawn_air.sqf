params [["_first_objective", ""], ["_ignoreLimit", false], ["_spawnNumber", 1]];
private _isAllowedToSpawnAir = true;

BATTLEGROUP_SPAWN_RATE = 2;

if (isNil { BATTLEGROUP_SPAWN_COUNT }) then {
    BATTLEGROUP_SPAWN_COUNT = 0;
};

if(BATTLEGROUP_SPAWN_RATE > 1) then {
    if(!_ignoreLimit) then {

        
        BATTLEGROUP_SPAWN_COUNT = BATTLEGROUP_SPAWN_COUNT + 1;

        _isAllowedToSpawnAir = (BATTLEGROUP_SPAWN_COUNT mod BATTLEGROUP_SPAWN_RATE) == 0;

        
    } else {

        BATTLEGROUP_SPAWN_COUNT = BATTLEGROUP_SPAWN_COUNT + 1;

        private _check = (BATTLEGROUP_SPAWN_COUNT mod BATTLEGROUP_SPAWN_RATE) == 0;

        if(_check) then {
            BATTLEGROUP_SPAWN_COUNT = BATTLEGROUP_SPAWN_COUNT + 1;
        };
    };
} else {
    BATTLEGROUP_SPAWN_COUNT = BATTLEGROUP_SPAWN_COUNT + 1;
};

if(!_isAllowedToSpawnAir) exitWith {};

if (opfor_air isEqualTo []) exitWith {false};

private _planes_number = ((round linearConversion [40, 100, combat_readiness, 1, 2]) min 2) max 0;



if (_planes_number < 1) exitWith {};

private _class = selectRandom opfor_air;
if(_ignoreLimit) then {
    _planes_number = _spawnNumber;
    _class = selectRandom opfor_cap;
};


if (random 100 <= 99) then
{
    _class = selectRandom opfor_cap;
};


private _spawnPoint = ([sectors_airspawn, [_first_objective], {(markerPos _x) distance _input0}, "DESCEND"] call BIS_fnc_sortBy) select 0;
private _spawnPos = [];
private _plane = objNull;
private _grp = createGroup [GRLIB_side_enemy, true];

for "_i" from 1 to _planes_number do {
    _spawnPos = markerPos _spawnPoint;
    _spawnPos = [(((_spawnPos select 0) + 500) - random 1000), (((_spawnPos select 1) + 500) - random 1000), 200];
    _plane = createVehicle [_class, _spawnPos, [], 0, "FLY"];
    createVehicleCrew _plane;
    _plane flyInHeight (500 + (random 180));
    _plane addMPEventHandler ["MPKilled", {_this spawn kill_manager}];
    [_plane] call KPLIB_fnc_addObjectInit;
    {
        _x addMPEventHandler ["MPKilled", {_this spawn kill_manager}];
        [_x] call KPLIB_fnc_addObjectInit;
    } forEach (crew _plane);
    (crew _plane) joinSilent _grp;
    sleep 1;
};

while {!((waypoints _grp) isEqualTo [])} do {deleteWaypoint ((waypoints _grp) select 0);};
sleep 1;
{_x doFollow leader _grp} forEach (units _grp);
sleep 1;

private _waypoint = _grp addWaypoint [_first_objective, 500];
_waypoint setWaypointType "MOVE";
_waypoint setWaypointSpeed "FULL";
_waypoint setWaypointBehaviour "AWARE";
_waypoint setWaypointCombatMode "RED";

_waypoint = _grp addWaypoint [_first_objective, 500];
_waypoint setWaypointType "MOVE";
_waypoint setWaypointSpeed "FULL";
_waypoint setWaypointBehaviour "AWARE";
_waypoint setWaypointCombatMode "RED";

_waypoint = _grp addWaypoint [_first_objective, 500];
_waypoint setWaypointType "MOVE";
_waypoint setWaypointSpeed "FULL";
_waypoint setWaypointBehaviour "AWARE";
_waypoint setWaypointCombatMode "RED";

for "_i" from 1 to 6 do {
    _waypoint = _grp addWaypoint [_first_objective, 500];
    _waypoint setWaypointType "SAD";
};

_waypoint = _grp addWaypoint [_first_objective, 500];
_waypoint setWaypointType "CYCLE";

_grp setCurrentWaypoint [_grp, 2];
