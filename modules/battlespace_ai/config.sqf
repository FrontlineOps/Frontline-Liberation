// OVERALL BATTLESPACE AI LOGISTICS
BATTLESPACE_THRESHOLDS = createHashMap;

BATTLESPACE_SET_THRESHOLD = {
	params ["_sectorType", "_thresholdType", "_resourceType", "_value"];

	private _thresholdsData = BATTLESPACE_THRESHOLDS getOrDefault [_sectorType, createHashMap];

	private _thresholdData = _thresholdsData getOrDefault [_thresholdType, createHashMap];


	_thresholdData set [_resourceType, _value];

	_thresholdsData set [_thresholdType, _thresholdData];

	BATTLESPACE_THRESHOLDS set [_sectorType, _thresholdsData];
};

// Maximum amount that a sector type can store the type of resources.
// Higher amount = the bigger reserves the sector would have for various activities
// A zero amount means that the sector type can not hold the type of resource from any source.
// Non-zeros should be used for most types, but set to not be able to request off-map resupplies of the resource type and will rely on linked logistics to ferry specialist equipment around.
private _maximumCapacities = [
	[
		"military",
		createHashMapFromArray [
			["manpower", 300],
			["strategic_sam", 3],
			["strategic_missiles", 60],
			["tactical_sam", 3],
			["tactical_missiles", 60],
			["tanks", 8],
			["rocket_artillery", 3],
			["rockets", 240],
			["howitzers", 3],
			["mortars", 3],
			["spaag", 8],
			["ifv", 16],
			["apc", 16],
			["car", 32],
			["truck", 32]
		]
	],
	[
		"bigtown",
		createHashMapFromArray [
			["manpower", 240],
			["strategic_sam", 3],
			["strategic_missiles", 60],
			["tactical_sam", 3],
			["tactical_missiles", 60],
			["tanks", 8],
			["rocket_artillery", 3],
			["rockets", 240],
			["howitzers", 3],
			["mortars", 3],
			["spaag", 8],
			["ifv", 16],
			["apc", 16],
			["car", 32],
			["truck", 32]
		]
	],
	[
		"capture",
		createHashMapFromArray [
			["manpower", 240],
			["strategic_sam", 3],
			["strategic_missiles", 60],
			["tactical_sam", 3],
			["tactical_missiles", 60],
			["tanks", 8],
			["rocket_artillery", 3],
			["rockets", 240],
			["howitzers", 3],
			["mortars", 3],
			["spaag", 8],
			["ifv", 16],
			["apc", 16],
			["car", 32],
			["truck", 32]
		]
	],
	[
		"tower",
		createHashMapFromArray [
			["manpower", 240],
			["strategic_sam", 3],
			["strategic_missiles", 60],
			["tactical_sam", 3],
			["tactical_missiles", 60],
			["tanks", 8],
			["rocket_artillery", 3],
			["rockets", 240],
			["howitzers", 3],
			["mortars", 3],
			["spaag", 8],
			["ifv", 16],
			["apc", 16],
			["car", 32],
			["truck", 32]
		]
	],
	[
		"factory",
		createHashMapFromArray [
			["manpower", 240],
			["strategic_sam", 3],
			["strategic_missiles", 60],
			["tactical_sam", 3],
			["tactical_missiles", 60],
			["tanks", 8],
			["rocket_artillery", 3],
			["rockets", 240],
			["howitzers", 3],
			["mortars", 3],
			["spaag", 8],
			["ifv", 16],
			["apc", 16],
			["car", 32],
			["truck", 32]
		]
	]
];


