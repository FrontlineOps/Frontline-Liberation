/*

	'sweep' the sky at every interval, evaluating targets
	Tracks are kept in a state each time they appear without being occluded
	Once tracks appear for long enough, a launch will be ordered, of which a target is told to aim at, then fire at forcefully
	Guidance logic will hook onto the fired missile even if it did not initialize with a missileTarget as we will set a variable

	TODO: How to coordinate with other things in the network and not just local 

*/

IADS_Tracks = [];

IADS_LaunchVehicles = [];
IADS_SearchRadars = [];
[] call compileFinal preprocessFileLineNumbers "modules\missileGuidance\fire-control\catalog.sqf";


[] call compileFinal preprocessFileLineNumbers "modules\missileGuidance\fire-control\calculateImpactPoint.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\missileGuidance\fire-control\scan.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\missileGuidance\fire-control\engage.sqf";

[
	{ _this call IADS_Sweep; ITC_LAND_CIWS = false; },
	0.1,
	[0]
] call CBA_fnc_addPerFrameHandler;

IADS_DEBUG_LAUNCH = false;

IADS_DISABLE_AUTOFIRE = {
	(_this select 0) params ["_vehicle"];

	if(IADS_DEBUG_LAUNCH) then {
		systemChat format ["Try to disable fire"];
	};

	if((isNull _vehicle) || !(alive _vehicle)) exitWith {
		[_this select 1] call CBA_fnc_removePerFrameHandler;
	};

    if (!local _vehicle || {isPlayer gunner _vehicle}) exitWith {};

	(group _vehicle) setCombatMode "BLUE";

	_vehicle setUnitCombatMode "BLUE";

	_vehicle disableAI "TARGET";
	_vehicle disableAI "AUTOTARGET";
	_vehicle disableAI "PATH";

	{
		_x setUnitCombatMode "BLUE";
		_x disableAI "TARGET";
		_x disableAI "AUTOTARGET";
		_x disableAI "PATH";
	} forEach (crew _vehicle);
};
{
	[
		_x, 
		"init",
		{
			private _vehicle = _this#0;
            IADS_LaunchVehicles pushBackUnique _vehicle;
            if (_vehicle getVariable ["IADS_FireControlRegistered", false]) exitWith {};
            _vehicle setVariable ["IADS_FireControlRegistered", true];

			
			_vehicle setVehicleReportRemoteTargets ((typeOf _vehicle) in IADS_SearchRadarClasses);
			_vehicle setVehicleReceiveRemoteTargets true;
			_vehicle setVehicleReportOwnPosition true;
			[
				{
					_this call IADS_DISABLE_AUTOFIRE;
				},
				2,
				[_vehicle]
			] call CBA_fnc_addPerFrameHandler;
		},
		false,
		[],
		true
	] call CBA_fnc_addClassEventHandler;
} forEach IADS_LaunchVehicleClasses;


{
	[
		_x, 
		"init", {
			private _vehicle = _this#0;
            IADS_SearchRadars pushBackUnique _vehicle;
            if (!local _vehicle) exitWith {};
			_vehicle setVehicleRadar 1;
			_vehicle setVehicleReportRemoteTargets true;
			_vehicle setVehicleReceiveRemoteTargets true;
			_vehicle setVehicleReportOwnPosition true;
		},
		false,
		[],
		true
	] call CBA_fnc_addClassEventHandler;
} forEach IADS_SearchRadarClasses;



IADS_REVEAL_TARGET = {
	params ["_toWhom", "_what", "_accuracy"];

	_toWhom reveal [_what, _accuracy];
};


if(isServer) then {

	IADS_REVEAL_TARGET_PFH = {

		private _airVehicles = [];
		{
			private _veh = vehicle _x;
			if(!(_veh isEqualTo _x)) then {

				if(_veh isKindOf "Air") then {
					_airVehicles pushBack _veh;
				};
			};
		} forEach allPlayers;

		{

			if ((side _x) != GRLIB_side_enemy) then {
				continue;
			};
			private _leader = leader _x;
			private _grp = _x;
			{
				if((_leader distance2D _x) <= 2500) then {

					[_grp, _x, 4] remoteExec ["IADS_REVEAL_TARGET", _grp];
				};
			} forEach _airVehicles;
		} forEach allGroups;
	};

	[
		{
			_this call IADS_REVEAL_TARGET_PFH;
		},
		10,
		[]
	] call CBA_fnc_addPerFrameHandler;
};
