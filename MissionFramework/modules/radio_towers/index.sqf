/* Server-owned tower lifecycle. Clients receive ordinary marker updates and the
   existing intelligence snapshots. No client request can capture/destroy a tower.
   Only command scheduling uses the slower clock; simulation and saves use real time. */
if (!isServer) exitWith {};

localNamespace setVariable ["KPLIB_RADIO_TOWERS", createHashMap];
localNamespace setVariable ["KPLIB_RADIO_CLOCK", [CBA_missionTime, CBA_missionTime]];
localNamespace setVariable ["KPLIB_RADIO_DISRUPTED_UNTIL", 0];
localNamespace setVariable ["KPLIB_RADIO_READY", false];

KPLIB_RADIO_SERVER_COMMAND_TIME = {
    if (!isServer || {isRemoteExecuted}) exitWith {CBA_missionTime};
    private _clock = localNamespace getVariable "KPLIB_RADIO_CLOCK";
    _clock params ["_lastAt", "_commandsAt"];
    private _now = CBA_missionTime;
    private _elapsed = (_now - _lastAt) max 0;
    private _until = localNamespace getVariable ["KPLIB_RADIO_DISRUPTED_UNTIL", 0];
    private _disrupted = ((_now min _until) - _lastAt) max 0 min _elapsed;
    private _factor = 1 max KPLIB_radio_disruption_multiplier;
    _commandsAt = _commandsAt + _elapsed - _disrupted + (_disrupted / _factor);
    localNamespace setVariable ["KPLIB_RADIO_CLOCK", [_now, _commandsAt]];
    _commandsAt
};

// Project a command interval into real seconds, including recovery partway through it.
KPLIB_RADIO_SERVER_COMMAND_DELAY = {
    params ["_duration"];
    private _remaining = ((localNamespace getVariable ["KPLIB_RADIO_DISRUPTED_UNTIL", 0]) - CBA_missionTime) max 0;
    private _factor = 1 max KPLIB_radio_disruption_multiplier;
    private _slowed = (0 max _duration) min (_remaining / _factor);
    _slowed * _factor + ((0 max _duration) - _slowed)
};

KPLIB_RADIO_SERVER_INTERVAL = {
    private _minimum = 60 max (KPLIB_radio_intercept_interval param [0, 600]);
    private _maximum = _minimum max (KPLIB_radio_intercept_interval param [1, 900]);
    _minimum + random (_maximum - _minimum)
};

KPLIB_RADIO_SERVER_CLASS_DESTRUCTIBLE = {
    params ["_class"];
    private _config = configFile >> "CfgVehicles" >> _class;
    private _destruction = _config >> "destrType";
    isClass _config && {if (isText _destruction) then {
        toLower (getText _destruction) != "destructno"
    } else {
        getNumber _destruction != 0
    }}
};

KPLIB_RADIO_SERVER_NOTIFY = {
    if (!isServer || {isRemoteExecuted}) exitWith {};
    params ["_message"];
    private _targets = allPlayers select {isPlayer _x && {side group _x == GRLIB_side_friendly}};
    if (_targets isNotEqualTo []) then {
        ["INFO", 0, _message] remoteExecCall ["KPLIB_INTEL_CLIENT_NOTIFY", _targets];
    };
};

KPLIB_RADIO_SERVER_MARKER = {
    if (!isServer || {isRemoteExecuted}) exitWith {};
    params ["_sector", "_entry"];
    private _suffix = if (_entry get "destroyed") then {" | DESTROYED"} else {
        ["", " | INTERCEPTING"] select (_entry get "held")
    };
    _sector setMarkerText ((_entry get "label") + _suffix);
};

KPLIB_RADIO_SERVER_DESTROYED = {
    params [["_tower", objNull, [objNull]]];
    if (!isServer || {isRemoteExecuted} || {isNull _tower} || {alive _tower}) exitWith {false};
    private _towers = localNamespace getVariable "KPLIB_RADIO_TOWERS";
    private _sector = _tower getVariable ["KPLIB_radioSector", ""];
    private _entry = _towers getOrDefault [_sector, createHashMap];
    if (count _entry == 0 || {(_entry get "object") isNotEqualTo _tower} || {_entry get "destroyed"}) exitWith {false};

    _entry set ["destroyed", true];
    _entry set ["nextInterceptAt", -1];
    _entry set ["held", _sector in blufor_sectors];
    // Capture ownership, not a caller-supplied side, determines the strategic effect.
    if !(_sector in blufor_sectors) then {
        call KPLIB_RADIO_SERVER_COMMAND_TIME;
        private _until = CBA_missionTime + (0 max KPLIB_radio_disruption_duration);
        _entry set ["disruptedUntil", _until];
        localNamespace setVariable ["KPLIB_RADIO_DISRUPTED_UNTIL", _until max (localNamespace getVariable ["KPLIB_RADIO_DISRUPTED_UNTIL", 0])];
        [format ["Radio tower at %1 destroyed. Enemy coordination is slowed for %2 minutes.", _entry get "label", round (KPLIB_radio_disruption_duration / 60)]] call KPLIB_RADIO_SERVER_NOTIFY;
    } else {
        [format ["Captured radio tower at %1 destroyed. Communications intercepts have stopped.", _entry get "label"]] call KPLIB_RADIO_SERVER_NOTIFY;
    };
    [_sector, _entry] call KPLIB_RADIO_SERVER_MARKER;
    [format ["Tower destroyed (sector=%1, friendlyHeld=%2, disruptionRemaining=%3)", _sector, _entry get "held", ((_entry get "disruptedUntil") - CBA_missionTime) max 0], "RADIO"] call KPLIB_fnc_log;
    localNamespace setVariable ["KPLIB_RADIO_DIRTY", true];
    true
};