// The higher the ratios, the more resources it needs before it can meet the requirements to be able to send an independent resupply to another sector using the current sector's stockpile.
// Meaning, the lower the ratio, the more likely the sector will meet the requirements and desire to send resources to a linked sector, with priority given to send resources to a frontline sector depending on the resource type. (i.e. strategic and tactical SAMs do not want to be on the frontline, but manpower should be)
// These should be high ratios, as the intent is that once a sector reaches high enough resources from off-map resupplies, it sends resources that other sectors can not request an emergency resupply of.
//    (i.e. strategic / tactical SAMs from military points to a town) or to naturally reinforce strongly linked frontline sectors at the expense of the second / third lines.
// NOTE: This one does NOT need to meet all thresholds to send. It will only send what it can give
private _resupplySendThresholds = [
	[
		"military",
		createHashMapFromArray [
			["manpower", 0.6],
			["strategic_sam", -1], // Can not send Strategic SAMs
			["strategic_missiles", -1],
			["tactical_sam", 0.66], // Once at 66% of stockpile reached, spread tactical SAMs to linked points that don't have them yet.
			["tactical_missiles", 0.66],
			["tanks", 0.6], // Once at 50% stockpile reached, spread tanks
			["rocket_artillery", 0.66], 
			["rockets", 0.66],
			["howitzers", 0.33],
			["mortars", 0.33],
			["spaag", 0.6],
			["ifv", 0.6],
			["apc", 0.6],
			["car", 0.6],
			["truck", 0.6]
		]
	],
	[
		"bigtown",
		createHashMapFromArray [
			["manpower", 0.5],
			["strategic_sam", 0.66],
			["strategic_missiles", 0.66],
			["tactical_sam", 0.66],
			["tactical_missiles", 0.66],
			["tanks", 0.5],
			["rocket_artillery", 0.66],
			["rockets", 0.66],
			["howitzers", 0.33],
			["mortars", 0.33],
			["spaag", 0.5],
			["ifv", 0.5],
			["apc", 0.5],
			["car", 0.5],
			["truck", 0.5]
		]
	],
	[
		"capture",
		createHashMapFromArray [
			["manpower", 0.5],
			["strategic_sam", 0.66],
			["strategic_missiles", 0.66],
			["tactical_sam", 0.66],
			["tactical_missiles", 0.66],
			["tanks", 0.5],
			["rocket_artillery", 0.66],
			["rockets", 0.66],
			["howitzers", 0.33],
			["mortars", 0.33],
			["spaag", 0.5],
			["ifv", 0.5],
			["apc", 0.5],
			["car", 0.5],
			["truck", 0.5]
		]
	],
	[
		"tower",
		createHashMapFromArray [
			["manpower", 0.5],
			["strategic_sam", 0.66],
			["strategic_missiles", 0.66],
			["tactical_sam", 0.66],
			["tactical_missiles", 0.66],
			["tanks", 0.5],
			["rocket_artillery", 0.66],
			["rockets", 0.66],
			["howitzers", 0.33],
			["mortars", 0.33],
			["spaag", 0.5],
			["ifv", 0.5],
			["apc", 0.5],
			["car", 0.5],
			["truck", 0.5]
		]
	],
	[
		"factory",
		createHashMapFromArray [
			["manpower", 0.5],
			["strategic_sam", 0.66],
			["strategic_missiles", 0.66],
			["tactical_sam", 0.66],
			["tactical_missiles", 0.66],
			["tanks", 0.5],
			["rocket_artillery", 0.66],
			["rockets", 0.66],
			["howitzers", 0.33],
			["mortars", 0.33],
			["spaag", 0.5],
			["ifv", 0.5],
			["apc", 0.5],
			["car", 0.5],
			["truck", 0.5]
		]
	]
];



