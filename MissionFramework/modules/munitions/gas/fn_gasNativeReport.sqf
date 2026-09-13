/* Explicit curator diagnostic, called locally on the server after validation. */
if (!isServer || {isRemoteExecuted}) exitWith {"Server-local invocation required"};
private _version = ["version"] call KPLIB_fnc_gasNative;
private _format = {
    private _text = _this joinString toString [13,10];
    if (count _text > 48000) then {_text = (_text select [0,47800]) + toString [13,10] + "REPORT TRUNCATED: inspect a single object for its pressure application."};
    _text
};
private _rows = [
    "FRONTLINE PHYSICAL SOLVER | SERVER BACKEND",
    "Compressible Euler / ideal gas / conservative finite volumes. Pressure in Pa; impulse in Pa s.",
    format ["Live game integration enabled=%1; empty-impact recording=%2. Absent/failed backend uses labeled LEGACY game fields.", KPLIB_munitions_gas_enabled, KPLIB_munitions_gas_record],
    "Live sources are indirectHit-to-energy GAME conversions, not measured explosive yields. Damage is a separate game rule; native ACE effects remain active.",
    "Passive tracer is transported with the gas. No combustion kinetics, thermobaric chemistry or validated injury law.",
    "Temperature display assumes air gas constant R=287.05 J/(kg K).",
    format ["Handshake: %1", _version]
];
private _jobs = +(localNamespace getVariable ["KPLIB_blastHistory", []]);
_jobs append (localNamespace getVariable ["KPLIB_blastJobs", []]);
_rows pushBack format ["Live metrics: %1", localNamespace getVariable ["KPLIB_blastMetrics", createHashMap]];
{
    _rows pushBack format ["FIELD %1 %2", _x get "id", (_x get "profile") get "ammo"];
    _rows append ([_x] call KPLIB_fnc_gasJobReport);
} forEach (_jobs select [((count _jobs) - 3) max 0,3]);
if !(_version select 0) exitWith {_rows call _format};
private _status = ["status"] call KPLIB_fnc_gasNative;
if !(_status select 0) exitWith {(_rows + [_status select 2]) call _format};
private _handles = _status select 1;
_rows pushBack format ["Active domains: %1 / 8; 4096 cells/domain; 8 steps/call; soft 2 ms native work budget.", count _handles];
{
    private _handle = _x;
    private _reply = ["stats", [_handle]] call KPLIB_fnc_gasNative;
    if (_reply select 0) then {
        (_reply select 1) params ["_time", "_steps", "_count", "_spacing", "_gamma", "_ambient", "_initial", "_source", "_boundary", "_total"];
        _rows pushBack format ["DOMAIN %1 t=%2 s steps=%3 cells=%4 spacing=%5 m gamma=%6 ambient=%7 Pa", _handle, _time, _steps, _count, _spacing, _gamma, _ambient];
        _rows pushBack "  Conserved order: mass kg, momentum x/y/z kg m/s, energy J, tracer mass kg.";
        _rows pushBack format ["  Initial=%1 | source changes=%2 | outward boundary transfer=%3 | current=%4", _initial, _source, _boundary, _total];
        private _residual = [];
        for "_i" from 0 to 5 do {
            _residual pushBack ((_total select _i) + (_boundary select _i) - (_initial select _i) - (_source select _i));
        };
        _rows pushBack format ["  Conservation residual (SQF display precision): %1", _residual];
        private _indices = [];
        for "_i" from 0 to 4 do {_indices pushBackUnique floor ((_count - 1) * _i / 4)};
        {
            private _sample = ["sample", [_handle, _x, 287.05]] call KPLIB_fnc_gasNative;
            _rows pushBack format ["  Cell %1 [t, absolute Pa, peak excess Pa, positive Pa s, signed Pa s, K, kg/m3, ux/uy/uz m/s, tracer fraction] = %2", _x, _sample select 1];
        } forEach _indices;
    } else {
        _rows pushBack (_reply select 2);
    };
} forEach (_handles select [0,8]);
_rows pushBack format ["Bridge [calls, total ms, last command, retained last error]: %1", missionNamespace getVariable ["KPLIB_gasNativeMetrics", []]];
_rows call _format
