params ["_target", "_caller", "_actionId", "_arguments"];

private _classname = _arguments select 0;
if (_classname isEqualTo KP_liberation_small_storage_building) then {
    build_confirmed = 1;
    build_invalid = 0;
    KP_vector = true;

    private _truePosition = [];
    private _sectorPosition = markerPos ([100] call KPLIB_fnc_getNearestSector);
    private _cancelAction = player addAction ["<t color='#B0FF00'>" + localize "STR_CANCEL" + "</t> <img size='2' image='res\ui_cancel.paa'/>", {build_confirmed = 3;}, "", -725, false, true, "", "build_confirmed == 1"];
    private _placeAction = player addAction ["<t color='#B0FF00'>" + localize "STR_PLACEMENT" + "</t> <img size='2' image='res\ui_confirm.paa'/>", {build_confirmed = 2;}, "", -775, false, true, "", "build_invalid == 0 && build_confirmed == 1"];
    private _vectorAction = player addAction ["<t color='#B0FF00'>" + localize "STR_VECACTION" + "</t>", {KP_vector = !KP_vector;}, "", -800, false, false, "", "build_confirmed == 1"];

    private _ghostPosition = (markerPos "ghost_spot") findEmptyPosition [0, 100];
    private _preview = _classname createVehicleLocal _ghostPosition;

    if (isNull _preview) then {
        build_confirmed = 3;
    } else {
        _preview allowDamage false;
        _preview setVehicleLock "LOCKED";
        _preview enableSimulationGlobal false;

        private _placementDistance = (0.6 * sizeOf _classname) max 3.5;
        _placementDistance = _placementDistance + 0.5;

        for "_textureIndex" from 0 to 4 do {
            _preview setObjectTextureGlobal [_textureIndex, "#(rgb,8,8,3)color(0,1,0,0.8)"];
        };

        while {build_confirmed isEqualTo 1 && {alive player}} do {
            private _playerPosition = getPos player;
            private _directionFromPlayer = 90 - (getDir player);
            _truePosition = [
                (_playerPosition select 0) + (_placementDistance * cos _directionFromPlayer),
                (_playerPosition select 1) + (_placementDistance * sin _directionFromPlayer),
                0
            ];

            private _validWaterPosition = !(surfaceIsWater _truePosition) && {!(surfaceIsWater _playerPosition)};
            private _insideSectorArea = _truePosition distance _sectorPosition <= 100;
            if (!_validWaterPosition || {!_insideSectorArea}) then {
                _preview setPos _ghostPosition;
                build_invalid = 1;

                if (!_validWaterPosition) then {
                    GRLIB_ui_notif = localize "STR_BUILD_ERROR_WATER";
                };
                if (!_insideSectorArea) then {
                    GRLIB_ui_notif = format [localize "STR_BUILD_ERROR_DISTANCE", 100];
                };
            } else {
                _preview setDir (getDir player);
                _preview setPos _truePosition;
                if (KP_vector) then {
                    _preview setVectorUp [0, 0, 1];
                } else {
                    _preview setVectorUp surfaceNormal position _preview;
                };

                if (build_invalid isEqualTo 1) then {
                    GRLIB_ui_notif = "";
                };
                build_invalid = 0;
            };

            sleep 0.05;
        };
    };

    GRLIB_ui_notif = "";

    if ((!alive player || {build_confirmed isEqualTo 3}) && {!isNull _preview}) then {
        deleteVehicle _preview;
    };

    if (build_confirmed isEqualTo 2 && {!isNull _preview}) then {
        private _buildingDirection = getDir _preview;
        deleteVehicle _preview;
        sleep 0.1;

        private _building = _classname createVehicle _truePosition;
        _building allowDamage false;
        _building setDir _buildingDirection;
        _building setPos _truePosition;
        if (KP_vector) then {
            _building setVectorUp [0, 0, 1];
        } else {
            _building setVectorUp surfaceNormal position _building;
        };
        _building setVariable ["KP_liberation_storage_type", 1, true];

        sleep 0.3;
        _building allowDamage true;
        _building setDamage 0;
    };

    player removeAction _cancelAction;
    player removeAction _placeAction;
    player removeAction _vectorAction;

    recalculate_sectors = true;
    if (!isServer) then {
        publicVariableServer "recalculate_sectors";
    };
    build_confirmed = 0;
} else {
    private _production = player getVariable ["KPLIB_nearProd", []];
    [_production param [1, ""], _classname] remoteExec ["build_fac_remote_call", 2];
};
