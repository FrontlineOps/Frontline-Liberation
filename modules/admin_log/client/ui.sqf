uiNamespace setVariable ["KC_ADMIN_EVENTS_LOG", KC_ADMIN_EVENTS_LOG];

if (count KC_ADMIN_EVENTS_LOG == 0 || isNil "KC_ADMIN_EVENTS_LOG") exitWith {
	systemChat "No event logs to show...";
};

with uiNamespace do 
{

	disableSerialization; 

	_ctrlPos    = [safeZoneW * 0.005, safeZoneH * 0.015];
	_bgPos      = [0, 0, 1, 1];
	_lBoxPos 	= [0, safeZoneH * 0.0435, safeZoneW * 0.625, safeZoneH * 0.75];
	_btnPos 	= [safeZoneW * 0.015, safeZoneH * 0.795, safeZoneW * 0.08, safeZoneH * 0.05];
	
	_clrBlack   = [0, 0, 0, 1];
	_clrYellow  = [0.8, 0.8, 0, 1];
	_clrRed     = [0.8, 0, 0, 1];
	_clrWhite   = [0.8, 0.8, 0.8, 1];

	KC_ADMIN_EVENTS_LOG_DISPLAY = (findDisplay 313) createDisplay "RscDisplayEmpty"; 
	KC_ADMIN_EVENTS_LOG_DISPLAY displaySetEventHandler ["onUnload", "hint 'unloaded!';"];

	_controlGroup = KC_ADMIN_EVENTS_LOG_DISPLAY ctrlCreate ["RscControlsGroup", -1];	
	_controlGroup ctrlSetPosition _ctrlPos;
	_controlGroup ctrlCommit 0;		

	_controlBg = KC_ADMIN_EVENTS_LOG_DISPLAY ctrlCreate ["RscTextMulti", -1, _controlGroup];
	_controlBg ctrlEnable false;
	_controlBg ctrlSetPosition [0, 0, 1, 1];
	_controlBg ctrlSetBackgroundColor _clrBlack;
	_controlBg ctrlCommit 0;

	_controlListbox = KC_ADMIN_EVENTS_LOG_DISPLAY ctrlCreate ["RscControlsGroup", -1, _controlGroup];
	_controlListbox ctrlSetPosition _lBoxPos;
	_controlListbox ctrlCommit 0;	

	{
		private _thisControl = KC_ADMIN_EVENTS_LOG_DISPLAY ctrlCreate ["RscButtonMenu", -1, _controlListbox];					
		_thisControl setVariable ["DATA_ITEM", _x];
		_thisControl ctrlSetBackgroundColor _clrBlack;

		switch (_x#1) do {
			case 1: {
				_thisControl ctrlSetTextColor _clrYellow;
			};
			case 2: {
				_thisControl ctrlSetTextColor _clrRed;
			};
			default {
				_thisControl ctrlSetTextColor _clrWhite;
			};
		};
		_thisControl ctrlCommit 0;
		_thisControl ctrlSetPosition [safeZoneW * 0.015, _forEachIndex * safeZoneH * 0.025, safeZoneW * 0.6, safeZoneH * 0.03];
		_text = format ["[%1:%2:%3]: %4 - %5", _x#3#3, _x#3#4, _x#3#5, _x#2, _x#0];
		_thisControl ctrlSetTooltip "Click to Copy";
		_thisControl ctrlSetStructuredText parseText format ["<t valign='center' font='PuristaMedium' align='left' size='1'>%1</t>", _text];
		_thisControl ctrlSetFontHeight (safeZoneH * 0.025);
		_thisControl ctrlAddEventHandler ["ButtonClick", {
			with uiNamespace do {
				copyToClipboard str (_this#0 getVariable "DATA_ITEM");
				systemChat "Copied to clipboard!";
			};
		}];

		_thisControl ctrlCommit 0;		
	} forEach KC_ADMIN_EVENTS_LOG;
	
	_titleHeader = KC_ADMIN_EVENTS_LOG_DISPLAY ctrlCreate ["RscButtonMenu", -1, _controlGroup];
	_titleHeader ctrlEnable false;
	_titleHeader ctrlSetPosition [0, 0, 1, 0.05];
	_titleHeader ctrlSetStructuredText parseText "<t shadow='2' valign='center' color='#FF0000' align='center'>KC EVENT LOGS [BETA]</t>";
	_titleHeader ctrlSetBackgroundColor _clrWhite;
	_titleHeader ctrlCommit 0;

	_btnCopy = KC_ADMIN_EVENTS_LOG_DISPLAY ctrlCreate ["RscButtonMenu", -1, _controlGroup];
	_btnCopy ctrlSetPosition _btnPos;
	_btnCopy ctrlSetBackgroundColor _clrWhite;
	_btnCopy ctrlSetStructuredText parseText "<t shadow='2' valign='center' color='#FF0000' align='center'>EXPORT</t>";
	_btnCopy ctrlSetTooltip "Copy All Log Entries To Clipboard";
	_btnCopy ctrlAddEventHandler ["ButtonClick", {
		with uiNamespace do {
			copyToClipboard str KC_ADMIN_EVENTS_LOG;
			systemChat "Exported to clipboard!";
		};
	}];
	_btnCopy ctrlCommit 0;

	_btnInfo = KC_ADMIN_EVENTS_LOG_DISPLAY ctrlCreate ["RscButtonMenu", -1, _controlGroup];
	_btnInfo ctrlSetPosition [safeZoneW * 0.105, safeZoneH * 0.795, safeZoneW * 0.08, safeZoneH * 0.05];
	_btnInfo ctrlSetBackgroundColor _clrWhite;
	_btnInfo ctrlSetStructuredText parseText "<t shadow='2' valign='center' color='#FF0000' align='center'>INFO</t>";
	_btnInfo ctrlSetTooltip "Click For Info";
	_btnInfo ctrlAddEventHandler ["ButtonClick", {
		(ctrlParent (_this select 0)) closeDisplay 1;
		[] execVM "modules\admin_log\client\info_ui.sqf";
	}];
	_btnInfo ctrlCommit 0;

	playsound "beep_target";

};