[
	"AIM-120",
	"PLACEHOLDER",
	{
		params ["_missilePos", "_targetPos", "_heading"];
		private _dist = _targetPos distance _missilePos;

		private _detonate = false;
		if(_dist <= 30) then {
			private _toTarget = _missilePos vectorFromTo _targetPos;
			private _cos = _heading vectorCos _toTarget;
			if(_cos >= 0.65) then {
				"HelicopterExploBig" createVehicle ASLtoAGL _missilePos;
				"HelicopterExploBig" createVehicle ASLtoAGL _missilePos;
				_detonate = true;
			};
			
		};
		_detonate;
	},
	[
		["AIM-120 LOFT", 0]
	],
	[99.4, 120, 10000],
	[25, 25, false, 0.2],
	[
		"FIR_AIM120"
	]
] call IADS_RegisterNewMissileClass;
