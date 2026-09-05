build_confirmed = 0;
KP_vector = true;

private _maxDistance = GRLIB_fob_range;
private _debugCollisions = false;

private _createBoundarySpheres = {
    private _objectSpheres = [];
    private _fobSpheres = [];

    for "_index" from 0 to 35 do {
        private _objectSphere = "Sign_Sphere100cm_F" createVehicleLocal [0, 0, 0];
        _objectSphere setObjectTexture [0, "#(rgb,8,8,3)color(0,1,0,1)"];
        _objectSpheres pushBack _objectSphere;
        _fobSpheres pushBack ("Sign_Sphere100cm_F" createVehicleLocal [0, 0, 0]);
    };

    [_objectSpheres, _fobSpheres]
};

private _deleteBoundarySpheres = {
    params ["_objectSpheres", "_fobSpheres"];
    {deleteVehicle _x;} forEach (_objectSpheres + _fobSpheres);
};

private _removeBuildAction = {
    params ["_actionId"];
    if (_actionId >= 0) then {
        player removeAction _actionId;
    };
};

if (isNil "manned") then {manned = false;};
if (isNil "gridmode") then {gridmode = 0;};
if (isNil "repeatbuild") then {repeatbuild = false;};
if (isNil "build_rotation") then {build_rotation = 0;};
if (isNil "build_elevation") then {build_elevation = 0;};

waitUntil {
    sleep 0.2;
    !isNil "dobuild"
    && {!isNil "KPLIB_fnc_startBuildOverlay"}
    && {!isNil "KPLIB_fnc_stopBuildOverlay"}
};

