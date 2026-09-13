/* Shared spatial discovery; each missile applies its own seeker/LOS checks. */
if (isRemoteExecuted) exitWith {[]};
params ["_record"];
private _missile = _record get "missile";
private _profile = _record get "profile";
private _position = getPosASL _missile;
private _range = (_profile get "range") min 20000;
private _cell = [floor ((_position select 0) / 2000), floor ((_position select 1) / 2000), ceil (_range / 2000)];
private _key = str _cell;
private _cache = localNamespace getVariable ["KPLIB_guidanceSpatial", createHashMap];
private _entry = _cache getOrDefault [_key, [0, []]];
private _searchAir = (_profile get "airCapable") && {!(_record get "locked")};
if (_searchAir && {CBA_missionTime >= (_entry select 0)}) then {
    private _center = [(_cell select 0) * 2000 + 1000, (_cell select 1) * 2000 + 1000, 0];
    private _aircraft = _center nearEntities ["Air", (_cell select 2) * 2000 + 1500];
    _entry = [CBA_missionTime + (missionNamespace getVariable ["KPLIB_guidance_search_interval", 0.5]), _aircraft];
    _cache set [_key, _entry];
    localNamespace setVariable ["KPLIB_guidanceSpatial", _cache];
    private _metrics = localNamespace getVariable "KPLIB_guidanceMetrics";
    _metrics set ["searches", (_metrics getOrDefault ["searches", 0]) + 1];
};
private _candidates = [];
{
    if (!isNull _x && {alive _x} && {_x != (_record get "carrier")}) then {_candidates pushBackUnique _x};
} forEach [_record get "target", _record get "originalTarget"];
if (_searchAir) then {
    {
        if (!isNull _x && {alive _x} && {_x != (_record get "carrier")} && {_x distance _missile <= _range}) then {
            _candidates pushBackUnique _x;
        };
    } forEach (_entry select 1);
};
private _family = _profile get "family";
if (_family in ["IR", "ARH", "SARH"]) then {
    private _flag = if (_family == "IR") then {2} else {8};
    {
        _x params ["_object", "_expires", "_mask"];
        if (!isNull _object && {CBA_missionTime < _expires} && {floor (_mask / _flag) mod 2 == 1}
            && {_missile distance _object <= _range}) then {_candidates pushBackUnique _object};
    } forEach (localNamespace getVariable ["KPLIB_guidanceCountermeasures", []]);
};
private _head = vectorDir _missile;
private _cos = cos (_profile get "gimbal");
_candidates = _candidates select {
    private _offset = (getPosASL _x) vectorDiff _position;
    vectorMagnitude _offset <= _range && {_head vectorDotProduct vectorNormalized _offset >= _cos}
};
// Current/original target takes precedence over nearby decoys in the bounded shortlist.
private _priorities = [_record get "target", _record get "originalTarget"];
private _ranked = _candidates apply {[if (_x in _priorities) then {-1} else {_x distanceSqr _missile}, _x]};
_ranked sort true;
(_ranked select [0, missionNamespace getVariable ["KPLIB_guidance_candidates_per_scan", 24]]) apply {_x select 1}
