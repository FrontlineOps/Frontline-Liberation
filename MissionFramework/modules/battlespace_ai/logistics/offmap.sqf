/* All entry markers share this server-private reserve. No client publication or
   RPC mutator; the logistics snapshot owns persistence with its paid convoys. */
BATTLESPACE_OFFMAP_LOAD = {
    params [["_saved", []]];
    if (!isServer || {isRemoteExecuted}) exitWith {};
    private _capacity = createHashMap;
    private _stock = createHashMap;
    private _fractions = createHashMap;
    private _fresh = _saved isEqualTo [];
    private _valid = _saved isEqualType createHashMap && {(_saved getOrDefault ["version", 0]) == 1};
    private _savedStock = if (_valid) then {_saved getOrDefault ["stock", createHashMap]} else {createHashMap};
    private _savedFractions = if (_valid) then {_saved getOrDefault ["fractions", createHashMap]} else {createHashMap};
    if !(_savedStock isEqualType createHashMap) then {_savedStock = createHashMap};
    if !(_savedFractions isEqualType createHashMap) then {_savedFractions = createHashMap};
    {
        private _cap = BATTLESPACE_STRATEGIC_OFFMAP_CAPACITY getOrDefault [_x, 0];
        if !(_cap isEqualType 0) then {_cap = 0};
        _cap = floor (_cap max 0);
        _capacity set [_x, _cap];
        private _amount = if (_fresh) then {_cap} else {_savedStock getOrDefault [_x, 0]};
        if !(_amount isEqualType 0) then {_amount = 0};
        _amount = floor (_amount max 0 min _cap);
        _stock set [_x, _amount];
        private _fraction = _savedFractions getOrDefault [_x, 0];
        if !(_fraction isEqualType 0) then {_fraction = 0};
        _fractions set [_x, if (_amount >= _cap) then {0} else {_fraction max 0 min 0.999999}];
    } forEach BATTLESPACE_RESOURCE_TYPES;
    private _interval = BATTLESPACE_STRATEGIC_OFFMAP_REGEN_INTERVAL max 1;
    private _remaining = if (_valid) then {_saved getOrDefault ["regenRemaining", _interval]} else {_interval};
    if !(_remaining isEqualType 0) then {_remaining = _interval};
    localNamespace setVariable ["BATTLESPACE_OFFMAP_STATE", createHashMapFromArray [
        ["capacity", _capacity], ["stock", _stock], ["fractions", _fractions],
        ["nextRegenAt", CBA_missionTime + (_remaining max 0 min _interval)]
    ]];
};

BATTLESPACE_OFFMAP_EXPORT = {
    if (!isServer || {isRemoteExecuted}) exitWith {[]};
    private _state = localNamespace getVariable ["BATTLESPACE_OFFMAP_STATE", createHashMap];
    if (count _state == 0) exitWith {[]};
    createHashMapFromArray [
        ["version", 1],
        ["stock", [_state get "stock"] call BATTLESPACE_COPY_RESOURCE_MAP],
        ["fractions", [_state get "fractions"] call BATTLESPACE_COPY_RESOURCE_MAP],
        ["regenRemaining", ((_state get "nextRegenAt") - CBA_missionTime) max 0]
    ]
};

BATTLESPACE_OFFMAP_DEBIT = {
    params ["_cost"];
    if (!isServer || {isRemoteExecuted} || {!(_cost isEqualType createHashMap)} || {count _cost == 0}) exitWith {false};
    private _paid = false;
    isNil {
        private _stock = (localNamespace getVariable ["BATTLESPACE_OFFMAP_STATE", createHashMap]) getOrDefault ["stock", createHashMap];
        private _valid = true;
        {
            if (!(_x in BATTLESPACE_RESOURCE_TYPES) || {!(_y isEqualType 0)} || {_y < 0} || {_y != floor _y}
                || {(_stock getOrDefault [_x, 0]) < _y}) exitWith {_valid = false};
        } forEach _cost;
        if (!_valid) exitWith {};
        {_stock set [_x, (_stock getOrDefault [_x, 0]) - _y]} forEach _cost;
        _paid = true;
    };
    _paid
};