// Higher ratios affect that the sector type will not want to send reinforcements unless its topped off. 
// Lower means that the sector may deplete its own stockpile to send reinforcements everytime a linked sector requests it
// NOTE: This one does NOT need to meet all thresholds to send. It will only send what it can give
// Sending reinforcements to linked sectors is independent of the normal battlespace consideratoin loop, and is instead event handler driven by the "Sector Defender" AI manager.
private _sendReinforcementsThresholds = [
	[
		"military",
		createHashMapFromArray [
			["manpower", 0.5],
			["strategic_sam", 0.66],
			["strategic_missiles", 0.66],
			["tactical_sam", 0.66],
			["tactical_missiles", 0.66],
			["tanks", 0.5],
			["rocket_artillery", 0.66],
			["rockets", 0.66],
			["howitzers", 0.33],
			["mortars", 0.33],
			["spaag", 0.5],
			["ifv", 0.5],
			["apc", 0.5],
			["car", 0.5],
			["truck", 0.5]
		]
	],
	[
		"bigtown",
		createHashMapFromArray [
			["manpower", 0.5],
			["strategic_sam", 0.66],
			["strategic_missiles", 0.66],
			["tactical_sam", 0.66],
			["tactical_missiles", 0.66],
			["tanks", 0.5],
			["rocket_artillery", 0.66],
			["rockets", 0.66],
			["howitzers", 0.33],
			["mortars", 0.33],
			["spaag", 0.5],
			["ifv", 0.5],
			["apc", 0.5],
			["car", 0.5],
			["truck", 0.5]
		]
	],
	[
		"capture",
		createHashMapFromArray [
			["manpower", 0.5],
			["strategic_sam", 0.66],
			["strategic_missiles", 0.66],
			["tactical_sam", 0.66],
			["tactical_missiles", 0.66],
			["tanks", 0.5],
			["rocket_artillery", 0.66],
			["rockets", 0.66],
			["howitzers", 0.33],
			["mortars", 0.33],
			["spaag", 0.5],
			["ifv", 0.5],
			["apc", 0.5],
			["car", 0.5],
			["truck", 0.5]
		]
	],
	[
		"tower",
		createHashMapFromArray [
			["manpower", 0.5],
			["strategic_sam", 0.66],
			["strategic_missiles", 0.66],
			["tactical_sam", 0.66],
			["tactical_missiles", 0.66],
			["tanks", 0.5],
			["rocket_artillery", 0.66],
			["rockets", 0.66],
			["howitzers", 0.33],
			["mortars", 0.33],
			["spaag", 0.5],
			["ifv", 0.5],
			["apc", 0.5],
			["car", 0.5],
			["truck", 0.5]
		]
	],
	[
		"factory",
		createHashMapFromArray [
			["manpower", 0.5],
			["strategic_sam", 0.66],
			["strategic_missiles", 0.66],
			["tactical_sam", 0.66],
			["tactical_missiles", 0.66],
			["tanks", 0.5],
			["rocket_artillery", 0.66],
			["rockets", 0.66],
			["howitzers", 0.33],
			["mortars", 0.33],
			["spaag", 0.5],
			["ifv", 0.5],
			["apc", 0.5],
			["car", 0.5],
			["truck", 0.5]
		]
	]
];

// Higher ratios affect how likely a sector type will want to start requesting a normal resupply (A resupply convoy from a backline Logistics Point / off map spawn point)
// There is a cap to how many resupplies requests will be fulfilled in one tick as well as active at any given time.
// Too high and it means it will request a resupply almost everytime its able to off cooldown.
// Too low and it means the point may never want to request a resupply if other ratios are off and it can't deplete its own reserves enough and will rely on linked sectors deciding to send reinforcements to it.
// NOTE: This one does NOT need to meet all thresholds to request a resupply. It will only request what it needs
private _regularResupplyRequestThreshold = [
	[
		"military",
		createHashMapFromArray [
			["manpower", 0.5],
			["strategic_sam", 0.66],
			["strategic_missiles", 0.66],
			["tactical_sam", 0.66],
			["tactical_missiles", 0.66],
			["tanks", 0.5],
			["rocket_artillery", 0.66],
			["rockets", 0.66],
			["howitzers", 0.33],
			["mortars", 0.33],
			["spaag", 0.5],
			["ifv", 0.5],
			["apc", 0.5],
			["car", 0.5],
			["truck", 0.5]
		]
	],
	[
		"bigtown",
		createHashMapFromArray [
			["manpower", 0.5],
			["strategic_sam", 0.66],
			["strategic_missiles", 0.66],
			["tactical_sam", 0.66],
			["tactical_missiles", 0.66],
			["tanks", 0.5],
			["rocket_artillery", 0.66],
			["rockets", 0.66],
			["howitzers", 0.33],
			["mortars", 0.33],
			["spaag", 0.5],
			["ifv", 0.5],
			["apc", 0.5],
			["car", 0.5],
			["truck", 0.5]
		]
	],
	[
		"capture",
		createHashMapFromArray [
			["manpower", 0.5],
			["strategic_sam", 0.66],
			["strategic_missiles", 0.66],
			["tactical_sam", 0.66],
			["tactical_missiles", 0.66],
			["tanks", 0.5],
			["rocket_artillery", 0.66],
			["rockets", 0.66],
			["howitzers", 0.33],
			["mortars", 0.33],
			["spaag", 0.5],
			["ifv", 0.5],
			["apc", 0.5],
			["car", 0.5],
			["truck", 0.5]
		]
	],
	[
		"tower",
		createHashMapFromArray [
			["manpower", 0.5],
			["strategic_sam", 0.66],
			["strategic_missiles", 0.66],
			["tactical_sam", 0.66],
			["tactical_missiles", 0.66],
			["tanks", 0.5],
			["rocket_artillery", 0.66],
			["rockets", 0.66],
			["howitzers", 0.33],
			["mortars", 0.33],
			["spaag", 0.5],
			["ifv", 0.5],
			["apc", 0.5],
			["car", 0.5],
			["truck", 0.5]
		]
	],
	[
		"factory",
		createHashMapFromArray [
			["manpower", 0.5],
			["strategic_sam", 0.66],
			["strategic_missiles", 0.66],
			["tactical_sam", 0.66],
			["tactical_missiles", 0.66],
			["tanks", 0.5],
			["rocket_artillery", 0.66],
			["rockets", 0.66],
			["howitzers", 0.33],
			["mortars", 0.33],
			["spaag", 0.5],
			["ifv", 0.5],
			["apc", 0.5],
			["car", 0.5],
			["truck", 0.5]
		]
	]
];


