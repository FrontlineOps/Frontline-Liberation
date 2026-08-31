params [
	["_killer", objNull, [objNull]],
	["_unit", objNull, [objNull]]
];

private _civKills = localNamespace getVariable ["CurrentCivKills", 0];
_civKills = _civKills + 1;
localNamespace setVariable ["CurrentCivKills", _civKills];
private _role = [_killer] call RoleArsenal_DetermineRole;
[format ["You have killed a civilian named ""%1"". Killing a Civilian Raises your Civilian Reputation. High Reputation Raises your Factory Production time. Lower the Civilian Reputation the faster production times. Multiple Civilian kills in quick succession without Feeding Civilians will result in a random Lost Sector. YOU HAVE BEEN WARNED!", name _unit]] call BIS_fnc_guiMessage;
if (_civKills >= 2 && !(_role in ["Hades", "Reaper"])) then {
   _killer setDamage [1];
};