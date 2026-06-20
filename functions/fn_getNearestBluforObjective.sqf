/*
    File: fn_getNearestBluforObjective.sqf
    Author: KP Liberation Dev Team - https://github.com/KillahPotatoes
    Date: 2019-12-03
    Last Update: 2019-12-11
    License: MIT License - http://www.opensource.org/licenses/MIT

    Description:
        Gets the position of the nearest blufor sector/fob from given position.

    Parameter(s):
        _pos - Position to check for nearest blufor sector/fob [POSITION, defaults to [0, 0, 0]]

    Returns:
        Nearest blufor sector/fob position [POSITION]
*/

params [
    ["_pos", [0, 0, 0], [[]], [2, 3]]
];

if (GRLIB_all_fobs isEqualTo [] && blufor_sectors isEqualTo []) exitWith {[]};

if (isNil "nearestBluforCache") then {
    
    nearestBluforCache = createHashMap;
};

// Calculated when sector liberated remote call
// Attack in progress sector
if (isNil "last_blufor_sector_change") then {
    last_blufor_sector_change = 0;
};


private _cached = nil;


// A cache misses when:
// It doesn't exist in the cache
// It exists in the cache but the TTL has expired
//   TTL is based on when the blufor sectors changed
//   If blufor sectors changed, it should recalculate.
{
    if(_x isEqualTo _pos) exitWith {
        

        private _cacheInfo = _y;

        private _cachedPos = _cacheInfo get "Position";

        private _cachedWhen = _cacheInfo getOrDefault ["CachedAt", -1];

        if(_cachedWhen == last_blufor_sector_change) then {
            _cached = _cachedPos;
        };

        
        
    };
} forEach nearestBluforCache;

if(!(isNil "_cached")) exitWith {
    _cached
};



private _objectives = GRLIB_all_fobs + (blufor_sectors apply {markerPos _x});

private _objectivesNotSeparatedByWater = [];
{
    private _vectorFromPosToBluforPoint = _pos vectorFromTo _x;

    private _distance = _x distance2D _pos;

    private _kmSeparated = floor (_distance / 1000);

    private _isWater = false;

    for "_i" from 1 to _kmSeparated do {
        private _scalar = _i * 1000;
        if(_kmSeparated <= 2) then {
            _scalar = _distance / 2;
        };

        private _scaledOffset = _vectorFromPosToBluforPoint vectorMultiply (_scalar);

        private _checkPos = _pos vectorAdd _scaledOffset;

        _isWater = surfaceIsWater _checkPos;

        if(_isWater) exitWith {
            diag_log format ["Position %1 is separated by water to %2", _pos, _x];
        };
    };

    if(!_isWater) then {
        _objectivesNotSeparatedByWater pushBack [_distance, _x];
    };

} forEach _objectives;

if((count _objectivesNotSeparatedByWater) <= 0) exitWith {

    diag_log format ["Position %1 does not have any blufor sectors that are not separated by water", _pos];
    nearestBluforCache set [_pos, createHashMapFromArray [
            ["Position", []],
            ["CachedAt", last_blufor_sector_change]
        ]
    ];

    []
};
_objectivesNotSeparatedByWater sort true;

private _closest = (_objectivesNotSeparatedByWater select 0) select 1;
nearestBluforCache set [_pos, createHashMapFromArray [
        ["Position", _closest],
        ["CachedAt", last_blufor_sector_change]
    ]
];

_closest
