BATTLESPACE_ZEN_COVERAGE_ENABLED = false;
BATTLESPACE_ZEN_CONTACTS_ENABLED = false;
BATTLESPACE_ZEN_COVERAGE_DATA = [[], []];
BATTLESPACE_ZEN_CONTACTS_DATA = [];
BATTLESPACE_ZEN_COVERAGE_PFH = -1;

BATTLESPACE_ZEN_COVERAGE_RECEIVE = {
    params ["_action", "_payload"];
    if (!hasInterface || {!isRemoteExecuted} || {remoteExecutedOwner != 2}) exitWith {};
    switch (_action) do {
        case "COVERAGE": {if (BATTLESPACE_ZEN_COVERAGE_ENABLED) then {BATTLESPACE_ZEN_COVERAGE_DATA = _payload}};
        case "CONTACTS": {if (BATTLESPACE_ZEN_CONTACTS_ENABLED) then {BATTLESPACE_ZEN_CONTACTS_DATA = _payload}};
        case "INSPECT_COVERAGE": {
            _payload params ["_summary", "_row"];
            if (_summary isEqualTo []) exitWith {hintSilent "Strategic state is not ready yet."};
            _summary params ["_forces", "_cap", "_formed", "_rate", "_physical", "_physicalCap", "_evaluated", "_now"];
            private _lines = ["GROUND FORCE ALLOCATION", format ["Ground formations: %1 / %2", _forces, _cap], format ["New formations this window: %1 / %2", _formed, _rate], format ["Physical OPFOR units: %1 / %2 admission limit", _physical, _physicalCap]];
            _lines pushBack (if (_evaluated < 0) then {"First evaluation pending"} else {format ["Last evaluation: %1 seconds ago", ceil (_now - _evaluated)]});
            if (_row isEqualTo []) then {
                _lines pushBack "No objective or field assignment within 1.5 km of the cursor.";
            } else {
                _row params ["_id", "_kind", "_position", "_name", "_target", "_present", "_incoming", "_status", "_reason", "_ids", "_role", "_spawned"];
                _lines append ["", _name, format ["%1 / %2", _kind, _role], _status, format ["Present %1 | Incoming %2 | Desired %3", _present, _incoming, _target], format ["Physical infantry here: %1 (distant formations may be simulated)", _spawned], _reason, format ["Assigned formations: %1", _ids joinString ", "], format ["Assignment: %1", _id]];
            };
            hintSilent (_lines joinString toString [10]);
        };
        case "INSPECT_CONTACT": {
            _payload params ["_row", "_now"];
            if (_row isEqualTo []) exitWith {hintSilent "No retained contact within 1.5 km of the cursor."};
            _row params ["_id", "_position", "_seenAt", "_name", "_weight", "_player", "_observers", "_previous"];
            private _lines = ["SHARED OPFOR CONTACT MEMORY", _name, format ["Reported grid: %1", mapGridPosition _position], format ["Report age: %1 seconds", ceil (_now - _seenAt)], format ["Expires in: %1 seconds", ceil (0 max (BATTLESPACE_CONTACT_MEMORY_MAX_AGE - (_now - _seenAt)))], format ["Player contact: %1 | Estimated threat weight: %2", _player, _weight], "", "Reporting groups:"];
            {_lines pushBack format ["%1 — report %2 seconds old", _x select 0, _x select 1]} forEach _observers;
            if (_observers isEqualTo []) then {_lines pushBack "Report retained; original observer no longer available"};
            _lines append ["", "Marker shows the reported position, not live tracking."];
            hintSilent (_lines joinString toString [10]);
        };
    };
};

