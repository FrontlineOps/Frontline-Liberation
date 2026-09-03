/*-----------------------------------------------------------------------------------------------*\
 | Copyright © 2022 pasta. 				                                                          |
 | All Rights Reserved.                                                                           |
 | Usage:                                 											              |
 | [ _vehicle, _timeInSeconds, _respawnLocation, _respawnDir ] call KPLIB_fnc_setupVehicle		  |
\*-----------------------------------------------------------------------------------------------*/

_this params [
	[ "_vehicle", objNull, [ objNull ] ],
	[ "_time", 0, [ 0 ] ],
	[ "_spawnLocation", [], [ [] ] ],
	[ "_rotation", 0, [ 0 ] ]
];

//--- Setup local variables
setVariables = {

	_this params [
		[ "_vehicle", objNull, [ objNull ] ],
		[ "_time", 0, [ 0 ] ],
		[ "_spawnLocation", [], [ [] ] ],
		[ "_rotation", 0, [ 0 ] ]
	];

	//--- Set
	{
		_vehicle setVariable [ _x select 0, _x select 1, true ];
	} forEach [
		[ "respawnTime", _time ],
		[ "spawnLocation", _spawnLocation ],
		[ "rotation", _rotation ],
		[ "class", typeOf _vehicle ]
	];

};

//--- Variables
[ _vehicle, _time, _spawnLocation, _rotation ] call setVariables;

//--- Check if it has the variable
if ( isNil { _vehicle getVariable "KP_liberation_preplaced" } ) then { _vehicle setVariable [ "KP_liberation_preplaced", true, true ] };

_vehicle removeAllEventHandlers "Killed";
[_vehicle,
	"Killed", 
	{
		_this params [ "_vehicle", "_killer" ];

		[	
			{ 
				
				private _vehicle = _this select 0;
				private _vehicleClass = _vehicle getVariable [ "class", "" ];

				private _veh = _vehicleClass createVehicle [ 0, 0, 0 ];
				
				//--- Disable for a few seconds
				_veh allowDamage false;
				_veh enableSimulation false;
				_veh enableDynamicSimulation false;
				_veh setVariable [ "KP_liberation_preplaced", true, true ];
				
				//systemChat format [ "%1 %2 %3", _veh getVariable "respawnTime", _veh getVariable "spawnLocation", _veh getVariable "rotation" ];
				private _vehicles = nearestObjects [ _vehicle, [], 2, true ];
				[ _veh, _vehicle getVariable "respawnTime", _vehicle getVariable "spawnLocation", _vehicle getVariable "rotation" ] call setVariables;

				//--- Vehicle nearby
				[
					{
						private _vehicle = _this select 0;
						private _veh = _this select 1;

						_veh allowDamage true;
						_veh enableSimulation true;
						_veh enableDynamicSimulation true;

						private _vehicles = _this select 2;
						private _type = typeof _veh;

						private _spawnLocation = _veh getVariable [ "spawnLocation", [] ];
						
						//--- Set variables
						( _this select 3 ) call KPLIB_fnc_setupVehicle;

						//--- Delete old vehicle
						{

							if ( 
								!alive _x 
								|| { _vehicle iskindof "Air"  }
								|| { _vehicle iskindof "Car" } 
								|| { _vehicle iskindof "Boat" } 
								|| { _vehicle iskindof "Ship" } 
								|| { _vehicle iskindof "Support" }
								|| { _type == "B_Slingload_01_Repair_F" }
								|| { _type == "B_Slingload_01_Ammo_F" }
								|| { _type == "B_Slingload_01_Fuel_F" }
								|| { _type == "Land_Cargo40_military_green_F" }
								|| { _type in ( missionNamespace getVariable [ "ResupplyCrateSourceClasses ", [] ] ) }
							) then { deleteVehicle _x; };

						} forEach _vehicles;

						//--- Set pos
						_veh setPos _spawnLocation;
					},
					[ 
						_vehicle, 
						_veh, 
						_vehicles,
						[ 
							_veh, 
							_vehicle getVariable "respawnTime", 
							_vehicle getVariable "spawnLocation", 
							_vehicle getVariable "rotation" 
						]
					],
					3
				] call CBA_fnc_waitAndExecute;
			},
			[ _vehicle ],
			_vehicle getVariable [ "respawnTime", 0 ]
		]  call CBA_fnc_waitAndExecute;
	} 
] call CBA_fnc_addBISEventHandler;
