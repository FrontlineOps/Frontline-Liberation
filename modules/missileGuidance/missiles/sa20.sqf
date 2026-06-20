[
	"SA-20",
	"ARH",
	{
		params ["_missilePos", "_targetPos", "_heading", ["_forceDetonate", false]];
		private _dist = _targetPos distance _missilePos;

		private _detonate = false;
		if(_dist <= 80 || _forceDetonate) then {

			
			private _toTarget = _missilePos vectorFromTo _targetPos;
			
			private _cos = _heading vectorCos _toTarget;
			// 30 degrees
			if(_cos >= 0.86602540378) then {
				private _toMissile = _targetPos vectorFromTo _missilePos;
					
				private _pos = _targetPos vectorAdd (_toMissile vectorMultiply 5);
				private _vel = (_toTarget vectorMultiply 40);
				private _right = _toTarget vectorCrossProduct [0,0,1];

				private _up = _toTarget vectorCrossProduct _right;
				private _eff = "Karmakut_Proximity_Detonate_Effect" createVehicle ASLtoAGL _missilePos;
				private _det = "Karma_SA20_Proximity" createVehicle ASLtoAGL _pos;

				_det setVelocity (_vel vectorMultiply 25);
				_eff setVelocity _vel;
				
				_eff setVectorDirAndUp [_toTarget, _up];
				_det setVectorDirAndUp [_toTarget, _up];
				_detonate = true;

				systemChat format ["SA-20 Detonate %1", _dist];
			};

		};
		_detonate;
			
		
	},
	[
		["VLS ROTATE", 0],
		["SA-20 MID-COURSE", 0]
	],
	[99.9, 120, 10000],
	[40, 40, false, 0.5],
	[
		"karmakut_sa20_missile"
	],
	true
] call IADS_RegisterNewMissileClass;