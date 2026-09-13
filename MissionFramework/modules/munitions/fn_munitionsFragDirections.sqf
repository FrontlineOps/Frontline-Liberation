/* Equal-area sphere strata with independent jitter and a random azimuth offset.
   Generic game sampling, not a casing model. No scene/target queries or steering. */
params [["_count", 0, [0]]];
if (!finite _count || {_count < 1} || {_count > 512}) exitWith {[]};
_count = floor _count;
private _bands = (floor sqrt (_count / 2)) max 1;
private _base = floor (_count / _bands);
private _extra = _count mod _bands;
private _rotation = random 360;
private _first = 0;
private _directions = [];
for "_band" from 0 to (_bands - 1) do {
    private _columns = _base + ([0,1] select (_band < _extra));
    for "_column" from 0 to (_columns - 1) do {
        private _z = -1 + 2 * (_first + (random 1) * _columns) / _count;
        private _azimuth = _rotation + 360 * (_column + random 1) / _columns;
        private _radial = sqrt ((1 - _z * _z) max 0);
        _directions pushBack [_radial * cos _azimuth, _radial * sin _azimuth, _z];
    };
    _first = _first + _columns;
};
_directions
