[
	"PAC-2/GEM",
	"BASIC",
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
		["PATRIOT MID-COURSE", 0]
	],
	[99.8, 80, 10000],
	[40, 40, false, 0.99],
	[
		"ammo_Missile_mim145"
	]
] call IADS_RegisterNewMissileClass;