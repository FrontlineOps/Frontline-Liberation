[
	"APN",
	{
		params ["_deltaTime", "_targetState", "_guidanceState", "_missileID", "_flightParams", "_timeElapsed", "_missile"];
		
		_guidanceState params ["_yaw", "_pitch", "_oldMissilePos", "_missilePos", "_missileVelocity", "_missileHeading"];
		
		_targetState params ["_lastVelocity", "_oldTargetPos", "_target", "_lastAcceleration", "_targetPos", "_targetVelocity"];

		_flightParams params ["_pitchRate", "_yawRate", "_isBangBangGuidance", "_stabilityCoefficient"];



		

		private _Vc = _targetVelocity vectorDiff _missileVelocity;
		private _los = _targetPos vectorDiff _missilePos;
		private _losOld = _oldTargetPos vectorDiff _oldMissilePos;

		private _distanceToTarget = _targetPos distance _missilePos;
		
		
		private _losUnit = vectorNormalized _los;
		private _losOldUnit = vectorNormalized _losOld;
		private _targetAcceleration = (_targetVelocity vectorDiff _lastVelocity) vectorMultiply (1 / _deltaTime);

		private _targetAccelerationAlongLOS = _losUnit vectorMultiply (_targetAcceleration vectorDotProduct _losUnit);

		_targetAccelerationAlongLOS = _targetAcceleration vectorDiff _targetAccelerationAlongLOS;


		private _losDelta = _losUnit vectorDiff _losOldUnit;

		private _losRate = 0;
		if(_deltaTime != 0) then {
			_losRate = 1 * (vectorMagnitude _losDelta) / _deltaTime;
		};

		// TODO: Maybe this is also part of some params 
		private _navGain = 3;
		private _lateralAcceleration = _navGain * _losRate;





		private _aCmd = _Vc vectorMultiply _lateralAcceleration;
		_aCmd = _aCmd vectorAdd (_losDelta vectorMultiply (0.5 * _navGain * vectorMagnitude _targetAccelerationAlongLOS));


		private _aCmdAlongLOS = _losUnit vectorMultiply (_aCmd vectorDotProduct _losUnit);

		_aCmdAlongLOS = _aCmd vectorDiff _aCmdAlongLOS;
		


		private _debug = "";

		if (IADS_SAM_DEBUG == true) then {
			_debug = format ["%1", _targetState];

			drawIcon3D ["\a3\ui_f\data\IGUI\Cfg\Cursors\selectover_ca.paa", [0,1,0,1], ASLToAGL _targetPos, 0.75, 0.75, 0, "Target Position", 1, 0.025, "TahomaB"];
		};

		private _aglTPos = ASLtoAGL _targetPos;
		private _missileAboveGround = ASLtoAGL _missilePos;


		private _aCmdInModelSpace = _missile vectorWorldToModelVisual _aCmd;
		if((_aCmdInModelSpace#2) < 0 && (_missilePos#2 < _targetPos#2) && (_missilePos#2 < 30) && _timeElapsed < 1) then {
			_aCmdInModelSpace set [2, 1];

			_aCmd = _missile vectorModelToWorldVisual _aCmdInModelSpace;
		};

		[_aCmdAlongLOS, false, _debug]
	}
] call IADS_RegisterNewGuidanceLaw;
