/*-----------------------------------------------------------------------------------------------*\
 | Copyright © 2022 pasta. 				                                                          |
 | All Rights Reserved.                                                                           |
 | Usage:                                 											              |
 | You don't call this on the client that would totally and utterly braindead like 100% 		  |
\*-----------------------------------------------------------------------------------------------*/

if ( !isserver ) exitwith {};

private _vehicle = param [ 0, objnull, [objnull] ];
private _respawnTime = _vehicle getvariable "respawnTime";

if ( isnull _vehicle || { isnil "_respawnTime" } ) exitwith {};

private _vehicleClass = _vehicle getvariable [ "class", "" ];
private _veh = _vehicleClass createvehicle [ 0, 0, 0 ];

//--- Disable for a few seconds
_veh allowdamage false;
_veh enablesimulationglobal false;
_veh enabledynamicsimulation false;

private _vehicles = nearestobjects [ _vehicle, [], 2, true ];
[ _veh, _respawnTime, _vehicle getvariable "spawnLocation", _vehicle getvariable "rotation" ] call fnc_setVariables;

//--- Vehicle nearby
[
	{
		private _vehicle = _this select 0;
		private _veh = _this select 1;

		_veh allowdamage true;
		_veh enablesimulationglobal true;
		_veh enabledynamicsimulation true;
		_veh setvariable [ "KP_liberation_preplaced", true, true ];

		private _vehicles = _this select 2;
		private _type = typeof _veh;

		private _spawnLocation = _veh getvariable [ "spawnLocation", [] ];
		
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
				|| { _type in ( missionnamespace getvariable [ "ResupplyCrateSourceClasses ", [] ] ) }
			) then { deletevehicle _x; };

		} foreach _vehicles;

		//--- Set pos
		if ( surfaceiswater _spawnLocation ) then { _veh setposasl agltoasl _spawnLocation } else { _veh setposworld _spawnLocation }
	},
	[ 
		_vehicle, 
		_veh, 
		_vehicles,
		[ 
			_veh, 
			_vehicle getvariable "respawnTime", 
			_vehicle getvariable "spawnLocation", 
			_vehicle getvariable "rotation" 
		]
	],
	3
] call CBA_fnc_waitAndExecute