[
	"AIM-9X",
	"IR",
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
		["ZEMG", 0]
	],
	[99.5, 120, 10000],
	[30, 30, false, 0],
	[
		"FIR_AIM9X"
	]
] call IADS_RegisterNewMissileClass;