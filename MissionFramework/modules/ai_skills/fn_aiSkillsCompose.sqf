/* Pure calculation: always start from immutable baseline, never prior output.
   General is deliberately first; explicit subskills follow in the writer. */
params ["_base", "_terrain", "_suppression", "_weather", "_boost"];
private _result = [];
{
    private _index = _forEachIndex;
    private _terrainFloor = 0 max (1 min (KPLIB_aiSkills_terrainFloor select _index));
    private _suppressionFloor = 0 max (1 min (KPLIB_aiSkills_suppressionFloor select _index));
    private _value = _x * (1 - (1 - _terrainFloor) * _terrain)
        * (1 - (1 - _suppressionFloor) * _suppression);
    if (_index in [4, 5]) then {_value = _value * _weather};
    if (_index in [1, 2, 3]) then {_value = _value * _boost};
    _result pushBack (0 max (1 min _value));
} forEach _base;
_result
