private _statement = {
	params ["_position", "_objects", "_groups", "_waypoints", "_markers", "_hoveredEntity", "_args"];

	private _structures = [];
	private _vehicles = [];

	private _vehsAdded = [];
	private _pVehAdded = [];

	private _insertedObjects = [];
	{
		private _dName = (getText (configFile >> "CfgVehicles" >> typeOf _x >> "displayName"));
		

		if((_x isKindOf "Tank") || (_x isKindOf "Car")) then {
			_vehicles pushBack (typeOf _x);
			_insertedObjects pushBack _x;

			_vehsAdded pushBack _dName;
			_pVehAdded pushBack [_dName, "", ""];
		};
		
	} forEach _objects;

	if((count _vehsAdded) <= 0) then {
		_vehsAdded = ["NO VEHICLES SELECTED"];
		_pVehAdded = [["NO VEHICLES SELECTED"]];
	};
	private _controls = [
		["SLIDER", "Manpower", [6, 60, 6, 0]],
		["LIST", "Vehicles Selected", [
			_vehsAdded,
			_pVehAdded
		]],
		["CHECKBOX", "Tied to Sector", [true]]
	];
	

	private _onConfirm = {
		params ["_values", "_args"];

		_args params ["_structures", "_vehicles", "_insertedObjects", "_position"];

		private _composition = createHashMapFromArray [
			["manpower", round (_values#0)],
			["structures", _structures],
			["vehicles", _vehicles]
		];


		private _tied = _values#2;

		systemChat format ["Confirm placement %1 | %2 | Composition %3", _values#0, _values#2, _composition];

		private _homePointSector = [sectors_allSectors - blufor_sectors, _position] call BIS_fnc_nearestPosition;

		_position set [2, 0];

		private _homePoint = _position;

		if(!_tied) then {
			_homePoint = getMarkerPos _homePointSector;
		};

		["Defensive Patrol", _composition, _position, _position, _homePoint] remoteExec ["BATTLESPACE_TASK_FORCES_INIT", 2];

		{
			deleteVehicle _x;
		} forEach _insertedObjects;

	};
	private _onCancel = {};
	["CREATE PATROL", _controls, _onConfirm, _onCancel, [_structures, _vehicles, _insertedObjects, _position]] call zen_dialog_fnc_create;
};

private _condition = {
	params ["_position", "_objects", "_groups", "_waypoints", "_markers", "_hoveredEntity", "_args"];

	true
};

private _modifier = {
	(_this select 1) params ["_position", "_objects", "_groups", "_waypoints", "_markers", "_hoveredEntity", "_args"];
	private _vehicles = [];
	{
		
		

		if((_x isKindOf "Tank") || (_x isKindOf "Car")) then {
			_vehicles pushBack (typeOf _x);
		};
		
	} forEach _objects;
	if((count _vehicles) > 0) then {
		(_this select 0) set [1, "Convert Vehicles to Patrol"];
	} else {
		(_this select 0) set [1, "Place Infantry Patrol"];
	};
};

private _action = ["placePatrol", "Place Patrol", ["", [1,1,1,1]], _statement, _condition, [], {}, _modifier] call zen_context_menu_fnc_createAction;
[_action, ["battlespaceAI"], 0] call zen_context_menu_fnc_addAction;