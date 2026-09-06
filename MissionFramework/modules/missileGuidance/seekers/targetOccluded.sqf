

IADS_TargetOccluded = {
	params ["_missile", "_target"];


	if(isNull _missile) exitWith { true };
	if(isNull _target) exitWith { true };

	if(!(alive _target)) exitWith { true };

	private _missilePos = _missile modelToWorldVisualWorld (getCenterOfMass _missile);
	private _targetPos = _target modelToWorldVisualWorld (getCenterOfMass _target);


	private _occluded = false;

	if(!(terrainIntersectASL [_missilePos, _targetPos])) then {
		if(lineIntersects [_missilePos, _targetPos, _missile, _target]) then {
			_occluded = true;
		};
	} else {
		_occluded = true;
	};

	_occluded
};