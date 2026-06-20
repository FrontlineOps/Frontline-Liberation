/*
    File: fn_getOpforSpawnPoint.sqf
    Author: KP Liberation Dev Team - https://github.com/KillahPotatoes
    Date: 2019-11-25
    Last Update: 2020-04-17
    License: MIT License - http://www.opensource.org/licenses/MIT

    Description:
        Gets a random opfor spawn point marker name respecting following conditions:
        * Wasn't used already in the current session (server restart to server restart)
        * Distance to blufor FOBs and sectors is more than given min distance
        * Distance to blufor FOBs and sectors is less than given max distance
        * Distance to an opfor sector is less than 2000m (to avoid strange spawn in blufor territory)
        * If nearest is set to true, the valid spawn point which is nearest to any blufor sector/FOB is returned
        * If a position is given, the closest valid spawn point to that position is returned

    Parameter(s):
        _min        - Minimum distance to any blufor sector or FOB                      [NUMBER, defaults to 2000]
        _max        - Maximum distance to any blufor sector or FOB                      [NUMBER, defaults to 20000]
        _nearest    - Provide the nearest spawn point of valid points                   [BOOL, defaults to false]
        _pos        - Position if the nearest spawn point to this should be selected    [POSITION, defaults to [0, 0, 0]]

    Returns:
        Opfor spawn point [STRING]
*/

params [
    ["_min", 2000, [0]],
    ["_max", 20000, [0]],
    ["_nearest", false, [false]],
    ["_pos", [0, 0, 0], [[]], [2, 3]],
    ["_ignoreWater", false, []],
    ["_randomClosest", true, []]
];

private _possibleSpawns = [];

// Only check for opfor spawn points which aren't used already in the current session
private _spawnsToCheck = sectors_opfor;
if (!isNil "used_positions") then {
    _spawnsToCheck = sectors_opfor - used_positions;
};

private ["_valid", "_current"];

private _distances = [];
{
    _valid = true;
    _current = _x;

    // Shouldn't be too close to the current/last position of a secondary mission
    if (!isNil "secondary_objective_position" && _valid) then {
        if !(secondary_objective_position isEqualTo []) then {
            _valid = !(((markerPos _current) distance2d secondary_objective_position) < 500);
        };
    };
    

    if(_valid) then {

        private _currentPos = markerPos _current;
        private _bluforPointsInRange = [];

        {

            private _distance = (markerPos _x) distance2D _currentPos;

            if( (_distance <= _max)) then {
                _bluforPointsInRange pushBack [markerPos _x, _distance, _x];
                _distances pushBack _distance;
            };
        } forEach blufor_sectors;

        {
            private _distance = (_x distance2D _currentPos);

            if( (_distance <= _max)) then {
                _bluforPointsInRange pushBack [_x, _distance, [_x] call KPLIB_fnc_getNearestFob];
                _distances pushBack _distance;
            };
        } forEach GRLIB_all_fobs;


        if(!_valid) then {
            continue;
        };


        if((count _bluforPointsInRange) <= 0) then {
            _valid = false;
        } else {
            // Hacky check of checking every interval of surfaceIsWater
            // Not as accurate but no access to a navmesh or method that tries to pathfind
            // Future: If we really want to be super accurate about this, there can be some pre-calculated indexing
            // Where you make your own custom A* pathfinding grid on the map and pre-calculate a lookup table for each point and what other points they can reach
            // And it exports to a file or something.
            if(!_ignoreWater) then {
                diag_log format ["Checking for water between %1 and blufor sectors", _current];
                private _bluforPointsNotSeparatedByWater = [];

                {
                    private _isWater = false;
                    private _position = _x select 0;
                    private _distance = _x select 1;
                    private _object = _x select 2;
                    // Produce a normalized vector pointing from the current spawn point to the blufor point
                    private _vectorFromCurrentToBluforPoint = _currentPos vectorFromTo _position;

                    private _kmSeparated = floor (_distance / 1000);

                    for "_i" from 1 to _kmSeparated do {

                        private _scalar = _i * 1000;

                        if(_kmSeparated <= 2) then {
                            _scalar = _distance / 2;
                        };

                        private _scaledOffset = _vectorFromCurrentToBluforPoint vectorMultiply (_scalar);

                        // Add the scaled vector to the pos of the spawn point, signifying an offset towards the blufor point.
                        private _checkPos = _currentPos vectorAdd _scaledOffset;

                        _isWater = surfaceIsWater _checkPos;

                        if(_isWater) exitWith {
                            diag_log format ["Detected water between %1 (%2) and %3", _currentPos, _current, _object];
                        };
                    };

                    if(!_isWater) then {    
                        _bluforPointsNotSeparatedByWater pushBack _position;
                    };
                } forEach _bluforPointsInRange;
                diag_log format ["Amount of blufor sectors for %1 not separated by water: %2", _current, count _bluforPointsNotSeparatedByWater];
                if((count _bluforPointsNotSeparatedByWater) <= 0) then {
                    
                    _valid = false;
                };
            };
        };
    };
    // Make sure that there is an opfor sector in sensible range to spawn
    if (_valid) then {
        if ((sectors_allSectors - blufor_sectors) findIf {((markerPos _current) distance2D (markerPos _x)) <= 250} < 0) then {
            _valid = false;
        };
    };

    // Make sure that there is no blufor unit inside min dist to spawn
    if (_valid) then {
        if (([markerpos _current, _min, GRLIB_side_friendly] call KPLIB_fnc_getUnitsCount) > 0) then {
            _valid = false;
        };
    };

    // Add distance and marker name to possible spawn, if still valid
    if (_valid) then {
        _distances sort true;
        _possibleSpawns pushBack [_distances select 0, _current];
    };
} forEach _spawnsToCheck;

// Return empty string, if no possible spawn point was found
if (_possibleSpawns isEqualTo []) exitWith {["No opfor spawn point found", "WARNING"] call KPLIB_fnc_log; ""};

// Return nearest spawn point to a blufor sector/FOB, if selected via parameter
if (_nearest) exitWith {
    _possibleSpawns sort true;
    private _indexToSelect = 0;

    if(_randomClosest) then {
        _indexToSelect = round (random (10 min ((count _possibleSpawns) - 1)));
    };
    (_possibleSpawns select _indexToSelect) select 1
};

// Return nearest spawn point to given position, if provided
if !(_pos isEqualTo [0, 0, 0]) exitWith {

    private _indexToSelect = 0;

    if(_randomClosest) then {
        _indexToSelect = round (random (10 min ((count _possibleSpawns) - 1)));
    };
    ([_possibleSpawns apply {_x select 1}, [_pos] , {_input0 distance (markerPos _x)} , "ASCEND"] call BIS_fnc_sortBy) select _indexToSelect;
};

// Return random spawn point
(selectRandom _possibleSpawns) select 1
