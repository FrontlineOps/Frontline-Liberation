// Disable ITC Land
// Fired code etc from ITC Land however uses definition here because too lazy to figure out config based.
ITC_LAND_CIWS = false;

IADS_OrdinanceInterceptables = [
	"Sh_155mm_AMOS",
    "Sh_82mm_AMOS_guided",
	"Sh_82mm_AMOS",
    "Missile_AGM_02_F",
    "LaserBombCore",
    "BombCore",
    "itc_land_230mm_he",
    "Missile_AGM_01_F",
    "ammo_Missile_AntiRadiationBase",
    "ammo_Missile_CruiseBase",
    "ammo_Bomb_SDB",
	"R_230mm_HE",
	"Karmakut_AGM88C_HARM",
	"karmakut_artillery_smoke_round"
];

IADS_OrdinanceClasses = createHashMapFromArray [
	[
		"karmakut_missile_target",
		[
			"ammo_Missile_AntiRadiationBase",
			"ammo_Missile_CruiseBase",
			"Karmakut_AGM88C_HARM"
		]
	],
	[
		"karmakut_rocket_target",
		[
			"R_230mm_HE",
			"itc_land_230mm_he"
		]
	]
];

IADS_SmokeRounds = [
	"rhs_ammo_m60a2_smoke",
	"rhs_ammo_152_WP",
	"rhs_ammo_d832du"
];


IADS_IsOrdinance = {
	params ["_type"];

	((_type find "missile_target" > -1) || (_type find "shell_target" > -1) || (_type find "rocket_target" > -1))
};

IADS_IsArtilleryOrdinance = {
	params ["_type"];

	((_type find "shell_target" > -1) || (_type find "rocket_target" > -1))
};

