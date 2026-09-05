/* Curator-only display of the compact, authenticated artillery snapshot. */
BATTLESPACE_ARTILLERY_TOGGLE_RENDER = {
    RENDER_BATTLESPACE_ARTILLERY = !RENDER_BATTLESPACE_ARTILLERY;
    if (RENDER_BATTLESPACE_ARTILLERY) then {
        if (RENDER_BATTLESPACE_ARTILLERY_PFH_ID < 0) then {
            RENDER_BATTLESPACE_ARTILLERY_PFH_ID = [{_this call RENDER_BATTLESPACE_ARTILLERY_PFH}, 0, [0]] call CBA_fnc_addPerFrameHandler;
        };
    } else {
        if (RENDER_BATTLESPACE_ARTILLERY_PFH_ID >= 0) then {
            [RENDER_BATTLESPACE_ARTILLERY_PFH_ID] call CBA_fnc_removePerFrameHandler;
            RENDER_BATTLESPACE_ARTILLERY_PFH_ID = -1;
        };
        BATTLESPACE_ARTILLERY_RENDER_DATA = [[], [], [true, 0, 0], []];
    };
    systemChat format ["Artillery debug: %1", ["OFF", "ON"] select RENDER_BATTLESPACE_ARTILLERY];
};

BATTLESPACE_TRP_DRAW = {
    params ["_rows"];
    {
        _x params ["_id", "_position", "_radius", "_status", "_reason", "_battery", "_batteryPosition", "_kind", "_sector", "_readyAt"];
        private _color = switch (_status) do {
            case "PREPARING": {[1,0.85,0.2,0.9]};
            case "FIRING": {[1,0.25,0.15,1]};
            case "RETIRED": {[0.65,0.65,0.65,0.7]};
            default {[0.3,1,0.65,0.9]};
        };
        private _registration = if (_status == "PREPARING") then {format [" (%1s)", ceil (0 max (_readyAt - CBA_missionTime))]} else {""};
        private _label = format ["%1 | %2%3 | %4 | %5", _id, _status, _registration, _battery, _reason];
        drawIcon3D ["\A3\ui_f\data\map\markers\military\destroy_CA.paa", _color, _position vectorAdd [0,0,12], 0.8, 0.8, 0, _label, 1, 0.025, "TahomaB"];
        for "_angle" from 0 to 345 step 15 do {
            private _from = _position getPos [_radius, _angle];
            private _to = _position getPos [_radius, _angle + 15];
            drawLine3D [_from vectorAdd [0,0,3], _to vectorAdd [0,0,3], _color];
        };
        if (_status != "RETIRED") then {drawLine3D [_batteryPosition vectorAdd [0,0,8], _position vectorAdd [0,0,8], _color]};
    } forEach _rows;
};

BATTLESPACE_TRP_INSPECT = {
    params ["_position"];
    if (isNull getAssignedCuratorLogic player) exitWith {};
    private _rows = BATTLESPACE_ARTILLERY_RENDER_DATA param [3, []];
    _rows = [_rows, [], {_position distance2D (_x # 1)}, "ASCEND"] call BIS_fnc_sortBy;
    if (_rows isEqualTo []) exitWith {hint "No prepared artillery points in the current snapshot. Plans require active frontline assignments and a surviving battery in range."};
    (_rows # 0) params ["_id", "_point", "_radius", "_status", "_reason", "_battery", "_batteryPosition", "_kind", "_sector", "_readyAt", "_expiresAt", ["_lastFiredAt", -1]];
    private _lastFire = if (_lastFiredAt < 0) then {"No shots recorded"} else {format ["%1s ago", round (CBA_missionTime - _lastFiredAt)]};
    hint format ["%1 — %2\n%3\n%4\n\nObjective: %5\nGrid: %6 | Contact radius: %7m\nBattery: %8 at %9\nRegistration remaining: %10s\nPlan expires in: %11s\nLast firing: %12\n\nThis is a fixed aim point. Recent observer contact is required. Network, ammunition, safety and cooldown rules still apply.\nSnapshot age: %13s",
        _id, _kind, _status, _reason, _sector, mapGridPosition _point, _radius, _battery, mapGridPosition _batteryPosition,
        ceil (0 max (_readyAt - CBA_missionTime)), ceil (0 max (_expiresAt - CBA_missionTime)), _lastFire,
        round (CBA_missionTime - (missionNamespace getVariable ["BSA_RENDER_RECEIVED_AT", CBA_missionTime]))];
};

private _root = ["artilleryDebug", "Artillery + Prepared Fire Plans", ["", [1,1,1,1]], {}, {true}] call zen_context_menu_fnc_createAction;
[_root, ["battlespaceAI"], 0] call zen_context_menu_fnc_addAction;

private _overlay = ["artilleryOverlay", "Toggle Artillery Debug", ["", [1,1,1,1]], {
    call BATTLESPACE_ARTILLERY_TOGGLE_RENDER;
}, {true}] call zen_context_menu_fnc_createAction;
[_overlay, ["battlespaceAI", "artilleryDebug"], 0] call zen_context_menu_fnc_addAction;

private _points = ["artilleryTRPs", "Toggle TRP Areas + Battery Links", ["", [1,1,1,1]], {
    RENDER_BATTLESPACE_ARTILLERY_TRPS = !RENDER_BATTLESPACE_ARTILLERY_TRPS;
    if (RENDER_BATTLESPACE_ARTILLERY_TRPS && {!RENDER_BATTLESPACE_ARTILLERY}) then {call BATTLESPACE_ARTILLERY_TOGGLE_RENDER};
    systemChat format ["Prepared fire areas: %1", ["HIDDEN", "VISIBLE"] select RENDER_BATTLESPACE_ARTILLERY_TRPS];
}, {true}] call zen_context_menu_fnc_createAction;
[_points, ["battlespaceAI", "artilleryDebug"], 0] call zen_context_menu_fnc_addAction;

private _inspect = ["artilleryInspectTRP", "Inspect Nearest TRP", ["", [1,1,1,1]], {
    params ["_position"];
    // Retry past the snapshot service's one-second limiter without adding a polling loop.
    [{[] remoteExecCall ["BATTLESPACE_ARTILLERY_RENDER_REQUEST", 2]}, [], 1.1] call CBA_fnc_waitAndExecute;
    [{_this call BATTLESPACE_TRP_INSPECT}, [+_position], 2.1] call CBA_fnc_waitAndExecute;
}, {true}] call zen_context_menu_fnc_createAction;
[_inspect, ["battlespaceAI", "artilleryDebug"], 0] call zen_context_menu_fnc_addAction;
