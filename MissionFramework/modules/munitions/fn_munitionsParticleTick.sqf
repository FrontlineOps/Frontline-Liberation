/* Up to 64 native creations per owner callback, soft 2 ms, 0.75 s queue age.
   Native collision/flight and four-second fragment TTL handle object lifetime. */
if (isRemoteExecuted) exitWith {};
if (CBA_missionTime >= (localNamespace getVariable ["KPLIB_munitionsSettingsNext", 0])) then {
    localNamespace setVariable ["KPLIB_munitionsSettingsNext", CBA_missionTime + 5];
    [] call KPLIB_fnc_munitionsSettings;
};
// Idle frames: nothing queued for this callback or the two it drives.
if ((localNamespace getVariable ["KPLIB_munitionsParticleQueue", []]) isEqualTo []
    && {(localNamespace getVariable ["KPLIB_munitionsDebrisQueue", []]) isEqualTo []}
    && {(localNamespace getVariable ["KPLIB_munitionsBackfaceQueue", []]) isEqualTo []}) exitWith {};
private _started = diag_tickTime;
[_started] call KPLIB_fnc_munitionsBackfaceTick;
[_started] call KPLIB_fnc_munitionsDebrisTick;
private _queue = localNamespace getVariable ["KPLIB_munitionsParticleQueue", []];
private _metrics = localNamespace getVariable ["KPLIB_munitionsParticleMetrics", [0,0,0,0]];
private _work = 0;
while {_queue isNotEqualTo [] && {_work < 64} && {diag_tickTime - _started < 0.002}} do {
    private _job = _queue deleteAt 0;
    _job params ["_origin", "_ammo", "_directions", "_index", "_types", "_speed", "_parents", "_kind", "_at", "_created", "_burst", "_anchor", "_serial"];
    private _expired = CBA_missionTime - _at > 0.75;
    if (_anchor isNotEqualTo []) then {
        _anchor params ["_object", "_position", "_direction", "_up"];
        _expired = _expired || {isNull _object} || {!alive _object} || {!isDamageAllowed _object}
            || {_object getVariable ["KPLIB_pressure_ignore", false]}
            || {getPosWorld _object distance _position > 0.1}
            || {vectorDir _object vectorDotProduct _direction < 0.999}
            || {vectorUp _object vectorDotProduct _up < 0.999};
    };
    if (_expired) then {
        _metrics set [2, (_metrics select 2) + count _directions - _index];
        [_serial, count _directions - _index] call KPLIB_fnc_munitionsBudgetReturn;
    } else {
        // Eight at a time keeps simultaneous impacts interleaved and bounded.
        for "_i" from 1 to (8 min (count _directions - _index)) do {
            private _direction = _directions select _index;
            private _fragment = createVehicleLocal [selectRandom _types, ASLToAGL _origin, [], 0, "CAN_COLLIDE"];
            if (!isNull _fragment) then {
                (localNamespace getVariable "KPLIB_munitionsBudgetLive") pushBack [_fragment, _serial];
                _fragment setVariable ["KPLIB_munitionsParticle", true];
                _fragment setVariable ["KPLIB_munitionsParticleKind", _kind];
                _fragment setVariable ["KPLIB_munitionsVisualBurst", _burst];
                _fragment setVariable ["ace_frag_blacklisted", true];
                // Exact observed origin: no engine spawn offset or terrain lift.
                _fragment setPosASL _origin;
                _fragment setShotParents _parents;
                _fragment setVectorDir _direction;
                _fragment setVelocity (_direction vectorMultiply (_speed * (0.5 + random 0.5)));
                [_fragment] call KPLIB_fnc_munitionsTrack;
                _created = _created + 1;
                _metrics set [1, (_metrics select 1) + 1];
            } else {
                _metrics set [3, (_metrics select 3) + 1];
                [_serial, 1] call KPLIB_fnc_munitionsBudgetReturn;
            };
            _index = _index + 1;
            _work = _work + 1;
        };
    };
    if (_expired || {_index >= count _directions}) then {
        [objNull, _kind + " COMPLETE", _origin, [_ammo, "created", _created, "expired", _expired, "queue age", CBA_missionTime - _at]] call KPLIB_fnc_munitionsEvent;
    } else {
        _job set [3, _index];
        _job set [9, _created];
        _queue pushBack _job;
    };
};
localNamespace setVariable ["KPLIB_munitionsParticleQueue", _queue];
localNamespace setVariable ["KPLIB_munitionsParticleMetrics", _metrics];
private _elapsed = 1000 * (diag_tickTime - _started);
localNamespace setVariable ["KPLIB_munitionsParticleMaxTickMs", _elapsed max (localNamespace getVariable ["KPLIB_munitionsParticleMaxTickMs", 0])];
