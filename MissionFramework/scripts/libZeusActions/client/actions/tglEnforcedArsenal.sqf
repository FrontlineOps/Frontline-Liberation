// Toggle enforced arsenal for all players
private _action = ["tglEnforcedArsenal", "Toggle Enforced Arsenal Global Bypass", "", {
	BYPASS_ENFORCED_ARSENAL = !BYPASS_ENFORCED_ARSENAL;
	publicVariable "BYPASS_ENFORCED_ARSENAL";
	hint format ["Enforced Arsenal Bypassed Globally: %1", BYPASS_ENFORCED_ARSENAL];
}] call zen_context_menu_fnc_createAction;
[_action, ["KarmaLibRoot"], 0] call zen_context_menu_fnc_addAction;