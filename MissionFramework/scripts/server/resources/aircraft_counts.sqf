KP_liberation_heli_count = 0;
KP_liberation_plane_count = 0;

// Preset class lists are static after initialization. Index the eligible
// non-UAV air classes once instead of linearly searching and re-reading UAV
// config data for every vehicle every five seconds.
private _countedAirClasses = createHashMap;
{
    if !([_x] call KPLIB_fnc_isClassUAV) then {
        _countedAirClasses set [toLower _x, true];
    };
} forEach KPLIB_b_air_classes;

while {true} do {
    private _local_heli_count = 0;
    private _local_plane_count = 0;
    {
        if (
            alive _x
            && {!(_x getVariable ["KP_liberation_preplaced", false])}
            && {_countedAirClasses getOrDefault [toLower (typeOf _x), false]}
        ) then {
            if (_x isKindOf "Helicopter") then {
                _local_heli_count = _local_heli_count + 1;
            };
            if (_x isKindOf "Plane") then {
                _local_plane_count = _local_plane_count + 1;
            };
        };
    } forEach vehicles;
    KP_liberation_heli_count = _local_heli_count;
    KP_liberation_plane_count = _local_plane_count;
    sleep (missionNamespace getVariable ["KP_liberation_aircraft_count_refresh_interval", 5]);
};
