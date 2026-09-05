KPLIB_fnc_recycleYield = {
    params ["_vehToRecycle"];
    private _type = typeOf _vehToRecycle;
    private _suppMulti = 0.5;
    private _ammoMulti = 0.5;
    private _fuelMulti = 0.5;

    if !(
        ((toLower _type) in KPLIB_b_buildings_classes) ||
        ((toLower _type) in KPLIB_storageBuildings) ||
        ((toLower _type) in KPLIB_upgradeBuildings) ||
        (_type == "B_Slingload_01_Repair_F") ||
        (_type == "B_Slingload_01_Fuel_F") ||
        (_type == "B_Slingload_01_Ammo_F")
    ) then {
        private _currentAmmo = 0;
        private _allAmmo = 0;
        if (count (magazinesAmmo _vehToRecycle) > 0) then {
            {
                _currentAmmo = _currentAmmo + (_x select 1);
                _allAmmo = _allAmmo + (getNumber(configFile >> "CfgMagazines" >> (_x select 0) >> "count"));
            } forEach (magazinesAmmo _vehToRecycle);
        } else {
            _allAmmo = 1;
        };

        _suppMulti = (((_vehToRecycle getHitPointDamage "HitEngine") - 1) * -1) * (((_vehToRecycle getHitPointDamage "HitHull") - 1) * -1);
        _ammoMulti = _currentAmmo / (_allAmmo max 1);
        _fuelMulti = fuel _vehToRecycle;

        if (_type in boats_names) then {
            _suppMulti = (((_vehToRecycle getHitPointDamage "HitEngine") - 1) * -1);
        };
    };

    private _price_s = 0;
    private _price_a = 0;
    private _price_f = 0;

    if ((toLower _type) in KPLIB_o_allVeh_classes) then {
        if (_vehToRecycle isKindOf "Car") then {
            _price_s = round (60 * _suppMulti);
            _price_a = round (25 * _ammoMulti);
            _price_f = round (40 * _fuelMulti);
        };
        if (_vehToRecycle isKindOf "Tank") then {
            _price_s = round (150 * _suppMulti);
            _price_a = round (120 * _ammoMulti);
            _price_f = round (100 * _fuelMulti);
        };
        if (_vehToRecycle isKindOf "Air") then {
            _price_s = round (250 * _suppMulti);
            _price_a = round (200 * _ammoMulti);
            _price_f = round (150 * _fuelMulti);
        };
    } else {
        private _catalog = [];
        {_catalog append _x} forEach (KPLIB_buildList select [2, 6]);
        private _objectinfo = (_catalog select {_type == (_x select 0)}) param [0, ["", 0, 0, 0]];
        _price_s = round ((_objectinfo select 1) * GRLIB_recycling_percentage * _suppMulti);
        _price_a = round ((_objectinfo select 2) * GRLIB_recycling_percentage * _ammoMulti);
        _price_f = round ((_objectinfo select 3) * GRLIB_recycling_percentage * _fuelMulti);
    };

    [_price_s max 0, _price_a max 0, _price_f max 0]
};
