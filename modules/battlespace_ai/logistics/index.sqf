
// Sector resources
/*
	Looping:
	If garrison task force is procced then check for distance to blufor if it was due to ground or not. If yes then we skip it.
	{
		garrisonTaskForce: string // Central task force. All additional manpower / vehicles are allocated to this task force at the end. It's composition is also considered part of the resources at the start of decision frame if not procced
		defenderTaskForces: Array<string> // Fortifications, Emplacements, Inner Patrols
		outerLayerTaskForces: Array<string> // Patrols, Outposts, etc... keep track so we're not stacking up to infinite
		offensiveTaskForces: Array<string> // ATGM OPs, ambush points, other offensive operations on the BLUFOR side of territory.
		Even so much as sending out movement to contact patrols towards known BLUFOR positions / checkpoints, etc.
		resources: {
			manpower: number,
			supplies: number,
			vehicles: Array<string>
		} 
	}

*/
if(isNil { BATTLESPACE_SECTORS }) then {
	BATTLESPACE_SECTORS = createHashMap;
};


// Array<string> of sectors
BATTLESPACE_SECTORS_COUNTEROFFENSIVE_STAGING_AREAS = [];
/*

{
	[key: TaskForceId]: sectorTarget
}
*/
BATTLESPACE_SECTORS_COUNTEROFFENSIVE_TARGETS = createHashMap;

// Depending on how far it keeps ticking, ramp up convoy counts until we get to a counteroffensive
BATTLESPACE_SECTORS_COUNTEROFFENSIVE_REMAINING_COOLDOWN = 0;

// Minimum range in real time before counteroffensive stock time happens again
BATTLESPACE_SECTORS_COUNTEROFFENSIVE_MIN_RANGE_HOURS = 8;
// Maximum range in real time before counteroffensive stock time happens again
BATTLESPACE_SECTORS_COUNTEROFFENSIVE_MAX_RANGE_HOURS = 16;

// Remaining time before step off 
// Amount of intel and civ rep causes a longer time to go.
// At time of Tgo being set, a notification of large troop movements towards a front along with a general circle. The averages of the staging areas add up to a marker position with the radius of the maximum distance between the sectors.
// At Tgo = 0, resources are consumed and virtual groups sent out, from the sectors that are still not yet procced.
BATTLESPACE_SECTORS_COUNTEROFFENSIVE_TIME_TO_GO = 0;

// Counter offensive task forces. Once all groups become invalid, we can reset the cooldown and begin the process all over again and delete the build up marker
BATTLESPACE_SECTORS_COUNTEROFFENSIVE_GROUPS = [];

BATTLESPACE_LOGISTICS_SAVE_KEY = format ["Battlespace/Logistics/%1", toUpper worldName];
BATTLESPACE_LOGISTICS_LOAD = {


	true
};

BATTLESPACE_LOGISTICS_SAVE = {

};


/*
LOGISTICS:

Global Logistics:

For each sectors at depth 3 - 5:
	Is sector linked to a logistics point?
	YES:
		Determine how badly the sector needs to be resupplied as number and push
Sort resupply priorities
for 1 to MaximumConvoysPerFrame:
	Fulfill highest priority resupply
		Determine amount of manpower being sent
		Determine how many vehicles / armor to be sent
		Determine amount of filler trucks to be sent (Configs for vehicle seats need to be setup?)
		Determine random amount of supplies that are contained

Cascading Logi:

Sectors that can cascade down must be at depth 3, up to depth 5

1) Check for sectors selected to be the staging area for a counter-offensive, prioritize sending cascading supplies down to it if possible, including laterally from same depth sectors
	1a) Look for connected sectors that can cascade down with enough resources
		YES - Send out convoy, add sector to visited list, including the one that sent reinforcements
		NO - Continue searching until no remaining left
2) Check for frontline sectors to cascade down towards.
	repeat 1a, but sectors that are stocking up will not send anything



*/
BATTLESPACE_LOGISTICS_INIT = {


	// Load saves
	// If there's a mismatch somewhere we don't need to nuke everything but we need to initialize what's missing
};

BATTLESPACE_SECTORS_DECIDE_PLACE_NEW_FORTIFICATION = { };
BATTLESPACE_SECTORS_DECIDE_PLACE_NEW_EMPLACEMENT = {};
BATTLESPACE_SECTORS_DECIDE_PLACE_NEW_OUTPOST = {};

BATTLESPACE_SECTORS_DECISION_TICK = {


	// Look at all sectors up to depth 4
	// Look at resource pool including garrison task force
	
	// If building up for counter-offensive - Skip all operations except fortification operations, we want to save up those resources.
	// Fortification operations - Spend supplies to build fortifications, roadblocks, emplacements
	// Defensive operations - Patrols, set up defensive outposts (i.e. checkpoints)
	// Offensive operations - Emplacement teams with the intent to setup ATGMs or other impactful weapons at a more forward, stationary point. Movement to contact foot patrols

	// Counter-offensive operations - If counter-offensive is set to enabled, then evaluate if the desired sectors have reached the resources needed to mount the offensive. If yes, then we call to have the counter-offensive start
};










BATTLESPACE_LOGISTICS = {
	params ["_sector", "_frontline", "_nextLine"];

	if(!canSuspend) exitWith { _this spawn BATTLESPACE_LOGISTICS };

	

	// Construct what sectors are in need of resupply
	private _frontlineSectors = [blufor_sectors + ["startbase_marker"], 1] call NETWORKED_SECTORS_GET_SECTORS_UP_TO_COST;

	private _remainingResuppliesThisFrame = 5;

	{
		_x params ["_cost", "_sector"];
		if(_remainingResuppliesThisFrame <= 0) exitWith {};


		private _resupplySectors = [_sector, "logistics_spawn", blufor_sectors + ["startbase_marker"]] call NETWORKED_SECTORS_traverseGraphAndFindSectorsOfType;

		

		if((count _resupplySectors) > 0) then {
			private _resupplySector = selectRandom _resupplySectors;
			private _spawnPos = getMarkerPos _resupplySector;

			private _roads = _spawnPos nearRoads 200;

			if((count _roads) > 0) then {
				_spawnPos = getPos (selectRandom _roads);
			};

			private _composition = createHashMapFromArray [
				["manpower", 21],
				["vehicles", ["rhs_bmd4_vdv","rhs_btr80_vdv","rhs_bmd2k"]],
				["structures", []]
			];

			["Convoy", _composition, _spawnPos, getMarkerPos _sector, getMarkerPos _resupplySector] call BATTLESPACE_TASK_FORCES_INIT;
			_remainingResuppliesThisFrame = _remainingResuppliesThisFrame - 1;
			sleep 10;
		};
	} forEach _frontlineSectors;
};
