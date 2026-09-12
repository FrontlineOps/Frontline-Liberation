/* Canonical inventory identity. Allocated radio/ACE instances keep their base permission. */
params [["_class", "", [""]]];
if (_class == "") exitWith {""};
private _cache = localNamespace getVariable ["KPLIB_gearIdentityCache", createHashMap];
private _key = toLower _class;
if (_key in _cache) exitWith {_cache get _key};
private _cfg = configFile >> "CfgWeapons" >> _class;
if !(isClass _cfg) then {_cfg = configFile >> "CfgMagazines" >> _class};
if !(isClass _cfg) then {_cfg = configFile >> "CfgVehicles" >> _class};
if !(isClass _cfg) then {_cfg = configFile >> "CfgGlasses" >> _class};
private _base = getText (_cfg >> "ace_arsenal_uniqueBase");
if (_base == "" && {getNumber (_cfg >> "acre_isRadio") == 1}) then {
    _base = getText (_cfg >> "acre_baseClass");
};
if (_base == "" && {getNumber (_cfg >> "tf_radio") > 0}) then {
    _base = getText (_cfg >> "tf_parent");
};
private _result = toLower ([_class, _base] select (_base != ""));
if (_base == "" && {isClass _cfg}) then {
    private _kind = if (_class isKindOf "Bag_Base") then {"backpack"} else {str getNumber (_cfg >> "type")};
    private _current = _cfg;
    for "_depth" from 0 to 31 do {
        private _scope = getNumber (_current >> "scope");
        private _visible = if (isNumber (_current >> "scopeArsenal")) then {
            getNumber (_current >> "scopeArsenal") == 2 && {_scope > 0}
        } else {_scope == 2};
        if (_visible && {getNumber (_current >> "ace_arsenal_hide") != 1}) exitWith {
            _result = toLower configName _current;
        };
        _current = inheritsFrom _current;
        if (!isClass _current) exitWith {};
        private _sameKind = if (_kind == "backpack") then {
            configName _current isKindOf "Bag_Base"
        } else {str getNumber (_current >> "type") == _kind};
        if (!_sameKind) exitWith {};
    };
};
_cache set [_key, _result];
localNamespace setVariable ["KPLIB_gearIdentityCache", _cache];
_result
