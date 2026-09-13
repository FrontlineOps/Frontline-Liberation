/* Current v1 senders keep each polyline contiguous. Read one whole path
   per owner per round, stopping an owner when its next path cannot fit.
   Work scales with admitted lines, not sixteen complete 4096-line packets. */
params ["_packets", ["_limit", 256]];
_limit = floor (_limit max 256 min 8192);
private _lines = [];
private _tags = [];
private _stats = [0,0,0,0,0,0,0,0,0,0,0,0,0];
private _available = 0;
private _owners = [];
private _cursors = [];
private _active = [];
{
    _x params ["_owner", "_paths", "_labels", "_ownerStats"];
    _available = _available + count _paths;
    for "_i" from 0 to 12 do {_stats set [_i, (_stats select _i) + (_ownerStats select _i)]};
    if (_paths isNotEqualTo []) then {
        _active pushBack count _owners;
        _owners pushBack [_owner,_paths,_labels];
        _cursors pushBack 0;
    };
} forEach (_packets select [0,16]);
private _displayed = 0;
while {_active isNotEqualTo [] && {count _lines < _limit}} do {
    private _next = [];
    {
        private _index = _x;
        (_owners select _index) params ["_owner", "_paths", "_labels"];
        private _cursor = _cursors select _index;
        private _tag = if (_cursor < count _labels) then {_labels select _cursor} else {["UNKNOWN",format ["Unclassified segment #%1",_cursor]]};
        private _end = _cursor + 1;
        while {_end < count _paths && {_end < count _labels && {(_labels select _end) isEqualTo _tag}}} do {_end = _end + 1};
        private _size = _end - _cursor;
        if (count _lines + _size <= _limit) then {
            _lines append (_paths select [_cursor,_size]);
            private _label = [_tag select 0, format ["Owner %1 | %2",_owner,_tag select 1]];
            for "_i" from 1 to _size do {_tags pushBack _label};
            _displayed = _displayed + 1;
            _cursors set [_index,_end];
            if (_end < count _paths) then {_next pushBack _index};
        };
    } forEach _active;
    _active = _next;
};
[_lines,_tags,_stats,(_available - count _lines) max 0,_displayed]
