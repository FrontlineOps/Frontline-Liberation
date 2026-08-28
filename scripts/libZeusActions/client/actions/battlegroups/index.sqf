private _rootAction = ["Battlegroups", "Battlegroups", "", {}, { true }] call zen_context_menu_fnc_createAction;

[_rootAction, ["KarmaLibRoot"], 0] call zen_context_menu_fnc_addAction;

private _directedBattlegroupRoot = ["DirectedBattlegroups", "Directed Battlegroups", "", {}, { true }] call zen_context_menu_fnc_createAction;

[_directedBattlegroupRoot, ["KarmaLibRoot"], 0] call zen_context_menu_fnc_addAction;
[] call compileFinal preprocessFileLineNumbers "scripts\libZeusActions\client\actions\battlegroups\airborne.sqf";
[] call compileFinal preprocessFileLineNumbers "scripts\libZeusActions\client\actions\battlegroups\motorized.sqf";
[] call compileFinal preprocessFileLineNumbers "scripts\libZeusActions\client\actions\battlegroups\mechanized.sqf";
[] call compileFinal preprocessFileLineNumbers "scripts\libZeusActions\client\actions\battlegroups\combat_air_patrol.sqf";
[] call compileFinal preprocessFileLineNumbers "scripts\libZeusActions\client\actions\battlegroups\directed_battlegroup_send.sqf";
[] call compileFinal preprocessFileLineNumbers "scripts\libZeusActions\client\actions\battlegroups\directed_battlegroup_set_spawn.sqf";
[] call compileFinal preprocessFileLineNumbers "scripts\libZeusActions\client\actions\battlegroups\directed_battlegroup_set_type.sqf";
