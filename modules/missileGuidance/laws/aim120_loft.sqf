// Utilizes ZEMG; Switch to ACZEMG once Tgo is low enough
[
	"AIM-120 LOFT",
	{
		params ["_deltaTime", "_targetState", "_guidanceState", "_missileID", "_flightParams", "_timeElapsed", "_missile"];
		
		_guidanceState params ["_yaw", "_pitch", "_oldMissilePos", "_missilePos", "_missileVelocity", "_missileHeading"];
		
		_targetState params ["_lastVelocity", "_oldTargetPos", "_target", "_lastAcceleration", "_targetPos", "_targetVelocity"];

		
		private _closingVelocity = _targetVelocity vectorDiff _missileVelocity;
		private _timeToGo = (_targetPos distance _missilePos) / vectorMagnitude _closingVelocity;

		private _range = _targetPos distance _missilePos;

		private _angle = _timeToGo * (_timeToGo / 2);

		_angle = 10;

		private _zDiff = _targetPos#2 - _missilePos#2;

		if(_zDiff <= -1500) then {
			_angle = 3;
		};

		if(_timeToGo <= 2) then {
			_angle = 0;
		};



		if(!(isNull _target)) then {

			private _type = typeOf _target;
			private _isMissile = (_type find "missile") > -1;
			_isMissile = (_isMissile || (_type find "shell") > -1);

			if(_isMissile) then {
				_angle = 0;
			};
		};
		private _newTargetState = [_lastVelocity, _oldTargetPos vectorAdd [0,0,sin _angle * _range], _target, _lastAcceleration, _targetPos vectorAdd [0,0, sin _angle * _range], _targetVelocity];

		private _navLaw = "ZEMG" call IADS_GetGuidanceLaw;


		private _result = [_deltaTime, _newTargetState, _guidanceState, _missileID, _flightParams, _timeElapsed, _missile] call _navLaw;

		_result
	}
] call IADS_RegisterNewGuidanceLaw;