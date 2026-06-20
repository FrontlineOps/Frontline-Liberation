// Opens zeus admin log
private _action = ["openLog", "Admin Log", "", {
	execVM "modules\admin_log\client\ui.sqf";
}] call zen_context_menu_fnc_createAction;
[_action, ["KarmaLibRoot"], 0] call zen_context_menu_fnc_addAction;