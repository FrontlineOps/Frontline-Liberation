/* Separate recovery of disorientation and sustained instability. */
params ["_scores", "_elapsed"];
private _half = [
    (missionNamespace getVariable ["KPLIB_munitions_trauma_fast_recovery", 15]) max 1,
    (missionNamespace getVariable ["KPLIB_munitions_trauma_slow_recovery", 90]) max 1
];
[
    (_scores select 0) * 0.5^((_elapsed max 0) / (_half select 0)),
    (_scores select 1) * 0.5^((_elapsed max 0) / (_half select 1))
]

