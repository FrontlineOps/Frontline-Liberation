RotateEWR = {
	params ["_radarVeh", "_currentFacing", "_execCount"];
    

	_newExecCount = 0;
	if( !isNil { _execCount }) then {
		_newExecCount = _execCount;
	};

	_newExecCount = _newExecCount + 1;

	
	
	if(_newExecCount >= 120) then {
		
	
		
		diag_log format ["ROTATE EWR (%1, %2, HC: %3)", _radarVeh, _currentFacing];
		_newExecCount = 0;
	};

	

 	if (isNull _radarVeh) exitWith {
		 diag_log format ["EWR Vehicle Null"];
	 }; 
 
 	if (!(alive _radarVeh)) exitWith {
		 diag_log format ["EWR Vehicle Not Alive"];
	}; 



	_nextFacing = _currentFacing + 20;
	
	if(_nextFacing >= 360) then {
		_nextFacing = _nextFacing - 360;
	};
	
	
	
	[_radarVeh, "AUTOTARGET"] remoteExec ["disableAI", 0];
	[_radarVeh, true] remoteExec ["stop", 0];
	[_radarVeh, 1] remoteExec ["setVehicleRadar", 0];
	[_radarVeh, (_radarVeh getRelPos [100, _currentFacing])] remoteExec ["lookAt", 0];
	[RotateEWR, [_radarVeh, _nextFacing, _newExecCount], 0.5] call CBA_fnc_waitAndExecute; 
};