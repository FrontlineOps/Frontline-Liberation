[
	"Tamir",
	"BASIC", // TODO: Should be able to pick up a new target if the current one dies
	{
		params ["_missilePos", "_targetPos", "_heading", ["_forceDetonate", false], ["_target", objNull]];
		private _dist = _targetPos distance _missilePos;

		private _detonate = false;
		private _type = typeOf _target;
		private _isRAM = [_type] call IADS_IsArtilleryOrdinance;
		if(_dist <= ([30, 100] select _isRAM) || _forceDetonate) then {
			

			private _toTarget = _missilePos vectorFromTo _targetPos;
			
			private _cos = _heading vectorCos _toTarget;

			private _toMissile = _targetPos vectorFromTo _missilePos;
				
			private _pos = _targetPos vectorAdd (_toMissile vectorMultiply 5);
			private _vel = (_toTarget vectorMultiply 40);
			private _right = _toTarget vectorCrossProduct [0,0,1];

			private _up = _toTarget vectorCrossProduct _right;

			if(!_isRAM) then {
				// 30 Degrees
				if(_cos >= 0.86602540378) exitWith {
					private _eff = "Karmakut_Proximity_Detonate_Effect" createVehicle ASLtoAGL _pos;

					_eff setVelocity _vel;
					
					_eff setVectorDirAndUp [_toTarget, _up];
					_detonate = true;
				};
			} else {
				private _eff = "Karmakut_Proximity_Detonate_Effect" createVehicle ASLtoAGL _pos;

				_eff setVelocity _vel;
				
				_eff setVectorDirAndUp [_toTarget, _up];
				_detonate = true;
			};

			if(!isNull _target && _forceDetonate == false && _detonate) then {

				_target setDamage 1;
			};
			



		};
		_detonate;
	},
	[
		["ZEMG", 0]
	],
	[99, 90, 10000],
	[55, 55, false, 0.6],
	[
		"karmakut_tamir_missile"
	],
	false
] call IADS_RegisterNewMissileClass;