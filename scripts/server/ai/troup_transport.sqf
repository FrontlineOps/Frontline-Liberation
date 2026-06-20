params [
    ["_transVeh", objNull, []],
    ["_shouldDismount", false, []],
    ["_startPoint", []]
];

if (isNull _transVeh) exitWith {};

sleep 1;

private _transGrp = (group (driver _transVeh));
private _start_pos = getpos _transVeh;
private _objPos =  [_startPoint] call KPLIB_fnc_getNearestBluforObjective;
private _unload_distance = 500 + (random 300);
private _crewcount = count crew _transVeh;

if(_objPos isEqualTo []) exitWith {
    diag_log format ["Troop Transport AI Group %1 could not find nearest blufor objective", groupId _grp];
};


if ((alive _transVeh) && (alive (driver _transVeh))) then {
    _infGrp = createGroup [GRLIB_side_enemy, true];


    private _cargoSpots = fullCrew [_transVeh, "cargo", true];

    private _squadSize = count _cargoSpots;


    if(_squadSize <= 2) exitWith {};


    // Each entry = their chance
    private _squadAdditions = [opfor_heavygunner, opfor_marksman, opfor_rpg, opfor_grenadier, opfor_aa, opfor_at];

    if(air_weight > 40) then {
        _squadAdditions append [opfor_aa, opfor_at, opfor_grenadier];
    };

    if(armor_weight > 40) then {
        _squadAdditions append [opfor_rpg, opfor_rpg, opfor_rpg, opfor_rpg];
    };

    if(infantry_weight > 40) then {
        _squadAdditions append [opfor_heavygunner, opfor_sharpshooter, opfor_sniper];
    };


    private _baseSquad = [opfor_squad_leader, opfor_medic];

    private _willHaveRto = (random 100) <= 15;

    if(_willHaveRto == true) then {
        _baseSquad pushBack opfor_rto;
    };


    while {(count _baseSquad < _squadSize)} do {
        _baseSquad pushBack selectRandom _squadAdditions;
    };
    
    {
        private _unit = [_x, _start_pos, _infGrp, "PRIVATE", 0.5] call KPLIB_fnc_createManagedUnit;
        _unit moveInCargo _transVeh;
    } foreach _baseSquad;

    while {(count (waypoints _infGrp)) != 0} do {deleteWaypoint ((waypoints _infGrp) select 0);};

    sleep 3;

    private _transVehWp =  _transGrp addWaypoint [_objPos, 0,0];
    _transVehWp setWaypointType "TR UNLOAD";
    _transVehWp setWaypointCompletionRadius 200;

    private _infWp = _infGrp addWaypoint [_objPos, 0];
    _infWp setWaypointType "GETOUT";
    _infWp setWaypointCompletionRadius 200;

    _infWp synchronizeWaypoint [_transVehWp];

    waitUntil {
        sleep 5;

        private _nearby = false;
        {
            if((vehicle _x) isKindOf "Air") then { continue };
            if((_transVeh distance _x) <= _unload_distance) exitWith {
                _nearby = true;
            };
        } forEach (allPlayers - (entities "HeadlessClient_F"));
        !(alive _transVeh) ||
        !(alive (driver _transVeh)) ||
        (((_transVeh distance _objPos) <= _unload_distance) && !(surfaceIsWater (getpos _transVeh))) ||
        _nearby
    };


    {unassignVehicle _transVeh} forEach (units _infGrp);
    _infGrp leaveVehicle _transVeh;
    (units _infGrp) allowGetIn false;

    private _infWp_2 = _infGrp addWaypoint [getpos _transVeh, 250];
    _infWp_2 setWaypointType "MOVE";
    _infWp_2 setWaypointCompletionRadius 5;

    sleep 2;

    while {(count (waypoints _transGrp)) != 0} do {deleteWaypoint ((waypoints _transGrp) select 0);};

    if(_shouldDismount) then {
        _transVehWp = _transGrp addWaypoint [getPos _transVeh, 0];

       
        _transVehWp setWaypointType "GETOUT";
        _transGrp leaveVehicle _transVeh;

        
        sleep 2;
        (units _transGrp) joinSilent _infGrp;

    };

    sleep 2;

    [_infGrp, _objPos] spawn battlegroup_ai;
};
