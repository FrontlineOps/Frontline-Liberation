/**
	Zero-Effort-Miss Guidance (Optimal Control Theory)

	The zero effort miss happens at Time-To-Go = 0s and would be when both the pursuer and target's paths would intersect.
	The ZEM is the vector from the target's position at Tgo = 0 subtracted by the pursuer's position at Tgo = 0.
	In theory, if the zero effort miss vector is 0, then the pursuer and the target will be on a collision course.

	Mathematically, simplistic ZEMG and augmented proportional navigation are equal. It is the further supersets of ZEMG that enhance the control law to be more optimal than Pro Nav.
	
	This guidance control law requires access to kinematic information and the resulting acceleration command is naturally perpendicular to the Line-Of-Sight.
	In real life, ZEMG and other supersets of pro nav are used by the most advanced missiles, typically seen on missiles supported by a radar which gives access to kinematic information easily.


	ZEM = LOS + relative velocity of target to pursuer (closing velocity) * time to go

	Acceleration = ZEM normal to the LOS * N / Tgo^2

 */
[
	"ZEMG",
	{
		params ["_deltaTime", "_targetState", "_guidanceState", "_missileID", "_flightParams", "_timeElapsed", "_missile"];
		
		_guidanceState params ["_yaw", "_pitch", "_oldMissilePos", "_missilePos", "_missileVelocity", "_missileHeading"];
		
		_targetState params ["_lastVelocity", "_oldTargetPos", "_target", "_lastAcceleration", "_targetPos", "_targetVelocity"];


		private _navGain = 3;
		private _los = _targetPos vectorDiff _missilePos;
		private _closingVelocity = _targetVelocity vectorDiff _missileVelocity;
		private _timeToGo = (_targetPos distance _missilePos) / vectorMagnitude _closingVelocity;

		_timeToGo = 0.01 max _timeToGo;

		_timeToGo = 30 min _timeToGo;

		private _zem = _los vectorAdd (_closingVelocity vectorMultiply _timeToGo);
		private _zemToLOS = _missileHeading vectorMultiply (_zem vectorDotProduct _los);
		private _zemNormalToLOS = _zem vectorDiff _zemToLOS;

		private _aCmd = _zemNormalToLOS vectorMultiply (_navGain / (_timeToGo * _timeToGo));

		private _aCmdInModelSpace = _missile vectorWorldToModelVisual _aCmd;

		if((_aCmdInModelSpace#2) < 0 && (_missilePos#2 < _targetPos#2) && (_missilePos#2 < 20)) then {
			_aCmdInModelSpace set [2, 1];

			_aCmd = _missile vectorModelToWorldVisual _aCmdInModelSpace;
		};

		[_aCmd, false, format ["Tgo: %1", _timeToGo]]
	}
] call IADS_RegisterNewGuidanceLaw;