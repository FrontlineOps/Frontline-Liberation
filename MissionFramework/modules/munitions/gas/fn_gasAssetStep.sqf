/* One exterior face sample per work unit, at final solver time. Peak/impulse
   histories only belong to stationary geometry. Moving objects are omitted. */
if (!isServer || {isRemoteExecuted}) exitWith {};
params ["_job"];
private _assets = _job getOrDefault ["gasAssets",[]];
private _index = _job getOrDefault ["gasAssetIndex",0];
if (_index >= count _assets) exitWith {
    _job set ["phase","DONE"];
    _job set ["gasReason","Completed; source and damage conversion are game assumptions"];
};
private _asset = _assets select _index;
private _object = _asset get "object";
private _finish = {
    params ["_status"];
    _asset set ["status",_status];
    _job set ["gasAssetIndex",_index + 1];
};
if (!(missionNamespace getVariable ["KPLIB_munitions_gas_assets",true])) exitWith {["Disabled"] call _finish};
if (!([_object] call KPLIB_fnc_gasAssetEligible)) exitWith {["Protected / destroyed / ineligible"] call _finish};
if (getPosASL _object distance (_asset get "position") > 0.25
    || {vectorDir _object vectorDotProduct (_asset get "direction") < 0.999}
    || {vectorUp _object vectorDotProduct (_asset get "up") < 0.999}) exitWith {["Moved: frozen-grid history not applied"] call _finish};
if (damage _object + 0.001 < (_asset get "baseline")) exitWith {["Repaired since observation"] call _finish};
private _bounds = _asset get "bounds";
private _min = _bounds select 0;
private _max = _bounds select 1;
private _centre = (_min vectorAdd _max) vectorMultiply 0.5;
private _half = (_max vectorDiff _min) vectorMultiply 0.5;
private _cursor = _asset get "cursor";
private _faces = _asset get "faces";
private _cell = _job get "gasCell";
private _n = _job get "gasN";
if (_cursor < 6) exitWith {
    private _axis = floor (_cursor / 2);
    private _sign = [-1,1] select (_cursor mod 2);
    private _face = +_centre;
    _face set [_axis, (_centre select _axis) + _sign * (_half select _axis)];
    private _surface = _object modelToWorldWorld _face;
    private _sampleIndex = -1;
    for "_trial" from 1 to 3 do {
        private _outside = +_face;
        _outside set [_axis,(_face select _axis) + _sign * _cell * 0.55 * _trial];
        private _world = _object modelToWorldWorld _outside;
        private _grid = ((_world vectorDiff (_job get "origin")) vectorMultiply (1 / _cell)) apply {floor (_x + _n / 2)};
        if (_grid findIf {_x < 0 || {_x >= _n}} >= 0) exitWith {};
        private _candidate = (_grid select 0) + _n * ((_grid select 1) + _n * (_grid select 2));
        private _point = [_job,_candidate] call KPLIB_fnc_gasPosition;
        private _relative = _object worldToModel (ASLToAGL _point);
        if (((_relative select _axis) - (_face select _axis)) * _sign > 0.02
            && {(_point select 2) >= getTerrainHeightASL _point}
            && {[_point,_surface,_object] call KPLIB_fnc_blastClear}) exitWith {
            _sampleIndex = _candidate;
        };
    };
    private _row = [_sampleIndex,_surface,0,0,0];
    if (_sampleIndex >= 0) then {
        private _reply = ["sample",[_job get "gasHandle",_sampleIndex,287.05]] call KPLIB_fnc_gasNative;
        if (_reply select 0) then {
            private _sample = _reply select 1;
            _row set [2,(_sample select 2) max 0];
            _row set [3,(_sample select 3) max 0];
            private _reference = (_job get "gasSourcePressure") max 1;
            _row set [4,0.5 * (_row select 2) / _reference + 0.5 * (_row select 3) / (_reference * _cell / 340)];
        };
    };
    _faces pushBack _row;
    _asset set ["cursor",_cursor + 1];
    _asset set ["status","Sampling exterior faces"];
};
private _components = [_asset] call KPLIB_fnc_gasAssetProfile;
private _gainName = ["KPLIB_munitions_gas_vehicle_gain","KPLIB_munitions_gas_building_gain"] select (_asset get "building");
private _gain = (missionNamespace getVariable [_gainName,1]) max 0 min 4;
private _floors = [];
{
    _x params ["_component","_name","_position","_resistance"];
    private _response = 0;
    private _weight = 0;
    private _exterior = false;
    if (_position isNotEqualTo []) then {
        private _relative = _position vectorDiff _centre;
        for "_axis" from 0 to 2 do {
            private _fraction = abs (_relative select _axis) / ((_half select _axis) max 0.1);
            _exterior = _exterior || {_fraction > 0.5};
            private _selected = 2 * _axis + ([0,1] select (_relative select _axis > 0));
            private _proximity = (_fraction min 1)^2;
            _response = _response + ((_faces select _selected) select 4) * _proximity;
            _weight = _weight + _proximity;
        };
    };
    // Edge/corner components receive a weighted mix of their adjacent faces.
    // Unavailable faces stay zero: do not redirect their load around cover.
    if (_exterior && {_weight > 0}) then {_response = _response / _weight} else {
        _response = 0;
        {_response = _response + (_x select 4) / 6} forEach _faces;
    };
    private _floor = ((_job get "profile") get "strength") * _gain * _response / (_resistance max 0.1);
    private _baseline = if (_component < 0) then {_asset get "baseline"} else {(_asset get "baselineParts") param [_component,0]};
    _floors pushBack [_component,_name,_floor max 0 min 1,_baseline];
} forEach _components;
_asset set ["floors",_floors];
if (_floors findIf {_x select 2 > 0.0001} < 0) exitWith {["No additional pressure floor"] call _finish};
private _payload = [_object,(_job get "id") + ":asset:" + str _index,_job get "at",_asset get "position",_floors,_job get "source"];
if (local _object) then {
    [_payload call KPLIB_fnc_gasAssetApply] call _finish;
} else {
    private _owner = owner _object;
    if (_owner > 0) then {
        _payload remoteExecCall ["KPLIB_fnc_gasAssetApply",_owner];
        [format ["Sent to owner %1; inspect owner report for actual damage",_owner]] call _finish;
    } else {["No reachable owner"] call _finish};
};
