
NEW_PRIORITY_QUEUE = {[0,[]]};
PRIORITY_QUEUE_ENQUEUE = {
	params ["_queue", "_priority", "_value"];
	_queue params ["_counter", "_data"];
	_counter = _counter + 1;
	_data pushBack [_priority, _counter, [_value]];
	_data sort true;
	_queue set [0, _counter];
};
PRIORITY_QUEUE_ENQUEUE_MULTIPLE = {
	params ["_queue", "_rows"];
	_queue params ["_counter", "_data"];
	for "_i" from 0 to ((count _rows) - 1) do {
		private _row = _rows select _i;

		_row params ["_priority", "_value"];

		_counter = _counter + 1;
		
		_data pushBack [_priority, _counter, [_value]];

	};

	_data sort true;

	_queue set [0, _counter];
};
PRIORITY_QUEUE_POP = {
	params ["_queue"];
	(_queue select 1 deleteAt 0) select 2 select 0
};
PRIORITY_QUEUE_IS_EMPTY = {
	params ["_queue"];
	_queue select 1 isEqualTo []
};
