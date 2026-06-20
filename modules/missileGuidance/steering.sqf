// Credits to some guys from the missile guidance ACE3 fork.
// Quaternion bullshit that I can't understand right now for steering.
IADS_MissileSteering = {
	params ["_deltaTime", "_commandedAcceleration", "_missile", "_flightParams", "_guidanceState", "_accumulator", "_missileID", "_navType", "_forcedPitchYawChange"];
    _guidanceState params ["_yaw", "_pitch", "_oldMissilePos", "_missilePos", "_missileVelocity", "_missileHeading"];
		
		_targetState params ["_lastVelocity", "_oldTargetPos", "_target", "_lastAcceleration", "_targetPos", "_targetVelocity"];
	_flightParams params ["_pitchRate", "_yawRate", "_isBangBangGuidance", "_stabilityCoefficient"];
	if(IADS_SAM_DEBUG == true) then {
		private _missilePosAGL = ASLToAGL (getPosASLVisual _missile);
		private _cmdAccelLocal = _missile vectorWorldToModelVisual _commandedAcceleration;
		drawIcon3D ["", [1,0,0,1], _missilePosAGL vectorAdd [0, 0, 1], 0.75, 0.75, 0, format ["cmdPitch: %1 cmdYaw %2", _cmdAccelLocal#2, _cmdAccelLocal#0], 1, 0.025, "TahomaB"];
        drawIcon3D ["\a3\ui_f\data\IGUI\Cfg\Cursors\selectover_ca.paa", [1,1,0,1], _missilePosAGL vectorAdd [0, 0, -10], 0.75, 0.75, 0, _navType, 1, 0.025, "TahomaB"];
        drawLine3D [_missilePosAGL, _missilePosAGL vectorAdd _commandedAcceleration, [1, 0, 1, 1]];
        drawIcon3D ["\a3\ui_f\data\IGUI\Cfg\Cursors\selectover_ca.paa", [0,1,0,1], _missilePosAGL vectorAdd _commandedAcceleration, 0.75, 0.75, 0, "A", 1, 0.025, "TahomaB"];

	};
	if (!isGamePaused && accTime > 0) exitWith {
        _guidanceState params ["_yaw", "_pitch"];

        _commandedAcceleration = _missile vectorWorldToModelVisual _commandedAcceleration;
        _commandedAcceleration params ["_yawChange", "", "_pitchChange"];

        if(!(_forcedPitchYawChange isEqualTo [])) then {
            _yawChange = _forcedPitchYawChange#0;
            _pitchChange = _forcedPitchYawChange#2;

            _pitchRate = 90 min _pitchRate * 2;
            _yawRate = 90 min _yawRate * 2;

            _pitchRate = 45 max _pitchRate;
            _yawRate = 45 max _yawRate;
        };

        if (isNil "_yawChange") then {
            _yawChange = 0;
        };
        if (isNil "_pitchChange") then {
            _pitchChange = 0;
        };


        private _velMag = vectorMagnitude (_missileVelocity);

        if(_velMag <= 250) then {
            _pitchRate = 90 min _pitchRate * 1.5;
            _yawRate = 90 min _yawRate * 1.5;
        };

        private _clampedPitch = (_pitchChange min _pitchRate) max -_pitchRate;
        private _clampedYaw = (_yawChange min _yawRate) max -_yawRate;
        
        // controls are either on or off, no proportional
        if (_isBangBangGuidance) then {
            private _pitchSign = if (_clampedPitch == 0) then {
                0
            } else {
                _clampedPitch / abs _clampedPitch
            };
            private _yawSign = if (_clampedYaw == 0) then {
                0
            } else {
                _clampedYaw / abs _clampedYaw
            };
            _clampedPitch = _pitchSign * _pitchRate;
            _clampedYaw = _yawSign * _yawRate;
        };

        // directional stability
        private _localVelocity = _missile vectorWorldToModelVisual (velocity _missile);
		

        private _velocityAngleYaw = (_localVelocity#0) atan2 (_localVelocity#1);
        private _velocityAnglePitch = (_localVelocity#2) atan2 (_localVelocity#1);

        // bastardized version of direction stability https://en.wikipedia.org/wiki/Directional_stability#Steering_forces
        private _forceYaw = _stabilityCoefficient * _velocityAngleYaw + _clampedYaw;
        private _forcePitch = _stabilityCoefficient * _velocityAnglePitch + _clampedPitch;

        _pitch = _pitch + _forcePitch * _deltaTime;
        _yaw = _yaw + _forceYaw * _deltaTime;


        private _multiplyQuat = {
            params ["_qLHS", "_qRHS"];
            _qLHS params ["_lhsX", "_lhsY", "_lhsZ", "_lhsW"];
            _qRHS params ["_rhsX", "_rhsY", "_rhsZ", "_rhsW"];

            private _lhsImaginary = [_lhsX, _lhsY, _lhsZ];
            private _rhsImaginary = [_rhsX, _rhsY, _rhsZ];

            private _scalar = _lhsW * _rhsW - (_lhsImaginary vectorDotProduct _rhsImaginary);
            private _imginary = (_rhsImaginary vectorMultiply _lhsW) vectorAdd (_lhsImaginary vectorMultiply _rhsW) vectorAdd (_lhsImaginary vectorCrossProduct _rhsImaginary);

            _imginary + [_scalar]
        };

        private _multiplyVector = {
            params ["_quaternion", "_vector"];

            private _real = _quaternion#3;
            private _imaginary = [
                _quaternion#0,
                _quaternion#1,
                _quaternion#2
            ];
            
            private _vectorReturn = _vector vectorAdd ((
                _imaginary vectorCrossProduct (
                    (_imaginary vectorCrossProduct _vector) vectorAdd (
                        _vector vectorMultiply _real
                    )
                )
            ) vectorMultiply 2);

            _vectorReturn
        };

        private _quaternion = [0, 0, 0, 1];

        private _temp = [0, 0, sin (-_yaw / 2), cos (-_yaw / 2)];
        _quaternion = [_quaternion, _temp] call _multiplyQuat;

        _temp = [sin (_pitch / 2), 0, 0, cos (_pitch / 2)];
        _quaternion = [_quaternion, _temp] call _multiplyQuat;
        
        private _dir = [_quaternion, [0, 1, 0]] call _multiplyVector;
        private _up = [_quaternion, [0, 0, 1]] call _multiplyVector;

		if(_accumulator < 0.5 && IADS_SAM_DEBUG == true) then {
			diag_log format ["_missileID %9: YawChange %1 | PitchChange %2 | NewYaw %3 | NewPitch %4 | ForceYaw %5 | ForcePitch %6 | OldYaw %7 | OldPitch %8 | VelocityLocal %10 | VelocityAngleYaw %11 | VelocityAnglePitch %12", _yawChange, _pitchChange, _yaw, _pitch, _forceYaw, _forcePitch, _guidanceState#0, _guidanceState#2, _missileID, _localVelocity, _velocityAngleYaw, _velocityAnglePitch];
		};
        _missile setVectorDirAndUp [_dir, _up];


        _guidanceState set [0, _yaw];
        _guidanceState set [1, _pitch];

		_dir
    };
};