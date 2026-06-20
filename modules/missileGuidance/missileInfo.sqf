
IADS_NextMissileID = 0;
IADS_ActiveMissiles = createHashMap;


IADS_RegisterNewMissile = {

	params ["_type", "_missile"];

	IADS_NextMissileID = IADS_NextMissileID + 1;


	_newTable = createHashMap;
	
	_newTable set ["type", _type];
	_newTable set ["missile", _missile];
	IADS_ActiveMissiles set [IADS_NextMissileID, _newTable];

	IADS_NextMissileID
};
