/* Loaded GAME durability only. Hitpoint config and model selections are not
   material thickness/strength. ERA/SLAT follows other components in the cap. */
params ["_asset"];
private _object = _asset get "object";
private _cfg = configOf _object;
private _armor = (getNumber (_cfg >> "armor")) max 1;
private _structural = (getNumber (_cfg >> "armorStructural")) max 1;
private _resistance = sqrt (_armor * _structural / 100);
private _components = [];
private _hitpoints = getAllHitPointsDamage _object;
if (_hitpoints isEqualTo [] || {(_hitpoints select 0) isEqualTo []}) exitWith {[[-1,"GLOBAL (no component data)",[],_resistance]]};
private _cache = localNamespace getVariable ["KPLIB_gasAssetConfigs",createHashMap];
private _map = _cache get (typeOf _object);
if (isNil "_map") then {
    _map = createHashMap;
    private _nodes = [_cfg];
    for "_i" from 0 to 15 do {
        if (_i >= count _nodes) exitWith {};
        private _node = _nodes select _i;
        {
            _map set [toLower configName _x,[getNumber (_x >> "armor"),getText (_x >> "simulation")]];
        } forEach ("true" configClasses (_node >> "HitPoints"));
        _nodes append ("true" configClasses (_node >> "Turrets"));
    };
    if (count _cache < 256) then {_cache set [typeOf _object,_map]};
    localNamespace setVariable ["KPLIB_gasAssetConfigs",_cache];
};
private _selections = (_object selectionNames "HitPoints") apply {toLower _x};
private _ordered = [];
{
    private _part = _map getOrDefault [toLower _x,[1,""]];
    private _selection = (_hitpoints select 1) select _forEachIndex;
    private _position = [];
    if (toLower _selection in _selections) then {_position = _object selectionPosition [_selection,"HitPoints","AveragePoint"]};
    private _armorPart = (abs (_part select 0)) max 0.1;
    // Negative game armor is also used by ordinary wheels; only the declared
    // simulation identifies an ERA/SLAT component for quota ordering.
    private _simulation = toLower (_part select 1);
    private _special = _simulation find "armor_era" == 0 || {_simulation find "armor_slat" == 0};
    _ordered pushBack [[0,1] select _special,_forEachIndex,_x,_position,_resistance * sqrt _armorPart];
} forEach ((_hitpoints select 0) select [0,128]);
_ordered sort true;
{_components pushBack (_x select [1,4])} forEach (_ordered select [0,16]);
_asset set ["componentOmissions",((count (_hitpoints select 0)) - count _components) max 0];
_components
