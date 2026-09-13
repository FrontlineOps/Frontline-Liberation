params [["_object", objNull, [objNull]]];
private _rows = [
    format ["FRONTLINE MUNITIONS | machine=%1 server=%2 interface=%3 | mission time=%4 FPS=%5", clientOwner, isServer, hasInterface, CBA_missionTime, diag_fps],
    format ["ACE %1 | ZEN %2", getArray (configFile >> "CfgPatches" >> "ace_main" >> "versionAr"), getArray (configFile >> "CfgPatches" >> "zen_main" >> "versionAr")],
    "EFFECTIVE SETTINGS ON THIS MACHINE (UNAVAILABLE does not mean disabled)"
];
{
    _rows pushBack format ["  %1 = %2", _x, missionNamespace getVariable [_x, "UNAVAILABLE"]];
} forEach [
    "KPLIB_munitions_fragment_cap", "ace_missileguidance_enabled", "KPLIB_munitions_spatial_fragments", "KPLIB_munitions_blast_enabled", "KPLIB_munitions_blast_gain", "KPLIB_munitions_pressure_gain", "KPLIB_munitions_thermal_duration",
    "KPLIB_munitions_gas_enabled", "KPLIB_munitions_gas_record", "KPLIB_munitions_gas_radius", "KPLIB_munitions_gas_cell", "KPLIB_munitions_gas_grid_max", "KPLIB_munitions_gas_energy_per_hit", "KPLIB_munitions_gas_damage_gain",
    "ace_frag_enabled", "ace_frag_spallEnabled", "ace_frag_reflectionsEnabled", "ace_frag_spallIntensity",
    "ace_medical_AIDamageThreshold", "ace_medical_playerDamageThreshold", "ace_medical_fatalDamageSource",
    "ace_medical_useLimbDamage", "ace_medical_alternateArmorPenetration", "ace_medical_statemachine_fatalInjuriesAI",
    "ace_advanced_ballistics_enabled", "ace_overpressure_overpressureDistanceCoefficient", "ace_overpressure_backblastDistanceCoefficient"
];
_rows pushBack "ACE overpressure coefficients concern weapon firing/backblast. Explosion reflections, fragments and medical wounds have separate paths.";
_rows pushBack format ["MISSION effects: spatial fragments and native-exit spalling; [requested,created,quota/age omitted,creation failures]=%1; queued=%2/16. 64 creations/callback, soft 2 ms, 0.75 s deadline; native fragment assets retain their flight/damage. Live debug retains up to 2048 fragment/debris paths per owner; manual capture retains 128. Unrecorded particles are counted.", localNamespace getVariable ["KPLIB_munitionsParticleMetrics", [0,0,0,0]], count (localNamespace getVariable ["KPLIB_munitionsParticleQueue", []])];
_rows pushBack format ["Particle callback maximum observed on this owner: %1 ms (soft budget; not campaign FPS).", localNamespace getVariable ["KPLIB_munitionsParticleMaxTickMs", 0]];
_rows pushBack format ["STRUCTURAL DEBRIS: native entry-face chips plus exposed explosion-hit building surfaces; queued surface jobs=%1/8, 16 rays and at most 64 particles per explosion, shared particle budget. Native exit SPALL is separate. RPT SURFACE rows identify the actual contact/material and requested admission; visual trajectories remain native collision proxies.", count (localNamespace getVariable ["KPLIB_munitionsDebrisQueue", []])];
_rows pushBack format ["BACKFACE SPALL: native stopped-contact game approximation for supported building/armor surfaces, not material failure physics. Queued=%1/16, four contacts/projectile, 0.25 s confirmation/work deadline, one job/callback, up to eight reverse FIRE queries over 0.64 m. Game hit >=40, incoming speed >=50, nongrazing contact; 4-12 native proxies use the shared budget. Penetration, ricochet, continuing shots and missing rear geometry are rejected. Pose changes cancel pending creation; animated/subcell geometry remains approximate. RPT BACKFACE RESULT reports the reason and actual rear surface.", count (localNamespace getVariable ["KPLIB_munitionsBackfaceQueue", []])];
_rows pushBack "Explosion reflections: mission GAS reflecting faces, or reported LEGACY connected-exposure fallback. ACE generators are disabled; ACE medical and weapon backblast remain. No validated weapon/material injury calibration.";
if (!isNull _object) then {_rows append ([_object, true] call KPLIB_fnc_munitionsSnapshot)};
_rows pushBack format ["PRESSURE TRACE: last 64 owner-local records, retired=%1. [time,event,recipient class,owner,stage,detail]. Dispatch is not proof of application on a remote owner.", localNamespace getVariable ["KPLIB_blastTraceRetired", 0]];
_rows pushBack "MEDICAL RESULT before/after = [six ACE body-part damage values,open wound row count,alive,unconscious]. Wound rows are grouped injuries, not an individual fragment count.";
private _pressureTrace = localNamespace getVariable ["KPLIB_blastTrace", []];
_rows pushBack "This report shows the latest 16 pressure records; the automatic RPT writer also emits all retained pressure records separately.";
{_rows pushBack format ["  PRESSURE TRACE %1", _x]} forEach (_pressureTrace select [((count _pressureTrace) - 16) max 0,16]);
private _shots = localNamespace getVariable ["KPLIB_munitionsShots", []];
private _events = localNamespace getVariable ["KPLIB_munitionsEvents", []];
_rows pushBack format ["CAPTURE session=%1 active=%2 traces=%3 (64 ordinary + 128 manual / 2048 live fragment-debris slots) text events=%4/192 dropped=%5", localNamespace getVariable ["KPLIB_munitionsSession", -1], CBA_missionTime < (localNamespace getVariable ["KPLIB_munitionsUntil", -1]), count _shots, count _events, localNamespace getVariable ["KPLIB_munitionsDropped", 0]];
_rows pushBack "Shot/parent IDs are owner/session-local. Traces sample at up to 20 Hz (40 Hz live) plus native impact, penetration, deflection and deletion events; bounded histories retain 64 ordinary/16 fragment points manually or 128 points per live trace, preferring contact vertices and retaining creation/final observations. Segments interpolate observations; no unobserved fragment paths are invented.";
_rows pushBack format ["Live worldwide=%1; retired traces reused=%2; explosion bursts share 60 s history (eight per owner); other ended traces 20 s; remote owner polls 1-4 Hz; UI admits whole paths within 8192 segments and eight fields. Omitted samples are not invented.", localNamespace getVariable ["KPLIB_munitionsLive", false], localNamespace getVariable ["KPLIB_munitionsEvicted", 0]];
_rows pushBack format ["Burst history=%1; whole bursts retired by capacity=%2. Ordinary association uses observations within 0.5 s / 2 m; structural debris carries its emitting explosion's origin/time. Deadlines do not renew when fragments end.", localNamespace getVariable ["KPLIB_munitionsBursts", []], localNamespace getVariable ["KPLIB_munitionsBurstEvicted", 0]];
private _ammo = [];
private _lines = [];
_rows pushBack format ["BLAST ready=%1 metrics=%2 | GAS has SI observations with GAME source/damage inputs; LEGACY has normalized exposure. Neither predicts validated weapon injury.", localNamespace getVariable ["KPLIB_blastReady", false], localNamespace getVariable ["KPLIB_blastMetrics", createHashMap]];
private _blasts = +(localNamespace getVariable ["KPLIB_blastHistory", []]);
_blasts append (localNamespace getVariable ["KPLIB_blastJobs", []]);
{
    private _job = _x;
    private _profile = _job get "profile";
    private _nodes = _job get "nodes";
    _rows pushBack format ["FIELD %1 %2 phase=%3 thermal=%4 (%5) targetOverflow=%6", _job get "id", _profile get "ammo", _job get "phase", _profile get "thermal", _profile get "reason", _job get "targetOverflow"];
    _rows append ([_job] call KPLIB_fnc_gasJobReport);
    if (_job getOrDefault ["backend", "LEGACY"] != "GAS") then {
        _rows pushBack format ["BLAST %1 %2 phase=%3 age=%4 cells=%5 truncated=%6 targetOverflow=%7 confinement=%8 thermal=%9 (%10)", _job get "id", _profile get "ammo", _job get "phase", CBA_missionTime - (_job get "at"), count _nodes, _job get "truncated", _job get "targetOverflow", _job get "confinement", _profile get "thermal", _profile get "reason"];
        _rows pushBack format ["  model radius=%1 cell=%2 connected-field radius=%3 cumulative [pressure,thermal] by target index=%4", _profile get "radius", _profile get "cell", _profile get "fieldRadius", _job get "dose"];
        {
            _x params ["_unit", "_pressure", "_path", "_fraction", "_closed", "_from", "_body"];
            _rows pushBack format ["  target=%1 pressureFloor=%2 airPath=%3 directBodyExposure=%4 localConfinement=%5", typeOf _unit, _pressure, _path, _fraction, _closed];
            if (count _lines < 96) then {_lines pushBack [_from, _body]};
        } forEach (_job get "exposures");
        {
            private _parent = _x select 3;
            if (_parent >= 0 && {count _lines < 96}) then {_lines pushBack [(_nodes select _parent) select 0, _x select 0]};
        } forEach _nodes;
    };
} forEach (_blasts select [((count _blasts) - 3) max 0, 3]);
_rows pushBack "GEOMETRY lines belong only to the legacy model and are not projectiles. Gas completion and trajectory capture completeness are separate. Primary/GAS share a cumulative event dose. Native credits are retained for 10 seconds and matched within 0.5 seconds of the original impact; near-simultaneous same-ammo events cannot be individually attributed.";
private _fragmentRows = 0;
{
    private _fragment = (_x getOrDefault ["kind", "PROJECTILE"]) == "FRAGMENT";
    if (!_fragment || {_fragmentRows < 16}) then {
        _rows pushBack format ["%1 #%2 parent=%3 %4 created=%5 speedAtRegistration=%6 points=%7 impactObserved=%8 state=%9 historyBurst=%10 historyUntil=%11 effect=%12", _x getOrDefault ["kind", "PROJECTILE"], _x get "id", _x get "parent", _x get "ammo", _x get "at", _x get "speed", count (_x get "points"), _x getOrDefault ["hasEndpoint", false], _x get "state", _x getOrDefault ["historyBurst", -1], _x getOrDefault ["historyUntil", -1], _x getOrDefault ["effect", ""]];
    };
    if (_fragment) then {_fragmentRows = _fragmentRows + 1} else {_ammo pushBackUnique (_x get "ammo")};
} forEach _shots;
private _paths = [_shots, _lines] call KPLIB_fnc_munitionsPaths;
_lines = _paths select 0;
private _meta = _paths select 1;
private _counts = _meta select 2;
_rows pushBack format ["CAPTURE COUNTERS [observed ordinary,observed known fragments,dropped ordinary,dropped fragments,dropped text,captured projectile,child,fragment,undersampled traces,decimated points,available segments,sent segments,omitted segments] = %1", _counts];
_rows pushBack "These sent/omitted segments describe this 128-segment report, not the live 4096-owner/8192-viewer selection.";
_rows pushBack format ["Observed known fragments=%1; captured=%2; dropped=%3. These are local in-area observations, NOT the total generated by the mission, nor confirmed hits. Unknown addon fragment classes stay PROJECTILE. Fragment text rows omitted=%4; traces have a separate budget.", _counts select 1, _counts select 7, _counts select 3, (_fragmentRows - 16) max 0];
{
    _x params ["_time", "_id", "_kind", "_position", "_detail"];
    _rows pushBack format ["%1 #%2 %3 ASL=%4 %5", _time, _id, _kind, _position, _detail];
} forEach _events;
{
    _rows append ([_x] call KPLIB_fnc_munitionsSnapshot);
} forEach (localNamespace getVariable ["KPLIB_munitionsTargets", []]);
{
    _rows append ([_x] call KPLIB_fnc_munitionsAmmo);
} forEach (_ammo select [0, 8]);
_rows pushBack format ["Guidance metrics (local accumulated game measurements): %1", localNamespace getVariable ["KPLIB_guidanceMetrics", createHashMap]];
_rows pushBack "Limits: client/HC observations are diagnostic claims, not authoritative damage evidence. Fragment requests do not prove fragment hits. Missing events can reflect budgets, ownership or geometry. No real-world kill radius or pressure is inferred.";
private _text = _rows joinString toString [13, 10];
if (count _text > 48000) then {
    _text = (_text select [0, 47800]) + toString [13, 10] + "REPORT TRUNCATED AT 48,000 CHARACTERS. Use a smaller capture or inspect a single object.";
};
[_text, _lines, _meta]
