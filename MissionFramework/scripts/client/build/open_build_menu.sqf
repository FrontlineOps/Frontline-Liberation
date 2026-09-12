if !([player, "BUILD"] call KPLIB_fnc_hasPermission) exitWith {hint "Building permission is required."};
if (([getPos player, 500, GRLIB_side_enemy] call KPLIB_fnc_getUnitsCount) > 4) exitWith {
    hint localize "STR_BUILD_ENEMIES_NEARBY";
};

if (isNil "buildtype" || {!(buildtype in [2, 3, 4, 5, 6, 7])}) then {buildtype = 2;};
if (isNil "buildindex") then {buildindex = -1;};

dobuild = 0;
private _oldBuildType = -1;
private _vehicleConfig = configFile >> "CfgVehicles";
private _initialIndex = buildindex;

if !(createDialog "liberation_build") exitWith {};
waitUntil {dialog || {!alive player};};
if (!dialog) exitWith {};

private _display = findDisplay 5501;
if (isNull _display) exitWith {};

private _buildListControl = _display displayCtrl 110;
private _pageControl = _display displayCtrl 151;
private _capControl = _display displayCtrl 134;
private _unlockControl = _display displayCtrl 161;
private _buildButton = _display displayCtrl 120;
private _supplyControl = _display displayCtrl 131;
private _ammoControl = _display displayCtrl 132;
private _fuelControl = _display displayCtrl 133;
private _buildPages = [
    "", // Reserved former recruitment category.
    localize "STR_BUILD2",
    localize "STR_BUILD3",
    localize "STR_BUILD4",
    localize "STR_BUILD5",
    localize "STR_BUILD6",
    localize "STR_BUILD7"
];

private _nearestFob = [] call KPLIB_fnc_getNearestFob;
private _actualFob = KP_liberation_fob_resources select {
    (_x select 0) distance _nearestFob < GRLIB_fob_range
};
private _isStartBase = _nearestFob isEqualTo (getMarkerPos "startbase_marker");

