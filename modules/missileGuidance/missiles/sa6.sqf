[
	"SA-6",
	"ARH", // TODO: SA-6s aren't actually ARH but SARH.
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

				systemChat format ["SA-6 Detonate %1", _dist];
			};

		};
		_detonate;	
	},
	[
		["APN", 0]
	],
	[99.6, 75, 10000],
	[14.5, 14.5, false, 0.1],
	[
		"M_9M38_AA",
		"M_9M317_AA",
		"karmakut_sa6_missile"
	]
] call IADS_RegisterNewMissileClass;