BATTLESPACE_OFFMAP_DEPOSIT = {
    params ["_returned"];
    if (!isServer || {isRemoteExecuted} || {!(_returned isEqualType createHashMap)}) exitWith {createHashMap};
    private _accepted = createHashMap;
    isNil {
        private _state = localNamespace getVariable ["BATTLESPACE_OFFMAP_STATE", createHashMap];
        private _stock = _state getOrDefault ["stock", createHashMap];
        private _capacity = _state getOrDefault ["capacity", createHashMap];
        private _fractions = _state getOrDefault ["fractions", createHashMap];
        {
            if (!(_x in BATTLESPACE_RESOURCE_TYPES) || {!(_y isEqualType 0)} || {_y <= 0}) then {continue};
            private _current = _stock getOrDefault [_x, 0];
            private _cap = _capacity getOrDefault [_x, 0];
            private _amount = (floor _y) min ((_cap - _current) max 0);
            if (_amount > 0) then {
                _stock set [_x, _current + _amount];
                _accepted set [_x, _amount];
                if (_current + _amount >= _cap) then {_fractions set [_x, 0]};
            };
        } forEach _returned;
    };
    _accepted
};

BATTLESPACE_OFFMAP_CONVOY_FORCE_COST = {
    params ["_definition"];
    private _cost = [_definition] call BATTLESPACE_LOGISTICS_BUILD_CONVOY_FORCE_COST;
    private _crew = 0;
    {
        _crew = _crew + ([_x, false] call BIS_fnc_crewCount);
    } forEach ((_definition get "composition") getOrDefault ["vehicles", []]);
    _cost set ["manpower", (_cost getOrDefault ["manpower", 0]) + _crew];
    _cost
};

BATTLESPACE_OFFMAP_CONVOY_DEBIT = {
    params ["_cargo", "_definition"];
    private _debit = [_cargo] call BATTLESPACE_COPY_RESOURCE_MAP;
    {
        _debit set [_x, (_debit getOrDefault [_x, 0]) + _y];
    } forEach ([_definition] call BATTLESPACE_OFFMAP_CONVOY_FORCE_COST);
    _debit
};

BATTLESPACE_OFFMAP_PLAN_CARGO = {
    params ["_request", "_definition"];
    if (!isServer || {isRemoteExecuted}) exitWith {createHashMap};
    private _stock = (localNamespace getVariable ["BATTLESPACE_OFFMAP_STATE", createHashMap]) getOrDefault ["stock", createHashMap];
    private _cost = [_definition] call BATTLESPACE_OFFMAP_CONVOY_FORCE_COST;
    private _affordable = true;
    {
        if ((_stock getOrDefault [_x, 0]) < _y) exitWith {_affordable = false};
    } forEach _cost;
    private _cargo = createHashMap;
    if (!_affordable) exitWith {_cargo};
    {
        if (!(_x in BATTLESPACE_RESOURCE_TYPES) || {!(_y isEqualType 0)} || {_y <= 0}) then {continue};
        private _available = ((_stock getOrDefault [_x, 0]) - (_cost getOrDefault [_x, 0])) max 0;
        private _amount = (floor _y) min _available;
        if (_amount > 0) then {_cargo set [_x, _amount]};
    } forEach _request;
    _cargo
};

BATTLESPACE_OFFMAP_TICK = {
    if (!isServer || {isRemoteExecuted}) exitWith {false};
    private _changed = false;
    isNil {
        private _state = localNamespace getVariable ["BATTLESPACE_OFFMAP_STATE", createHashMap];
        if (count _state == 0 || {CBA_missionTime < (_state get "nextRegenAt")}) exitWith {};
        private _interval = BATTLESPACE_STRATEGIC_OFFMAP_REGEN_INTERVAL max 1;
        private _ticks = 1 + floor ((CBA_missionTime - (_state get "nextRegenAt")) / _interval);
        private _ratio = BATTLESPACE_STRATEGIC_OFFMAP_REGEN_RATIO max 0 min 1;
        private _stock = _state get "stock";
        private _fractions = _state get "fractions";
        {
            // Retain fractional equipment production; small pools eventually
            // gain whole assets. Full pools cannot bank future replenishments.
            private _produced = (_fractions getOrDefault [_x, 0]) + _y * _ratio * _ticks;
            private _whole = floor (_produced + 0.000001);
            private _amount = ((_stock getOrDefault [_x, 0]) + _whole) min _y;
            _stock set [_x, _amount];
            _fractions set [_x, if (_amount >= _y) then {0} else {(_produced - _whole) max 0}];
        } forEach (_state get "capacity");
        _state set ["nextRegenAt", (_state get "nextRegenAt") + _ticks * _interval];
        _changed = true;
    };
    _changed
};