// Higher ratios affect how likely a sector type will want to start requesting an emergency resupply (A resupply convoy from a backline Logistics Point or an emergency air drop)
// Similar to normal resupplies, there is a cap to how many resupplies of this type will be fulfilled in one tick as well as active at any given time.
// Too high and it means it will request a resupply almost everytime its able to off cooldown.
// Too low and it means the point may never want to request a resupply if other ratios are off and it can't deplete its own reserves enough and will rely on linked sectors deciding to send reinforcements to it.
// NOTE: This one does NOT need to meet all thresholds to request a resupply. It will only request what it needs
// This and the regular resupply are different. A sector can potentially request both at one time and have them both fulfilled, meaning a large wave of off-map resupply.
// An emergency resupply request is independent of the normal battlespace consideration loop, and is instead event handler driven by the "Sector Defender" AI manager that also request reinforcements from nearby linked sectors.
// If no sector can spare reinforcements, an emergency resupply request may be dispatched as a last ditch effort to continue holding the sector.
// NEGATIVE RATIOS INDICATE THAT IT IS UNABLE TO REQUEST THAT RESOURCE TYPE
private _emergencyResupplyRequestThresholds = [
	[
		"military",
		createHashMapFromArray [
			["manpower", 0.5],
			["strategic_sam", 0.66],
			["strategic_missiles", 0.66],
			["tactical_sam", 0.66],
			["tactical_missiles", 0.66],
			["tanks", 0.5],
			["rocket_artillery", 0.66],
			["rockets", 0.66],
			["howitzers", 0.33],
			["mortars", 0.33],
			["spaag", 0.5],
			["ifv", 0.5],
			["apc", 0.5],
			["car", 0.5],
			["truck", 0.5]
		]
	],
	[
		"bigtown",
		createHashMapFromArray [
			["manpower", 0.5],
			["strategic_sam", 0.66],
			["strategic_missiles", 0.66],
			["tactical_sam", 0.66],
			["tactical_missiles", 0.66],
			["tanks", 0.5],
			["rocket_artillery", 0.66],
			["rockets", 0.66],
			["howitzers", 0.33],
			["mortars", 0.33],
			["spaag", 0.5],
			["ifv", 0.5],
			["apc", 0.5],
			["car", 0.5],
			["truck", 0.5]
		]
	],
	[
		"capture",
		createHashMapFromArray [
			["manpower", 0.5],
			["strategic_sam", 0.66],
			["strategic_missiles", 0.66],
			["tactical_sam", 0.66],
			["tactical_missiles", 0.66],
			["tanks", 0.5],
			["rocket_artillery", 0.66],
			["rockets", 0.66],
			["howitzers", 0.33],
			["mortars", 0.33],
			["spaag", 0.5],
			["ifv", 0.5],
			["apc", 0.5],
			["car", 0.5],
			["truck", 0.5]
		]
	],
	[
		"tower",
		createHashMapFromArray [
			["manpower", 0.5],
			["strategic_sam", 0.66],
			["strategic_missiles", 0.66],
			["tactical_sam", 0.66],
			["tactical_missiles", 0.66],
			["tanks", 0.5],
			["rocket_artillery", 0.66],
			["rockets", 0.66],
			["howitzers", 0.33],
			["mortars", 0.33],
			["spaag", 0.5],
			["ifv", 0.5],
			["apc", 0.5],
			["car", 0.5],
			["truck", 0.5]
		]
	],
	[
		"factory",
		createHashMapFromArray [
			["manpower", 0.5],
			["strategic_sam", 0.66],
			["strategic_missiles", 0.66],
			["tactical_sam", 0.66],
			["tactical_missiles", 0.66],
			["tanks", 0.5],
			["rocket_artillery", 0.66],
			["rockets", 0.66],
			["howitzers", 0.33],
			["mortars", 0.33],
			["spaag", 0.5],
			["ifv", 0.5],
			["apc", 0.5],
			["car", 0.5],
			["truck", 0.5]
		]
	]
];



