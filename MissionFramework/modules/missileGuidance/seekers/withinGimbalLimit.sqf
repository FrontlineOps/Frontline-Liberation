IADS_WithinGimbalLimit = {
	params ["_missile", "_target", "_gimbalLimit"];
	if(isNull _missile) exitWith { false };
	if(isNull _target) exitWith { false };
	if(!(alive _target)) exitWith { false };

	private _missileHeading = vectorNormalized (velocity _missile);

	private _los = vectorNormalized ((getPosASLVisual _target) vectorDiff (getPosASLVisual _missile));



	private _angleBetweenTwo = (_missileHeading vectorCos _los);

	(_angleBetweenTwo >= cos _gimbalLimit);
};