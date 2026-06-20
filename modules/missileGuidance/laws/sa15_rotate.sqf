[
	"SA-15 VLS",
	{
		params ["_deltaTime", "_targetState", "_guidanceState", "_missileID", "_flightParams", "_timeElapsed", "_missile"];
			
		_guidanceState params ["_yaw", "_pitch", "_oldMissilePos", "_missilePos", "_missileVelocity", "_missileHeading"];
		
		_targetState params ["_lastVelocity", "_oldTargetPos", "_target", "_lastAcceleration", "_targetPos", "_targetVelocity"];

		
		private _range = (_targetPos) distance2D (_missilePos);
		
		private _angle = 80;

		if(!(isNull _target)) then {

			private _type = typeOf _target;
			private _isMissile = (_type find "missile") > -1;
			_isMissile = (_isMissile || (_type find "shell") > -1);

			private _to = _missilePos vectorFromTo _targetPos;

			_angle = asin (_to#2);
	
			_angle = 80 min _angle;
		};

		_angle = 10 max _angle;
		

		private _navLaw = "ZEMG" call IADS_GetGuidanceLaw;
		private _result = [_deltaTime, _newTargetState, _guidanceState, _missileID, _flightParams, _timeElapsed, _missile] call _navLaw;
		_result set [2, format["%1\nDesired Loft Angle: %2", _result#2, _angle]];

		private _aCmdBase = _result select 0;
		private _done = false;


		(_missile call BIS_fnc_getPitchBank) params ["_pitch", "_bank"];

		if(_pitch >= _angle) then {

			_aCmdBase = [0,0,0];


		} else {
			_done = true;
		};



		private _forceVector = [0,0, -60];

		private _vel = velocity _missile;

		private _velMag = vectorMagnitude _vel;

		if(_velMag <= 5) then {
			_forceVector = [0,0,0];
		};



		[_aCmdBase, _done, _result#2, _forceVector ];
	}
] call IADS_RegisterNewGuidanceLaw;