uiSleep 3;

private _savedTowerClasses = createHashMap;
{
    private _sector = _x select 0;
    if !(_sector in _savedTowerClasses) then {
        _savedTowerClasses set [_sector, _x select 1];
    };
} forEach KPLIB_sectorTowers;

{
    private _sector = _x;
    private _hasSavedClass = _sector in _savedTowerClasses;
    private _classname = _savedTowerClasses getOrDefault [_sector, ""];
    if (!_hasSavedClass) then {
        _classname = selectRandom KPLIB_radioTowerClassnames;
        KPLIB_sectorTowers pushBack [_sector, _classname];
        _savedTowerClasses set [_sector, _classname];
    };

    private _sectorPos = markerPos _sector;
    private _tower = _classname createVehicle _sectorPos;
    _tower setPos _sectorPos;
    _tower setVectorUp [0, 0, 1];
    [_tower, "HandleDamage", {0}] call CBA_fnc_addBISEventHandler;
} forEach sectors_tower;
