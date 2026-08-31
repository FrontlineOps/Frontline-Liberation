params [
	["_killer", objNull, [objNull]],
	["_unit", objNull, [objNull]]
];

private _bluforKills = localNamespace getVariable ["CurrentBluforKills", 0];
_bluforKills = _bluforKills + 1;
localNamespace setVariable ["CurrentBluforKills", _bluforKills];
private _role = [_killer] call RoleArsenal_DetermineRole;
[format ["You have been found guilty for killing a friendly team member named ""%1"". You are unfit for duty. Take the time necessary to reflect on what a friendly team member looks like.", name _unit]] call BIS_fnc_guiMessage;
if (_bluforKills >= 2 && !(_role in ["Hades", "Reaper"])) then {
   _killer setDamage [1];
};