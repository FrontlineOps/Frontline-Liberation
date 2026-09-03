if (isServer) then {
    KPLIB_FIELD_HOSPITALS = createHashMap;

    KPLIB_FIELD_HOSPITAL_SERVER_GET_CALLER = {
        if (!isRemoteExecuted) exitWith {objNull};
        private _ownerId = remoteExecutedOwner;
        (allPlayers select {isPlayer _x && {owner _x == _ownerId}}) param [0, objNull]
    };

    KPLIB_FIELD_HOSPITAL_SERVER_RESPOND = {
        params ["_caller", "_status", ["_hospital", objNull, [objNull]]];
        if (!isNull _caller) then {
            [_status, _hospital] remoteExecCall ["KPLIB_FIELD_HOSPITAL_CLIENT_RESPONSE", owner _caller];
        };
    };

    KPLIB_FIELD_HOSPITAL_SERVER_DEPLOY = {
        if (!isServer || {!isRemoteExecuted}) exitWith {};

        private _caller = [] call KPLIB_FIELD_HOSPITAL_SERVER_GET_CALLER;
        if (isNull _caller) exitWith {
            [format ["Deploy rejected (remoteOwner=%1, reason=invalid caller)", remoteExecutedOwner], "FIELD HOSPITAL"] call KPLIB_fnc_log;
        };

        private _uid = getPlayerUID _caller;
        private _existing = KPLIB_FIELD_HOSPITALS getOrDefault [_uid, objNull];
        if (!isNull _existing && {alive _existing}) exitWith {
            [_caller, "EXISTS", _existing] call KPLIB_FIELD_HOSPITAL_SERVER_RESPOND;
        };
        KPLIB_FIELD_HOSPITALS deleteAt _uid;

        if (
            _uid == ""
            || {!alive _caller}
            || {side group _caller != GRLIB_side_friendly}
            || {!isNull objectParent _caller}
            || {_caller getVariable ["ace_medical_medicclass", 0] != 2}
        ) exitWith {
            [_caller, "REJECTED"] call KPLIB_FIELD_HOSPITAL_SERVER_RESPOND;
            [format ["Deploy rejected (playerOwner=%1, reason=ineligible player state)", owner _caller], "FIELD HOSPITAL"] call KPLIB_fnc_log;
        };

        private _position = getPosATL _caller;
        if ((_position select 2) > KPLIB_fieldHospital_groundTolerance || {surfaceIsWater _position}) exitWith {
            [_caller, "GROUND"] call KPLIB_FIELD_HOSPITAL_SERVER_RESPOND;
            [format ["Deploy rejected (playerOwner=%1, reason=not on terrain)", owner _caller], "FIELD HOSPITAL"] call KPLIB_fnc_log;
        };

        if !(isClass (configFile >> "CfgVehicles" >> KPLIB_fieldHospital_classname)) exitWith {
            [_caller, "REJECTED"] call KPLIB_FIELD_HOSPITAL_SERVER_RESPOND;
            [format ["Deploy rejected (playerOwner=%1, reason=missing class %2)", owner _caller, KPLIB_fieldHospital_classname], "FIELD HOSPITAL"] call KPLIB_fnc_log;
        };

        private _hospital = createVehicle [KPLIB_fieldHospital_classname, _position, [], 0, "CAN_COLLIDE"];
        if (isNull _hospital) exitWith {
            [_caller, "REJECTED"] call KPLIB_FIELD_HOSPITAL_SERVER_RESPOND;
            [format ["Deploy failed (playerOwner=%1, class=%2)", owner _caller, KPLIB_fieldHospital_classname], "FIELD HOSPITAL"] call KPLIB_fnc_log;
        };

        _hospital setDir direction _caller;
        _hospital setPosATL _position;
        _hospital setVariable ["KPLIB_fieldHospitalOwnerUID", _uid, true];
        _hospital setVariable ["ace_medical_isMedicalFacility", true, true];
        KPLIB_FIELD_HOSPITALS set [_uid, _hospital];

        [_hospital, "Killed", {
            params ["_hospital"];
            private _uid = _hospital getVariable ["KPLIB_fieldHospitalOwnerUID", ""];
            if ((KPLIB_FIELD_HOSPITALS getOrDefault [_uid, objNull]) isEqualTo _hospital) then {
                KPLIB_FIELD_HOSPITALS deleteAt _uid;
                [format ["Field hospital destroyed (class=%1)", typeOf _hospital], "FIELD HOSPITAL"] call KPLIB_fnc_log;
            };
        }] call CBA_fnc_addBISEventHandler;

        [_caller, "DEPLOYED", _hospital] call KPLIB_FIELD_HOSPITAL_SERVER_RESPOND;
        [format ["Field hospital deployed (playerOwner=%1, class=%2, grid=%3)", owner _caller, typeOf _hospital, mapGridPosition _hospital], "FIELD HOSPITAL"] call KPLIB_fnc_log;
    };

    KPLIB_FIELD_HOSPITAL_SERVER_REPACK = {
        params [["_hospital", objNull, [objNull]]];
        if (!isServer || {!isRemoteExecuted}) exitWith {};

        private _caller = [] call KPLIB_FIELD_HOSPITAL_SERVER_GET_CALLER;
        if (isNull _caller) exitWith {
            [format ["Repack rejected (remoteOwner=%1, reason=invalid caller)", remoteExecutedOwner], "FIELD HOSPITAL"] call KPLIB_fnc_log;
        };

        private _uid = getPlayerUID _caller;
        private _registered = KPLIB_FIELD_HOSPITALS getOrDefault [_uid, objNull];
        if (
            isNull _hospital
            || {!alive _caller}
            || {side group _caller != GRLIB_side_friendly}
            || {!isNull objectParent _caller}
            || {_caller getVariable ["ace_medical_medicclass", 0] != 2}
            || {_caller distance _hospital > KPLIB_fieldHospital_repackDistance}
            || {!(_registered isEqualTo _hospital)}
            || {_hospital getVariable ["KPLIB_fieldHospitalOwnerUID", ""] != _uid}
        ) exitWith {
            [_caller, "REJECTED", _registered] call KPLIB_FIELD_HOSPITAL_SERVER_RESPOND;
            [format ["Repack rejected (playerOwner=%1, reason=invalid hospital or player state)", owner _caller], "FIELD HOSPITAL"] call KPLIB_fnc_log;
        };

        KPLIB_FIELD_HOSPITALS deleteAt _uid;
        private _grid = mapGridPosition _hospital;
        private _class = typeOf _hospital;
        deleteVehicle _hospital;

        [_caller, "REPACKED"] call KPLIB_FIELD_HOSPITAL_SERVER_RESPOND;
        [format ["Field hospital repacked (playerOwner=%1, class=%2, grid=%3)", owner _caller, _class, _grid], "FIELD HOSPITAL"] call KPLIB_fnc_log;
    };

    KPLIB_FIELD_HOSPITAL_SERVER_SYNC = {
        if (!isServer || {!isRemoteExecuted}) exitWith {};

        private _caller = [] call KPLIB_FIELD_HOSPITAL_SERVER_GET_CALLER;
        if (isNull _caller) exitWith {};

        private _uid = getPlayerUID _caller;
        private _hospital = KPLIB_FIELD_HOSPITALS getOrDefault [_uid, objNull];
        if (!isNull _hospital && {!alive _hospital}) then {
            KPLIB_FIELD_HOSPITALS deleteAt _uid;
            _hospital = objNull;
        };
        [_caller, "SYNC", _hospital] call KPLIB_FIELD_HOSPITAL_SERVER_RESPOND;
    };

    [format ["Field hospital module initialized (class=%1, duration=%2s)", KPLIB_fieldHospital_classname, KPLIB_fieldHospital_actionDuration], "FIELD HOSPITAL"] call KPLIB_fnc_log;
};

