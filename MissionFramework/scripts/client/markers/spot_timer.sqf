// Idempotent presentation: all capture progress comes from the server snapshot.
if (!hasInterface || {!isNil {missionNamespace getVariable "KPLIB_captureStatusRenderer"}}) exitWith {};
[] call KPLIB_fnc_captureStatusRender;
KPLIB_captureStatusRenderer = [{
    [] call KPLIB_fnc_captureStatusRender;
}, 1] call CBA_fnc_addPerFrameHandler;
