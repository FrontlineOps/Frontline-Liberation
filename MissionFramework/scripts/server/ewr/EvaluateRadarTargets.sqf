EWR_TRACKFILES = [];
EWR_THREAT_RANGE = 3000;
EWR_SEARCH_RANGE = 6000;
EvaluateRadarTargets = { 
 	params ["_radarVeh", "_side", "_canPlaySound"]; 

	if (!isNil { DEBUG_AIR_RAID }) then {
		diag_log format ["EVALUATE RADAR TARGETS (%1, %2, %3)", _radarVeh, _side, _canPlaySound];
	};

	

 	if (isNull _radarVeh) exitWith {
		 diag_log format ["RADAR VEHICLE NULL"];
	 }; 
 
 	if (!(alive _radarVeh)) exitWith {
		 diag_log format ["RADAR VEHICLE NOT ALIVE"];
	 }; 
 
 	private _hasEH = _radarVeh getVariable ["KILLED_EH_SET", false];


 
	if (!_hasEH) exitWith { 
		
		diag_log format ["INITIALIZING NEW EWR %1", _radarVeh];
		_radarVeh setVariable ["KILLED_EH_SET", true, true]; 
		[_radarVeh, "Killed", {
			params ["_unit", "_killer", "_instigator", "_useEffects"]; 
			
			private _soundSource = _unit getVariable ["WEEWOOSOURCE", objNull]; 
			
			if (!(isNull _soundSource)) then { 
				deleteVehicle _soundSource; 
			}; 
		}] call CBA_fnc_addBISEventHandler;

		[_radarVeh, "Deleted", {
			params ["_entity"];
			
			private _soundSource = _entity getVariable ["WEEWOOSOURCE", objNull]; 
			
			if (!(isNull _soundSource)) then { 
				deleteVehicle _soundSource; 
			}; 
		}] call CBA_fnc_addBISEventHandler;
		// [RotateEWR, [_radarVeh, 0], 2] call CBA_fnc_waitAndExecute; 
		// diag_log format ["EWR INITIALIZED, CALL ROTATE EWR"];

		[EvaluateRadarTargets, [_radarVeh, _side, _canPlaySound], 8] call CBA_fnc_waitAndExecute;
		
	}; 
 
	private _currentRemoteTargets = listRemoteTargets _side; 
	private _airTargets = [];
	{ 
	
		private _target = _x select 0; 
		private _targetSide = side group _target; 
		
		if (_targetSide != east ) then { 
			continue; 
		}; 
		
		private _isAir = _target isKindOf "Air"; 

		private _isRAM = [typeOf _target] call IADS_IsArtilleryOrdinance;
		
		if(!_isAir || _isRAM) then { 
			continue; 
		}; 

		private _isAlive = alive _target;

		if(!_isAlive) then {
			continue;
		};
		
		private _distance = _target distance2D _radarVeh; 
		
		private _inRaidRange = _distance <= EWR_THREAT_RANGE;

		
		if(!_inRaidRange) then { 
			continue; 
		}; 
		
		_airTargets pushBack _target; 
	} forEach _currentRemoteTargets; 
		
	private _hasAirTargets = count _airTargets > 0; 

	if ( !isNil { DEBUG_AIR_RAID } ) then {
		diag_log format ["HAS AIR TARGETS %1, %2", _hasAirTargets, _airTargets];
	};

	if ( isNil { _canPlaySound }) then {
		_canPlaySound = true;
	};

	private _canStillPlaySound = _canPlaySound;

	
	if (_hasAirTargets == true) then { 
		if (!isNil { DEBUG_AIR_RAID }) then {
			diag_log format ["AIR TARGETS TRUE %1, CAN PLAY?", _airTargets, _canPlaySound];
		};
		if(_canPlaySound) then {
			// PLAY SOUND

			playSound3D [getMissionPath "res\alarm.ogg", _radarVeh, false, getPosASL _radarVeh, 5, 1, 3000];
			_canStillPlaySound = false;
		} else {
			_canStillPlaySound = true;
		};
		
	} else {
		_canStillPlaySound = true;
	};

	
	if (!isNil { DEBUG_AIR_RAID }) then {
		diag_log format ["CAN STILL PLAY? %1", _canStillPlaySound];
	};
	// May have some clipping but sound file is 16s long. 
	// 0-8s (can play sound and will play)
	// 8-16s (can't play sound even if air threats still detected since it would be 8s into the sound file and has 8s left)
	// 16-24s (can play sound, if air  threats, play again or else sound will naturally fade and stop by this point)
	[EvaluateRadarTargets, [_radarVeh, _side, _canStillPlaySound], 8] call CBA_fnc_waitAndExecute; 
	
	1
};
