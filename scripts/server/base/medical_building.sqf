KC_AUTOHEALER = {
	params ["_building", ["_disabledWhenEnemiesNearby", false]];


	if(!canSuspend) exitWith {
		_this spawn KC_AUTOHEALER;
	};

	_building allowDamage false;

	while { alive _building } do {
		if(_disabledWhenEnemiesNearby) then {
			private _enemiesNearby = (getPos _building) nearEntities [["Man", "Air", "Car", "Tank"], 1000];

			_enemiesNearby = _enemiesNearby select {

				[side _x, GRLIB_side_friendly] call BIS_fnc_sideIsEnemy
			};

			_enemiesNearby = (count _enemiesNearby) > 0;

			if(_enemiesNearby) then {
				sleep 10;
				continue;
			};
		};




		private _nearbyPlayers = (getPos _building) nearEntities ["Man", 5];


		_nearbyPlayers = _nearbyPlayers select {
			(side _x) == GRLIB_side_friendly && isPlayer _x
		};

		{
			[objNull, _x] call ace_medical_treatment_fnc_fullHeal;
		} forEach _nearbyPlayers;

		sleep 10;
	};
};