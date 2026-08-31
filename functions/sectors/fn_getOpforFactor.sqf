/* Returns the opfor factor to scale down enemy forces, if "adapt to player count" mission param is enabled.
Parameter(s): NONE
Returns: Opfor factor [NUMBER] */

if !(GRLIB_adaptive_opfor) exitWith {1};

private _bluforcount = ([] call KPLIB_fnc_getPlayerCount);

(0.35 + (_bluforcount / GRLIB_blufor_cap)) min 1
