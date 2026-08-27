IADS_CHAFF_SEARCH_DIST = 1250;
[
	"ARH",
	{
		params ["_missile", "_seekerPerformance", "_targetState", "_guidanceState"];

		_guidanceState params ["_yaw", "_pitch", "_lastPosition", "_missilePos", "_missileVelocity", "_missileHeading", ["_nextSeekerTick", 0], ["_lastFlares", []]];

		_targetState params ["_lastVelocity", "_lastPos", "_target", "_lastAcceleration", "_targetPos", "_targetVelocity"];

		_seekerPerformance params [["_irCMResistance", 99], ["_gimbalLimit", 45], ["_newAcquireRange", 10000]];
		


		if(diag_tickTime < _nextSeekerTick) exitWith {

			if (IADS_SAM_DEBUG == true) then {
				{

					if((isNull _x)) then {
						continue;
					};
					private _cmPos = ASLToAGL getPosASLVisual _x;
					private _color = [0,0,1,1];
					// Convert to local space, y doesn't matter in local space as that's front / back, we're interested in azimuth + elevation represented by x and z. 
					private _lastVelocityInModelSpace = _missile vectorWorldToModelVisual _lastVelocity;
					_lastVelocityInModelSpace set [1, 0];
					private _cmVelocityInModelSpace = _missile vectorWorldToModelVisual velocity _x;
					_cmVelocityInModelSpace set [1, 0];


					private _angleBetweenTwo = acos (_lastVelocityInModelSpace vectorCos _cmVelocityInModelSpace);

					// Linearly decrease to 0% chance if the velocity of the flare travelling compared to the target is too different
					private _likelihoodToBeAirplane = 100 - 100 * ((_gimbalLimit min (abs _angleBetweenTwo)) / _gimbalLimit);


					_likelihoodToBeAirplane = 0 max _likelihoodToBeAirplane;

					if(_likelihoodToBeAirplane > 25) then {
						_color = [1,1,0,1];
					};
			

					if(_target isEqualTo _x) then {
						private _missileHeadingInModelSpace = _missile vectorWorldToModelVisual vectorDirVisual _missile;


						private _los = vectorNormalized ((getPosASLVisual _x) vectorDiff (getPosASLVisual _missile));
						private _losInModelSpace = _missile vectorWorldToModelVisual _los;


						_angleBetweenTwo = acos (_missileHeadingInModelSpace vectorCos _losInModelSpace);

						_color = [1,0,0,1];
					};

					drawIcon3D ["\a3\ui_f\data\IGUI\Cfg\Cursors\selectover_ca.paa", _color, _cmPos, 0.75, 0.75, 0, format ["θ %1 - %2", _angleBetweenTwo, _likelihoodToBeAirplane], 1, 0.025, "TahomaB"];
				} forEach (_lastFlares + [_target]);

			};
			_targetState set [2, _target];
			_target
		};

		_guidanceState set [6, diag_tickTime + 0.5];


		// If the target is still within the LOS angle and no obstructions then move to next stage for looking for flares
		// Otherwise try to find a new target thats in the air infront and within new acquire range
		private _occluded = true;
		private _withinGimbalLimit = false;

		if(!(isNull _target)) then {
			_occluded = [_missile, _target] call IADS_TargetOccluded;
			_withinGimbalLimit = [_missile, _target, _gimbalLimit] call IADS_WithinGimbalLimit;
			
		};

	
		



		private _newTarget = _target;
		if(_occluded || !_withinGimbalLimit) then {
			_newTarget = objNull;
		} else {
			
			private _losUnit = vectorNormalized ((getPosASLVisual _newTarget) vectorDiff (_missilePos));

			// Convert to local space so we can get rid of the forward / back

			private _losUnitModelSpace = _missile vectorWorldToModelVisual _losUnit;

			private _vel = vectorNormalized (velocity _newTarget);

			private _velModelSpace = _missile vectorWorldToModelVisual _vel;

			_velModelSpace set [1, 0];
			_losUnitModelSpace set [1, 0];

			private _likeness = _velModelSpace vectorCos _losUnitModelSpace;
			// ~89 deg
			// Notched
			
			if((abs _likeness) <= 0.026) then {
				if (IADS_SAM_DEBUG) then {systemChat format ["Notched %1", _likeness];};
				_newTarget = objNull;
			};
		};
		
		private _tPos = _targetPos;
		private _tVel = _targetVelocity;

		if(!(isNull _newTarget)) then {
			_tPos = getPosASLVisual _newTarget;
			_tVel = velocity _newTarget;
		};

		private _objects = (ASLToAGL _tPos) nearObjects IADS_CHAFF_SEARCH_DIST;
		// Everything nearby that is a potential target
		_objects = _objects select {

			if (_x isEqualTo _missile) then {
				continue;
			};
			private _posATL = getPosATLVisual _x;

			if((_posATL#2) <= 5) then {
				continue;
			};


			private _countermeasureType = configOf _x >> "weaponLockSystem";
			private _isTarget = false;
			if (isNumber _countermeasureType) then {
				_isTarget = (8 == getNumber _countermeasureType);
			};

			if (isText _countermeasureType) then {
				_isTarget = ("8" in getText _countermeasureType);
			};


			if(_x isKindOf "Air" && (count (crew _x)) > 0) then {
				_isTarget = true;
			};

			



			if(!_isTarget) then {
				continue;
			};



			private _losUnit = vectorNormalized ((getPosASLVisual _x) vectorDiff (_missilePos));

			// Convert to local space so we can get rid of the forward / back

			private _losUnitModelSpace = _missile vectorWorldToModelVisual _losUnit;

			private _vel = vectorNormalized (velocity _x);

			private _velModelSpace = _missile vectorWorldToModelVisual _vel;

			_velModelSpace set [1, 0];
			_losUnitModelSpace set [1, 0];

			private _likeness = _velModelSpace vectorCos _losUnitModelSpace;
			// ~89 deg
			// Notched
			
			if((abs _likeness) <= 0.026) then {
				continue;
			};

			private _targetOccluded = [_missile, _x] call IADS_TargetOccluded;
			if(_targetOccluded) then {
				continue;
			};

			
			private _targetInGimbalLimits = [_missile, _x, _gimbalLimit] call IADS_WithinGimbalLimit;
			_targetInGimbalLimits
		};


		// Sort by range as closest ones will block radar of things further behind
		
		private _potentials = [];
		private _previousDirections = [];
		// Then loop through, only adding ones that are not obstructed by others

		// Now loop through the remaining ones and find the best target.


		// TODO: Redo ev erything here, chaff doesn't work like flares
		// Chaff only works if the deplyoing aircraft hides behind it
		private _targetVelocityInModelSpace = _missile vectorWorldToModelVisual _tVel;
		_targetVelocityInModelSpace set [1, 0];
		{
			if(isNull _newTarget) then {
				_newTarget = _x;
				continue;
			};
			private _hasPotential = false;

			private _flareVelocityInModelSpace = _missile vectorWorldToModelVisual velocity _x;
            _flareVelocityInModelSpace set [1, 0];

			private _angleBetweenTwo = acos (_targetVelocityInModelSpace vectorCos _flareVelocityInModelSpace);

			// Linearly decrease to 0% chance if the velocity of the flare travelling compared to the target is too different
			private _likelihoodToBeAirplane = 100 - 100 * ((_gimbalLimit min (abs _angleBetweenTwo)) / _gimbalLimit);

			// Likelihood goes less when the flares are further away as well.
			// No penalty until 40n
			// becomes 0% chance when its 125m away
			_likelihoodToBeAirplane = _likelihoodToBeAirplane - (0 max (-40 + (_x distance _tPos) / 3));

			_likelihoodToBeAirplane = 0 max _likelihoodToBeAirplane;

			if(_likelihoodToBeAirplane > 50) then {
				_hasPotential = true;
				private _chance = random 100;
				

				if(_chance > _irCMResistance) then {
					_newTarget = _x;
				};
			};


			if (IADS_SAM_DEBUG == true) then {
				private _flarePos = ASLToAGL getPosASLVisual _x;
				private _color = [0,0,1,1];

				if(_hasPotential) then { _color = [1,1, 0,1 ]; };

				if(_newTarget isEqualTo _x) then {
					continue;
				};

				drawIcon3D ["\a3\ui_f\data\IGUI\Cfg\Cursors\selectover_ca.paa", _color, _flarePos, 0.75, 0.75, 0, format ["θ %1 - %2", _angleBetweenTwo, _likelihoodToBeAirplane], 1, 0.025, "TahomaB"];

			};
		} forEach _objects;
		if(!isNull _newTarget) then {
			_newTarget setVariable ["RMissileTargetSet", CBA_missionTime, true];
		};
		_guidanceState set [7, _objects];
		_targetState set [2, _newTarget];
		_missile setMissileTarget _newTarget;

		_newTarget

	}
] call IADS_RegisterNewSeeker;
