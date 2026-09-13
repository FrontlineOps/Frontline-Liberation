if (isRemoteExecuted) exitWith {["NATIVE", "Remote invocation rejected"]};
params ["_profile", ["_shooter", objNull], ["_projectile", objNull]];
if !(missionNamespace getVariable ["KPLIB_guidance_enabled", true]) exitWith {["NATIVE", "Mission guidance disabled"]};
if (!isNull _projectile && {_projectile getVariable ["KPLIB_guidanceExternal", ""] != ""}) exitWith {
    ["NATIVE", _projectile getVariable "KPLIB_guidanceExternal"]
};
[_profile get "backend", _profile get "reason"]
