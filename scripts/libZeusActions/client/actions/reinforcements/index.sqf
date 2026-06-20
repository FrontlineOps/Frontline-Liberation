private _rootAction = ["Reinforcements", "Reinforcements", "", {}, { true }] call zen_context_menu_fnc_createAction;

[_rootAction, ["KarmaLibRoot"], 0] call zen_context_menu_fnc_addAction;
[] call compileFinal preprocessFileLineNumbers "scripts\libZeusActions\client\actions\reinforcements\airborne.sqf";