/*
    File: fn_spawnSectorCrates.sqf
    Author: KP Liberation Dev Team - https://github.com/KillahPotatoes
    Date: 2020-04-28
    Last Update: 2020-05-07
    License: MIT License - http://www.opensource.org/licenses/MIT

    Description:
        Spawns a configured amount of random resource crates at given sector,
        if not already given during this session.
        Crate value is scaled by the resources multiplier.

    Parameter(s):
        _sector - Sector marker string [STRING, defaults to ""]

    Returns:
        Function reached the end [BOOL]
*/

params [
    ["_sector", "", [""]]
];

if (_sector isEqualTo "") exitWith {["Empty string given"] call BIS_fnc_error; false};
if (isNil "KPLIB_sectorCratesSpawned") then {KPLIB_sectorCratesSpawned = [];};

if ((random 100) <= KP_liberation_sector_resource_chance) then {
    if !(_sector in KPLIB_sectorCratesSpawned) then {
        KPLIB_sectorCratesSpawned pushBack _sector;

        private _countRange = missionNamespace getVariable ["KP_liberation_sector_resource_crate_count", [3, 5]];
        private _minimum = round ((_countRange param [0, 3, [0]]) max 1);
        private _maximum = round ((_countRange param [1, 5, [0]]) max _minimum);
        private _amount = _minimum + floor random ((_maximum - _minimum) + 1);
        private _crateValue = round (
            (missionNamespace getVariable ["KP_liberation_sector_resource_crate_value", 100])
            * GRLIB_resources_multiplier
        ) max 1;
        private _spawned = 0;

        for "_i" from 1 to _amount do {
            private _spawnPos = [];
            for "_attempt" from 1 to 10 do {
                _spawnPos = ((markerPos _sector) getPos [random 50, random 360]) findEmptyPosition [10, 40, KP_liberation_ammo_crate];
                if (_spawnPos isNotEqualTo []) exitWith {};
            };
            if !(_spawnPos isEqualTo []) then {
                [selectRandom KPLIB_crates, _crateValue, _spawnPos] call KPLIB_fnc_createCrate;
                _spawned = _spawned + 1;
            } else {
                ["No suitable spawn position found."] call BIS_fnc_error;
                [format ["Couldn't find spawn position for resource crate for sector %1", _sector], "WARNING"] call KPLIB_fnc_log;
            };
        };

        [format [
            "Sector %1 awarded %2/%3 resource crates at %4 resources each",
            _sector,
            _spawned,
            _amount,
            _crateValue
        ], "SECTOR"] call KPLIB_fnc_log;
    };
};

true
