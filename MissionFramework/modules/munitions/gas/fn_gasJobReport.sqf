/* Bounded, read-only report for live and retained game domains. */
params ["_job"];
private _rows = [format ["  backend=%1 status=%2", _job getOrDefault ["backend", "LEGACY"], _job getOrDefault ["gasReason", ""]]];
if (_job getOrDefault ["backend", "LEGACY"] != "GAS") exitWith {
    _rows append ([_job] call KPLIB_fnc_gasAssetReport);
    _rows
};
_rows append [
    _job get "gasBasis",
    format ["  Grid=%5 per axis (%6 cells), dx=%1 m, half-width=%2 m; initially blocked faces=%3/%4. Opening samples refine connectivity; unresolved openings can remain.", _job get "gasCell", _job get "gasRadius", _job get "gasWalls", _job get "gasFaceCount", _job get "gasN", (_job get "gasN")^3],
    format ["  Requested dx=%1 m; under-resolved=%2; 64 fixed probes, not particles/fragments. Hover spacing is actual dx. Finer grids change numerical/game response, not weapon calibration.", _job get "gasRequestedCell", (_job get "gasCell") > (_job get "gasRequestedCell") + 0.001],
    format ["  Solver t=%1/%2 s steps=%3 max native batch=%4 ms; geometry latency=%5 ms; retained frames=%6/12; truncated=%7 released=%8", _job get "gasTime", _job get "gasEnd", _job getOrDefault ["gasSteps", 0], _job getOrDefault ["gasMaxBatchMs", 0], _job getOrDefault ["gasGeometryMs", -1], count (_job get "gasFrames"), _job get "truncated", _job getOrDefault ["gasReleaseOK", false]],
    format ["  Prescribed added heat=%1 J (not chemistry); late pressure omitted=%2; cumulative GAME [pressure,heat] dose=%3", _job get "gasHeatAdded", _job getOrDefault ["gasLatePressure", false], _job get "dose"]
];
_rows pushBack format ["  Openings: checked=%1, connected=%2, unrefined=%3, passes=%4, changed=%5, later changes omitted=%6. Dust: sampled cells=%7/12. Native schema=%8.", count (_job getOrDefault ["gasOpeningEdges", []]), _job getOrDefault ["gasOpenConnections", 0], _job getOrDefault ["gasOpeningOmissions", 0], _job getOrDefault ["gasOpeningPasses", 0], _job getOrDefault ["gasOpeningChanges", 0], _job getOrDefault ["gasOpeningRechecksOmitted", false], count (_job getOrDefault ["gasDustCells", []]), missionNamespace getVariable ["KPLIB_gasNativeSchema", []]];
_rows pushBack format ["  PRIMARY EXPOSURE: direct cover rays; finished age=%1 s, pressure gain=%2; [recipient,age,dose,visible fraction,path]=%3. GAS refines the same cumulative maximum.", _job getOrDefault ["primaryDoneAt", -1], missionNamespace getVariable ["KPLIB_munitions_pressure_gain", 8], _job getOrDefault ["primaryExposure", []]];
_rows pushBack format ["  OPEN-GROUND REFERENCE: enabled=%1 cache hit=%2 ready age=%3 s max batch=%4 ms ground ASL=%5. Same source/grid over level ground at source terrain height; actual field retains hills and structures. Covered response uses the open-distance baseline multiplied by resolved peak/impulse ratios, capped after attenuation. Older extensions retain prior scaling.", _job getOrDefault ["gasReference", false], _job getOrDefault ["gasReferenceCacheHit", false], _job getOrDefault ["gasReferenceReadyAge", -1], _job getOrDefault ["gasReferenceMaxBatchMs", 0], _job getOrDefault ["gasReferenceGround", 0]];
private _measures = _job get "gasMeasures";
_rows pushBack "  Sheltered response uses r + 0.26*r*max(1-r,0) for each reference ratio. Zero, full and reflected exposure stay unchanged; the 15 m finite-wall control is approximately 5.0 units. Impulse refinement accumulates without replaying earlier samples.";
_rows pushBack "  PRESSURE PIPELINE: latest per-recipient decision while debug enabled; candidate/accepted/dispatched doses are game values. Rejections/credits/actual medical results are in the recipient owner's PRESSURE TRACE.";
private _trace = _job getOrDefault ["gasTrace", createHashMap];
{
    _rows pushBack format ["    target index %1: %2", _x, _trace get _x];
} forEach ((keys _trace) select [0,48]);
_rows append ([_job] call KPLIB_fnc_gasAssetReport);
_rows pushBack "  Recipient samples [solver s,cell,cell positive Pa s,excess Pa,normalized heat,recipient positive Pa s,peak excess Pa,normalized impulse response,normalized peak response,whole-cell history valid,last observed cell peak,body visibility,current-cell impulse ratio]:";
{
    _rows pushBack format ["    target index %1: %2", _x, _measures get _x];
} forEach ((keys _measures) select [0,48]);
private _stats = _job getOrDefault ["gasFinalStats", []];
if (count _stats >= 10) then {
    _stats params ["_time", "_steps", "_count", "_spacing", "_gamma", "_ambient", "_initial", "_source", "_boundary", "_total"];
    private _residual = [];
    for "_i" from 0 to 5 do {
        _residual pushBack ((_total select _i) + (_boundary select _i) - (_initial select _i) - (_source select _i));
    };
    _rows pushBack format ["  Conservation residual [kg,3x kg m/s,J,kg tracer] at SQF display precision: %1", _residual];
    _rows pushBack format ["  Initial=%1 source=%2 outward boundary transfer=%3 final=%4", _initial, _source, _boundary, _total];
};
_rows
