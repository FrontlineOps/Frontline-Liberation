
/**
	Guidance Phases: We utilize an array of guidance control laws for each phase of flight.
		When the previous guidance control law returns TRUE, then the next control law will be used (assuming there is one)
		This can be used to simulate that the first stage of the missile is to use the booster engine to loft up high for lower drag, etc..
		An optional 'timeout' parameter can be used in which, once the cumulative time in the current control law has elapsed, it will switch to the next guidance law.
	Current Phase:
		The current phase of the guidance law we are using
	Accumulator:
		How much time has passed
 */
IADS_GuidanceComputer = {
(_this select 0 ) params [
	["_guidancePhases", []],
	["_seeker", {}],
	["_fuzing", {}],
	["_missileID", -1],
	["_missile", objNull],
	["_flightParams", [30, 30, false, 0.4]],
	["_seekerPerformance", [90, 45, 10000]],
	["_initialTargetData", [objNull, []]],
	["_launchVehicle", objNull],
	["_currentPhase", 0],
	["_accumulator", 0],
	["_phaseAccumulator", 0],
	["_missAccumulator", 0],
	["_targetState", []],
	["_guidanceState", []],
	["_miscState", []]
];






if((isNull _missile) || (!(alive _missile)) || (_missileID < 0)) exitWith {
	_guidanceState params ["_yaw", "_pitch", "_oldMissilePos", "_missilePos", "_missileVelocity", "_missileHeading"];
	_targetState params ["_lastVelocity", "_oldTargetPos", "_target", "_lastAcceleration", ["_targetPos", []], "_targetVelocity"];
	if(!isNull _target || !(_targetPos isEqualTo [])) then {

		if((_missilePos#2) > 10) then {
			private _detonate = [_missilePos, _targetPos, _missileHeading, true] call _fuzing;
		};
	};
	[_this select 1] call CBA_fnc_removePerFrameHandler;
};






if(_guidancePhases isEqualTo []) exitWith {
	if (IADS_SAM_DEBUG) then {systemChat "Guidance initiated without guidance laws";};
	[_this select 1] call CBA_fnc_removePerFrameHandler;
};



if(accTime <= 0 || isGamePaused) exitWith {};

if(_targetState isEqualTo []) exitWith {

	_initialTargetData params ["_initialTarget", "_initialTargetPos"];
	// TODO: Refactor this when active radar homings are added to just fire as pitbull
	if((isNull _initialTarget) && _initialTargetPos isEqualTo []) exitWith {
		if (IADS_SAM_DEBUG) then {systemChat "Guidance initiated without valid initial target";};
		[_this select 1] call CBA_fnc_removePerFrameHandler;
	};

	private _newTargetState = [];
	if((isNull _initialTarget)) then {
		_newTargetState = [[0,0,0], _initialTargetPos, objNull, [0,0,0], _initialTargetPos, [0,0,0]];
	} else {
		_newTargetState = [velocity _initialTarget, getPosASLVisual _initialTarget, _initialTarget, [0,0,0], getPosASLVisual _initialTarget, velocity _initialTarget];
	};
	private _yaw = getDir _missile;

	private _pitchBank = _missile call BIS_fnc_getPitchBank;

	_pitchBank params ["_pitch", "_bank"];
	_guidanceState = [_yaw, _pitch, getPosASLVisual _missile];
	(_this select 0) set [13, _newTargetState];
	(_this select 0) set [14, _guidanceState];
};
_guidanceState params ["_yaw", "_pitch", "_lastMissilePos"];

_targetState params ["_lastVelocity", "_lastPos", "_target", "_lastAcceleration"];

_target = [_missile, _seekerPerformance, _targetState, _guidanceState, _launchVehicle, _accumulator] call _seeker;





private _deltaTime = diag_deltaTime * accTime;

if(_accumulator < 1.1 && vectorMagnitude (velocity _missile) < 10) then {
	[_missile, (vectorDir _missile) vectorMultiply 10] remoteExec ["setVelocity", 0];
};


private _heading = vectorDirVisual _missile;
private _missilePos = getPosASLVisual _missile;
private _missileVelocity = velocity _missile;



_guidanceState set [3, _missilePos];
_guidanceState set [4, _missileVelocity];
_guidanceState set [5, _heading];



private _targetPos = _lastPos;
private _targetVelocity = _lastVelocity;

if(!(isNull _target)) then {
	_targetPos = _target modelToWorldVisualWorld (getCenterOfMass _target);
	_targetVelocity = velocity _target;
	private _targetVelocityFromHeading = _heading vectorMultiply (_heading vectorDotProduct _targetVelocity);

	_targetVelocity = _targetVelocity vectorDiff _targetVelocityFromHeading;

	
	_targetState set [4, _targetPos];
	_targetState set [5, _targetVelocity];
};






private _los = _targetPos vectorDiff _missilePos;
private _losOld = _lastPos vectorDiff _lastMissilePos;

private _losUnit = vectorNormalized _los;
private _likeness = (_losUnit) vectorCos (vectorNormalized _missileVelocity);

private _velMag =  vectorMagnitude (_missileVelocity);

if(_likeness < 0.1 || _velMag <= 250 || _accumulator >= 28) then {
	if(_accumulator >= 5) then {
		(_this select 0) set [12, _missAccumulator + _deltaTime];
	};
};
private _mag = vectorMagnitude _missileVelocity;



if(_missAccumulator >= 1.5) exitWith {
	"ACE_ammoExplosionLarge" createVehicle ASLtoAGL _missilePos;
	deleteVehicle _missile;
	[_this select 1] call CBA_fnc_removePerFrameHandler;
};






private _detonate = [_missilePos, _targetPos, _heading, false, _target] call _fuzing;

if(_detonate) exitWith {
	// if(!isNull _target) then {
	// 	systemChat format ["Full kill"];
	// 	_target allowDamage true;
	// 	_target setDamage 1;

	// 	{
	// 		_x setDamage 1;
	// 	} forEach (crew _target);
		
	// };
	deleteVehicle _missile;
	[_this select 1] call CBA_fnc_removePerFrameHandler;
};






private _guidancePhase = _guidancePhases select _currentPhase;
private _newPhase = _currentPhase;

private _guidanceTimeout = _guidancePhase param [1, 0];


if(_guidanceTimeout > 0) then {

	if(_phaseAccumulator >= _guidanceTimeout) then {
		private _nextPhase = _guidancePhases param [_currentPhase + 1, nil];

		if(!isNil { _nextPhase }) then {
			_guidancePhase = _nextPhase;
			_newPhase = _currentPhase + 1;
		};
		
	};
};

private _guidanceLawName = _guidancePhase select 0;


private _guidanceLaw = _guidanceLawName call IADS_GetGuidanceLaw;

private _result = [_deltaTime, _targetState, _guidanceState, _missileID, _flightParams, _accumulator, _missile] call _guidanceLaw;


private _aCmd = _result param [0, [0,0,0]];
private _phaseCompleted = _result param [1, false];
private _debugText = _result param [2, ""];
private _overrideYawPitchChange = _result param [3, []];






[_deltaTime, _aCmd, _missile, _flightParams, _guidanceState, _accumulator, _missileID, format ["%1 - %2 - %3", _missileID, (IADS_ActiveMissiles get _missileID) get "type", _guidanceLawName ], _overrideYawPitchChange] call IADS_MissileSteering;


if(IADS_SAM_DEBUG == true) then {

	hintSilent (_debugText + format ["\nPhase: %1\nT Velocity: %2\nC: %3\n%4", _currentPhase, _targetVelocity, _aCmd, _likeness]);
};



if(_phaseCompleted) then {
	private _nextPhase = _guidancePhases param [_currentPhase + 1, nil];

	if(!isNil { _nextPhase }) then {
		_guidancePhase = _nextPhase;
		_newPhase = _currentPhase + 1;
	};
};




_targetState set [0, _targetVelocity];
_targetState set [1, _targetPos];
_guidanceState set [2, _missilePos];
(_this select 0) set [9, _newPhase];
(_this select 0) set [10, _accumulator + _deltaTime];
(_this select 0) set [11, _phaseAccumulator + _deltaTime];
(_this select 0) set [13, _targetState];
(_this select 0) set [14, _guidanceState];




};
