/* One round-robin CBA callback. Registry lifetime follows actual men; each
   callback visits at most batchSize entries and performs a separate capped
   number of small-radius terrain samples. No periodic global unit scan. */
if (!isServer || {isRemoteExecuted}) exitWith {};
private _registry = localNamespace getVariable "KPLIB_aiSkills_registry";
private _queue = localNamespace getVariable "KPLIB_aiSkills_queue";
private _cursor = localNamespace getVariable ["KPLIB_aiSkills_cursor", 0];
private _samples = 0;
private _now = CBA_missionTime;
private _wasEnabled = localNamespace getVariable ["KPLIB_aiSkills_wasEnabled", KPLIB_aiSkills_enabled];
if (_wasEnabled != KPLIB_aiSkills_enabled) then {
    [format ["Dynamic AI skills %1; existing units reconcile through the bounded queue", ["disabled", "enabled"] select KPLIB_aiSkills_enabled], "AI SKILLS"] call KPLIB_fnc_log;
    localNamespace setVariable ["KPLIB_aiSkills_wasEnabled", KPLIB_aiSkills_enabled];
};
for "_step" from 1 to ((count _queue) min (1 max floor KPLIB_aiSkills_batchSize)) do {
    if (_queue isEqualTo []) exitWith {};
    if (_cursor >= count _queue) then {_cursor = 0};
    private _key = _queue select _cursor;
    private _state = _registry get _key;
    private _unit = _state get "unit";
    if (isNull _unit || {!alive _unit}) then {
        _registry deleteAt _key;
        _queue deleteAt _cursor;
        continue;
    };
    _cursor = _cursor + 1;
    if (!local _unit || {isPlayer _unit} || {_now < (_state get "nextUpdate")}) then {continue};
    _state set ["nextUpdate", _now + (0.25 max KPLIB_aiSkills_updateInterval)];
    if (KPLIB_aiSkills_enabled && {_samples < KPLIB_aiSkills_terrainSamplesPerTick}
        && {_now >= (_state get "nextTerrain")} && {[_unit] call KPLIB_fnc_aiSkillsEligible}) then {
        private _count = count nearestTerrainObjects [_unit, ["TREE", "SMALL TREE", "BUSH"], KPLIB_aiSkills_terrainRadius, false, true];
        private _density = 1 min (_count / (1 max KPLIB_aiSkills_terrainSaturation));
        _state set ["terrain", _density * _density];
        _state set ["nextTerrain", _now + (1 max KPLIB_aiSkills_terrainInterval)];
        _samples = _samples + 1;
    };
    [_state] call KPLIB_fnc_aiSkillsUpdate;
};
localNamespace setVariable ["KPLIB_aiSkills_cursor", _cursor];
