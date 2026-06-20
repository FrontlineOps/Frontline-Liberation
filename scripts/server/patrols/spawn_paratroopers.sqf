params ["_objectivePos", "_vehicle", "_squadLimit", "_sizeOfSquad", "_composition", "_reinforcements"];



private _para_units = [];
private _para_groups = [];

for "_i" from 1 to _squadLimit do {
	_group = createGroup [GRLIB_side_enemy, false];

	_para_groups pushBack _group;
};

diag_log format ["Created groups %1", _para_groups];
[
	{
		private _args = _this select 0;
		private _handle = _this select 1;

		private _vehicle = _args select 0;
		private _units = _args select 1;
		private _groups = _args select 2;
		private _amount = _args select 3;
		private _sizeOfSquad = _args select 4;
		private _composition = _args select 5;
		private _objectivePos = _args select 6;
		private _reinforcements = _args select 7;



		private _unitCount = (count _units);

		if(_unitCount >= _amount || !(alive _vehicle)) exitWith {

			[_handle] call CBA_fnc_removePerFrameHandler;

						
			doStop (crew _vehicle);

			_vehicle setVariable ["terminalFlight", true, true];
					
			if(!_reinforcements) then {
			{
				[_x, _objectivePos] call battlegroup_ai;
				_x deleteGroupWhenEmpty true;
			} forEach _groups;
			} else {
				{
					private _waypoint = [];
					_waypoint = _x addWaypoint [_objectivePos, 400];
					_waypoint setWaypointType "SAD";
					_waypoint = _x addWaypoint [_objectivePos, 400];
					_waypoint setWaypointType "SAD";
					_waypoint = _x addWaypoint [_objectivePos, 400];
					_waypoint setWaypointType "SAD";
					_waypoint = _x addWaypoint [_objectivePos, 400];
					_waypoint setWaypointType "CYCLE";
					_x deleteGroupWhenEmpty true;
				} forEach _groups;
			};

		};

		for "_i" from 1 to 2 do {
			
			private _unitCount = (count _units);

			if(_unitCount >= _amount) exitWith {};
			private _groupIndexToBeIn = floor (_unitCount / _sizeOfSquad);


			private _spawnSL = (_unitCount - (_groupIndexToBeIn * _sizeOfSquad)) == 0;

			private _spawnMedic = (_unitCount - (_groupIndexToBeIn * _sizeOfSquad)) == 1;

			private _canSpawnRto = (_unitCount - (_groupIndexToBeIn * _sizeOfSquad)) == 2;

			private _willHaveRto = (random 100) <= 17;
	

			

			private _spawnClass = selectRandom _composition;
			if(_spawnSL) then {
				_spawnClass = opfor_squad_leader;
			};
			if(_spawnMedic) then {
				_spawnClass = opfor_medic;
			};
			if(_willHaveRto == true && _canSpawnRto ) then {
				_spawnClass = opfor_rto;
			};

			private _heading = 90;

			if(_unitCount % 2 == 0) then {
				_heading = 270;
			};

			private _group = (_groups select _groupIndexToBeIn);
					
			private _size = sizeOf (typeOf _vehicle);
			private _vel = velocity _vehicle;
			private _offset = _vehicle getRelPos [_size, 90];

			private _vectorDir = (getPos _vehicle) vectorFromTo _offset;

			private _unitSpawnPos = ((_vehicle getRelPos [_size, 180]) vectorAdd [(_vectorDir select 0) * 15, (_vectorDir select 1) * 15, 0]);
			private _height = getPosASL _vehicle;

			_height = _height select 2;
			private _unit = [_spawnClass, _unitSpawnPos, _group, "PRIVATE", 0.5] call KPLIB_fnc_createManagedUnit;
			_unit setPosASL [_unitSpawnPos select 0, _unitSpawnPos select 1, _height - 5];
			_unit setDir (getDir _vehicle);

			_unit setVelocity _vel;
			removeBackpack _unit;
			_unit addBackPack "B_parachute";

			_units pushBack _unit;
		};
		

	},
	0.5,
	[_vehicle, _para_units, _para_groups, (_squadLimit * _sizeOfSquad), _sizeOfSquad, _composition, _objectivePos, _reinforcements]
] call CBA_fnc_addPerFrameHandler;
