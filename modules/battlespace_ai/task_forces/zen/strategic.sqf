BATTLESPACE_ZEN_STRATEGIC_OVERLAY = false;
BATTLESPACE_ZEN_STRATEGIC_OVERLAY_DATA = [[], []];
BATTLESPACE_ZEN_STRATEGIC_OVERLAY_PFH = -1;

BATTLESPACE_ZEN_FORMAT_DURATION = {
	params ["_seconds"];
	private _value = ceil (_seconds max 0);
	private _remainder = _value mod 60;
	format ["%1:%2", floor (_value / 60), if (_remainder < 10) then {"0" + str _remainder} else {str _remainder}]
};

BATTLESPACE_ZEN_SHOW_SECTOR_SNAPSHOT = {
	params ["_snapshot"];
	if (_snapshot isEqualTo []) exitWith {hintSilent "No Battlespace sector found."};
	_snapshot params ["_sector", "_type", "_owner", "_stock", "_pressure", "_cooldowns", "_operations"];
	private _lines = [format ["<t size='1.25'>%1</t><br/>%2 / %3<br/>Casualty pressure: %4<br/><br/>", _sector, _owner, _type, _pressure]];
	{
		_x params ["_resource", "_amount", "_capacity", ["_shortage", false]];
		private _ratio = if (_capacity > 0) then {round (100 * _amount / _capacity)} else {0};
		_lines pushBack format ["%1%2: %3 / %4 (%5%%)<br/>", if (_shortage) then {"<t color='#ff9c75'>SHORT </t>"} else {""}, _resource, _amount, _capacity, _ratio];
	} forEach _stock;
	_cooldowns params ["_resupply", "_emergency", "_reinforcement", "_deepRecon", "_battlegroup", ["_airResponse", 0], ["_fortification", 0], ["_minefield", 0]];
	_lines pushBack format ["<br/>Cooldowns — supply %1, emergency %2, reinforcement %3, deep recon %4, battlegroup %5, air %6, construction %7, mines %8<br/>",
		[_resupply] call BATTLESPACE_ZEN_FORMAT_DURATION,
		[_emergency] call BATTLESPACE_ZEN_FORMAT_DURATION,
		[_reinforcement] call BATTLESPACE_ZEN_FORMAT_DURATION,
		[_deepRecon] call BATTLESPACE_ZEN_FORMAT_DURATION,
		[_battlegroup] call BATTLESPACE_ZEN_FORMAT_DURATION,
		[_airResponse] call BATTLESPACE_ZEN_FORMAT_DURATION,
		[_fortification] call BATTLESPACE_ZEN_FORMAT_DURATION,
		[_minefield] call BATTLESPACE_ZEN_FORMAT_DURATION
	];
	if (_operations isEqualTo []) then {
		_lines pushBack "Operations: none";
	} else {
		_lines pushBack "Operations:<br/>";
		{_lines pushBack format ["%1 — %2 / %3<br/>", _x#0, _x#1, _x#2]} forEach _operations;
	};
	hintSilent parseText (_lines joinString "");
};

BATTLESPACE_ZEN_RECEIVE_SNAPSHOT = {
	params ["_action", "_payload"];
	if (!hasInterface) exitWith {};
	switch (_action) do {
		case "OVERLAY": {BATTLESPACE_ZEN_STRATEGIC_OVERLAY_DATA = _payload};
		case "AUDIT";
		case "SELF_TEST": {
			_payload params [["_errors", []], ["_warnings", []], ["_sectorCount", 0], ["_operationCount", 0]];
			private _title = ["Battlespace Integrity Audit", "Battlespace Resource/Persistence Self-Test"] select (_action == "SELF_TEST");
			private _lines = [format ["<t size='1.25'>%1</t><br/>Sectors: %2 / Operations: %3<br/>Errors: %4 / Warnings: %5<br/><br/>", _title, _sectorCount, _operationCount, count _errors, count _warnings]];
			{_lines pushBack format ["<t color='#ff6b6b'>ERROR</t> %1<br/>", _x]} forEach _errors;
			{_lines pushBack format ["<t color='#ffd166'>WARN</t> %1<br/>", _x]} forEach _warnings;
			if (_errors isEqualTo [] && {_warnings isEqualTo []}) then {_lines pushBack "All checked invariants pass."};
			hintSilent parseText (_lines joinString "");
		};
		case "BALANCE": {
			_payload params [["_resourceRows", []], ["_operationRows", []], ["_settings", []]];
			private _lines = ["<t size='1.25'>Battlespace Balance Report</t><br/><br/>"];
			{
				_x params ["_resource", "_amount", "_capacity", "_shortages"];
				private _ratio = if (_capacity > 0) then {round (100 * _amount / _capacity)} else {0};
				_lines pushBack format ["%1: %2 / %3 (%4%%), short sectors %5<br/>", _resource, _amount, _capacity, _ratio, _shortages];
			} forEach _resourceRows;
			_lines pushBack "<br/>Operation pressure:<br/>";
			{_lines pushBack format ["%1: %2%3<br/>", _x#0, _x#1, if ((_x#2) < 0) then {""} else {" / " + str (_x#2)}]} forEach _operationRows;
			_settings params [["_decision", 0], ["_airDecision", 0], ["_pressure", 0], ["_emergency", 0], ["_reinforcement", 0], ["_deepRecon", 0], ["_airResponse", 0], ["_fortification", 0], ["_minefield", 0]];
			_lines pushBack format ["<br/>Strategic decision %1; air decision %2; casualty trigger %3; cooldowns E/R/D/A/F/M %4/%5/%6/%7/%8/%9",
				[_decision] call BATTLESPACE_ZEN_FORMAT_DURATION,
				[_airDecision] call BATTLESPACE_ZEN_FORMAT_DURATION,
				_pressure,
				[_emergency] call BATTLESPACE_ZEN_FORMAT_DURATION,
				[_reinforcement] call BATTLESPACE_ZEN_FORMAT_DURATION,
				[_deepRecon] call BATTLESPACE_ZEN_FORMAT_DURATION,
				[_airResponse] call BATTLESPACE_ZEN_FORMAT_DURATION,
				[_fortification] call BATTLESPACE_ZEN_FORMAT_DURATION,
				[_minefield] call BATTLESPACE_ZEN_FORMAT_DURATION
			];
			hintSilent parseText (_lines joinString "");
		};
		case "OVERVIEW";
		case "RUN_DECISION";
		case "SAVE": {
			_payload params [["_sectorCount", 0], ["_forceCount", 0], ["_counts", []]];
			private _lines = [format ["<t size='1.25'>Battlespace Strategic Overview</t><br/>Sectors: %1<br/>Logical task forces: %2<br/><br/>", _sectorCount, _forceCount]];
			{_lines pushBack format ["%1: %2<br/>", _x#0, _x#1]} forEach _counts;
			hintSilent parseText (_lines joinString "");
		};
		default {[_payload] call BATTLESPACE_ZEN_SHOW_SECTOR_SNAPSHOT};
	};
};

BATTLESPACE_ZEN_STRATEGIC_OVERLAY_RENDER = {
	if (!BATTLESPACE_ZEN_STRATEGIC_OVERLAY || {isNull curatorCamera}) exitWith {};
	BATTLESPACE_ZEN_STRATEGIC_OVERLAY_DATA params [["_sectors", []], ["_operations", []]];
	{
		_x params ["_sector", "_position", "_owner", "_fillRatio", "_pressure"];
		private _color = if (_owner == "OPFOR") then {[1, 0.25, 0.2, 0.9]} else {[0.2, 0.45, 1, 0.75]};
		private _height = +_position;
		_height set [2, 35];
		drawIcon3D ["\A3\ui_f\data\map\markers\nato\o_support.paa", _color, _height, 0.7, 0.7, 0,
			format ["%1 | STOCK %2%% | PRESS %3", _sector, round (100 * _fillRatio), _pressure], 1, 0.025, "TahomaB"];
	} forEach _sectors;
	{
		_x params ["_id", "_kind", "_phase", "_current", "_destination", ["_routeData", []]];
		if (_current isEqualTo []) then {continue};
		if (_kind in ["FORTIFICATION", "MINEFIELD"]) then {
			private _sitePosition = +_current;
			if (count _sitePosition == 2) then {_sitePosition pushBack 0};
			_sitePosition set [2, 35];
			private _icon = ["\A3\ui_f\data\map\markers\nato\o_installation.paa", "\a3\Ui_F_Curator\Data\CfgMarkers\minefield_ca.paa"] select (_kind == "MINEFIELD");
			drawIcon3D [_icon, [1, 0.35, 0.15, 0.95], _sitePosition, 0.8, 0.8, 0,
				format ["%1 %2 / %3", _kind, _id, _phase], 1, 0.025, "TahomaB"];
			continue;
		};
		if (_destination isEqualTo []) then {continue};
		[_current, _routeData, [1, 0.75, 0.1, 0.8]] call BATTLESPACE_TASK_FORCE_DRAW_ROUTE_3D;
		private _labelPosition = +_current;
		_labelPosition set [2, 50];
		drawIcon3D ["\A3\ui_f\data\map\groupicons\waypoint.paa", [1, 0.75, 0.1, 0.9], _labelPosition, 0.6, 0.6, 0,
			format ["%1 %2 / %3 | %4", _kind, _id, _phase, [_routeData] call BATTLESPACE_TASK_FORCE_ROUTE_LABEL], 1, 0.025, "TahomaB"];
		private _destinationPosition = +_destination;
		if (count _destinationPosition == 2) then {_destinationPosition pushBack 0};
		_destinationPosition set [2, 35];
		drawIcon3D ["\A3\ui_f\data\map\groupicons\selector_selectedEnemy_ca.paa", [1, 0.75, 0.1, 0.9], _destinationPosition, 0.6, 0.6, 0,
			format ["%1 DESTINATION", _id], 1, 0.022, "TahomaB"];
	} forEach _operations;
};

BATTLESPACE_ZEN_TOGGLE_STRATEGIC_OVERLAY = {
	BATTLESPACE_ZEN_STRATEGIC_OVERLAY = !BATTLESPACE_ZEN_STRATEGIC_OVERLAY;
	if (BATTLESPACE_ZEN_STRATEGIC_OVERLAY) then {
		["OVERLAY", screenToWorld getMousePosition] remoteExecCall ["BATTLESPACE_ZEN_SERVER_REQUEST", 2];
		BATTLESPACE_ZEN_STRATEGIC_OVERLAY_PFH = [{
			(_this#0) params [["_nextRefresh", 0]];
			if (!BATTLESPACE_ZEN_STRATEGIC_OVERLAY) exitWith {[_this#1] call CBA_fnc_removePerFrameHandler};
			if (CBA_missionTime >= _nextRefresh) then {
				["OVERLAY", screenToWorld getMousePosition] remoteExecCall ["BATTLESPACE_ZEN_SERVER_REQUEST", 2];
				(_this#0) set [0, CBA_missionTime + 5];
			};
			[] call BATTLESPACE_ZEN_STRATEGIC_OVERLAY_RENDER;
		}, 0, [0]] call CBA_fnc_addPerFrameHandler;
	} else {
		if (BATTLESPACE_ZEN_STRATEGIC_OVERLAY_PFH >= 0) then {[BATTLESPACE_ZEN_STRATEGIC_OVERLAY_PFH] call CBA_fnc_removePerFrameHandler};
		BATTLESPACE_ZEN_STRATEGIC_OVERLAY_PFH = -1;
		BATTLESPACE_ZEN_STRATEGIC_OVERLAY_DATA = [[], []];
	};
};

BATTLESPACE_ZEN_CONFIRM_SERVER_ACTION = {
	params ["_action", "_position", "_title"];
	[
		_title,
		[["CHECKBOX", "Confirm server-side test action", [false]]],
		{params ["_values", "_args"]; if (_values#0) then {_args remoteExecCall ["BATTLESPACE_ZEN_SERVER_REQUEST", 2]}},
		{},
		[_action, _position]
	] call zen_dialog_fnc_create;
};

private _overview = ["battlespaceStrategicOverview", "Strategic Overview", ["", [1,1,1,1]], {
	["OVERVIEW", _this#0] remoteExecCall ["BATTLESPACE_ZEN_SERVER_REQUEST", 2];
}, {true}] call zen_context_menu_fnc_createAction;
[_overview, ["battlespaceAI"], 0] call zen_context_menu_fnc_addAction;

private _inspect = ["battlespaceInspectSector", "Inspect Nearest Sector", ["", [1,1,1,1]], {
	["INSPECT", _this#0] remoteExecCall ["BATTLESPACE_ZEN_SERVER_REQUEST", 2];
}, {true}] call zen_context_menu_fnc_createAction;
[_inspect, ["battlespaceAI"], 0] call zen_context_menu_fnc_addAction;

private _audit = ["battlespaceIntegrityAudit", "Run Integrity Audit", ["", [1,1,1,1]], {
	["AUDIT", _this#0] remoteExecCall ["BATTLESPACE_ZEN_SERVER_REQUEST", 2];
}, {true}] call zen_context_menu_fnc_createAction;
[_audit, ["battlespaceAI"], 0] call zen_context_menu_fnc_addAction;

private _balance = ["battlespaceBalanceReport", "Show Balance Report", ["", [1,1,1,1]], {
	["BALANCE", _this#0] remoteExecCall ["BATTLESPACE_ZEN_SERVER_REQUEST", 2];
}, {true}] call zen_context_menu_fnc_createAction;
[_balance, ["battlespaceAI"], 0] call zen_context_menu_fnc_addAction;

private _overlay = ["battlespaceStrategicOverlay", "Toggle Strategic Overlay + Live Routes", ["", [1,1,1,1]], {
	[] call BATTLESPACE_ZEN_TOGGLE_STRATEGIC_OVERLAY;
}, {true}] call zen_context_menu_fnc_createAction;
[_overlay, ["battlespaceAI"], 0] call zen_context_menu_fnc_addAction;

{
	_x params ["_id", "_label", "_action"];
	private _zenAction = [_id, _label, ["", [1,0.75,0.2,1]], {
		params ["_position", "_objects", "_groups", "_waypoints", "_markers", "_hoveredEntity", "_args"];
		_args params ["_serverAction", "_dialogTitle"];
		[_serverAction, _position, _dialogTitle] call BATTLESPACE_ZEN_CONFIRM_SERVER_ACTION;
	}, {true}, [_action, _label]] call zen_context_menu_fnc_createAction;
	[_zenAction, ["battlespaceAI"], 0] call zen_context_menu_fnc_addAction;
} forEach [
	["battlespaceRunDecision", "Run Strategic Decision Tick (Test)", "RUN_DECISION"],
	["battlespaceSave", "Save Strategic State (Test)", "SAVE"],
	["battlespaceSelfTest", "Run Resource/Persistence Self-Test", "SELF_TEST"],
	["battlespaceEmergency", "Request Emergency Response (Test)", "EMERGENCY"],
	["battlespaceRefill", "Refill Nearest OPFOR Sector (Test)", "REFILL"],
	["battlespaceDrain", "Drain Nearest OPFOR Sector (Test)", "DRAIN"],
	["battlespaceFortify", "Construct Nearest OPFOR Site (Test)", "FORTIFY"],
	["battlespaceMinefield", "Construct Nearest OPFOR Minefield (Test)", "MINE"]
];
