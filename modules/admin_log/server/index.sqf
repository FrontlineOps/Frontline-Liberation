// Grom was here :wave:

[] call compile preprocessFileLineNumbers "modules\admin_log\config.sqf";

KC_ADMIN_EVENTS_LOG = [];

KC_ADMIN_LOG_EVENT	= {
	// determine priority
	_priority   = 0;
	_priorities = [
		KC_ADMIN_LOG_LOW,
		KC_ADMIN_LOG_MEDIUM,
		KC_ADMIN_LOG_HIGH
	];
	{
		if (_this#1 in _x) then {
			_priority = _forEachIndex;
		};
	} forEach _priorities;

	// [ [message, priority, type, serverTime], ... ]
	KC_ADMIN_EVENTS_LOG pushBack [_this#0, _priority, _this#1, systemTime];
	publicVariable "KC_ADMIN_EVENTS_LOG";
};