BATTLESPACE_ZEN_COVERAGE_DRAW = {
    if (isNull curatorCamera) exitWith {};
    private _cursor = screenToWorld getMousePosition;
    if (BATTLESPACE_ZEN_COVERAGE_ENABLED) then {
        {
            _x params ["_id", "_kind", "_position", "_name", "_target", "_present", "_incoming", "_status", "_reason"];
            private _color = switch (_status) do {
                case "COVERED": {[0.2, 0.95, 0.55, 0.9]};
                case "RELIEF INCOMING": {[1, 0.75, 0.15, 0.95]};
                default {[1, 0.25, 0.2, 0.95]};
            };
            private _label = if (_cursor distance2D _position <= 650) then {format ["%1 | %2 | PRESENT %3 / INCOMING %4 / TARGET %5", _name, _status, _present, _incoming, _target]} else {""};
            private _icon = ["\A3\ui_f\data\map\markers\nato\o_installation.paa", "\A3\ui_f\data\map\markers\military\circle_CA.paa"] select (_kind == "FIELD");
            drawIcon3D [_icon, _color, _position vectorAdd [0, 0, 25], 0.85, 0.85, 0, _label, 1, 0.025, "TahomaB"];
            if (_kind == "FIELD" && {_cursor distance2D _position <= 650}) then {
                for "_angle" from 0 to 330 step 30 do {
                    private _a = _position getPos [BATTLESPACE_FIELD_COVERAGE_RADIUS, _angle];
                    private _b = _position getPos [BATTLESPACE_FIELD_COVERAGE_RADIUS, _angle + 30];
                    drawLine3D [_a vectorAdd [0, 0, 3], _b vectorAdd [0, 0, 3], _color];
                };
            };
        } forEach (BATTLESPACE_ZEN_COVERAGE_DATA param [1, []]);
    };
    if (BATTLESPACE_ZEN_CONTACTS_ENABLED) then {
        {
            _x params ["_id", "_position", "_seenAt", "_name", "_weight", "_player", "_observers", "_previous"];
            private _age = CBA_missionTime - _seenAt;
            if (_age > BATTLESPACE_CONTACT_MEMORY_MAX_AGE) then {continue};
            private _color = if (_age < 30) then {[0.25, 0.85, 1, 0.95]} else {if (_age < 90) then {[1, 0.75, 0.2, 0.9]} else {[1, 0.3, 0.2, 0.65]}};
            private _label = if (_cursor distance2D _position <= 650) then {format ["REPORTED %1 | AGE %2s | OBSERVERS %3", _name, ceil _age, count _observers]} else {""};
            drawIcon3D ["\A3\ui_f\data\map\markers\military\unknown_CA.paa", _color, _position vectorAdd [0, 0, 15], 0.8, 0.8, 0, _label, 1, 0.025, "TahomaB"];
            if (_previous isNotEqualTo [] && {_previous distance2D _position > 10}) then {
                drawLine3D [_previous vectorAdd [0, 0, 10], _position vectorAdd [0, 0, 10], _color];
            };
        } forEach BATTLESPACE_ZEN_CONTACTS_DATA;
    };
};

BATTLESPACE_ZEN_COVERAGE_TOGGLE = {
    params ["_contacts"];
    if (_contacts) then {BATTLESPACE_ZEN_CONTACTS_ENABLED = !BATTLESPACE_ZEN_CONTACTS_ENABLED} else {BATTLESPACE_ZEN_COVERAGE_ENABLED = !BATTLESPACE_ZEN_COVERAGE_ENABLED};
    if (!BATTLESPACE_ZEN_COVERAGE_ENABLED) then {BATTLESPACE_ZEN_COVERAGE_DATA = [[], []]};
    if (!BATTLESPACE_ZEN_CONTACTS_ENABLED) then {BATTLESPACE_ZEN_CONTACTS_DATA = []};
    if (!BATTLESPACE_ZEN_COVERAGE_ENABLED && {!BATTLESPACE_ZEN_CONTACTS_ENABLED}) exitWith {
        if (BATTLESPACE_ZEN_COVERAGE_PFH >= 0) then {[BATTLESPACE_ZEN_COVERAGE_PFH] call CBA_fnc_removePerFrameHandler};
        BATTLESPACE_ZEN_COVERAGE_PFH = -1;
    };
    if (BATTLESPACE_ZEN_COVERAGE_PFH >= 0) exitWith {};
    BATTLESPACE_ZEN_COVERAGE_PFH = [{
        if (isNull curatorCamera) exitWith {};
        (_this select 0) params ["_next"];
        if (CBA_missionTime >= _next) then {
            private _position = screenToWorld getMousePosition;
            if (BATTLESPACE_ZEN_COVERAGE_ENABLED) then {["COVERAGE", _position] remoteExecCall ["BATTLESPACE_ZEN_COVERAGE_REQUEST", 2]};
            if (BATTLESPACE_ZEN_CONTACTS_ENABLED) then {["CONTACTS", _position] remoteExecCall ["BATTLESPACE_ZEN_COVERAGE_REQUEST", 2]};
            (_this select 0) set [0, CBA_missionTime + 5];
        };
        [] call BATTLESPACE_ZEN_COVERAGE_DRAW;
    }, 0, [0]] call CBA_fnc_addPerFrameHandler;
};

private _root = ["battlespaceCoverage", "Coverage + Contact Memory", "", {}, {true}] call zen_context_menu_fnc_createAction;
[_root, ["battlespaceAI"], 0] call zen_context_menu_fnc_addAction;
{
    _x params ["_id", "_label", "_code"];
    private _action = [_id, _label, "", _code, {true}] call zen_context_menu_fnc_createAction;
    [_action, ["battlespaceAI", "battlespaceCoverage"], 0] call zen_context_menu_fnc_addAction;
} forEach [
    ["coverageToggle", "Toggle Objective + Field Coverage", {[false] call BATTLESPACE_ZEN_COVERAGE_TOGGLE}],
    ["coverageInspect", "Inspect Coverage + Allocation Reason", {["INSPECT_COVERAGE", _this select 0] remoteExecCall ["BATTLESPACE_ZEN_COVERAGE_REQUEST", 2]}],
    ["contactToggle", "Toggle Shared Contact Memory", {[true] call BATTLESPACE_ZEN_COVERAGE_TOGGLE}],
    ["contactInspect", "Inspect Reported Contact + Observers", {["INSPECT_CONTACT", _this select 0] remoteExecCall ["BATTLESPACE_ZEN_COVERAGE_REQUEST", 2]}]
];
