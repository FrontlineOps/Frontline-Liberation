params [
    [ "_object", objnull, [objnull] ],
    [ "_side", west, [west] ]
];

if (_side == GRLIB_side_civilian || _side == GRLIB_side_resistance) exitwith { hint "You can't deploy a PB for this side" };

private _pbCount = 0;
private _maxPBs = 0;

if (_side == GRLIB_side_friendly) then {
    _pbCount = missionnamespace getvariable [ "GRLIB_cop_count", 0 ];
    _maxPBs = missionnamespace getvariable [ "GRLIB_max_cops", 0 ];
}
else {
    _pbCount = missionnamespace getvariable [ "OPFOR_cop_count", 0 ];
    _maxPBs = missionnamespace getvariable [ "OPFOR_max_cops", 0 ];
};

if ( _pbCount >= _maxPBs ) exitwith { hint "A PB has already been deployed" };

private _canSpawn = true;
private _objectPos = getposatl _object;
private _objectRotation = getdir _object;
private _nearestFOB = [ _objectPos ] call KPLib_fnc_getNearestFOB;
private _nearestSector = "";
if (_side == GRLIB_side_friendly) then {
    _nearestSector = [ 2500, _objectPos ] call KPLib_fnc_getNearestOpforSector;
} else {
    _nearestSector = [ 2500, _objectPos ] call KPLib_fnc_getNearestBluforSector;
};
private _nearestSectorPos = getmarkerpos _nearestSector;

//--- Distance Exit
private _pbDistance = _nearestFOB distance2d _objectPos;
if ( _pbDistance < 500 ) exitwith { hint "A PB is too close" };

_pbDistance = _nearestSectorPos distance2d _objectPos;
if ( _pbDistance < 1000 && _side == GRLIB_side_friendly) exitwith { hint "This PB would be too close to an OPFOR objective (1.1K)" };
if ( _pbDistance < 950 && _side == GRLIB_side_enemy) exitwith { hint "This PB would be too close to an BLUFOR objective (1.0K)" };

//--- Increase count
_pbCount = _pbCount + 1;
if (_side == GRLIB_side_friendly) then {
    missionnamespace setvariable [ "GRLIB_cop_count", _pbCount, true ];
} else {
    missionnamespace setvariable [ "OPFOR_cop_count", _pbCount, true ];
};

//--- You ever just have an array of one thing
private _objects = [];

private _PBTentObject = "";

if (_side == GRLIB_side_friendly) then {
    _PBTentObject = "Land_Shed_06_F";
    _objects = [
        [ "Land_Shed_06_F", [ -16.0000, 11.00000,0 ], [ 1, 0, 0], false, true ],
        [ "Flag_CW_US", [ -10.0000, 7.00000,-0.3 ], [ 1, 0, 0], false, true ]
        //[ "uns_US_SearchLight", [ -9.00000, 7.70000, 0.0 ], [ 1, 0, 0], false, true ]
    ];
} else {
    _PBTentObject = "Land_House_C_12_EP1";
    _objects = [
        [ "Land_House_L_7_dam_EP1", [ -16.0000, 11.00000,0 ], [ 1, 0, 0], false, true ]
    ];
};

private _markerPos = _object modeltoworld [ -17, 11, 0 ];
_markerPos set [ 2, 0 ];

[ _markerPos, _canSpawn, 0, _side ] call KPLIB_fnc_createPBMarker;

//--- "The most aids I have ever seen in my life" - Pasta
private _allMarkers = [];

if (_side == GRLIB_side_friendly) then {
    _allMarkers = missionnamespace getvariable [ "GRLIB_all_cops", [] ];
} else {
    _allMarkers = missionnamespace getvariable [ "OPFOR_all_cops", [] ];
};

private _marker = _allMarkers select ((count _allMarkers) - 1);
[ _markerPos, _canSpawn, _pbCount - 1, _side] remoteexeccall [ "KPLIB_fnc_createPBMarker", _side ];


//--- AHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
{ 

    _x params [ "_objectclass", "_objectstart", "_objectdirection", "_objectsim", "_normal" ];

    private _placement = _object modeltoworld _objectstart;
    _placement set [ 2, _objectstart select 2 ];
    
    private _current = createvehicle [ _objectclass, _placement, [], 0, "can_collide" ]; 
    [_current,_objectsim] remoteexec [ "enablesimulation", 0 ]; 
   
    private _worldvector = _object vectormodeltoworld _objectdirection;
    _current setvectordir _worldvector; 
    
    if ( _normal ) then { _current setvectorup surfacenormal position _current } else { _current setvectorup [ 0, 0, 1 ] };
    if ( tolower typeof _current == tolower _PBTentObject ) then {
        _current setvariable [ "copmarker", _marker, true ];
        _current setvariable [ "copside", _side, true ];

        _current addeventhandler [
            "killed", 
            {
                params [ "_unit", "_killer", "_instigator", "_useeffects" ];
				[_unit] remoteExecCall ["KPLIB_fnc_queueDeadObjectCleanup", 2];
                
                private _marker = _unit getvariable ["copmarker", ""];
                private _side = _unit getVariable ["copside", GRLIB_side_friendly];

                if (_side == GRLIB_side_friendly) then {
                    ["lib_admin_notification", ["PB lost", format ["PB - %1 has been destroyed!", mapgridposition ( getmarkerpos _marker ) ], "res\notif\ui_notif_sec_los.paa" ] ] remoteexec [ "bis_fnc_shownotification" ];
                    GRLIB_all_cops = GRLIB_all_cops - [ _marker ];
                    GRLIB_cop_count = count GRLIB_all_cops;
                    publicVariable "GRLIB_all_cops";
                    publicVariable "GRLIB_cop_count";
                } else {
                    OPFOR_all_cops = OPFOR_all_cops - [ _marker ];
                    OPFOR_cop_count = count OPFOR_all_cops;
                    publicVariable "OPFOR_all_cops";
                    publicVariable "OPFOR_cop_count";
                };
                
                //--- Delete
                deletemarker _marker;
            }
        ]
    }

} foreach _objects;

hintSilent "PB Deployed!";
