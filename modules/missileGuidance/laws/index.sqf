/**
	The missile knows where it is at all times. It knows this because it knows where it isn't.
	By subtracting where it is, from where it isn't, or, where it isn't, from where it is, it obtains a difference, or deviation.
	The guidance subsystem uses deviations to generate corrective commands to drive the missile from a position where it is, to a position where it isn't.
	And arriving at a position where it wasn't, it now is.


	All guidance laws should take info from the missile's sensors and the seeker head and output an acceleration command used to steer the missile

	[_deltaTime, _oldPositions, _newPositions, _velocities, _missileID, _missileHeading]

	_deltaTime = Time since last frame
	_oldPositions = [_oldMissile, _oldTarget]
	_newPositions = [_newMissile, _newTarget]
	_velocities = [
		[_oldMissileVel, _newMissileVel],
		[_oldTargetVel, _newTargetVel]
	]
	_missileID = Number from the global hashmap used to give the missiles a state. May be changed later? Could keep state within the PFH, however probably needed for global state to make sure missiles aren't being spammed at just one target for a lookup as we'd probably need missile info outside of the PFH scope.
	_missileHeading = _headingDir
*/

IADS_GuidanceLaws = createHashMap;


IADS_RegisterNewGuidanceLaw = {
	params ["_name", "_code"];

	IADS_GuidanceLaws set [_name, _code]
};

IADS_GetGuidanceLaw = {
	IADS_GuidanceLaws getOrDefault [_this, {}]
};
[] call compileFinal preprocessFileLineNumbers "modules\missileGuidance\laws\apn.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\missileGuidance\laws\apn_loft.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\missileGuidance\laws\aim120_loft.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\missileGuidance\laws\aczemg.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\missileGuidance\laws\zemg.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\missileGuidance\laws\zemg_loft.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\missileGuidance\laws\patriot_midcourse.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\missileGuidance\laws\sa20_midcourse.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\missileGuidance\laws\vls_rotate.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\missileGuidance\laws\sa15_rotate.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\missileGuidance\laws\sa24_midcourse.sqf";