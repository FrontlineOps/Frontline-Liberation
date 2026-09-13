/* Cell-centre measurements. Absolute pressure Pa; positive/signed excess-pressure
   impulse Pa*s; temperature K under the configured ideal-gas EOS.
   Tracer fraction is transported material, not oxygen or a reaction progress. */
if (isRemoteExecuted) exitWith {[]};
params ["_domain", "_index", ["_gasConstant", 287.05]];
private _cells = _domain getOrDefault ["cells", []];
if (_index < 0 || {_index >= count _cells} || {_index != floor _index} || {_gasConstant <= 0}) exitWith {[]};
private _w = [_cells select _index, _domain get "gamma"] call KPLIB_fnc_gasPrimitive;
if (_w isEqualTo []) exitWith {[]};
[
    _domain get "time", _w select 4, (_domain get "peak") select _index,
    (_domain get "impulse") select _index, (_domain get "signedImpulse") select _index,
    (_w select 4) / ((_w select 0) * _gasConstant), _w select 0,
    _w select 1, _w select 2, _w select 3, _w select 6
]
