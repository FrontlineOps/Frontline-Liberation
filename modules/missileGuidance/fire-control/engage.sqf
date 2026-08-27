
IADS_LaunchersUsedThisFrame = []; 
IADS_QueueFire = {
	params ["_target"];
	
	// Determine if this target is being engaged before commanding the fire. We consider an engagement if they've been fired at in the last 20 seconds.
	// Its not as effective as gaining real time which missiles are heading to it though, but its a lot of networking and state management compared to a stateless implementation.
	// TODO: Networked launches and target tracking for better engagements and allowing the use of multiple vehicles to launch on one target if the threat is deemed high enough
	
	private _track = nil;
	{
		
		if(_target isEqualTo (_x get "Entity")) exitWith {
			_track = _x;
		};
	} forEach IADS_Tracks;

	if(isNil "_track") exitWith {
	};



	private _type = typeOf _target;
	private _isOrdinance = [_type] call IADS_IsOrdinance;
	private _isRAM = [_type] call IADS_IsArtilleryOrdinance;
	private _isMissile = (_isOrdinance && !_isRAM);

	private _engagedTimers = _target getVariable ["engagementTimes", []];

	
	private _engagements =  1;
	private _rank = _track getOrDefault ["rank", 10];

	if(_rank <= 8) then {
		_engagements = 2;
	};
	if(_isOrdinance) then {
		_engagements = 1;
	};

	
	private _distanceToClosest = _track getOrDefault ["threatDistanceToClosestSystem", 12000];

	private _altitude = getPosATLVisual _target;

	_altitude = _altitude#2;
	// TODO: Maybe when there's a better way.
	
		

	if(_rank <= 4 && !_isOrdinance) then {
		_engagements = 3;
	};


	_engagedTimers = _engagedTimers select {
		(_x > (CBA_missionTime - 17))
	};
	if ((count _engagedTimers) < _engagements ) then {

		// Theoretically, the last one shot is the final one pushed to the array.
		// We make sure we fire only if it wasn't shot at in the last 5-10 seconds as well.

		private _lastEngagement = 0;
		
		if((count _engagedTimers > 0)) then {
			_lastEngagement = _engagedTimers select ((count _engagedTimers) - 1);
		};

		private _launchersUsed = [];

		private _timeout = 4;

		
		private _lastRank = _track getOrDefault ["lastRank", 10];
		// Swapped to critical, fire a missile immediately.
		if(_rank <= 3.5 && _lastRank > 3.5) then {
			_timeout = 0;
		};

		if(_lastEngagement < (CBA_missionTime - (_timeout))) then {
			// Get the closest launcher

			// TODO: Get the closest launcher as well as a bias towards the one that will be capable of a headon for intercept compared to trying to intercept a missile from the side which is significantly harder
			private _closest = -1;
			private _launcher = objNull;
			private _regularLauncherExists = false;

			
			private _potentialLaunchVehicles = [];
			IADS_LaunchVehicles = IADS_LaunchVehicles select {
				alive _x
			};
			private _hostileLaunchVehiclesToTarget = IADS_LaunchVehicles select {
				[side group _x, side group _target] call BIS_fnc_sideIsEnemy
			};

			// Figure out launcher to use
			{
				
				private _veh = _x;
				private _used = false;
				private _type = typeOf _veh;

				if(_isRAM && !(_type in IADS_CRAM)) then {
					continue;
				};
				
				if(_isMissile && !(_type in IADS_POINT_DEFENSE)) then {
					continue;
				};

				
				{
					if(_x isEqualTo _veh) exitWith {
						_used = true;
					};
				} forEach IADS_LaunchersUsedThisFrame;

				if(_used) then {
					continue;
				};

				_used = _veh getVariable ["forcedTargetSetTime", 0];

				if(_used > (CBA_missionTime)) then {
					continue;
				};


				private _distance = _x distance2D _target;
				private _slantDistance = _x distance _target;

				if(!_isRAM && (_type in IADS_CRAM)) then {
			
					if(_distance > 1000) then {
						continue;
					};
				};
				if(!_isOrdinance) then {

					

					

					if(_slantDistance > 14000) then {
						continue;
					};

					if(!(_type in IADS_CRAM) && _distance < 2250) then {
						if(_slantDistance < 3000) then {
							continue;
						};
					};
				} else {

					if(_slantDistance > 18000) then {
						continue;
					};
				};

				private _hasAmmo = false;

				{
					_x params ["_magazine", "_ammo"];

					if(_ammo > 0) exitWith {
						_hasAmmo = true;
					};
				} forEach (magazinesAmmo [_x]);

				if(!_hasAmmo) then {
					continue;
				};
				
				_potentialLaunchVehicles pushBack _x;
			} forEach _hostileLaunchVehiclesToTarget;

			if((count _potentialLaunchVehicles) > 0) then {

				private _sortedLaunchVehicles = [
					_potentialLaunchVehicles,
					[_target],
					{
						private _launcher = _x;
						private _target = _input0;


						private _isPointDefense = ((typeOf _launcher) in IADS_POINT_DEFENSE || (typeOf _launcher) in IADS_CRAM);

						private _prio = (_launcher distance2D _target) / 1000;

						
						// Point defense does not get prioritized dealing with non-missiles.
						// If its a missile, only point defense launchers are in this array so its fine.
						if(_isPointDefense) then {
							_prio = _prio + 8;
						};
						_prio
					},
					"ASCEND"
				] call BIS_fnc_sortBy;
				_launcher = _sortedLaunchVehicles#0;

			};

			if(!(isNull _launcher)) then {
				if(!(local _launcher)) exitWith {};
				IADS_LaunchersUsedThisFrame pushBack _launcher;
				

				
				_launcher setVariable ["forcedTarget", _target, true];
				_launcher setVariable ["forcedTargetPos", getPosASLVisual _target, true];
				
				if ( !((typeOf _launcher) in IADS_CRAM)) then {
					private _lastPlay = _launcher getVariable ["sirenPlayTime", 0];
					if((CBA_missionTime - _lastPlay) >= 16) then {
						playSound3D [getMissionPath "res\alarm.ogg", _launcher, false, getPosASLVisual _launcher, 5, 1, 4000];
						_launcher setVariable ["sirenPlayTime", CBA_missionTime, true];
					};
				};
				
				
				
				private _randomTime = 4 + random 1;
				private _delayInFiring = _randomTime;
				private _animDir = deg (_launcher animationPhase "mainTurret");
				// Negative is to the right
				// Positive is to the left
				// Caps at 180

				private _dir = (getDir _launcher + _animDir);


				if((typeOf _launcher) == "karmakut_tamir") then {
					if(_animDir < 0) then {
						_dir = getDir _launcher + abs _animDir;
					} else {
						_dir = getDir _launcher - _animDir;
					};
				};
				if(_dir > 360) then {
					_dir = _dir - 360;
				};

				if(_dir < 0) then {
					_dir = 360 + _dir;
				};

				private _angleToTarget = _launcher getDir _target;
				private _fixAngle = 0;

				
				private _angleTo = abs ((_angleToTarget) - (_dir - _fixAngle));
				
				if(_angleTo > 360) then {
					_angleTo = _angleTo - 360;
				};

				_delayInFiring = _angleTo / 45;
				
				
				

				


				if((typeOf _launcher) in IADS_CRAM) then {
					_randomTime = _delayInFiring + 1.75;
				} else {
					_randomTime = _delayInFiring + _randomTime;
				};
				if (IADS_DEBUG_LAUNCH) then {
					systemChat format ["Dir of launcher: %1 - Angle to target %2 - Angle diff %3 - degLauncher %4 - launcher dir %5", _dir, (_launcher getDir _target), _angleTo, deg (_launcher animationPhase "mainTurret"), getDir _launcher];
					systemChat format ["Engaging %1 - Delay in firing %2 - Cooldown %3", _target, _delayInFiring, _randomTime];
				};
				if(!((typeOf _launcher) in IADS_IGNORE_TURN)) then {

					private _pos = getPosASLVisual _target;
					if(!_isOrdinance) then {
						private _vel = (velocity _target);
						_vel set [2, 0];
						_pos = _pos vectorAdd ((_vel) vectorMultiply (_delayInFiring * 3));
						private _range = _target distance2D _launcher;
						_pos = _pos vectorAdd [0,0, _range * sin 5];
					};
					_launcher doWatch _pos;

			
			
				};

				if((typeOf _launcher) in IADS_VLS) then {
					_delayInFiring = 0;
				};

				

				
				_engagedTimers pushBack CBA_missionTime + _delayInFiring;
				_target setVariable ["engagementTimes", _engagedTimers, true];
			
				
				_launcher setVariable ["forcedTargetSetTime", CBA_missionTime + _randomTime, true];
				[
					{
						params ["_launcher", "_target"];

						if(!(alive _target)) exitWith {};
						_launcher fireAtTarget [_target, currentWeapon _launcher];

						[_target] remoteExec ["IADS_LaunchWarning", 0];
						// [_launcher, currentWeapon _launcher] call BIS_fnc_fire;
					},
					[_launcher, _target],
					_delayInFiring
				] call CBA_fnc_waitAndExecute;
				
			};
		};
	};
};
