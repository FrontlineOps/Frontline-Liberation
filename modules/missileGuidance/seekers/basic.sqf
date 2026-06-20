[
	"BASIC",
	{
		params ["_missile", "_seekerPerformance", "_targetState", "_guidanceState"];

		_guidanceState params ["_yaw", "_pitch", "_lastPosition", "_missilePos", "_missileVelocity", "_missileHeading", ["_nextSeekerTick", 0], ["_lastFlares", []]];

		_targetState params ["_lastVelocity", "_lastPos", "_target", "_lastAcceleration", "_targetPos", "_targetVelocity"];

		_seekerPerformance params [["_irCMResistance", 98], ["_gimbalLimit", 45], ["_newAcquireRange", 10000]];
		


		_target

	}
] call IADS_RegisterNewSeeker;