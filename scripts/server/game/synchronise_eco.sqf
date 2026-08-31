sync_eco = []; publicVariable "sync_eco";

waitUntil{!isNil "save_is_loaded"};
waitUntil{!isNil "KP_liberation_production"};
waitUntil{!isNil "KP_liberation_production_markers"};
waitUntil {save_is_loaded};

if (KP_liberation_production_markers isEqualTo []) then {
    {
        private _facility = selectRandom [[true,false,false], [false,true,false], [false,false,true]];
        KP_liberation_production_markers pushBack [_x, _facility select 0, _facility select 1, _facility select 2, markerText _x];
    } forEach sectors_factory;
};

private _productionMarkerIndex = createHashMap;
{
    private _sector = _x select 0;
    if !(_sector in _productionMarkerIndex) then {
        _productionMarkerIndex set [_sector, _forEachIndex];
    };
} forEach KP_liberation_production_markers;

private _productionOld = [0];

while {true} do {

    waitUntil {sleep (missionNamespace getVariable ["KP_liberation_state_sync_poll_interval", 1]);
        !(_productionOld isEqualTo KP_liberation_production)
    };
    {
        private _markerIndex = _productionMarkerIndex getOrDefault [_x select 1, -1];
        if (_markerIndex != -1) then {
            private _markerData = KP_liberation_production_markers select _markerIndex;
            _markerData set [1, _x select 4];
            _markerData set [2, _x select 5];
            _markerData set [3, _x select 6];
        };
    } forEach KP_liberation_production;
    sync_eco = [KP_liberation_production, KP_liberation_production_markers];
    publicVariable "sync_eco";

    _productionOld = +KP_liberation_production;
};
