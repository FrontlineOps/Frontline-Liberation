/** 
	Utilize APN with a set offset in height to simulate a loft
*/
[
	"ZEMG LOFT",
	{
		params ["_deltaTime", "_targetState", "_guidanceState", "_missileID", "_flightParams", "_timeElapsed", "_missile", ["_desiredLoftAngle", 10], ["_stopAtDistance", 2000], ["_stopAtTime", 10]];
		
		_guidanceState params ["_yaw", "_pitch", "_oldMissilePos", "_missilePos", "_missileVelocity", "_missileHeading"];
		
		_targetState params ["_lastVelocity", "_oldTargetPos", "_target", "_lastAcceleration", "_targetPos", "_targetVelocity"];

		_flightParams params ["_pitchRate", "_yawRate", "_isBangBangGuidance", "_stabilityCoefficient"];
		


		private _range = _targetPos distance _missilePos;
		private _closingRate = vectorMagnitude _missileVelocity;
		private _timeToGo = (_missilePos distance _targetPos) / _closingRate;
		private _los = vectorNormalized (_targetPos vectorDiff _missilePos); 
		private _angleToTarget = acos (_missileHeading vectorCos _los);
		private _atMinRotationAngle = _angleToTarget >= (0.5 * _pitchRate * _timeToGo);
		private _newTargetPos = _targetPos;
		private _newOldTargetPos = _oldTargetPos;
		if(_atMinRotationAngle == false) then {
			(_missile call BIS_fnc_getPitchBank) params ["_pitch", "_bank"];
		
			if(_pitch < _desiredLoftAngle) then {

				
				_newTargetPos = _newTargetPos vectorAdd [0,0, _range * sin _desiredLoftAngle];
				_newOldTargetPos = _newOldTargetPos vectorAdd [0,0, _range * sin _desiredLoftAngle];

			};
			private _zDiff = (_missilePos select 2) - (_targetPos select 2);
			_atMinRotationAngle = _zDiff > (_range / 3);
		};

		

		private _zemg = "ZEMG" call IADS_GetGuidanceLaw;

		private _result = [_deltaTime, [_lastVelocity, _newOldTargetPos, _target, _lastAcceleration, _newTargetPos, _targetVelocity], _guidanceState, _missileID, _flightParams, _timeElapsed, _missile] call _zemg;


		private _aCmdBase = _result select 0;
		private _done = false;



		if(_atMinRotationAngle || (_targetPos distance2D _missilePos) <= _stopAtDistance || _timeToGo < _stopAtTime) then {
			if(IADS_SAM_DEBUG == true) then {
				systemChat format ["%1 | %2 | %3", _atMinRotationAngle, (_targetPos distance2D _missilePos) <= _stopAtDistance, _timeToGo < _stopAtTime];
			};
			_done = true;
		};
		
		[_aCmdBase, _done, format ["Angle %1\n%2", _angleToTarget, _result param [2, ""]]]
	}
] call IADS_RegisterNewGuidanceLaw;