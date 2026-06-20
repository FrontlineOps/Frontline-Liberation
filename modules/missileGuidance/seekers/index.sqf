
/**

	A seeker head will have code that scans the area infront of the missile to naturally acquire a target, be it chaff, flare, the intended aircraft, or some other unfortunate aircraft.

	A seeker head will also combine the logic of having data-link capabilities for mid-course updates so it doesn't need to setMissileTarget too early
	This is to simulate behavior of stuff like AIM-120 where the missile is guided via data-link before pitbull and it turns on its own radar to acquire the target / new targets

	It will also be responsible for setMissileTarget

	It returns the target that its decided to go for


 */

([] call compileFinal preprocessFileLineNumbers "modules\missileGuidance\seekers\targetOccluded.sqf");
([] call compileFinal preprocessFileLineNumbers "modules\missileGuidance\seekers\withinGimbalLimit.sqf");

IADS_Seekers = createHashMap;

IADS_RegisterNewSeeker = {
	params ["_seekerName", "_seekerCode"];

	diag_log format ["RegisterNewSeeker %1", _seekerName];

	IADS_Seekers set [_seekerName, _seekerCode]
};

([] call compileFinal preprocessFileLineNumbers "modules\missileGuidance\seekers\IR.sqf");
([] call compileFinal preprocessFileLineNumbers "modules\missileGuidance\seekers\placeholder.sqf");
([] call compileFinal preprocessFileLineNumbers "modules\missileGuidance\seekers\RadarHoming.sqf");
([] call compileFinal preprocessFileLineNumbers "modules\missileGuidance\seekers\basic.sqf");