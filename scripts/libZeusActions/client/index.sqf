private _rootAction = ["KarmaLibRoot", "Liberation Actions", "", {}, { true }] call zen_context_menu_fnc_createAction;

[_rootAction, [], 0] call zen_context_menu_fnc_addAction;

[] call compileFinal preprocessFileLineNumbers "scripts\libZeusActions\client\actions\reinforcements\index.sqf";
[] call compileFinal preprocessFileLineNumbers "scripts\libZeusActions\client\actions\battlegroups\index.sqf";
[] call compileFinal preprocessFileLineNumbers "scripts\libZeusActions\client\actions\notification.sqf";
[] call compileFinal preprocessFileLineNumbers "scripts\libZeusActions\client\actions\toggle_sector.sqf";
[] call compileFinal preprocessFileLineNumbers "scripts\libZeusActions\client\actions\roleDescriptionAndBlacklist.sqf";
[] call compileFinal preprocessFileLineNumbers "scripts\libZeusActions\client\actions\wh.sqf";
[] call compileFinal preprocessFileLineNumbers "scripts\libZeusActions\client\actions\tglEnforcedArsenal.sqf";
[] call compileFinal preprocessFileLineNumbers "scripts\libZeusActions\client\actions\openLog.sqf";