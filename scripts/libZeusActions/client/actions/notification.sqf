private _statement = {
	private _controls = [ 
		["EDIT", "Title"], 
		["EDIT", "Description"], 
		["LIST", "Icon", [ 
				[
					"\a3\Ui_f\data\Map\Markers\Military\warning_ca.paa",
					"res\notif\ui_notif_restart.paa",
					"res\notif\ui_notif_ref.paa",
					"res\notif\ui_notif_sob.paa",
					"res\notif\ui_notif_int.paa",
					"res\notif\ui_notif_bgp.paa",
					"res\notif\ui_notif_fob_los.paa",
					"res\notif\ui_notif_fob_und.paa",
					"res\notif\ui_notif_fob_sec.paa",
					"res\notif\ui_notif_fob_new.paa",
					"res\notif\ui_notif_sec_saf.paa",
					"res\notif\ui_notif_sec_los.paa",
					"res\notif\ui_notif_sec_una.paa",
					"res\notif\ui_notif_sec_cap.paa",
					"\A3\ui_f\data\map\mapcontrol\taskIcon_ca.paa",
					"\A3\ui_f\data\map\mapcontrol\taskIconCanceled_ca.paa",
					"\A3\UI_F\data\IGUI\Cfg\Actions\settimer_ca.paa",
					"\A3\ui_f\data\map\mapcontrol\power_CA.paa",
					"\A3\ui_f\data\gui\cfg\Debriefing\endDefault_ca.paa",
					"\a3\Ui_f\data\GUI\Cfg\Hints\ActionMenu_ca.paa",
					"\A3\ui_f\data\map\mapcontrol\taskIconDone_ca.paa"
				], 
				[
					["", "", "\a3\Ui_f\data\Map\Markers\Military\warning_ca.paa"],
					["", "", "res\notif\ui_notif_restart.paa"],
					["", "", "res\notif\ui_notif_ref.paa"],
					["", "", "res\notif\ui_notif_sob.paa"],
					["", "", "res\notif\ui_notif_int.paa"],
					["", "", "res\notif\ui_notif_bgp.paa"],
					["", "", "res\notif\ui_notif_fob_los.paa"],
					["", "", "res\notif\ui_notif_fob_und.paa"],
					["", "", "res\notif\ui_notif_fob_sec.paa"],
					["", "", "res\notif\ui_notif_fob_new.paa"],
					["", "", "res\notif\ui_notif_sec_saf.paa"],
					["", "", "res\notif\ui_notif_sec_los.paa"],
					["", "", "res\notif\ui_notif_sec_una.paa"],
					["", "", "res\notif\ui_notif_sec_cap.paa"],
					["", "", "\A3\ui_f\data\map\mapcontrol\taskIcon_ca.paa"],
					["", "", "\A3\ui_f\data\map\mapcontrol\taskIconCanceled_ca.paa"],
					["", "", "\A3\UI_F\data\IGUI\Cfg\Actions\settimer_ca.paa"],
					["", "", "\A3\ui_f\data\map\mapcontrol\power_CA.paa"],
					["", "", "\A3\ui_f\data\gui\cfg\Debriefing\endDefault_ca.paa"],
					["", "", "\a3\Ui_f\data\GUI\Cfg\Hints\ActionMenu_ca.paa"],
					["", "", "\A3\ui_f\data\map\mapcontrol\taskIconDone_ca.paa"]
					
				]
			]
		] 
	]; 
	["Send Admin Notificaton", _controls, {  
	
		params ["_values"]; 
	
		["lib_admin_notification", _values] remoteExec ["bis_fnc_shownotification"];
	
	}, {}, []] call zen_dialog_fnc_create 
};

private _action = ["CreateNotification", "Create Notification", "", _statement, { true }] call zen_context_menu_fnc_createAction;

[_action, ["KarmaLibRoot"], 0] call zen_context_menu_fnc_addAction;