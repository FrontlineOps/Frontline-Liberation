/* Find an opposing same-object FIRE face with eight bounded reverse queries.
   The search distance is a game geometry bound, not inferred armor thickness. */
if (isRemoteExecuted) exitWith {[]};
params ["_object", "_entry", "_normal"];
private _inward = _normal vectorMultiply -1;
private _front = _entry vectorAdd (_normal vectorMultiply 0.04);
private _result = [];
private _blocked = false;
for "_step" from 1 to 8 do {
    private _probe = _entry vectorAdd (_inward vectorMultiply (_step * 0.08));
    if (terrainIntersectASL [_front, _probe]) exitWith {};
    private _hits = lineIntersectsSurfaces [_probe, _front, objNull, objNull, true, 1, "FIRE", "NONE", false];
    if (_hits isNotEqualTo []) then {
        private _hit = _hits select 0;
        if ((_hit select 2) isNotEqualTo _object) exitWith {_blocked = true};
        private _position = _hit select 0;
        private _backNormal = _hit select 1;
        // Queries begun inside a solid may report arbitrary normals. Require
        // an opposing face, close to the struck layer, with clear rear space.
        if (_backNormal vectorDotProduct _inward >= 0.5
            && {(_position vectorDiff _entry) vectorDotProduct _inward >= -0.01}) then {
            private _outside = _position vectorAdd (_backNormal vectorMultiply 0.02);
            if (_outside select 2 >= getTerrainHeightASL _outside
                && {!lineIntersects [_outside, _probe]}) then {
                _result = [_position, _backNormal, _hit param [5, "observed FIRE geometry"]];
            };
        };
    };
    if (_blocked || {_result isNotEqualTo []}) exitWith {};
};
_result
