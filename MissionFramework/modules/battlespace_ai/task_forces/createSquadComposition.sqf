BATTLESPACE_TASK_FORCES_GET_SQUAD_COMPOSITION = {
	params ["_size", ["_overrideSquadAdditions", []], ["_ambush", false], ["_allowSmallSquad", false]];
	if (_size <= 2) exitWith {
		if (!_allowSmallSquad || {_size <= 0}) exitWith {[]};
		[opfor_squad_leader, opfor_medic] select [0, _size]
	};

	// Each entry = their chance
	private _squadAdditions = [opfor_heavygunner, opfor_marksman, opfor_rpg, opfor_grenadier, opfor_aa, opfor_at];

	if(air_weight > 40) then {
		_squadAdditions append [opfor_aa, opfor_aa, opfor_aa];
	};

	if(armor_weight > 40) then {
		_squadAdditions append [opfor_rpg, opfor_rpg, opfor_rpg, opfor_rpg];
	};

	if(infantry_weight > 40) then {
		_squadAdditions append [opfor_heavygunner, opfor_sharpshooter, opfor_rto];
	};

	if((count _overrideSquadAdditions) > 0) then {
		_squadAdditions = _overrideSquadAdditions;
	};


	private _baseSquad = [opfor_squad_leader, opfor_medic];

	if(!_ambush) then {
		private _rtoChance = (random 100);
		private _willHaveRto = false;
		_willHaveRto = _rtoChance <= 12;
		if(_willHaveRto == true) then {
			_baseSquad pushBack opfor_rto;
		};
	};


	while {(count _baseSquad < _squadSize)} do {
		_baseSquad pushBack selectRandom _squadAdditions;
	};
	_baseSquad
};
