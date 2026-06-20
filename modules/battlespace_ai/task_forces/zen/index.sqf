private _rootAction = ["battlespaceAI", "Battlespace AI", ["", [1,1,1,1]], {}, { true }] call zen_context_menu_fnc_createAction;

[_rootAction, [], 0] call zen_context_menu_fnc_addAction;


[] call compileFinal preprocessFileLineNumbers "modules\battlespace_ai\task_forces\zen\placePatrol.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\battlespace_ai\task_forces\zen\renderToggle.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\battlespace_ai\task_forces\zen\convertToOutpost.sqf";