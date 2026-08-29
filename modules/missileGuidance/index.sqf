/**
	The missile knows where it is at all times. It knows this because it knows where it isn't.
	By subtracting where it is, from where it isn't, or, where it isn't, from where it is, it obtains a difference, or deviation.
	The guidance subsystem uses deviations to generate corrective commands to drive the missile from a position where it is, to a position where it isn't.
	And arriving at a position where it wasn't, it now is.

	
	Each SAM site will be subordinate to the side's IADS center (not a physical thing, but a master script that on each frame or delay evaluates radar targets and gets subordinate SAM vehicles to engage)
	Each SAM launch vehicle such as the SA-15 or the Fan Song Radar has a per frame handler that forces the proper radar mode (on / off) as well as preventing it from randomly engaging stuff on its own. Engagements will be forced via scripts. The radar should only turn off if its within range of a search radar.
	In the case of the Fan Song Radar and other command radars that have subordinate launchers, a different approach is used when commanding to fire.
	Commanding to fire with subordinate launchers:
		Launch vehicle adds itself to the target. This addition makes sure the master script knows the target is already being actively engaged and does not keep commanding the fires of subordinate launch controllers.
		When the launch vehicle dies, or some other condition that prevents it from actually engaging it will remove itself from the target. This removal makes sure the master script knows the target can potentially be engaged.
		The launch vehicle commands a subordinate launcher to align and fire. This command is when it adds the launch vehicle to the target (to indicate that its properly queued up a fire command and a launch is imminent)
	The evaluators for this distance + target checking should probably be run every few seconds instead of every frame.
	When a search radar is allocated to the IADS, all applicable SAM site tracking radars would shut off (? Might not be desired cuz it can make it too hard and extra complexity)
	When the IADS confirms a hostile target, either airplane or missile, it will look for the two closest SAM vehicles in range with ammo and can fire.
	Finding the closest SAM vehicles, the script will set the vehicle's target. Depending on the type of SAM, the SAM can just vertical launch at multiple targets without needing to traverse, otherwise it will traverse and wait for alignment. The vehicle would have some boolean flag about multipleLaunchesSupported
	Once fired, the missile will initialize with a guidance computer which also adds the missile to a master tracking list to prevent too many missiles on one target.
	When a missile is defeated and the number of active missiles engaging the target is less than 2 and its still alive, the condition to launch on it becomes true.
	


	When target exists:
		Evaluate range to launch vehicles with ammo and is capable of firing. (targetsBeingEngaged < simultaneousLaunchCount) This evaluation function can have more complex logic such as estimating Pk and only launch if the Pk gets high enough.
		Can probably also add a function that evaluates if this launch vehicle is capable of the simulataneous engagement (within gimbal limits of the current track radar if the vehicle has targets already in its array) Remember a vehicle with targets in its target list means its already engaging or about to.
		If launch vehicles are in range:
			Tell closest 2 vehicles that they have a new target for the duration of their one missile.
			Vehicle per frame handlers handles this and turns to align or launches the missile if its a data-link supported vehicle like the SA-15.
			Evaluate if vehicle needs to fire by comparing its vehicle target list and if there are missiles currently on the way via a missile tracking list for the vehicle as well? Probably doesn't work with missiles and there can be delay.
			Instead it'd be a separate list where the launch vehicle instead is queued into it. When the missile it launches is destroyed, the parent vehicle also gets removed for that one occurrence.
			When the parent vehicle is destroyed or runs out of ammo, it too will be removed (entirely across the array)
			If fired:
				the missile is added to a master tracking list that can be looked up. As well as the vehicle's tracking list (so it doesn't launch too many at once either)
				A cooldown is set for the vehicle to prevent another launch too quickly, however it will queue it up.
			Once the missile is destroyed:
				the missile is removed from the master tracking list and vehicle target list and vehicle tracking list.


	Perhaps the master tracking list is just a variable on the vehicle that has an array of missiles currently going towards it.
	The missile will also have a variable denoting the launch vehicle.

	To make a launch vehicle fire the 2 missiles by themselves instead of 2 separate vehicles, perhaps it just needs 2 entries of the target into their target array, and it compares if the amount of missiles incoming to that target from the vehicle is less than the amount of fire commands.

	// Assumption: SAM capable of engaging multiple targets will not need to face the target(s) and it is assumed these SAMs do this because they are data-link capable and do not need their tracking radar to engage a target incoming from the launch control.
	// Probably unrealistic for some SAM systems.
	// To simulate it better and not be as overpowered that an EWR of an IADS can guide the missiles, the missile can have a check in which it evaluates the angle between where the launch vehicle is looking vs the target. If it exceeds the gimbal limit, it's been defeated.
	Vehicle PFH:
		Do I have targets in my target array?
		Yes:
			Turn on radar
			For each target:
				Add to a hashmap for occurences
				If targets has changed since the last execution:
					Every unique target added to a new array where:
						Every unique target is assigned a threat rank to the vehicle itself unless otherwise overriden by the IADS launch center (probably a param somewhere?) The threat would be a scalar value, so higher threats to the vehicle can override the IADS decision and force the tracking radar to slew and ensure a potential intercept on the highest threat.
						This would only be recalculated when the target array has changed.
				
			End:
			For each ranked threat from highest to lowest:
				If this target is the highest ranked threat:
					Slew the tracking radar to it.
				For each missile tracking the target:
					Evaluate parent, does it match me?
					Yes:
						Add to count
				If count of missiles sent by me heading to target is greater or equal to the amount of times the target shows up in my targeting list:
					I do not need to send a missile
				Else:
					If cooldown period elapsed:
						If vertical launch platform (SA-15, SA-10, SA-20):
							yeet
						Else:
							Wait until turret has been sufficently aligned then:
								yeet
					Else:
						wait for next loop for the same checks
	

	Missile:
		On init, add missile to the target's missile list.
		
		On death, remove missile from the target's missile list.

		On each frame:
			Check for line of sight between the engagement radar and the target every few seconds.
			If line of sight broken:
				detonate the missile, it's been defeated.
			Check for gimbal limit between the engagement radar and the target every few seconds.
			If gimbal limit exceeded:
				detonate the missile, it's been defeated.
			Check for proximity to detonate warhead
			If proximity is close enough:
				If target is within a 45 degree cone of the missile's head:
					Detonate warhead
				Else:
					continue flying and end guidance subsystem

			If closing rate has continually gotten positive (gaining distance) for enough time:
				Detonate the missile, it's been defeated

			Run guidance subsystem:
				Via an array of guidance control laws and the current state, evaluate which guidance control law to execute.
				Use returned acceleration command to command the missile
		
	How to implement a missile where the vehicle is just a launcher and doesn't have radar? (Like the SA-2 or SA-3).
	Instead, set the parent as the Fan Song Radar, the Fan Song Radar will have the normal vehicle PFH. The difference will be their fire command.

	Instead of directly firing it:
		Loops through all its current launchers and finds the closest one to the target with ammo and can fire:
			Initializes a PFH that will force the launcher to slew to the target and then fire.
			Once fired from the launcher, it will do the standard missile additions, etc..?
			If the launcher is destroyed before it can launch a missile then it: 


	On vehicle being targeted:
		On countermeasures deployed:
			Figure out if it is chaff or flares or both.
			If chaff:
				Evaluate based on some parameters (or just rng chance) if the radar has been spoofed.
				If the radar has been spoofed then set the missile to be spoofed and fly to the spoof location before detonating or a timeout of 5s
			If flares:
				Same as chaff, if the seekerhead is IR guided without a radar component.. However an IR launch would not be part of the IADS system.
 */
