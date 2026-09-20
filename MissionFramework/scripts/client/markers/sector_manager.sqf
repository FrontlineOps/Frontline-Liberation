waitUntil {!isNil "save_is_loaded"};
waitUntil {!isNil "GRLIB_vehicle_to_military_base_links"};
waitUntil {!isNil "blufor_sectors"};
waitUntil {save_is_loaded};

private _vehicle_unlock_markers = [];
private _cfg = configFile >> "cfgVehicles";

{
    _x params ["_vehicle", "_base"];
    private _marker = createMarkerLocal [format ["vehicleunlockmarker%1", _base], [(markerpos _base) select 0, ((markerpos _base) select 1) + 125]];
    _marker setMarkerTextLocal (getText (_cfg >> _vehicle >> "displayName"));
    _marker setMarkerColorLocal GRLIB_color_enemy;
    _marker setMarkerTypeLocal "mil_pickup";
    _marker setMarkerAlphaLocal 0;
    _vehicle_unlock_markers pushback [_marker, _base];
} forEach GRLIB_vehicle_to_military_base_links;

private _ownedSectors = [];
private _initialized = false;

while {true} do {
    if (!_initialized || {!(blufor_sectors isEqualTo _ownedSectors)}) then {
        private _currentOwnedSectors = +blufor_sectors;
        {
            _x setMarkerColorLocal GRLIB_color_enemy;
            _x setMarkerAlphaLocal 0;
        } forEach (sectors_allSectors - _currentOwnedSectors);
        {
            _x setMarkerColorLocal GRLIB_color_friendly;
            _x setMarkerAlphaLocal 1;
        } forEach _currentOwnedSectors;

        {
            _x params ["_marker", "_base"];
            private _owned = _base in _currentOwnedSectors;
            _marker setMarkerColorLocal ([GRLIB_color_enemy, GRLIB_color_friendly] select _owned);
            _marker setMarkerAlphaLocal ([0, 1] select _owned);
        } forEach _vehicle_unlock_markers;
        _ownedSectors = _currentOwnedSectors;
        _initialized = true;
    };
    uiSleep 1;
};
