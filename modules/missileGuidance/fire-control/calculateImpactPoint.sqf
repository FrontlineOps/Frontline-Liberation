// Credits to ITC Land for the loop
// Fixes so that the pitch is derived via the velocity vector, not where the model is pointing.
IADS_CalculateImpactPoint = {
	params ["_shell"];
	private ["_x","_y","_vx","_vy","_elevation","_fc","_tof"];

	private _currentVel = _shell getVariable ["targetVelocity", velocity _shell];


	


	private _realAmmoType = _shell getVariable ["underlyingProjectileType", ""];
	_ammo = typeOf _shell;

	if(_realAmmoType != "") then {
		_ammo = _realAmmoType;
	};
	_vel = vectorMagnitude (_currentVel);
	_airFriction = getNumber(configFile >> "CfgAmmo" >> _ammo >> "airFriction");
	_grav = -9.80665;
	_fps = 20;

	private _pitch = asin ((vectorNormalized (_currentVel)) select 2);

	private _rawPitch = _pitch;
	private _rawVelocity = (vectorNormalized (_currentVel))#2;
	// This should lower the higher in altitude..

	private _altitude = ((getPosASL _shell) select 2);

	private _pitchMin = 16 - (_altitude / 275);
	_pitch = _pitch min _pitchMin;
	_fc = 0;
	_tof = 0;

	// Set t0 parameters
	_vx = _vel * cos(_pitch);
	_vy = _vel * sin(_pitch);

	// systemChat format ["VX %1 | VY %2 | Pitch %3 | Sin %4 | Cos %5 | RawPitch %6 | RawVel %7 | StoredVel %8", _vx, _vy, _pitch, sin _pitch, cos _pitch, _rawPitch, _rawVelocity, _currentVel];
	_frame = 1 / _fps;
	_x = 0;
	_y = 0.1;
	_alt = 0;
	_aboveLand = true;
	_simulatedPos = [];
	
	while {_aboveLand} do
	{

		if(_fc % 2 == 0) then {
			_simulatedPosXY = ((getPosASL _shell) getPos [_x, getDir _shell]) vectorAdd [0,0,_y];
			_simulatedPos = [_simulatedPosXY # 0, _simulatedPosXY # 1, ((getPosASL _shell) # 2) + _y];
			_alt = _simulatedPos # 2;
			_terrainAlt = getTerrainHeightASL  _simulatedPos;
			_aboveLand = _terrainAlt < _alt;
		};

		// Calculate next velocity frame
		_vx = _vx + (_vx * _vel * _airFriction * _frame);
		_vy = _vy + (_vy * _vel * _airFriction * _frame);
		_vy = _vy + (_grav * _frame);
		_vel = sqrt(_vx*_vx + _vy*_vy);
		// Increment positions
		_y = _y + (_vy * _frame);
		_x = _x + (_vx * _frame);
		// Increment frame count.
		_fc = _fc + 1;
	};
	[_simulatedPos, _fc * _frame]

};