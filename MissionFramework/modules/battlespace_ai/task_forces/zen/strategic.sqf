BATTLESPACE_ZEN_STRATEGIC_OVERLAY = false;
BATTLESPACE_ZEN_STRATEGIC_OVERLAY_DATA = [[], []];
BATTLESPACE_ZEN_STRATEGIC_OVERLAY_PFH = -1;
BATTLESPACE_ZEN_CELL_LINES = [];

// Control cells near the cursor as line segments, built once per snapshot: each cell an inset
// square (red OPFOR .. grey .. blue BLUFOR, yellow contested; thick when a dead-space squad
// is posted there), theater borders in white.
BATTLESPACE_ZEN_BUILD_CELL_LINES = {
	params [["_cells", []]];
	_cells params [["_size", 250], ["_rows", []]];
	private _lines = [];
	private _theaterAt = createHashMap;
	{_theaterAt set [format ["%1:%2", _x select 0, _x select 1], _x select 2]} forEach _rows;
	private _inset = _size * 0.08;
	{
		_x params ["_x0", "_y0", "_theater", "_control", "_contested", ["_post", false]];
		private _value = _control / 100;
		private _color = if (_contested) then {[1, 0.85, 0.1, 0.9]} else {
			private _band = [[1, 0.2, 0.15], [0.55, 0.55, 0.55], [0.2, 0.45, 1]] select (([0, 1] select (_value >= -0.15)) + ([0, 1] select (_value > 0.15)));
			_band + [0.3 + 0.6 * abs _value]
		};
		private _a = [_x0 + _inset, _y0 + _inset, 4];
		private _b = [_x0 + _size - _inset, _y0 + _inset, 4];
		private _c = [_x0 + _size - _inset, _y0 + _size - _inset, 4];
		private _d = [_x0 + _inset, _y0 + _size - _inset, 4];
		private _width = [2, 6] select _post;
		_lines append [[_a, _b, _color, _width], [_b, _c, _color, _width], [_c, _d, _color, _width], [_d, _a, _color, _width]];
		{
			_x params ["_dx", "_dy", "_from", "_to"];
			private _other = _theaterAt getOrDefault [format ["%1:%2", _x0 + _dx, _y0 + _dy], _theater];
			if (_other != _theater) then {_lines pushBack [_from, _to, [1, 1, 1, 0.95], 6]};
		} forEach [
			[_size, 0, [_x0 + _size, _y0, 8], [_x0 + _size, _y0 + _size, 8]],
			[0, _size, [_x0, _y0 + _size, 8], [_x0 + _size, _y0 + _size, 8]]
		];
	} forEach _rows;
	BATTLESPACE_ZEN_CELL_LINES = _lines;
};

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
        _lines pushBack format ["%1%2: %3 / %4 (%5%%)<br/>", (["", "<t color='#ff9c75'>SHORT </t>"] select (_shortage)), _resource, _amount, _capacity, _ratio];
	} forEach _stock;
	_cooldowns params ["_resupply", "_emergency", "_reinforcement", "_deepRecon", ["_airResponse", 0], ["_fortification", 0], ["_minefield", 0]];
	_lines pushBack format ["<br/>Cooldowns — supply %1, emergency %2, reinforcement %3, deep recon %4, air %5, construction %6, mines %7<br/>",
		[_resupply] call BATTLESPACE_ZEN_FORMAT_DURATION,
		[_emergency] call BATTLESPACE_ZEN_FORMAT_DURATION,
		[_reinforcement] call BATTLESPACE_ZEN_FORMAT_DURATION,
		[_deepRecon] call BATTLESPACE_ZEN_FORMAT_DURATION,
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
	if (!hasInterface || {!isRemoteExecuted} || {remoteExecutedOwner != 2}) exitWith {};
	switch (_action) do {
		case "OVERLAY": {
			BATTLESPACE_ZEN_STRATEGIC_OVERLAY_DATA = _payload;
			[_payload param [3, []]] call BATTLESPACE_ZEN_BUILD_CELL_LINES;
		};
		case "AUDIT": {
			_payload params [["_errors", []], ["_warnings", []], ["_sectorCount", 0], ["_operationCount", 0]];
			private _title = "Battlespace Integrity Audit";
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
			_settings params [["_decision", 0], ["_airDecision", 0], ["_pressure", 0], ["_emergency", 0], ["_reinforcement", 0], ["_deepRecon", 0], ["_airResponse", 0], ["_fortification", 0], ["_minefield", 0], ["_logisticsDecision", 60]];
			_lines pushBack format ["<br/>Logistics evaluation %1", [_logisticsDecision] call BATTLESPACE_ZEN_FORMAT_DURATION];
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
		case "OVERVIEW": {
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
	BATTLESPACE_ZEN_STRATEGIC_OVERLAY_DATA params [["_sectors", []], ["_operations", []], ["_theaters", []]];
	{drawLine3D _x} forEach BATTLESPACE_ZEN_CELL_LINES;
	{
		_x params ["_name", "_center", "_radius", "_alert", "_level"];
		private _color = [[0.6, 0.85, 0.6, 0.55], [1, 0.8, 0.2, 0.8], [1, 0.2, 0.2, 0.9]] select _level;
		private _label = +_center;
		_label set [2, 70];
		drawIcon3D ["", _color, _label, 0, 0, 0,
			format ["THEATER %1 | %2 %3", _name, ["CALM", "ALERT", "HIGH"] select _level, _alert], 2, 0.03, "TahomaB"];
	} forEach _theaters;
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
		BATTLESPACE_ZEN_CELL_LINES = [];
	};
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
