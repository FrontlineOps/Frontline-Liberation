private _actions = [];
veh_action_detect_distance = 20;
veh_action_distance = 10;

while {true} do {
    private _detected = [];
    if (alive player && {[player, "RECYCLE"] call KPLIB_fnc_hasPermission}) then {
        private _nearFob = (player getVariable ["KPLIB_fobDist", 99999]) < GRLIB_fob_range;
        if (KPLIB_salvage_field_enabled || {_nearFob}) then {
            _detected = (getPos player nearObjects veh_action_detect_distance) select {
                ([_x, player] call KPLIB_fnc_canRecycle)
                    && {_nearFob || {_x isKindOf "LandVehicle" || {_x isKindOf "Air"} || {_x isKindOf "Ship"}}}
            };
        };
    };
    {
        _x params ["_object", "_action"];
        if !(_object in _detected) then {_object removeAction _action};
    } forEach _actions;
    _actions = _actions select {(_x select 0) in _detected};
    {
        private _object = _x;
        if (_actions findIf {(_x select 0) isEqualTo _object} < 0) then {
            private _vehicle = _object isKindOf "LandVehicle" || {_object isKindOf "Air"} || {_object isKindOf "Ship"};
            private _label = [localize "STR_RECYCLE", "-- SALVAGE VEHICLE"] select _vehicle;
            private _action = _object addAction [
                ([_label, "#FFFF00"] call KPLIB_fnc_actionLabel),
                "scripts\client\actions\do_recycle.sqf", "", -900, true, true, "",
                "build_confirmed == 0 && {[_this, 'RECYCLE'] call KPLIB_fnc_hasPermission} && {[_target, _this] call KPLIB_fnc_canRecycle}"
            ];
            _actions pushBack [_object, _action];
        };
    } forEach _detected;
    sleep 3;
};