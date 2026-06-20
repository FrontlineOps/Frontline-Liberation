
[
	{
		(!isNull findDisplay 46)
	},
	{

		private _display = findDisplay 46;

		_display displayAddEventHandler ["KeyDown", {
			params ["", "_key"];	

			private _escapeKeys = actionKeys "ingamePause";

			if(_key in _escapeKeys) then {
				
				private _stateTo = true;

				
				if (!(alive player) || player getVariable ["ACE_isUnconscious", false]) then {
					_stateTo = false;
					
				};
				_abortButton =	(findDisplay 49) displayCtrl 104;
				_abortButton ctrlEnable _stateTo;
			};
		}];
	},	
	[]
] call CBA_fnc_waitUntilAndExecute;