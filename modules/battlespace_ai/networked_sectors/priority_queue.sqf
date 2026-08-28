// Stable binary min-heap. Queue shape stays [insertionCounter, heapArray] so
// existing callers keep the same API while insertion/pop become O(log n).
NEW_PRIORITY_QUEUE = {[0, []]};

PRIORITY_QUEUE_ENQUEUE = {
	params ["_queue", "_priority", "_value"];
	_queue params ["_counter", "_data"];

	_counter = _counter + 1;
	private _node = [_priority, _counter, _value];
	_data pushBack _node;

	private _index = (count _data) - 1;
	while {_index > 0} do {
		private _parentIndex = floor ((_index - 1) / 2);
		private _parent = _data select _parentIndex;
		private _parentPriority = _parent select 0;
		private _parentOrder = _parent select 1;
		if (
			_parentPriority < _priority
			|| {_parentPriority == _priority && {_parentOrder <= _counter}}
		) exitWith {};

		_data set [_index, _parent];
		_index = _parentIndex;
	};
	_data set [_index, _node];
	_queue set [0, _counter];
};

PRIORITY_QUEUE_ENQUEUE_MULTIPLE = {
	params ["_queue", "_rows"];
	{
		_x params ["_priority", "_value"];
		[_queue, _priority, _value] call PRIORITY_QUEUE_ENQUEUE;
	} forEach _rows;
};

PRIORITY_QUEUE_POP = {
	params ["_queue"];
	private _data = _queue select 1;
	if (_data isEqualTo []) exitWith {nil};

	private _root = _data select 0;
	private _last = _data deleteAt ((count _data) - 1);
	if (_data isNotEqualTo []) then {
		private _index = 0;
		private _count = count _data;
		while {true} do {
			private _left = 2 * _index + 1;
			if (_left >= _count) exitWith {};
			private _right = _left + 1;
			private _best = _left;
			if (_right < _count) then {
				private _leftNode = _data select _left;
				private _rightNode = _data select _right;
				if (
					(_rightNode select 0) < (_leftNode select 0)
					|| {
						(_rightNode select 0) == (_leftNode select 0)
						&& {(_rightNode select 1) < (_leftNode select 1)}
					}
				) then {
					_best = _right;
				};
			};

			private _child = _data select _best;
			if (
				(_last select 0) < (_child select 0)
				|| {
					(_last select 0) == (_child select 0)
					&& {(_last select 1) <= (_child select 1)}
				}
			) exitWith {};

			_data set [_index, _child];
			_index = _best;
		};
		_data set [_index, _last];
	};

	_root select 2
};

PRIORITY_QUEUE_IS_EMPTY = {
	params ["_queue"];
	(_queue select 1) isEqualTo []
};