while {true} do {
    waitUntil {sleep 0.2; dobuild != 0;};

    if !([player, "BUILD"] call KPLIB_fnc_hasPermission) then {
        dobuild = 0;
        hint "Building permission is required.";
        continue;
    };
    build_confirmed = 1;
    build_invalid = 0;

    private _selectedBuildType = buildtype;
    private _selectedBuildIndex = buildindex;
    private _isFobBuild = _selectedBuildType isEqualTo 99;
    private _classname = FOB_typename;
    if (!_isFobBuild) then {
        _classname = ((KPLIB_buildList select _selectedBuildType) select _selectedBuildIndex) select 0;
    };

    if (_selectedBuildType in [1, 8]) then {
        [_selectedBuildType, _selectedBuildIndex, [], 0, true, manned] remoteExecCall ["build_remote_call", 2];
        build_confirmed = 0;
    } else {
        private _fobPosition = getPos player;
        if (!_isFobBuild) then {
            _fobPosition = [] call KPLIB_fnc_getNearestFob;
        };

        private _classnameLower = toLower _classname;
        private _isStaticBuild = _classnameLower in KPLIB_b_static_classes;
        private _isBuildingBuild = _selectedBuildType isEqualTo 6;
        private _isBoatBuild = _classname in boats_names;
        private _supportsVector = _isBuildingBuild
            || {_isFobBuild}
            || {_classnameLower in KPLIB_storageBuildings}
            || {_classname isEqualTo KP_liberation_recycle_building}
            || {_classname isEqualTo KP_liberation_air_vehicle_building};

        private _actionCancel = -1;
        private _actionSnap = -1;
        private _actionRepeat = -1;
        private _actionVector = -1;

        _actionCancel = player addAction ["<t color='#B0FF00'>" + localize "STR_CANCEL" + "</t> <img size='2' image='res\ui_cancel.paa'/>", {build_confirmed = 3; GRLIB_ui_notif = ""; hint localize "STR_CANCEL_HINT";}, "", -725, false, true, "", "build_confirmed == 1"];
        if (_isBuildingBuild) then {
            _actionRepeat = player addAction ["<t color='#B0FF00'>" + localize "STR_PLACEMENT_BIS" + "</t> <img size='2' image='res\ui_confirm.paa'/>", {build_confirmed = 2; repeatbuild = true; hint localize "STR_CONFIRM_HINT";}, "", -785, false, false, "", "build_invalid == 0 && build_confirmed == 1"];
        };
        if (_supportsVector) then {
            _actionSnap = player addAction ["<t color='#B0FF00'>" + localize "STR_GRID" + "</t>", {gridmode = gridmode + 1;}, "", -735, false, false, "", "build_confirmed == 1"];
            _actionVector = player addAction ["<t color='#B0FF00'>" + localize "STR_VECACTION" + "</t>", {KP_vector = !KP_vector;}, "", -800, false, false, "", "build_confirmed == 1"];
        };

        private _actionRotate = player addAction ["<t color='#B0FF00'>" + localize "STR_ROTATION" + "</t> <img size='2' image='res\ui_rotation.paa'/>", {build_rotation = build_rotation + 90;}, "", -750, false, false, "", "build_confirmed == 1"];
        private _actionRaise = player addAction ["<t color='#B0FF00'>" + localize "STR_RAISE" + "</t>", {build_elevation = build_elevation + 0.2;}, "", -765, false, false, "", "build_confirmed == 1"];
        private _actionLower = player addAction ["<t color='#B0FF00'>" + localize "STR_LOWER" + "</t>", {build_elevation = build_elevation - 0.2;}, "", -766, false, false, "", "build_confirmed == 1"];
        private _actionPlace = player addAction ["<t color='#B0FF00'>" + localize "STR_PLACEMENT" + "</t> <img size='2' image='res\ui_confirm.paa'/>", {build_confirmed = 2; hint localize "STR_CONFIRM_HINT";}, "", -775, false, true, "", "build_invalid == 0 && build_confirmed == 1"];

        private _ghostPosition = (markerPos "ghost_spot") findEmptyPosition [0, 100];
        [] call KPLIB_fnc_stopBuildOverlay;
        private _preview = _classname createVehicleLocal _ghostPosition;
        private _truePosition = _ghostPosition;

        if (isNull _preview) then {
            build_confirmed = 3;
        } else {
            _preview allowDamage false;
            _preview setVehicleLock "LOCKED";
            _preview enableSimulationGlobal false;
            _preview setVariable ["KP_liberation_preplaced", true, true];

            private _placementDistance = (0.6 * sizeOf _classname) max 3.5;
            _placementDistance = _placementDistance + 1;

            for "_textureIndex" from 0 to 4 do {
                _preview setObjectTextureGlobal [_textureIndex, "#(rgb,8,8,3)color(0,1,0,0.8)"];
            };

            (call _createBoundarySpheres) params ["_objectSpheres", "_fobSpheres"];
            if (!_isFobBuild) then {
                {
                    _x setPos (_fobPosition getPos [GRLIB_fob_range, 10 * _forEachIndex]);
                } forEach _fobSpheres;
            };
            [] call KPLIB_fnc_startBuildOverlay;

            while {build_confirmed isEqualTo 1 && {alive player}} do {
                private _playerDirection = getDir player;
                private _directionFromPlayer = 90 - _playerDirection;
                private _playerPosition = if (_isStaticBuild) then {getPosATL player} else {getPos player};

                _truePosition = [
                    (_playerPosition select 0) + (_placementDistance * cos _directionFromPlayer),
                    (_playerPosition select 1) + (_placementDistance * sin _directionFromPlayer),
                    if (_isStaticBuild) then {_playerPosition select 2} else {0}
                ];

                private _actualDirection = _playerDirection + build_rotation;
                if (_classname in ["Land_Cargo_Patrol_V1_F", "Land_PortableLight_single_F"]) then {
                    _actualDirection = _actualDirection + 180;
                };
                if (_isFobBuild) then {
                    _actualDirection = _actualDirection + 270;
                };

                while {_actualDirection > 360} do {_actualDirection = _actualDirection - 360;};
                while {_actualDirection < 0} do {_actualDirection = _actualDirection + 360;};
                if ((_isBuildingBuild || {_isFobBuild}) && {(gridmode % 2) isEqualTo 1}) then {
                    if (_actualDirection >= 22.5 && {_actualDirection <= 67.5}) then {_actualDirection = 45;};
                    if (_actualDirection >= 67.5 && {_actualDirection <= 112.5}) then {_actualDirection = 90;};
                    if (_actualDirection >= 112.5 && {_actualDirection <= 157.5}) then {_actualDirection = 135;};
                    if (_actualDirection >= 157.5 && {_actualDirection <= 202.5}) then {_actualDirection = 180;};
                    if (_actualDirection >= 202.5 && {_actualDirection <= 247.5}) then {_actualDirection = 225;};
                    if (_actualDirection >= 247.5 && {_actualDirection <= 292.5}) then {_actualDirection = 270;};
                    if (_actualDirection >= 292.5 && {_actualDirection <= 337.5}) then {_actualDirection = 315;};
                    if (_actualDirection <= 22.5 || {_actualDirection >= 337.5}) then {_actualDirection = 0;};
                };

                {
                    _x setPos (_truePosition getPos [_placementDistance, 10 * _forEachIndex]);
                } forEach _objectSpheres;

                _preview setDir _actualDirection;
                _truePosition set [2, (_truePosition select 2) + build_elevation];

                private _nearObjects = [];
                if (!_isStaticBuild) then {
                    private _candidates = _truePosition nearObjects ["AllVehicles", 50];
                    _candidates append (_truePosition nearObjects [FOB_box_typename, 50]);
                    _candidates append (_truePosition nearObjects [Arsenal_typename, 50]);
                    if (!_isBuildingBuild) then {
                        _candidates append (_truePosition nearObjects ["Static", 50]);
                    };

                    _candidates = _candidates select {
                        private _candidateType = typeOf _x;
                        !(_x isKindOf "Animal")
                        && {!(_candidateType in GRLIB_ignore_colisions_when_building)}
                        && {!(_candidateType isKindOf "CAManBase")}
                        && {!isPlayer _x}
                        && {!(_x isEqualTo _preview)}
                    };

                    _nearObjects = _candidates select {_truePosition distance _x <= _placementDistance};
                    if (_nearObjects isEqualTo []) then {
                        {
                            private _candidateDistance = (0.6 * sizeOf (typeOf _x)) max 1;
                            if (_truePosition distance _x < _candidateDistance) then {
                                _nearObjects pushBack _x;
                            };
                        } forEach _candidates;
                    };
                };

                GRLIB_conflicting_objects = _nearObjects;

                private _insideBuildArea = _truePosition distance _fobPosition < _maxDistance;
                private _validWaterPosition = (!(surfaceIsWater _truePosition) && {!(surfaceIsWater _playerPosition)}) || {_isBoatBuild};
                if (_nearObjects isEqualTo [] && {_insideBuildArea} && {_validWaterPosition}) then {
                    if ((_isBuildingBuild || {_isFobBuild}) && {(gridmode % 2) isEqualTo 1}) then {
                        _preview setPos [round (_truePosition select 0), round (_truePosition select 1), _truePosition select 2];
                    } else {
                        if (_isStaticBuild) then {
                            _preview setPosATL _truePosition;
                        } else {
                            _preview setPos _truePosition;
                        };
                    };

                    if (_supportsVector && {KP_vector}) then {
                        _preview setVectorUp [0, 0, 1];
                    } else {
                        _preview setVectorUp surfaceNormal position _preview;
                    };

                    if (build_invalid isEqualTo 1) then {
                        GRLIB_ui_notif = "";
                        {_x setObjectTexture [0, "#(rgb,8,8,3)color(0,1,0,1)"];} forEach _objectSpheres;
                    };
                    build_invalid = 0;
                } else {
                    if (build_invalid isEqualTo 0) then {
                        {_x setObjectTexture [0, "#(rgb,8,8,3)color(1,0,0,1)"];} forEach _objectSpheres;
                    };

                    _preview setPos _ghostPosition;
                    build_invalid = 1;

                    if !(_nearObjects isEqualTo []) then {
                        GRLIB_ui_notif = format [localize "STR_PLACEMENT_IMPOSSIBLE", count _nearObjects, round _placementDistance];
                        if (_debugCollisions) then {
                            private _objectClassnames = _nearObjects apply {typeOf _x};
                            hint format ["Colisions : %1", _objectClassnames];
                        };
                    };
                    if (!_validWaterPosition) then {
                        GRLIB_ui_notif = localize "STR_BUILD_ERROR_WATER";
                    };
                    if (!_insideBuildArea) then {
                        GRLIB_ui_notif = format [localize "STR_BUILD_ERROR_DISTANCE", _maxDistance];
                    };
                };

                sleep 0.05;
            };

            [] call KPLIB_fnc_stopBuildOverlay;
            [_objectSpheres, _fobSpheres] call _deleteBoundarySpheres;
        };

        GRLIB_ui_notif = "";

        if ((!alive player || {build_confirmed isEqualTo 3}) && {!isNull _preview}) then {
            deleteVehicle _preview;
        };

        if (build_confirmed isEqualTo 2 && {!isNull _preview}) then {
            private _vehicleDirection = getDir _preview;
            private _placedPosition = if (_isStaticBuild) then {getPosATL _preview} else {getPos _preview};
            deleteVehicle _preview;
            if (_isFobBuild) then {
                [KPLIB_buildFobContainer, _placedPosition, _vehicleDirection, KP_vector] remoteExecCall ["build_fob_remote_call", 2];
            } else {
                [_selectedBuildType, _selectedBuildIndex, _placedPosition, _vehicleDirection, _supportsVector && {KP_vector}, manned] remoteExecCall ["build_remote_call", 2];
            };
        };

        {
            [_x] call _removeBuildAction;
        } forEach [_actionCancel, _actionSnap, _actionRepeat, _actionVector, _actionRotate, _actionPlace, _actionRaise, _actionLower];

        if (_isFobBuild) then {
            FOB_build_in_progress = false;
            KPLIB_buildFobContainer = objNull;
            buildtype = 1;
        };

        build_confirmed = 0;
    };

    if (repeatbuild) then {
        dobuild = 1;
        repeatbuild = false;
    } else {
        dobuild = 0;
    };
    manned = false;
};
