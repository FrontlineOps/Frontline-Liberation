if (isRemoteExecuted) exitWith {["NATIVE", "Remote invocation rejected"]};
params ["_profile", ["_shooter", objNull], ["_projectile", objNull]];
// ACE starts its own worker from FiredBIS. Yield before any Frontline override,
// including when Frontline is disabled; never attach a second steering worker.
private _aceLevel = missionNamespace getVariable ["ace_missileguidance_enabled", 0];
private _aceActive = _profile getOrDefault ["ace", false]
    && {!isNil "ace_missileguidance_fnc_onFired"} && {_aceLevel >= 1}
    && {isNull _shooter || {isPlayer _shooter} || {_aceLevel >= 2}};
if (_aceActive || {!isNull _projectile && {_projectile getVariable ["KPLIB_guidanceAce", false]}}) exitWith {
    ["ACE", "ACE owns seeker, operator inputs and steering"]
};
if !(missionNamespace getVariable ["KPLIB_guidance_enabled", true]) exitWith {["NATIVE", "Mission guidance disabled"]};
if (!isNull _projectile && {_projectile getVariable ["KPLIB_guidanceExternal", ""] != ""}) exitWith {
    ["NATIVE", _projectile getVariable "KPLIB_guidanceExternal"]
};
[_profile get "backend", _profile get "reason"]
