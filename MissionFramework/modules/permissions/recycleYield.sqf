KPLIB_fnc_recycleYield = {
    params ["_vehToRecycle", ["_field", false]];
    if (isNull _vehToRecycle) exitWith {[0, 0, 0]};
    private _type = typeOf _vehToRecycle;
    private _catalog = [];
    {_catalog append _x} forEach (KPLIB_buildList select [2, 6]);
    private _entry = (_catalog select {toLower _type == toLower (_x select 0)}) param [0, []];
    private _percentage = GRLIB_recycling_percentage max 0 min 1;

    if !(_vehToRecycle isKindOf "LandVehicle" || {_vehToRecycle isKindOf "Air"} || {_vehToRecycle isKindOf "Ship"}) exitWith {
        if (_entry isEqualTo []) exitWith {[0, 0, 0]};
        (_entry select [1, 3]) apply {round (_x * _percentage * 0.5) max 0}
    };

    // Captured vehicles use the same valuation as a generated BLUFOR vehicle.
    // Catalog prices take precedence so custom build costs cannot be farmed.
    private _price = if (_entry isEqualTo []) then {
        [_type] call KPLIB_fnc_getAutomaticFactionPrice
    } else {
        _entry select [1, 3]
    };
    private _profile = [_type] call KPLIB_fnc_getVehicleResourceProfile;
    private _scrap = KPLIB_salvage_wreck_supply_fraction max 0 min 1;
    private _condition = (1 - damage _vehToRecycle) max 0 min 1;
    private _supplyFraction = _scrap + (1 - _scrap) * _condition;
    private _ammoFraction = 0;
    private _fuelFraction = 0;
    if (alive _vehToRecycle) then {
        private _remaining = 0;
        {
            _remaining = _remaining + (([_x select 0] call KPLIB_fnc_getMagazineResourceValue) * ((_x select 2) max 0));
        } forEach magazinesAllTurrets [_vehToRecycle, true];
        private _full = _profile get "ammunition";
        if (_full > 0) then {_ammoFraction = (_remaining / _full) min 1};
        _fuelFraction = if (_vehToRecycle isKindOf "StaticWeapon") then {0} else {fuel _vehToRecycle max 0 min 1};
    };
    if (_field) then {_percentage = _percentage * (KPLIB_salvage_field_multiplier max 0 min 1)};
    private _fractions = [_supplyFraction, _ammoFraction, _fuelFraction];
    private _yield = [0, 1, 2] apply {floor ((_price select _x) * _percentage * (_fractions select _x)) max 0};

    // Empty/captured/wrecked objects lose their enemy side, so use the generated
    // OPFOR catalog, including configured extras and static weapons. A class also
    // available to build keeps its normal refund to prevent buy/salvage profit.
    private _catalogs = missionNamespace getVariable ["KPLIB_autoFactionCatalogs", createHashMap];
    private _enemyVehicles = (_catalogs getOrDefault ["opfor", createHashMap]) getOrDefault ["allVehicles", []];
    if (_entry isEqualTo [] && {_enemyVehicles findIf {toLower _x == toLower _type} >= 0}) then {
        private _multiplier = (missionNamespace getVariable ["KPLIB_salvage_enemy_multiplier", 2]) max 0;
        // Apply after the existing rounding: 2 means exactly twice each old payout.
        _yield = _yield apply {floor (_x * _multiplier)};
    };
    _yield
};
