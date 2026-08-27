/* Reads inherited config cargo from a vehicle or crate class. */

params [
    ["_class", "", [""]]
];

private _result = createHashMapFromArray [
    ["Weapons", createHashMap],
    ["Magazines", createHashMap],
    ["Items", createHashMap],
    ["Backpacks", createHashMap]
];

private _cfg = configFile >> "CfgVehicles" >> _class;
if (_class isEqualTo "" || {!isClass _cfg}) exitWith {_result};

private _sections = [
    ["TransportWeapons", "weapon", "Weapons", configFile >> "CfgWeapons"],
    ["TransportMagazines", "magazine", "Magazines", configFile >> "CfgMagazines"],
    ["TransportItems", "name", "Items", configFile >> "CfgWeapons"],
    ["TransportBackpacks", "backpack", "Backpacks", configFile >> "CfgVehicles"]
];

{
    _x params ["_section", "_field", "_bucketName", "_configRoot"];
    private _bucket = _result get _bucketName;

    {
        private _cargoClass = getText (_x >> _field);
        private _count = (getNumber (_x >> "count")) max 1;
        if (_cargoClass != "" && {isClass (_configRoot >> _cargoClass)}) then {
            _bucket set [_cargoClass, (_bucket getOrDefault [_cargoClass, 0]) + _count];
        };
    } forEach (configProperties [_cfg >> _section, "isClass _x", true]);

    _result set [_bucketName, _bucket];
} forEach _sections;

_result