if (hasInterface) then {
    KPLIB_FIELD_HOSPITAL_CLIENT_HOSPITAL = objNull;

    KPLIB_FIELD_HOSPITAL_CLIENT_RESPONSE = {
        params [
            ["_status", "", [""]],
            ["_hospital", objNull, [objNull]]
        ];

        switch (_status) do {
            case "SYNC": {
                KPLIB_FIELD_HOSPITAL_CLIENT_HOSPITAL = _hospital;
            };
            case "DEPLOYED": {
                KPLIB_FIELD_HOSPITAL_CLIENT_HOSPITAL = _hospital;
                hint localize "STR_KPLIB_FIELD_HOSPITAL_DEPLOYED";
            };
            case "EXISTS": {
                KPLIB_FIELD_HOSPITAL_CLIENT_HOSPITAL = _hospital;
                hint localize "STR_KPLIB_FIELD_HOSPITAL_ALREADY_DEPLOYED";
            };
            case "REPACKED": {
                KPLIB_FIELD_HOSPITAL_CLIENT_HOSPITAL = objNull;
                hint localize "STR_KPLIB_FIELD_HOSPITAL_REPACKED";
            };
            case "GROUND": {
                hint localize "STR_KPLIB_FIELD_HOSPITAL_MUST_BE_DEPLOYED_ON_TERRAIN";
            };
            default {
                KPLIB_FIELD_HOSPITAL_CLIENT_HOSPITAL = _hospital;
                hint localize "STR_KPLIB_FIELD_HOSPITAL_ACTION_REJECTED";
            };
        };
    };

    private _deployAction = [
        "KPLIB_FIELD_HOSPITAL_DEPLOY",
        localize "STR_KPLIB_DEPLOY_FIELD_HOSPITAL",
        "res\ui_build.paa",
        {
            params ["_target", "_player"];
            [
                KPLIB_fieldHospital_actionDuration,
                [_player],
                {
                    params ["_arguments"];
                    _arguments params ["_unit"];
                    if (_unit isEqualTo player) then {
                        [] remoteExecCall ["KPLIB_FIELD_HOSPITAL_SERVER_DEPLOY", 2];
                    };
                },
                {},
                localize "STR_KPLIB_DEPLOY_FIELD_HOSPITAL",
                {
                    params ["_arguments"];
                    _arguments params ["_unit"];
                    alive _unit
                        && {isNull objectParent _unit}
                        && {_unit getVariable ["ace_medical_medicclass", 0] == 2}
                        && {(getPosATL _unit select 2) <= KPLIB_fieldHospital_groundTolerance}
                        && {!(surfaceIsWater (getPosATL _unit))}
                }
            ] call ace_common_fnc_progressBar;
        },
        {
            params ["_target", "_player"];
            _target isEqualTo _player
                && {alive _player}
                && {side group _player == GRLIB_side_friendly}
                && {isNull objectParent _player}
                && {_player getVariable ["ace_medical_medicclass", 0] == 2}
                && {(getPosATL _player select 2) <= KPLIB_fieldHospital_groundTolerance}
                && {!(surfaceIsWater (getPosATL _player))}
                && {isNull KPLIB_FIELD_HOSPITAL_CLIENT_HOSPITAL || {!alive KPLIB_FIELD_HOSPITAL_CLIENT_HOSPITAL}}
        }
    ] call ace_interact_menu_fnc_createAction;
    ["CAManBase", 1, ["ACE_SelfActions"], _deployAction, true] call ace_interact_menu_fnc_addActionToClass;

    private _repackAction = [
        "KPLIB_FIELD_HOSPITAL_REPACK",
        localize "STR_KPLIB_REPACK_FIELD_HOSPITAL",
        "res\ui_build.paa",
        {
            params ["_target", "_player"];
            [
                KPLIB_fieldHospital_actionDuration,
                [_target, _player],
                {
                    params ["_arguments"];
                    _arguments params ["_hospital", "_unit"];
                    if (_unit isEqualTo player) then {
                        [_hospital] remoteExecCall ["KPLIB_FIELD_HOSPITAL_SERVER_REPACK", 2];
                    };
                },
                {},
                localize "STR_KPLIB_REPACK_FIELD_HOSPITAL",
                {
                    params ["_arguments"];
                    _arguments params ["_hospital", "_unit"];
                    !isNull _hospital
                        && {alive _unit}
                        && {isNull objectParent _unit}
                        && {_unit getVariable ["ace_medical_medicclass", 0] == 2}
                        && {_unit distance _hospital <= KPLIB_fieldHospital_repackDistance}
                }
            ] call ace_common_fnc_progressBar;
        },
        {
            params ["_target", "_player"];
            !isNull _target
                && {alive _player}
                && {side group _player == GRLIB_side_friendly}
                && {isNull objectParent _player}
                && {_player getVariable ["ace_medical_medicclass", 0] == 2}
                && {_player distance _target <= KPLIB_fieldHospital_repackDistance}
                && {_target getVariable ["KPLIB_fieldHospitalOwnerUID", ""] == getPlayerUID _player}
        }
    ] call ace_interact_menu_fnc_createAction;
    [KPLIB_fieldHospital_classname, 0, ["ACE_MainActions"], _repackAction, true] call ace_interact_menu_fnc_addActionToClass;

    [
        {!isNull player},
        {[] remoteExecCall ["KPLIB_FIELD_HOSPITAL_SERVER_SYNC", 2]}
    ] call CBA_fnc_waitUntilAndExecute;
};