// Existing save slot 21 still holds tower records. Old [sector, classname] rows
// default to intact. Optional fields hold destruction and remaining mission time.
KPLIB_RADIO_SERVER_EXPORT = {
    if (!isServer || {isRemoteExecuted}) exitWith {[]};
    if !(localNamespace getVariable ["KPLIB_RADIO_READY", false]) exitWith {+KPLIB_sectorTowers};
    private _rows = [];
    {
        _rows pushBack [
            _x, _y get "class", _y get "destroyed",
            ((_y get "disruptedUntil") - CBA_missionTime) max 0,
            ((_y get "nextInterceptAt") - CBA_missionTime) max 0,
            _y get "held"
        ];
    } forEach (localNamespace getVariable "KPLIB_RADIO_TOWERS");
    _rows
};

KPLIB_RADIO_SERVER_INIT = {
    if (!isServer || {isRemoteExecuted} || {localNamespace getVariable ["KPLIB_RADIO_READY", false]}) exitWith {false};
    if !(missionNamespace getVariable ["save_is_loaded", false]) exitWith {false};
    private _saved = createHashMap;
    {
        if !(_x isEqualType [] && {count _x >= 2}) then {continue};
        if ((_x # 0) isEqualType "" && {(_x # 0) in sectors_tower} && {(_x # 1) isEqualType ""}) then {
            _saved set [_x # 0, _x];
        };
    } forEach KPLIB_sectorTowers;
    private _towers = localNamespace getVariable "KPLIB_RADIO_TOWERS";
    private _classes = KPLIB_radioTowerClassnames select {[_x] call KPLIB_RADIO_SERVER_CLASS_DESTRUCTIBLE};
    private _until = 0;
    {
        private _sector = _x;
        private _row = _saved getOrDefault [_sector, []];
        private _class = _row param [1, "", [""]];
        if !([_class] call KPLIB_RADIO_SERVER_CLASS_DESTRUCTIBLE) then {
            private _replacement = _classes param [0, ""];
            if (_classes isNotEqualTo []) then {_replacement = selectRandom _classes};
            if (_class != "") then {
                [format ["Tower %1 replaces unsupported destruction class %2 with %3", _sector, _class, _replacement], "RADIO"] call KPLIB_fnc_log;
            };
            _class = _replacement;
        };
        if (_class == "") then {
            [format ["Cannot create radio tower %1: invalid class %2", _sector, _class], "RADIO"] call KPLIB_fnc_log;
            continue;
        };
        private _destroyed = _row param [2, false, [false]];
        private _remaining = if (_destroyed) then {0 max (_row param [3, 0, [0]]) min KPLIB_radio_disruption_duration} else {0};
        private _held = _sector in blufor_sectors;
        private _interval = call KPLIB_RADIO_SERVER_INTERVAL;
        if (count _row >= 6 && {_held} && {_row param [5, false, [false]]}) then {
            _interval = (0 max (_row param [4, _interval, [0]])) min (KPLIB_radio_intercept_interval # 1);
        };
        private _position = markerPos _sector;
        private _tower = createVehicle [_class, _position, [], 0, "CAN_COLLIDE"];
        _tower setPos _position;
        _tower setVectorUp [0, 0, 1];
        _tower setVariable ["KPLIB_radioSector", _sector];
        private _entry = createHashMapFromArray [
            ["object", _tower], ["class", _class], ["label", markerText _sector],
            ["held", _held], ["destroyed", _destroyed],
            ["disruptedUntil", CBA_missionTime + _remaining],
            ["nextInterceptAt", if (_held && {!_destroyed}) then {CBA_missionTime + _interval} else {-1}]
        ];
        _towers set [_sector, _entry];
        if (_remaining > 0) then {_until = _until max (CBA_missionTime + _remaining)};
        if (_destroyed) then {
            // Restore the ruin before registering the handler; loading cannot reapply the reward.
            _tower setDamage 1;
        } else {
            [_tower, "Killed", {[_this # 0] call KPLIB_RADIO_SERVER_DESTROYED}] call CBA_fnc_addBISEventHandler;
        };
        [_sector, _entry] call KPLIB_RADIO_SERVER_MARKER;
    } forEach sectors_tower;
    call KPLIB_RADIO_SERVER_COMMAND_TIME;
    localNamespace setVariable ["KPLIB_RADIO_DISRUPTED_UNTIL", _until];
    localNamespace setVariable ["KPLIB_RADIO_READY", true];
    localNamespace setVariable ["KPLIB_RADIO_DIRTY", true];
    [format ["Initialized %1 radio towers; %2 destroyed; communications disruption remaining %3 seconds", count _towers, {_x get "destroyed"} count (values _towers), (_until - CBA_missionTime) max 0], "RADIO"] call KPLIB_fnc_log;
    localNamespace setVariable ["KPLIB_RADIO_PFH", [{call KPLIB_RADIO_SERVER_TICK}, 5] call CBA_fnc_addPerFrameHandler];
    true
};

KPLIB_RADIO_SERVER_TICK = {
    if (!isServer || {isRemoteExecuted} || {!(localNamespace getVariable ["KPLIB_RADIO_READY", false])}) exitWith {};
    call KPLIB_RADIO_SERVER_COMMAND_TIME;
    private _until = localNamespace getVariable ["KPLIB_RADIO_DISRUPTED_UNTIL", 0];
    if (_until > 0 && {CBA_missionTime >= _until}) then {
        localNamespace setVariable ["KPLIB_RADIO_DISRUPTED_UNTIL", 0];
        localNamespace setVariable ["KPLIB_RADIO_DIRTY", true];
        ["Enemy communications have recovered. Normal coordination speed has resumed."] call KPLIB_RADIO_SERVER_NOTIFY;
        ["Enemy communications recovered after tower disruption", "RADIO"] call KPLIB_fnc_log;
    };
    private _due = "";
    {
        private _entry = _y;
        private _held = _x in blufor_sectors;
        private _tower = _entry get "object";
        if (!(_entry get "destroyed") && {!isNull _tower} && {!alive _tower}) then {
            [_tower] call KPLIB_RADIO_SERVER_DESTROYED;
        };
        if (_held != (_entry get "held")) then {
            _entry set ["held", _held];
            _entry set ["nextInterceptAt", if (_held && {!(_entry get "destroyed")}) then {CBA_missionTime + (call KPLIB_RADIO_SERVER_INTERVAL)} else {-1}];
            [_x, _entry] call KPLIB_RADIO_SERVER_MARKER;
            localNamespace setVariable ["KPLIB_RADIO_DIRTY", true];
            private _message = if (_entry get "destroyed") then {"The tower is destroyed and cannot intercept communications."} else {
                ["Enemy control restored; intercepts have stopped.", "Tower captured intact; periodic communications intercepts are now available."] select _held
            };
            [(_entry get "label") + ": " + _message] call KPLIB_RADIO_SERVER_NOTIFY;
            [format ["Tower control changed (sector=%1, friendlyHeld=%2, destroyed=%3)", _x, _held, _entry get "destroyed"], "RADIO"] call KPLIB_fnc_log;
        };
        if (_due == "" && {_held} && {!(_entry get "destroyed")} && {!isNull _tower} && {alive _tower}
            && {CBA_missionTime >= (_entry get "nextInterceptAt")}) then {_due = _x};
    } forEach (localNamespace getVariable "KPLIB_RADIO_TOWERS");
    // At most one report collection per pass, even if many towers were due at startup.
    if (_due != "" && {missionNamespace getVariable ["KPLIB_INTEL_SERVER_INITIALIZED", false]} && {KPLIB_intelligence_enabled}) then {
        private _entry = (localNamespace getVariable "KPLIB_RADIO_TOWERS") get _due;
        _entry set ["nextInterceptAt", CBA_missionTime + (call KPLIB_RADIO_SERVER_INTERVAL)];
        // Successful publication already requests a campaign save through intelligence.
        if !([_due] call KPLIB_INTEL_SERVER_INTERCEPT) then {
            localNamespace setVariable ["KPLIB_RADIO_DIRTY", true];
        };
    };
    if (localNamespace getVariable ["KPLIB_RADIO_DIRTY", false] && {missionNamespace getVariable ["KPLIB_init", false]}
        && {!(missionNamespace getVariable ["kp_liberation_saving", false])} && {!(localNamespace getVariable ["KPLIB_RADIO_SAVE_QUEUED", false])}) then {
        localNamespace setVariable ["KPLIB_RADIO_DIRTY", false];
        localNamespace setVariable ["KPLIB_RADIO_SAVE_QUEUED", true];
        [] spawn {
            if !(call KPLIB_fnc_doSave) then {localNamespace setVariable ["KPLIB_RADIO_DIRTY", true]};
            localNamespace setVariable ["KPLIB_RADIO_SAVE_QUEUED", false];
        };
    };
};
