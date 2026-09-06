/* Resource value of one round. Utility ammunition has no combat value. */
params [["_magazine", "", [""]]];

private _cache = localNamespace getVariable ["KPLIB_magazineResourceCache", createHashMap];
private _key = toLower _magazine;
private _cached = _cache get _key;
if (!isNil "_cached") exitWith {_cached};

private _ammo = getText (configFile >> "CfgMagazines" >> _magazine >> "ammo");
private _readAmmo = {
    params ["_class", ["_depth", 0]];
    if (_depth > 4) exitWith {0};
    private _cfg = configFile >> "CfgAmmo" >> _class;
    private _simulation = toLower getText (_cfg >> "simulation");
    if !(_simulation in ["shotbullet", "shotshell", "shotrocket", "shotmissile", "shotbomb", "shotsubmunitions"]) exitWith {0};
    private _name = toLower _class;
    if ((["smoke", "flare", "laser"] findIf {_name find _x >= 0}) >= 0) exitWith {0};

    private _hit = (getNumber (_cfg >> "hit")) max 0;
    private _blast = (getNumber (_cfg >> "indirectHit")) max 0;
    private _radius = (getNumber (_cfg >> "indirectHitRange")) max 0;
    private _value = 0;
    if (_hit > 1 || {_blast > 0}) then {
        _value = switch (_simulation) do {
            case "shotbullet": {0.02 + (_hit min 500) * 0.001};
            case "shotmissile": {15 + sqrt _hit * 0.75 + sqrt _blast * 0.5 + _radius * 0.3};
            case "shotrocket": {3 + sqrt _hit * 0.5 + sqrt _blast * 0.5 + _radius * 0.3};
            default {0.4 + sqrt _hit * 0.25 + sqrt _blast * 0.3 + _radius * 0.15};
        };
    };

    // HEAT carriers and cluster rounds can delegate their damage to submunitions.
    private _children = getArray (_cfg >> "submunitionAmmo");
    private _child = getText (_cfg >> "submunitionAmmo");
    if (_child != "") then {_children pushBack _child};
    {
        if (_x isEqualType "" && {_x != ""}) then {
            _value = _value max ([_x, _depth + 1] call _readAmmo);
        };
    } forEach _children;
    _value min 300
};

private _value = [_ammo] call _readAmmo;
_cache set [_key, _value];
localNamespace setVariable ["KPLIB_magazineResourceCache", _cache];
_value
