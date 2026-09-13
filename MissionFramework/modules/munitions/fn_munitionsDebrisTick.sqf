/* At most two surface queries in the existing particle callback. Expired work
   is discarded; no global object scan, persistent rubble or damage RPC. */
if (isRemoteExecuted) exitWith {};
params ["_started"];
private _queue = localNamespace getVariable ["KPLIB_munitionsDebrisQueue", []];
for "_work" from 1 to 2 do {
    if (_queue isEqualTo [] || {diag_tickTime - _started >= 0.001}) exitWith {};
    private _job = _queue deleteAt 0;
    private _expired = CBA_missionTime - (_job get "at") > 0.75;
    private _index = _job get "index";
    private _origin = _job get "origin";
    if (!_expired && {_job get "remaining" > 0}) then {
        private _contact = _job get "contact";
        private _hit = [];
        if (_contact isNotEqualTo []) then {
            _contact params ["", "_object", "_position", "_normal", "_surface"];
            _hit = [_position, _normal, _object, _surface];
            _job set ["contact", []];
        } else {
            private _direction = (_job get "directions") select _index;
            private _end = _origin vectorAdd (_direction vectorMultiply (_job get "radius"));
            private _surfaces = lineIntersectsSurfaces [_origin, _end, objNull, objNull, true, 8, "FIRE", "NONE", true];
            // Personnel do not shield the geometry query; every other first
            // surface, including terrain/vehicles, blocks sampling beyond it.
            private _first = _surfaces findIf {!((_x select 2) isKindOf "CAManBase")};
            if (_first >= 0) then {
                private _surface = _surfaces select _first;
                if (!terrainIntersectASL [_origin, _surface select 0]) then {
                    _hit = [_surface select 0, _surface select 1, _surface select 2, _surface param [5, "sampled FIRE geometry"]];
                };
            };
            _index = _index + 1;
            _job set ["index", _index];
        };
        if (_hit isNotEqualTo []) then {
            _hit params ["_position", "_normal", "_object", "_surface"];
            private _seen = _job get "surfaces";
            if (!isNull _object && {_object isKindOf "House" || {_object isKindOf "Building"}}
                && {count _seen < 8}
                && {_seen findIf {(_x select 0) isEqualTo _object && {(_x select 1) distance _position < 1}} < 0}) then {
                _seen pushBack [_object, _position];
                private _count = 8 min (_job get "remaining");
                private _admitted = [_object, _position, _normal, _job get "ammo", _count, 120, _job get "parents", "STRUCTURAL DEBRIS", [_origin, _job get "at"], _surface] call KPLIB_fnc_munitionsSurfaceDebris;
                _job set ["remaining", (_job get "remaining") - _count];
                _job set ["created", (_job get "created") + _admitted];
            };
        };
    };
    if (_expired || {_index >= 16} || {_job get "remaining" <= 0}) then {
        [objNull, "STRUCTURAL DEBRIS SAMPLED", _origin, [_job get "ammo", "rays", _index, "patches", count (_job get "surfaces"), "admitted particles", _job get "created", "expired", _expired]] call KPLIB_fnc_munitionsEvent;
    } else {
        _queue pushBack _job;
    };
};
localNamespace setVariable ["KPLIB_munitionsDebrisQueue", _queue];
