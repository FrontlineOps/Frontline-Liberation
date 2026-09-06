private _cleanupClassnames = [];
{
    _cleanupClassnames append _x;
} forEach [KPLIB_b_light_classes, KPLIB_b_recon_classes, KPLIB_b_medical_classes, KPLIB_b_groundlogi_classes, KPLIB_b_artillery_classes, KPLIB_b_atgm_classes, KPLIB_b_aa_classes, KPLIB_b_heavy_classes, KPLIB_b_air_classes, KPLIB_b_support_classes];

private _cleanupClassIndex = createHashMap;
{
    _cleanupClassIndex set [toLower _x, true];
} forEach _cleanupClassnames;

while {GRLIB_cleanup_vehicles > 0} do {

    sleep 600;

    {
        private _vehicle = _x;
        private _resetTicker = true;

        // Only eligible, empty player-faction vehicles need the comparatively
        // expensive nearest-FOB search.
        if (
            (_cleanupClassIndex getOrDefault [toLower (typeOf _vehicle), false])
            && {(crew _vehicle) isEqualTo []}
        ) then {
            private _nearestFob = [getPos _vehicle] call KPLIB_fnc_getNearestFob;
            if (
                count _nearestFob == 3
                && {_vehicle distance _nearestFob > (1.2 * GRLIB_fob_range)}
                && {_vehicle distance startbase > (1.2 * GRLIB_fob_range)}
            ) then {
                _vehicle setVariable ["GRLIB_empty_vehicle_ticker", (_vehicle getVariable ["GRLIB_empty_vehicle_ticker", 0]) + 1];
                _resetTicker = false;
            };
        };

        if (_resetTicker) then {
            _vehicle setVariable ["GRLIB_empty_vehicle_ticker", 0];
        };

        if (_vehicle getVariable ["GRLIB_empty_vehicle_ticker", 0] >= (6 * GRLIB_cleanup_vehicles)) then {
            deleteVehicle _vehicle;
        };
        if ((_forEachIndex % 25) == 24) then {
            sleep 0.01;
        };
    } foreach vehicles;
};
