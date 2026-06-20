/**
	ZEM = LOS + relative velocity of target to pursuer (closing velocity) * time to go

	Acceleration = ZEM normal to the LOS * N / Tgo^2


	Acceleration Compensated takes target acceleration into account.
 */
[
	"ACZEMG",
	{
		params ["_deltaTime", "_targetState", "_guidanceState", "_missileID", "_flightParams", "_timeElapsed", "_missile"];
		
		_guidanceState params ["_yaw", "_pitch", "_oldMissilePos", "_missilePos", "_missileVelocity", "_missileHeading"];
		
		_targetState params ["_lastVelocity", "_oldTargetPos", "_target", "_lastAcceleration", "_targetPos", "_targetVelocity"];

		

		private _navGain = 3;
		private _los = _targetPos vectorDiff _missilePos;
		private _closingVelocity = _targetVelocity vectorDiff _missileVelocity;
		private _timeToGo = (_targetPos distance _missilePos) / vectorMagnitude _closingVelocity;

	
		_timeToGo = 0.01 max _timeToGo;

		_timeToGo = 100 min _timeToGo;

		private _zem = _los vectorAdd (_closingVelocity vectorMultiply _timeToGo);
		private _zemToLOS = _missileHeading vectorMultiply (_zem vectorDotProduct _los);
		private _zemNormalToLOS = _zem vectorDiff _zemToLOS;
		private _losUnit = vectorNormalized _los;
		private _targetAcceleration = (_targetVelocity vectorDiff _lastVelocity) vectorMultiply (1 / _deltaTime);
		private _targetAccelerationAlongLOS = _losUnit vectorMultiply (_targetAcceleration vectorDotProduct _losUnit);

		_targetAccelerationAlongLOS = _targetAcceleration vectorDiff _targetAccelerationAlongLOS;

		private _aCmd = _zemNormalToLOS vectorMultiply (_navGain / (_timeToGo * _timeToGo));

		_aCmd = _aCmd vectorAdd (_targetAccelerationAlongLOS vectorMultiply (_navGain / 2));


		private _aCmdInModelSpace = _missile vectorWorldToModelVisual _aCmd;

		if((_aCmdInModelSpace#2) < 0 && (_missilePos#2 < _targetPos#2) && (_missilePos#2 < 20)) then {
			_aCmdInModelSpace set [2, 1];

			_aCmd = _missile vectorModelToWorldVisual _aCmdInModelSpace;
		};

		[_aCmd, false, format ["Tgo: %1", _timeToGo]]
	}
] call IADS_RegisterNewGuidanceLaw