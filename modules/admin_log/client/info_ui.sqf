with uiNamespace do {
	
	disableSerialization;
	
	_display = findDisplay 46 createDisplay "RscDisplayEmpty";

	_ctrlGroup = _display ctrlCreate ["RscControlsGroupNoScrollbars", -1];
	_ctrlGroup ctrlSetPosition [0.5, 0.5, 0, 0];
	_ctrlGroup ctrlCommit 0;

	_ctrlButton = _display ctrlCreate ["RscShortcutButton", -1, _ctrlGroup];
	_ctrlButton ctrlSetPosition [0, 0.45, 0.13, 0.05];
	_ctrlButton ctrlCommit 0;
	_ctrlButton ctrlSetText "CLOSE";
	_ctrlButton ctrlAddEventHandler ["ButtonClick", {(ctrlParent (_this select 0)) closeDisplay 1;}];
	_ctrlButton ctrlSetActiveColor [1, 0, 0, 1];
	_ctrlButton ctrlSetTextColor [1, 0, 0, 1];
	_ctrlButton ctrlSetBackgroundColor [0, 0, 0, 1];
	_ctrlGroup ctrlSetPosition [0.25, 0.25, 0.5, 0.5];
	_ctrlGroup ctrlCommit 0.1;

	_ctrlHeader = _display ctrlCreate ["RscText", -1, _ctrlGroup];
	_ctrlHeader ctrlSetPosition [0, 0, 0.5, 0.05];
	_ctrlHeader ctrlSetBackgroundColor [0, 0, 0, 1];
	_ctrlHeader ctrlSetTextColor [1, 0, 0, 1];
	_ctrlHeader ctrlSetText "KC EVENT LOGS [BETA]";
	_ctrlHeader ctrlEnable false;
	_ctrlHeader ctrlCommit 0;

	_ctrlBackground = _display ctrlCreate ["RscTextMulti", -1, _ctrlGroup];
	_ctrlBackground ctrlSetPosition [0, 0.05, 0.5, 0.4];
	_ctrlBackground ctrlSetBackgroundColor [0.1, 0.1, 0.1, 1];
	_ctrlBackground ctrlSetText "Click on an entry to copy it to clipboard. 
	
Export: Copy all entries to clipboard. 

Configuration: modules\admin_log\config.sqf
Grom - 2023
	";
	_ctrlBackground ctrlEnable false;
	_ctrlBackground ctrlCommit 0;	
	
	playsound "beep_target";
};