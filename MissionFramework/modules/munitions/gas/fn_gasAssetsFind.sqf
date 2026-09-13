/* One spatial query per observed explosion, never a per-frame global scan.
   Separate quotas stop a dense street from excluding every nearby vehicle. */
if (!isServer || {isRemoteExecuted}) exitWith {[[],0]};
params ["_origin", "_profile"];
if (!(missionNamespace getVariable ["KPLIB_munitions_gas_enabled", true])
    || {!(missionNamespace getVariable ["KPLIB_munitions_gas_assets", true])}) exitWith {[[],0]};
private _radius = (((_profile get "range") * 2) max 3) min KPLIB_munitions_gas_radius;
private _limit = floor ((missionNamespace getVariable ["KPLIB_munitions_gas_asset_limit",8]) max 1 min 16);
private _groups = [[],[]];
{
    if ([_x] call KPLIB_fnc_gasAssetEligible) then {
        private _bounds = boundingBoxReal _x;
        private _min = _bounds select 0;
        private _max = _bounds select 1;
        private _relative = _x worldToModel (ASLToAGL _origin);
        private _near = [];
        for "_i" from 0 to 2 do {_near pushBack (((_relative select _i) max (_min select _i)) min (_max select _i))};
        private _distance = (_x modelToWorldWorld _near) distance _origin;
        if (_distance <= _radius * 1.733) then {
            private _group = _groups select ([0,1] select (_x isKindOf "House"));
            _group pushBack [_distance,count _group,_x,_bounds];
        };
    };
} forEach (nearestObjects [ASLToAGL _origin,["LandVehicle","Air","Ship","StaticWeapon","House"],_radius + 30,true]);
private _assets = [];
private _overflow = 0;
{
    _x sort true;
    _overflow = _overflow + ((count _x - _limit) max 0);
    {
        _x params ["_distance", "", "_object", "_bounds"];
        _assets pushBack createHashMapFromArray [
            ["object",_object], ["class",typeOf _object], ["building",_object isKindOf "House"],
            ["position",getPosASL _object], ["direction",vectorDir _object], ["up",vectorUp _object],
            ["bounds",_bounds], ["baseline",damage _object], ["distance",_distance],
            ["baselineParts",(getAllHitPointsDamage _object) param [2,[]]],
            ["faces",[]], ["cursor",0], ["status","Pending field completion"], ["floors",[]]
        ];
    } forEach (_x select [0,_limit]);
} forEach _groups;
[_assets,_overflow]
