/* Select a distance-appropriate policy, then a single-round trigger at that
   cyclic rate. Scripted hidden AI modes do not reliably complete their bursts.
   Real magazine state and Fired events govern every round of our burst. */
params ["_modes", "_distance", ["_single", false]];
if (_modes isEqualTo []) exitWith {[]};
private _policy = _modes select 0;
private _best = 1e12;
{
    _x params ["_name", "_auto", "_burst", "_maxBurst", "_reload", "_visible", "_min", "_mid", "_max"];
    if (_max <= 0) then {continue};
    private _gap = ((_min - _distance) max 0) + ((_distance - _max) max 0);
    private _score = _gap * 1000 + abs (_distance - _mid) / ((_max - _min) max 1);
    if (_score < _best) then {_best = _score; _policy = _x};
} forEach _modes;
private _trigger = [];
_best = 1e12;
{
    // A one-round mode makes interruption and accounting deterministic.
    if (_x select 2 != 1) then {continue};
    private _score = abs ((_x select 4) - (_policy select 4)) * 1000;
    if ((_x select 1) != (_policy select 1)) then {_score = _score + 1};
    if (!(_x select 5)) then {_score = _score + 0.1};
    if (_score < _best) then {_best = _score; _trigger = _x};
} forEach _modes;
// An unsupported burst-only muzzle retains its existing native controller.
if (_trigger isEqualTo []) exitWith {[]};
private _count = floor (_policy select 2);
private _max = floor (_policy select 3);
if (_max > _count) then {_count = _count + floor random (1 + _max - _count)};
if (_single) then {_count = 1};
[
    _trigger select 0, _trigger select 4, (_count max 1) min 32,
    (_policy select 9) max (_trigger select 4), _policy select 0
]
