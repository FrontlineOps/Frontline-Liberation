// Every 2m loop through all units that are not player and make sure their loadout is set back up properly if their uniform ends up missing.
KC_FIX_AI_LOADOUT = {
	{
		if ( isPlayer _x ) then { continue };
		if ( !(_x isKindOf "Man")) then { continue };

		// Apply OPFOR RTO loadout modifications so they have what they need
		if ((typeOf _x) == opfor_rto) then {
			_x setUnitLoadout [opfor_rto_loadout, true];
			continue;
		};

		// Provide night vision scopes
		if ((side _x) isEqualTo GRLIB_side_enemy) then {
            private _nightVision = if (missionNamespace getVariable ["KPLIB_autoFactionActive", false]) then {
                missionNamespace getVariable ["KPLIB_autoFactionOpforNightVision", ""]
            } else {
                "rhs_1PN138"
            };
            if (_nightVision != "") then {_x linkItem _nightVision};
        };

		// Find current unit uniform and check to see if it needs to be replaced
		private _currentUniform = uniform _x;
		// Check if OPFOR unit currently doesn't have a uniform
		if ((count _currentUniform) == 0 && (side _x) isEqualTo GRLIB_side_enemy && {opfor_uniforms isNotEqualTo []}) then {
			// Don't change if currently has a valid OPFOR uniform
			if (!(_currentUniform in opfor_uniforms)) then {
				// No valid uniform, apply a default one from the OPFOR preset
				_uniformDef = [
					selectRandom opfor_uniforms,
					opfor_uniform_kit
				];

				private _configLoadout = getUnitLoadout (typeOf _x);
				_configLoadout set [3, _uniformDef];

				private _logMsg = format [
					"OPFOR Unit %1: Doesn't have valid uniform, replacing with: %3]",
					str (typeOf _x), str _uniformDef
				];
				diag_log _logMsg;

				// Apply updated loadout to unit
				_x setUnitLoadout [_configLoadout, true];
			};
		};
	} forEach allUnits;
};

while { true } do {
	[] call KC_FIX_AI_LOADOUT;
	sleep 120;
};