// Higher ratios affect that the sector type needs more resources to mount a battlegroup
// Negative ratios means that the resource type is unavailable to send for a battlegroup.
// NOTE: This one MUST meet multiple thresholds to constitute a battlegroup.
// It does not need to meet all of them, but it must meet a fair amount that the AI commander logic will deem is necessary for an effective battlegroup.
// If it does not meet the requirements for a battlegroup, the sector would be limited to more passive operations until it gets resupplies
// This should essentially only be a thing for military sectors to be able to do.     xd
private _sendBattlegroupThresholds = [
	[
		"military",
		createHashMapFromArray [
			["manpower", 0.5],
			["strategic_sam", 0.66],
			["strategic_missiles", 0.66],
			["tactical_sam", 0.66],
			["tactical_missiles", 0.66],
			["tanks", 0.5],
			["rocket_artillery", 0.66],
			["rockets", 0.66],
			["howitzers", 0.33],
			["mortars", 0.33],
			["spaag", 0.5],
			["ifv", 0.5],
			["apc", 0.5],
			["car", 0.5],
			["truck", 0.5]
		]
	],
	[
		"bigtown",
		createHashMapFromArray [
			["manpower", 0.5],
			["strategic_sam", 0.66],
			["strategic_missiles", 0.66],
			["tactical_sam", 0.66],
			["tactical_missiles", 0.66],
			["tanks", 0.5],
			["rocket_artillery", 0.66],
			["rockets", 0.66],
			["howitzers", 0.33],
			["mortars", 0.33],
			["spaag", 0.5],
			["ifv", 0.5],
			["apc", 0.5],
			["car", 0.5],
			["truck", 0.5]
		]
	],
	[
		"capture",
		createHashMapFromArray [
			["manpower", 0.5],
			["strategic_sam", 0.66],
			["strategic_missiles", 0.66],
			["tactical_sam", 0.66],
			["tactical_missiles", 0.66],
			["tanks", 0.5],
			["rocket_artillery", 0.66],
			["rockets", 0.66],
			["howitzers", 0.33],
			["mortars", 0.33],
			["spaag", 0.5],
			["ifv", 0.5],
			["apc", 0.5],
			["car", 0.5],
			["truck", 0.5]
		]
	],
	[
		"tower",
		createHashMapFromArray [
			["manpower", 0.5],
			["strategic_sam", 0.66],
			["strategic_missiles", 0.66],
			["tactical_sam", 0.66],
			["tactical_missiles", 0.66],
			["tanks", 0.5],
			["rocket_artillery", 0.66],
			["rockets", 0.66],
			["howitzers", 0.33],
			["mortars", 0.33],
			["spaag", 0.5],
			["ifv", 0.5],
			["apc", 0.5],
			["car", 0.5],
			["truck", 0.5]
		]
	],
	[
		"factory",
		createHashMapFromArray [
			["manpower", 0.5],
			["strategic_sam", 0.66],
			["strategic_missiles", 0.66],
			["tactical_sam", 0.66],
			["tactical_missiles", 0.66],
			["tanks", 0.5],
			["rocket_artillery", 0.66],
			["rockets", 0.66],
			["howitzers", 0.33],
			["mortars", 0.33],
			["spaag", 0.5],
			["ifv", 0.5],
			["apc", 0.5],
			["car", 0.5],
			["truck", 0.5]
		]
	]
];