IADS_SAM_DEBUG = false;
IADS_FCR_DEBUG = false;

[] call compileFinal preprocessFileLineNumbers "modules\missileGuidance\laws\index.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\missileGuidance\steering.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\missileGuidance\seekers\index.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\missileGuidance\missileInfo.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\missileGuidance\missiles\index.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\missileGuidance\guidanceComputer.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\missileGuidance\fire-control\index.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\missileGuidance\ordinanceTargeting\index.sqf";
[] call compileFinal preprocessFileLineNumbers "modules\missileGuidance\avionics\index.sqf";


// TODO: Fired event has a map of functions that then invoke comparison / match functions before invoking the child code that would handle it.


IADS_SAMOverride = {
	params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_vehicle", ["_missileTargetDesired", objNull]];

	private _target = _missileTargetDesired;

	private _targetPos = [0,0,0];
	if(!(isNull _vehicle)) then {
		private _forcedTarget = _vehicle getVariable ["forcedTarget", objNull];
		private _forcedTime = _vehicle getVariable ["forcedTargetSetTime", 0];
		if(!(isNull _target)) then {
			_targetPos = getPosASLVisual _target;

		};
		if(_forcedTime >= (CBA_missionTime - 2)) then {
			if(!(isNull _forcedTarget)) then {

				_vehicle setVariable ["forcedTarget", objNull];
				_target = _forcedTarget;
				_targetPos = _vehicle getVariable ["forcedTargetPos", [0,0,0]];

				_vehicle setWeaponReloadingTime [(crew _vehicle)#0, currentMuzzle ((crew _vehicle)#0), 0];
			};
		};

		
	};
	
	if(!(isNull _target) || !(_targetPos isEqualTo [0,0,0])) then {

		private _missileType = IADS_AmmoToMissile get _ammo;


		if(!(isNil "_missileType")) then {
			[_missileType, _projectile, _target, _vehicle, _unit] call IADS_HookGuidanceLogic;
		};
	};	

};





IADS_HandleFiredEvent = {
	params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_vehicle"];

	if(!isNull _projectile && local _projectile) then {
		if(IADS_SAM_DEBUG == true) then {

			diag_log format ["IADS_HandleFiredEvent %1", _this];
		};

		private _missileTargetDesired = missileTarget _projectile;
		
		[_unit, _weapon, _muzzle, _mode, _ammo, _magazine, _projectile, _vehicle, _missileTargetDesired] call IADS_SAMOverride;
	};
};
["Man", "FiredMan", { 
	params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_vehicle"];
	
	_this call IADS_HandleFiredEvent;

}] call CBA_fnc_addClassEventHandler;


 /* else {
	["Man", "FiredMan", { 
		params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_vehicle"];

		if(IADS_SAM_DEBUG == true) then {
			
			diag_log format ["FiredMan triggered on local, projectile %1 from %2 out of %3, owner of projectile: %4, owner of unit: %5, owner of vehicle: %6, missile target of projectile %7", _projectile, _unit, _vehicle, owner _projectile, owner _unit, owner _vehicle, missileTarget _projectile];
		};
		// If something was local then they have the projectile on the event while others don't, however the logic should be guided by the server... probably.
		// Headless clients would run this too.. theoretically as they are not a server.
		[_unit, _weapon, _muzzle, _mode, _ammo, _magazine, _projectile, _vehicle, missileTarget _projectile] remoteExec ["IADS_HandleFiredEvent", 2];
	}] call CBA_fnc_addClassEventHandler;

};*/


/*
	Rewrite missile Guidance:
	We want missile Guidance to universally apply all laws of logic within Missile Guidance to all missiles & vehicles for example rather then having to manually define these vehicles.
*/

