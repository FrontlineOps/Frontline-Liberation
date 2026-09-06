
IADS_LaunchWarning = {
	params ["_target"];
	private _vehicle = vehicle player;

	if(!(player isEqualTo cameraOn)) then {
		_vehicle = cameraOn;
	};
	if(_vehicle isEqualTo player) exitWith {};

	if(!(_target isEqualTo _vehicle)) exitWith {};
	
	private _valid = false;
	private _kind = toLower (typeOf _vehicle);
	{
		if((_kind find _x) > -1) exitWith { _valid = true };
	} forEach IADS_RWR_CAPABLE;
	if(_valid) then {
		private _lastPlay = _vehicle getVariable ["LastLaunchWarningPlay", 0];

		if((CBA_missionTime - 1) > _lastPlay) then {
			_vehicle setVariable ["LastLaunchWarningPlay", CBA_missionTime];
			playSound "Karmakut_LaunchWarning";
			playSound "Karmakut_StatusChange";
		};
		
	};

};

IADS_NewThreat = {
	params ["_target"];
	private _vehicle = vehicle player;

	if(!(player isEqualTo cameraOn)) then {
		_vehicle = cameraOn;
	};
	if(_vehicle isEqualTo player) exitWith {};

	if(!(_target isEqualTo _vehicle)) exitWith {};
	
	private _valid = false;
	private _kind = toLower (typeOf _vehicle);
	{
		if((_kind find _x) > -1) exitWith { _valid = true };
	} forEach IADS_RWR_CAPABLE;
	if(_valid) then {

		private _lastPlay = _vehicle getVariable ["LastNewThreatPlay", 0];

		if((CBA_missionTime - 1) > _lastPlay) then {
			_vehicle setVariable ["LastNewThreatPlay", CBA_missionTime];
			playSound "Karmakut_ALR69NewThreat";
		};
	};
};


IADS_RWR_CAPABLE = [
	"f16",
	"ah64",
	"ah1z",
	"ch47",
	"mh60",
	"hh60",
	"uh60",
	"a10",
	"f14",
	"f15",
	"f22",
	"av8b",
	"melb",
	"uh1y",
	"ac130"
];
IADS_RWR = {
	(_this select 0) params [["_nextTick", 0], ["_lastCount", 0], ["_lastCountSet", diag_tickTime], ["_lastVehicle", objNull]];
	

	if(_nextTick > diag_tickTime) exitWith {
		
	};

	private _vehicle = vehicle player;

	if(!(player isEqualTo cameraOn)) then {
		_vehicle = cameraOn;
	};
	if(_vehicle isEqualTo player) exitWith {};


	if(!(_lastVehicle isEqualTo _vehicle)) then {
		private _valid = false;
		private _kind = toLower (typeOf _vehicle);
		{
			if((_kind find _x) > -1) exitWith { _valid = true };
		} forEach IADS_RWR_CAPABLE;
		if(_valid && _vehicle isKindOf "Air") then {
			playSound "Karmakut_RWRPowerUp";
		};
		(_this select 0) set [3, _vehicle];
	};
	// If aircraft count hits 1 and lastCount is different or count is 1 and lastCount is equal but lastCountSet has large enough period
	// Then play RWR StatusChange to indicate moved into critical threat

	
	private _currentTrack = _vehicle getVariable ["TrackData", createHashMap];


	private _count = _currentTrack getOrDefault ["Count", -1];



	if(_count == 1 && _lastCount != _count) then {
		playSound "Karmakut_StatusChange";
	};
	private _lastTargetSet = _vehicle getVariable ["RMissileTargetSet", 0];

	if((_count >= 2 && ((diag_tickTime - 1.5) <= _lastCountSet)) || ((CBA_missionTime - 1.5) <= _lastTargetSet)) then {

		if(_lastCount != _count && _lastCount < 2 && _count >= 2) then {
			playSound "Karmakut_StatusChange";
		};

		playSound "Karmakut_MissileAlert";
		(_this select 0) set [0, diag_tickTime + 1.70];
	};

	(_this select 0) set [1, _count];
	if(_lastCount != _count && _count > -1) then {
		(_this select 0) set [2, diag_tickTime];
	};


};

[
	{
		_this call IADS_RWR
	},
	0.1,
	[]
] call CBA_fnc_addPerFrameHandler;