// Higher ratios affect that the sector type needs more resources to mount a patrol towards BLUFOR territory
// Negative ratios means that the resource type is unavailable to send for a patrol.
// NOTE: This one does not need to meet all thresholds to send. It will only send what it deems is capable.
// The resource types used for this is primarily
// manpower, cars, and ifv or apc.
private _combatPatrolThresholds = [
	[
		"military",
		createHashMapFromArray [
			["manpower", 0.5],
			["strategic_sam", 0.66],
			["strategic_missiles", 0.66],
			["tactical_sam", 0.66],
			["tactical_missiles", 0.66],
			["tanks", 0.5],
			["rocket_artillery", 0.66],
			["rockets", 0.66],
			["howitzers", 0.33],
			["mortars", 0.33],
			["spaag", 0.5],
			["ifv", 0.5],
			["apc", 0.5],
			["car", 0.5],
			["truck", 0.5]
		]
	],
	[
		"bigtown",
		createHashMapFromArray [
			["manpower", 0.5],
			["strategic_sam", 0.66],
			["strategic_missiles", 0.66],
			["tactical_sam", 0.66],
			["tactical_missiles", 0.66],
			["tanks", 0.5],
			["rocket_artillery", 0.66],
			["rockets", 0.66],
			["howitzers", 0.33],
			["mortars", 0.33],
			["spaag", 0.5],
			["ifv", 0.5],
			["apc", 0.5],
			["car", 0.5],
			["truck", 0.5]
		]
	],
	[
		"capture",
		createHashMapFromArray [
			["manpower", 0.5],
			["strategic_sam", 0.66],
			["strategic_missiles", 0.66],
			["tactical_sam", 0.66],
			["tactical_missiles", 0.66],
			["tanks", 0.5],
			["rocket_artillery", 0.66],
			["rockets", 0.66],
			["howitzers", 0.33],
			["mortars", 0.33],
			["spaag", 0.5],
			["ifv", 0.5],
			["apc", 0.5],
			["car", 0.5],
			["truck", 0.5]
		]
	],
	[
		"tower",
		createHashMapFromArray [
			["manpower", 0.5],
			["strategic_sam", 0.66],
			["strategic_missiles", 0.66],
			["tactical_sam", 0.66],
			["tactical_missiles", 0.66],
			["tanks", 0.5],
			["rocket_artillery", 0.66],
			["rockets", 0.66],
			["howitzers", 0.33],
			["mortars", 0.33],
			["spaag", 0.5],
			["ifv", 0.5],
			["apc", 0.5],
			["car", 0.5],
			["truck", 0.5]
		]
	],
	[
		"factory",
		createHashMapFromArray [
			["manpower", 0.5],
			["strategic_sam", 0.66],
			["strategic_missiles", 0.66],
			["tactical_sam", 0.66],
			["tactical_missiles", 0.66],
			["tanks", 0.5],
			["rocket_artillery", 0.66],
			["rockets", 0.66],
			["howitzers", 0.33],
			["mortars", 0.33],
			["spaag", 0.5],
			["ifv", 0.5],
			["apc", 0.5],
			["car", 0.5],
			["truck", 0.5]
		]
	]
];

// State for each sector, including the resources.
BATTLESPACE_SECTOR_STATES = createHashMap;


