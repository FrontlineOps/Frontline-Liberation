/* Reconcile real inventory, including loaded magazines and magazine wells. */
params ["_unit"];
if (!isServer || {isRemoteExecuted}) exitWith {[]};
private _inventory = magazinesAmmoFull _unit select {(_x select 1) > 0};
private _result = [];
private _cache = localNamespace getVariable "KPLIB_aiCombat_muzzles";
{
    private _weapon = _x;
    if (_weapon == "") then {continue};
    private _rows = _cache getOrDefault [_weapon, []];
    if (_rows isEqualTo []) then {
        {
            private _muzzle = [_x, _weapon] select (_x == "this");
            _rows pushBack [_muzzle, (compatibleMagazines [_weapon, _x]) apply {toLower _x}];
        } forEach getArray (configFile >> "CfgWeapons" >> _weapon >> "muzzles");
        if (count _cache >= 256) then {_cache deleteAt ((keys _cache) select 0)};
        _cache set [_weapon, _rows];
    };
    {
        _x params ["_muzzle", "_magazines"];
        private _seen = [];
        {
            private _magazine = _x select 0;
            if (!(toLower _magazine in _magazines) || {_magazine in _seen}) then {continue};
            _seen pushBack _magazine;
            _result pushBack ([_weapon, _muzzle, _magazine] call KPLIB_fnc_aiCombatProfile);
        } forEach _inventory;
    } forEach _rows;
} forEach [secondaryWeapon _unit, primaryWeapon _unit, handgunWeapon _unit];
_result
