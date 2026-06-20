[
	"RIM-162 ESSM",
	"PLACEHOLDER",
	{
		params ["_missilePos", "_targetPos", "_heading"];
		private _dist = _targetPos distance _missilePos;

		private _detonate = false;
		if(_dist <= 25) then {
			private _toTarget = _missilePos vectorFromTo _targetPos;
			private _cos = _heading vectorCos _toTarget;
			if(_cos >= 0.65) then {
				"HelicopterExploBig" createVehicle ASLtoAGL _missilePos;
				"HelicopterExploBig" createVehicle ASLtoAGL _missilePos;
				"HelicopterExploBig" createVehicle ASLtoAGL _missilePos;
				"HelicopterExploBig" createVehicle ASLtoAGL _missilePos;
				"HelicopterExploBig" createVehicle ASLtoAGL _missilePos;
				_detonate = true;
			};

		};
		_detonate;
			
		
	},
	[
		["ZEMG", 1],
		["AIM-120 LOFT", 0]
	],
	[99, 80, 10000],
	[40, 40, false, 0.5],
	[
		"itc_land_ammo_mn230_essm",
		"FIR_SM2_BLK4"
	],
	true
] call IADS_RegisterNewMissileClass;