IADS_OrdinanceTargetCreate = {
	[
		{
			params ["", "", "", "", "_ammo", "", "_projectile", "_gunner"];
			private _desiredClass = "";
			{

				if(_desiredClass != "") exitWith {};
				private _class = _x;
				private _ammoClasses = _y;

				{
					if(_ammo isKindOf [_x, configFile >> "cfgAmmo"]) exitWith {
						_desiredClass = _class;
					};
				} forEach _ammoClasses;
			} forEach IADS_OrdinanceClasses;
			private _initialClass = if(_desiredClass != "") then [{_desiredClass},{"karmakut_shell_target"}];
			
			private _class = if((side group _gunner) == west) then [{_initialClass + "_b"},{_initialClass + "_o"}];

			private _isWest = ((side group _gunner) == west);
			_class = if((side group _gunner) == resistance) then [{_initialClass + "_i"},{_class}];
			_target = _class createVehicle [0,0,1000];

			_target setVariable ["underlyingProjectileType", _ammo, true];
			_target setDir (getDirVisual _projectile);
			_target setPos (_projectile modelToWorld [0,-5,0]);
			_target setVelocity (velocity _projectile);
			_target setMass 0;
			_target setobjecttexture [0,""];
			createVehicleCrew _target;
			driver _target disableAI "ALL";
			gunner _target disableAI "ALL";
			_target deleteVehicleCrew (gunner _target);
			[{
				(_this select 0) params ["_projectile", "_target", "_isWest", "_gunner"];
				_canIntercept = (getPosATL _projectile # 2 > 30);
				_descending = (velocity _projectile # 2 < 0);
				blufor ReportRemoteTarget [_target, 10];
				east ReportRemoteTarget [_target, 10];
				resistance ReportRemoteTarget [_target, 10];
				if (!alive _projectile || (!alive _target && _canIntercept)) exitWith {

					

					deleteVehicle _projectile;
					deleteVehicle _target;
					[_this select 1] call CBA_fnc_removePerFrameHandler;
				};
				if(!_canIntercept && alive _target && _descending) then {
					deleteVehicle _target;
					
				

					private _vel = velocity _projectile;
					

					

				
				
					private _explPos = getPos _projectile;

					

					if(!(_explPos isEqualTo [0,0,0])) then {
						if((typeOf _projectile) in IADS_SmokeRounds && (_projectile distance2D _gunner) > 300) then {

							private _dir = (vectorNormalized _vel);
							private _right = _dir vectorCrossProduct [0,0,1];
							private _dirUp = _dir vectorCrossProduct _right;
							private _spawnPos = _explPos vectorAdd (((_explPos vectorAdd _dir) vectorFromTo _explPos) vectorMultiply 300);
							
							private _airburstSpawn = _explPos vectorAdd (((_explPos vectorAdd _dir) vectorFromTo _explPos) vectorMultiply 200);
							private _airburst = ("karmakut_artillery_smoke_airburst_effect" createVehicle _airburstSpawn);
							_airburst setVectorDirAndUp [_dir, _dirUp];
							_airburst setVelocity (_dir vectorMultiply 90);
							private _stepY = 3;
							private _max = 7;
							// Podnos
							if((typeOf _projectile) == "rhs_ammo_d832du") then {
								_stepY = 5;
								_max = 4;
							};
							for "_i" from 1 to _max do {
								
								
							

								private _eff = "karmakut_artillery_smoke_pellet" createVehicle _spawnPos;
								
								_eff setVectorDirAndUp [_dir, _dirUp];

								private _effVel = _dir vectorMultiply 90;

								
								

								_effVel = _effVel vectorAdd (_right vectorMultiply 2 * (-15 + random 30));

								_effVel = _effVel vectorAdd (_dirUp vectorMultiply 2 * (-15 + _stepY * _i));

								_eff setVelocity _effVel;
							};
						};
						[_explPos] remoteExec ["BATTLESPACE_ARTILLERY_REPORT_SHELL_IMPACT", 2];
					};
					
				
				} else {
					_target setDir (getDirVisual _projectile);
					_target setPos (_projectile modelToWorld [1,-5,1]);
					_target setVelocity (velocity _projectile);
					_target setVariable ["tVelocity", velocity _projectile, true];
				};
			}, 0.1, [_projectile, _target, _isWest, _gunner]] call CBA_fnc_addPerFrameHandler;
		},
		_this,
		1
	] call CBA_fnc_waitAndExecute;
};

// All the Arty that the OPFOR will try to counterbattery, doesn't include mortars at this time
IADS_WEST_ARTY = [
	//"RHS_M252_D",
	//"RHS_M252_WD",//unsund^^^
	//"RHS_M252_USMC_D",
	"RHS_M119_WD",
	"RHS_M119_D",
	"pook_M777",
	"pook_M777_DES",
	"UK3CB_B_M270_MLRS_HE_WDL",
	"itc_land_rhsusf_m109_usarmy",
	"itc_land_rhsusf_m109d_usarmy",
	"rhsusf_m109_usarmy",
	"rhsusf_m109d_usarmy"
];
IADS_OrdinanceFired = {
	params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_vehicle"];

	if(!local _vehicle) exitWith {};

	private _exit = false;

	if(isServer && hasInterface) then {
		


		if (isNil { PROJECTILE_DECONFLICT }) then {
			PROJECTILE_DECONFLICT = createHashMap;
		};

		private _exists = PROJECTILE_DECONFLICT get (str _projectile);

		if(_exists) then {
			_exit = true;
			PROJECTILE_DECONFLICT = createHashMap;
		};

		PROJECTILE_DECONFLICT set [str _projectile, true];
	};

	if(_exit) exitWith {};

	
	private _interceptable = false;
	{
		if(_ammo isKindOf [_x, configFile >> "cfgAmmo"]) exitWith { _interceptable = true; };
	} forEach IADS_OrdinanceInterceptables;


	if(!_interceptable) exitWith {};


	
	if((typeOf _unit) in IADS_WEST_ARTY) then {
		[_unit, _projectile] remoteExec ["BATTLESPACE_ARTILLERY_REPORT_SHELL_FIRED", 2];
	};


	_this call IADS_OrdinanceTargetCreate;
};