while {dialog && {alive player} && {dobuild isEqualTo 0}} do {
    private _buildList = KPLIB_buildList select buildtype;

    if (_oldBuildType != buildtype || {synchro_done}) then {
        synchro_done = false;
        _oldBuildType = buildtype;
        _actualFob = KP_liberation_fob_resources select {
            (_x select 0) distance _nearestFob < GRLIB_fob_range
        };
        _isStartBase = _nearestFob isEqualTo (getMarkerPos "startbase_marker");

        lbClear _buildListControl;
        _pageControl ctrlSetText (_buildPages select (buildtype - 1));

        {
            private _entry = _x;
            private _entryName = "";
            private _icon = "";

            private _entryClass = _entry select 0;
            private _customName = _entry param [4, ""];
            _entryName = getText (_vehicleConfig >> _entryClass >> "displayName");

            if (count _entry > 4 && {!isNil {_customName}}) then {
                _entryName = _customName;
            };

            switch (_entryClass) do {
                case FOB_box_typename: {_entryName = localize "STR_FOBBOX";};
                case Arsenal_typename: {
                    if (KP_liberation_mobilearsenal) then {
                        _entryName = localize "STR_ARSENAL_BOX";
                    };
                };
                case Respawn_truck_typename: {
                    if (KP_liberation_mobilerespawn) then {
                        _entryName = localize "STR_RESPAWN_TRUCK";
                    };
                };
                case FOB_truck_typename: {_entryName = localize "STR_FOBTRUCK";};
                case "Flag_White_F": {_entryName = localize "STR_INDIV_FLAG";};
                case KP_liberation_small_storage_building: {_entryName = localize "STR_SMALL_STORAGE";};
                case KP_liberation_large_storage_building: {_entryName = localize "STR_LARGE_STORAGE";};
                case KP_liberation_recycle_building: {_entryName = localize "STR_RECYCLE_BUILDING";};
                case KP_liberation_air_vehicle_building: {_entryName = localize "STR_HELI_BUILDING";};
                case KP_liberation_heli_slot_building: {_entryName = localize "STR_HELI_SLOT";};
                case KP_liberation_plane_slot_building: {_entryName = localize "STR_PLANE_SLOT";};
                default {};
            };

            _icon = getText (_vehicleConfig >> _entryClass >> "icon");
            if (isText (configFile >> "CfgVehicleIcons" >> _icon)) then {
                _icon = getText (configFile >> "CfgVehicleIcons" >> _icon);
            };

            private _row = _buildListControl lnbAddRow [
                _entryName,
                str (_entry select 1),
                str (_entry select 2),
                str (_entry select 3)
            ];

            if !(_icon isEqualTo "") then {
                _buildListControl lnbSetPicture [[_row, 0], _icon];
            };

            private _rowAffordable = !(
                ((_entry select 1) > 0 && {(_entry select 1) > ((_actualFob select 0) select 1)})
                || {(_entry select 2) > 0 && {(_entry select 2) > ((_actualFob select 0) select 2)}}
                || {(_entry select 3) > 0 && {(_entry select 3) > ((_actualFob select 0) select 3)}}
            );
            private _rowColor = if (_rowAffordable) then {[1, 1, 1, 1]} else {[0.4, 0.4, 0.4, 1]};

            for "_column" from 0 to 3 do {
                _buildListControl lnbSetColor [[_row, _column], _rowColor];
            };
        } forEach _buildList;
    };

    if (_initialIndex != -1) then {
        _buildListControl lbSetCurSel _initialIndex;
        _initialIndex = -1;
    };

    private _selectedItem = lbCurSel _buildListControl;
    private _affordable = false;
    private _hasUnlockRequirements = false;
    private _unlockRequirementsMet = true;
    private _requiredSectorCount = 0;

    if (dobuild isEqualTo 0 && {_selectedItem != -1} && {_selectedItem < (count _buildList)}) then {
        private _buildItem = _buildList select _selectedItem;
        private _selectedClass = _buildItem select 0;
        private _hasResources =
            ((_buildItem select 1) isEqualTo 0 || {(_buildItem select 1) <= ((_actualFob select 0) select 1)})
            && {(_buildItem select 2) isEqualTo 0 || {(_buildItem select 2) <= ((_actualFob select 0) select 2)}}
            && {(_buildItem select 3) isEqualTo 0 || {(_buildItem select 3) <= ((_actualFob select 0) select 3)}};

        if (_hasResources) then {
            private _selectedClassLower = toLower _selectedClass;
            if (_selectedClassLower in KPLIB_b_air_classes && {!([_selectedClass] call KPLIB_fnc_isClassUAV)}) then {
                _affordable = KP_liberation_air_vehicle_building_near
                    && {
                        (_selectedClass isKindOf "Helicopter" && {KP_liberation_heli_count < KP_liberation_heli_slots})
                        || {(_selectedClass isKindOf "Plane") && {KP_liberation_plane_count < KP_liberation_plane_slots}}
                    };
            } else {
                _affordable = !(_selectedClassLower in KPLIB_airSlots)
                    || {KP_liberation_air_vehicle_building_near};
            };
        };

        if (!KP_liberation_allow_fob_vehcile_building && {!_isStartBase} && {_selectedClass isEqualType ""}) then {
            if (_selectedClass isKindOf "LandVehicle" || {_selectedClass isKindOf "Helicopter"}) then {
                _affordable = false;
            };
            if (!KP_liberation_allow_fixedwing_at_fobs && {_selectedClass isKindOf "Plane"}) then {
                _affordable = false;
            };
        };

        private _unlockRequirement = nil;
        if (count _buildItem >= 6) then {
            _unlockRequirement = _buildItem select 5;
        };
        if (!isNil {_unlockRequirement}) then {
            _hasUnlockRequirements = true;
            _requiredSectorCount = if (_unlockRequirement < 1) then {
                round (count sectors_military * _unlockRequirement)
            } else {
                _unlockRequirement
            };
            _unlockRequirementsMet = count blufor_military_sectors >= _requiredSectorCount;
        };
    };

    _buildButton ctrlEnable (_affordable && {_unlockRequirementsMet});

    _supplyControl ctrlSetText format ["%1 : %2", localize "STR_MANPOWER", floor KP_liberation_supplies];
    _ammoControl ctrlSetText format ["%1 : %2", localize "STR_AMMO", floor KP_liberation_ammo];
    _fuelControl ctrlSetText format ["%1 : %2", localize "STR_FUEL", floor KP_liberation_fuel];

    _capControl ctrlSetStructuredText formatText [
        "%1/%2 %3 - %4/%5 %6",
        KP_liberation_heli_count,
        KP_liberation_heli_slots,
        image "\A3\air_f_beta\Heli_Transport_01\Data\UI\Map_Heli_Transport_01_base_CA.paa",
        KP_liberation_plane_count,
        KP_liberation_plane_slots,
        image "\A3\Air_F_EPC\Plane_CAS_01\Data\UI\Map_Plane_CAS_01_CA.paa"
    ];

    if (_hasUnlockRequirements) then {
        private _linkColor = (["#e00000", "#0040e0"] select (_unlockRequirementsMet));
        _unlockControl ctrlSetStructuredText parseText format [
            "<t color='%1' align='center'>(%2/%3) MILITARY SECTORS</t>",
            _linkColor,
            count blufor_military_sectors,
            _requiredSectorCount
        ];
    } else {
        _unlockControl ctrlSetStructuredText parseText "";
    };

    buildindex = _selectedItem;

    sleep 0.1;
};

if (!alive player || {dobuild != 0}) then {
    closeDialog 0;
};
