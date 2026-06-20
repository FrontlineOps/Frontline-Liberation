
IADS_CMDispense = {

	params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_vehicle", "_missileTargetDesired"];


	if(_weapon != "Karmakut_AN_ALE47_Dispenser") exitWith {};

	private _veh = vehicle player;

	if(!(player isEqualTo cameraOn)) then {
		_veh = cameraOn;
	};
	if(_veh isEqualTo player) exitWith {};


	if(_vehicle isEqualTo _veh) then {


		private _lastPlayTime = _veh getVariable ["LastChaffFlare", 0];

		if(_lastPlayTime < (CBA_missionTime - 2)) then {

			_veh setVariable ["LastChaffFlare", CBA_missionTime];
			playSound "Karmakut_BettyChaffFlare";
		};
	};
};