{
	_x params ["_sectorType", "_resourceDefs"];

	{
		private _resourceType = _x;
		private _value = _y;
		[_sectorType, "MaximumCapacity", _resourceType, _value] call BATTLESPACE_SET_THRESHOLD;
	} forEach _resourceDefs;
} forEach _maximumCapacities;


{
	_x params ["_sectorType", "_resourceDefs"];

	{
		private _resourceType = _x;
		private _value = _y;
		[_sectorType, "ResupplySend", _resourceType, _value] call BATTLESPACE_SET_THRESHOLD;
	} forEach _resourceDefs;
} forEach _resupplySendThresholds;


{
	_x params ["_sectorType", "_resourceDefs"];

	{
		private _resourceType = _x;
		private _value = _y;
		[_sectorType, "SendReinforcements", _resourceType, _value] call BATTLESPACE_SET_THRESHOLD;
	} forEach _resourceDefs;
} forEach _sendReinforcementsThresholds;

{
	_x params ["_sectorType", "_resourceDefs"];

	{
		private _resourceType = _x;
		private _value = _y;
		[_sectorType, "Resupply", _resourceType, _value] call BATTLESPACE_SET_THRESHOLD;
	} forEach _resourceDefs;
} forEach _regularResupplyRequestThreshold;

{
	_x params ["_sectorType", "_resourceDefs"];

	{
		private _resourceType = _x;
		private _value = _y;
		[_sectorType, "EmergencyResupply", _resourceType, _value] call BATTLESPACE_SET_THRESHOLD;
	} forEach _resourceDefs;
} forEach _emergencyResupplyRequestThresholds;

{
	_x params ["_sectorType", "_resourceDefs"];

	{
		private _resourceType = _x;
		private _value = _y;
		[_sectorType, "Battlegroup", _resourceType, _value] call BATTLESPACE_SET_THRESHOLD;
	} forEach _resourceDefs;
} forEach _sendBattlegroupThresholds;

{
	_x params ["_sectorType", "_resourceDefs"];

	{
		private _resourceType = _x;
		private _value = _y;
		[_sectorType, "Patrol", _resourceType, _value] call BATTLESPACE_SET_THRESHOLD;
	} forEach _resourceDefs;
} forEach _combatPatrolThresholds;

// Aircraft are paid strategic assets for funded rotary defenders. Current
// reinforcement, battlegroup, and patrol constructors are ground-only.
private _aircraftThresholdPolicy = createHashMapFromArray [
	["MaximumCapacity", 2],
	["ResupplySend", 0.5],
	["SendReinforcements", -1],
	["Resupply", 0.5],
	["EmergencyResupply", 0.5],
	["Battlegroup", -1],
	["Patrol", -1]
];
{
	private _sectorType = _x;
	{
		[_sectorType, _x, "aircraft", _y] call BATTLESPACE_SET_THRESHOLD;
	} forEach _aircraftThresholdPolicy;
} forEach ["military", "bigtown", "capture", "tower", "factory"];


// SAMS
BATTLESPACE_SAM_SITE_LIMIT = 4;
BATTLESPACE_SAM_SITE_COMPOSITION = createHashMapFromArray [
	[
		"TEL",
		1
	],
	[
		"FCR",
		1
	]
];
BATTLESPACE_SAM_SITE_TELS = [
	"karmakut_sa15",
	"karmakut_sa20"
];

BATTLESPACE_SAM_SITE_FCRS = [
	"karmakut_9s32"
];

BATTLESPACE_SAM_SITE_SHORAD = [
	["UK3CB_KDF_O_Igla_AA_pod"]
];

BATTLESPACE_SAM_PROC_RANGE = 6000;
BATTLESPACE_SAM_MAX_SPAWN_RANGE = 1000;
// 2hr 20m
BATTLESPACE_SAM_SPAWN_COOLDOWN = 8400;
BATTLESPACE_USE_SAM_SPAWN_DELAY = false;
BATTLESPACE_ENABLE_SAM_SPAWNS = true;
BATTLESPACE_SAM_SPAWN_CHANCE = 0.50;
BATTLESPACE_SAM_DELAY = 300;
