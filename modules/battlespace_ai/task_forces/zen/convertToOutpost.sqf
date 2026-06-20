private _statement = {
	params ["_position", "_objects", "_groups", "_waypoints", "_markers", "_hoveredEntity", "_args"];

	private _structures = [];
	private _vehicles = [];

	private _structAdded = [];
	private _pStructAdded = [];
	private _vehsAdded = [];
	private _pVehAdded = [];

	private _insertedObjects = [];
	{
		private _dName = (getText (configFile >> "CfgVehicles" >> typeOf _x >> "displayName"));
		if((_x isKindOf "Building") || (_x isKindOf "StaticWeapon")) then {
			_structures pushBack createHashMapFromArray [
				["position", getPos _x],
				["rotation", getDir _x],
				["className", typeOf _x]
			];

			_insertedObjects pushBack _x;
			_structAdded pushBack _dName;
			_pStructAdded pushBack [_dName, "", ""];
		} else {

			if((_x isKindOf "Tank") || (_x isKindOf "Car")) then {
				_vehicles pushBack (typeOf _x);
				_insertedObjects pushBack _x;

				_vehsAdded pushBack _dName;
				_pVehAdded pushBack [_dName, "", ""];
			};
		};
	} forEach _objects;
	systemChat format ["Test %1", _structAdded];

	if((count _vehsAdded) <= 0) then {
		_vehsAdded = ["NO VEHICLES SELECTED"];
		_pVehAdded = [["NO VEHICLES SELECTED"]];
	};
	if((count _structAdded) <= 0) then {
		_structAdded = ["NO BUILDINGS SELECTED"];
		_pStructAdded = [["NO BUILDINGS SELECTED"]];
	};
	private _controls = [
		["SLIDER", "Manpower", [6, 60, 6, 0]],
		["LIST", "Buildings Selected", [
			_structAdded,
			_pStructAdded
		]],
		["LIST", "Vehicles Selected", [
			_vehsAdded,
			_pVehAdded
		]]
	];
	

	private _onConfirm = {
		params ["_values", "_args"];

		_args params ["_structures", "_vehicles", "_insertedObjects", "_position"];

		_position set [2, 0];

		private _composition = createHashMapFromArray [
			["manpower", round (_values#0)],
			["structures", _structures],
			["vehicles", _vehicles]
		];

		["Outpost", _composition, _position, [], _position] remoteExec ["BATTLESPACE_TASK_FORCES_INIT", 2];

		{
			deleteVehicle _x;
		} forEach _insertedObjects;

	};
	private _onCancel = {};
	["CREATE OUTPOST", _controls, _onConfirm, _onCancel, [_structures, _vehicles, _insertedObjects, _position]] call zen_dialog_fnc_create;
};

private _condition = {
	params ["_position", "_objects", "_groups", "_waypoints", "_markers", "_hoveredEntity", "_args"];

	(count _objects > 0)
};

private _action = ["convertToOutpost", "Convert to Outpost", ["", [1,1,1,1]], _statement, _condition] call zen_context_menu_fnc_createAction;
[_action, ["battlespaceAI"], 0] call zen_context_menu_fnc_addAction;