KPLIB_COPS_CLIENT_SNAPSHOT = [0, KPLIB_COPS_MAX, []];
KPLIB_COPS_CLIENT_MARKERS = createHashMap;
KPLIB_COPS_CLIENT_DEPLOY_CACHE = [];
KPLIB_COPS_CLIENT_DEPLOY_CACHE_AT = 0;
KPLIB_COPS_CLIENT_REQUEST_PENDING = false;
KPLIB_COPS_CLIENT_INITIALIZED = false;

KPLIB_COPS_CLIENT_APPLY_SNAPSHOT = {
    params [["_snapshot", [], [[]]]];
    if !(_snapshot isEqualType [] && {count _snapshot == 3}) exitWith {};
    _snapshot params ["_revision", "_maximum", "_entries"];
    if !(
        _revision isEqualType 0
        && {_maximum isEqualType 0}
        && {_entries isEqualType []}
        && {_revision >= (KPLIB_COPS_CLIENT_SNAPSHOT select 0)}
    ) exitWith {};

    private _cleanEntries = [];
    private _desiredMarkers = createHashMap;
    {
        if (
            _x isEqualType []
            && {count _x == 2}
            && {(_x select 0) isEqualType 0}
            && {(_x select 1) isEqualType []}
            && {(count (_x select 1)) in [2, 3]}
            && {(_x select 1) findIf {!(_x isEqualType 0)} == -1}
        ) then {
            _x params ["_id", "_position"];
            private _markerName = KPLIB_COPS_CLIENT_MARKERS getOrDefault [_id, ""];
            if (_markerName == "") then {
                _markerName = createMarkerLocal [format ["KPLIB_COPS_PB_%1", _id], _position];
                _markerName setMarkerTextLocal KPLIB_COPS_MARKER_TEXT;
                _markerName setMarkerTypeLocal "b_support";
                _markerName setMarkerColorLocal "ColorBLUFOR";
            } else {
                _markerName setMarkerPosLocal _position;
            };
            _desiredMarkers set [_id, _markerName];
            _cleanEntries pushBack [_id, +_position];
        };
    } forEach _entries;

    {
        if ((_desiredMarkers getOrDefault [_x, ""]) == "") then {
            deleteMarkerLocal _y;
        };
    } forEach KPLIB_COPS_CLIENT_MARKERS;

    KPLIB_COPS_CLIENT_MARKERS = _desiredMarkers;
    KPLIB_COPS_CLIENT_SNAPSHOT = [_revision, _maximum max 0, _cleanEntries];
    KPLIB_COPS_CLIENT_DEPLOY_CACHE = [];
    KPLIB_COPS_CLIENT_DEPLOY_CACHE_AT = 0;
};

KPLIB_COPS_CLIENT_IS_SQUAD_LEADER = {
    params [["_unit", player, [objNull]]];
    !isNull _unit && {(toLower roleDescription _unit) find "squad leader" >= 0}
};

KPLIB_COPS_CLIENT_CAN_DEPLOY = {
    params [["_unit", player, [objNull]]];
    !isNull _unit
        && {alive _unit}
        && {side _unit == GRLIB_side_friendly}
        && {isNull objectParent _unit}
        && {[_unit] call KPLIB_COPS_CLIENT_IS_SQUAD_LEADER}
        && {!KPLIB_COPS_CLIENT_REQUEST_PENDING}
        && {count (KPLIB_COPS_CLIENT_SNAPSHOT select 2) < (KPLIB_COPS_CLIENT_SNAPSHOT select 1)}
};

KPLIB_COPS_CLIENT_IS_NEAR = {
    params [
        ["_unit", player, [objNull]],
        ["_distance", KPLIB_COPS_REDEPLOY_RADIUS, [0]]
    ];
    if (isNull _unit || {side _unit != GRLIB_side_friendly}) exitWith {false};
    ((KPLIB_COPS_CLIENT_SNAPSHOT select 2) findIf {
        _unit distance2D (_x select 1) <= _distance
    }) >= 0
};

KPLIB_COPS_CLIENT_GET_DEPLOY_DESTINATIONS = {
    private _now = diag_tickTime;
    if (_now < KPLIB_COPS_CLIENT_DEPLOY_CACHE_AT) exitWith {+KPLIB_COPS_CLIENT_DEPLOY_CACHE};

    private _destinations = [];
    {
        _x params ["_id", "_position"];
        private _hostiles = 0;
        {
            if (side group _x == GRLIB_side_enemy) then {
                _hostiles = _hostiles + 1;
                if (_hostiles >= KPLIB_COPS_CONTEST_COUNT) exitWith {};
            };
        } forEach (_position nearEntities [["Man", "Tank", "Car"], KPLIB_COPS_CONTEST_RADIUS]);

        if (_hostiles < KPLIB_COPS_CONTEST_COUNT) then {
            _destinations pushBack [
                format ["%1 - %2", KPLIB_COPS_MARKER_TEXT, mapGridPosition _position],
                +_position
            ];
        };
    } forEach (KPLIB_COPS_CLIENT_SNAPSHOT select 2);

    KPLIB_COPS_CLIENT_DEPLOY_CACHE = _destinations;
    KPLIB_COPS_CLIENT_DEPLOY_CACHE_AT = _now + KPLIB_COPS_REDEPLOY_REFRESH;
    +_destinations
};

KPLIB_COPS_CLIENT_RECEIVE_RESULT = {
    params [
        ["_success", false, [false]],
        ["_message", "", [""]]
    ];
    KPLIB_COPS_CLIENT_REQUEST_PENDING = false;
    if (_message != "") then {hintSilent _message};
};

KPLIB_COPS_CLIENT_REQUEST_DEPLOY = {
    if (KPLIB_COPS_CLIENT_REQUEST_PENDING) exitWith {};
    KPLIB_COPS_CLIENT_REQUEST_PENDING = true;
    [] remoteExecCall ["KPLIB_COPS_SERVER_REQUEST_DEPLOY", 2];
    [{KPLIB_COPS_CLIENT_REQUEST_PENDING = false}, [], 5] call CBA_fnc_waitAndExecute;
};

KPLIB_COPS_CLIENT_INSTALL_ACTION = {
    params [["_unit", player, [objNull]]];
    if (!hasInterface || {isNull _unit} || {!local _unit}) exitWith {false};
    if ((_unit getVariable ["KPLIB_COPS_ACTION_ID", -1]) >= 0) exitWith {true};

    private _actionId = _unit addAction [
        "<t color='#80FF80'>Place PB</t>",
        {[] call KPLIB_COPS_CLIENT_REQUEST_DEPLOY},
        nil,
        -860,
        false,
        true,
        "",
        "[_originalTarget] call KPLIB_COPS_CLIENT_CAN_DEPLOY"
    ];
    _unit setVariable ["KPLIB_COPS_ACTION_ID", _actionId, false];
    true
};

KPLIB_COPS_CLIENT_INIT = {
    if (!hasInterface || {KPLIB_COPS_CLIENT_INITIALIZED}) exitWith {};
    KPLIB_COPS_CLIENT_INITIALIZED = true;
    [player] call KPLIB_COPS_CLIENT_INSTALL_ACTION;
    [] remoteExecCall ["KPLIB_COPS_SERVER_REQUEST_SNAPSHOT", 2];
};
