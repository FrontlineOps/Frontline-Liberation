/* Generic game source, NOT munition yield. Only validated native detonations
   enter through the server's existing blast queue. Missing DLL uses the legacy
   game model and records why; no expensive SQF solver fallback. */
if (!isServer || {isRemoteExecuted}) exitWith {false};
params ["_job"];
_job set ["backend", "LEGACY"];
_job set ["gasReason", "Native gas disabled in mission settings"];
if !(missionNamespace getVariable ["KPLIB_munitions_gas_enabled", true]) exitWith {false};
private _profile = _job get "profile";
private _radius = (((_profile get "range") * 2) max 3) min KPLIB_munitions_gas_radius;
private _requested = (missionNamespace getVariable ["KPLIB_munitions_gas_cell", 2]) max 0.5 min 12;
private _cap = floor ((missionNamespace getVariable ["KPLIB_munitions_gas_grid_max", 11]) max 7 min 15);
if (_cap mod 2 == 0) then {_cap = _cap - 1};
private _n = ceil (2 * _radius / _requested);
if (_n mod 2 == 0) then {_n = _n + 1};
_n = _n max 7 min _cap;
private _centre = floor (_n^3 / 2);
private _cell = 2 * _radius / _n;
private _reply = ["create", [_n,_n,_n,_cell,1.4,1.2,0,0,0,101325,0,0,0,0,0,0,0]] call KPLIB_fnc_gasNative;
if !(_reply select 0) exitWith {
    _job set ["gasReason", _reply select 2];
    private _metrics = localNamespace getVariable "KPLIB_blastMetrics";
    _metrics set ["gasFallback", 1 + (_metrics getOrDefault ["gasFallback", 0])];
    false
};
private _handle = (_reply select 1) select 0;
private _stats = ["stats", [_handle]] call KPLIB_fnc_gasNative;
if !(_stats select 0) exitWith {
    ["release", [_handle]] call KPLIB_fnc_gasNative;
    _job set ["gasReason", _stats select 2];
    false
};
private _energy = ((_profile get "hit") min 5000) * KPLIB_munitions_gas_energy_per_hit;
private _deltaP = 0.4 * _energy / (_cell^3);
private _thermal = _profile get "thermal";
private _end = if (_thermal) then {KPLIB_munitions_thermal_duration} else {0.2 max (6 * _radius / 340)};
private _probes = [];
for "_z" from 0 to 3 do {
    for "_y" from 0 to 3 do {
        for "_x" from 0 to 3 do {
            _probes pushBack ((round ((_n - 1) * _x / 3)) + _n * ((round ((_n - 1) * _y / 3)) + _n * (round ((_n - 1) * _z / 3))));
        };
    };
};
_probes set [32, _centre];
private _times = [];
for "_i" from 0 to 11 do {_times pushBack (_end * (_i / 11)^2)};
{
    _job set _x;
} forEach [
    ["backend", "GAS"], ["phase", "GAS_PRIMARY"], ["gasHandle", _handle],
    ["gasN", _n], ["gasCentre", _centre], ["gasRequestedCell", _requested],
    ["gasCell", _cell], ["gasRadius", _radius], ["gasFaceCount", (_stats select 1) select 10],
    ["gasFaceCursor", 0], ["gasWalls", 0], ["gasTime", 0], ["gasEnd", _end],
    ["gasEnergy", _energy], ["gasHeatAdded", 0], ["gasSourcePressure", _deltaP],
    ["gasProbes", _probes], ["gasFrames", []], ["gasFrameTimes", _times],
    ["gasNextDose", 0.1], ["gasMeasures", createHashMap],
    ["gasInitialPositions", (_job get "targets") apply {aimPos _x}],
    ["gasReason", "Geometry pending"],
    ["gasReference", (missionNamespace getVariable ["KPLIB_gasNativeSchema", [0]]) select 0 >= 4],
    ["gasReferenceGround", getTerrainHeightASL (_job get "origin")],
    ["gasBasis", format ["GAME INPUT: min(indirectHit,5000) * %1 J/game-point = %2 J; ideal air gamma=1.4 rho=1.2; damage gain=%3. Not explosive yield or a clinical injury rule.", KPLIB_munitions_gas_energy_per_hit, _energy, KPLIB_munitions_gas_damage_gain]]
];
private _metrics = localNamespace getVariable "KPLIB_blastMetrics";
_metrics set ["gasAccepted", 1 + (_metrics getOrDefault ["gasAccepted", 0])];
true
