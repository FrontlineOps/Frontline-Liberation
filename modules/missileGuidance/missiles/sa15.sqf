[
	"SA-15",
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

				if (IADS_SAM_DEBUG) then {systemChat format ["SA-15 Detonate %1", _dist];};
			};

		};
		_detonate;
	},
	[
		["SA-15 VLS", 0],
		["SA-20 MID-COURSE", 0]
	],
	[99.75, 90, 10000],
	[27, 27, false, 0.25],
	[
		"M_9M332_AA",
		"karmakut_sa15_missile"
	],
	true
] call IADS_RegisterNewMissileClass;
