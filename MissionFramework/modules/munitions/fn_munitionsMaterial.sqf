/* Surface metadata classifies the contacted face, not the whole object.
   Unknown materials never inherit metal behavior from a vehicle/building class. */
params [["_surface", "", [""]]];
private _key = toLower _surface;
private _cache = localNamespace getVariable ["KPLIB_munitionsMaterials", createHashMap];
private _cached = _cache get _key;
if (!isNil "_cached") exitWith {_cached};
// Inspect the material basename, not directories such as a building pack name.
private _parts = _key splitString "\/";
private _name = if (_parts isEqualTo []) then {""} else {_parts select (count _parts - 1)};
private _category = "UNKNOWN";
{
    _x params ["_kind", "_names"];
    if (_names findIf {_name find _x >= 0} >= 0) exitWith {_category = _kind};
} forEach [
    ["VEGETATION", ["foliage", "leaf", "leaves", "grass", "bush", "plant"]],
    ["WOOD", ["wood", "timber", "bark", "trunk", "tree"]],
    ["GLASS", ["glass"]],
    ["SOFT", ["soil", "dirt", "sand", "mud", "rubber", "plastic", "fabric", "cloth"]],
    ["MASONRY", ["concrete", "beton", "brick", "stone", "rock", "cement", "plaster"]],
    ["METAL", ["metal", "armour", "armor", "steel", "iron", "aluminium", "aluminum"]]
];
if (count _cache >= 256) then {_cache deleteAt ((keys _cache) select 0)};
_cache set [_key, _category];
localNamespace setVariable ["KPLIB_munitionsMaterials", _cache];
if (_category == "UNKNOWN") then {
    [objNull, "UNKNOWN IMPACT MATERIAL", [0,0,0], [_surface, "generic damaging fragments omitted"]] call KPLIB_fnc_munitionsEvent;
};
_category
