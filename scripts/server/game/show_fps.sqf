if !(missionNamespace getVariable ["KP_liberation_runtime_diagnostics", false]) exitWith {};

private _marker = createMarker ["fpsmarkerServer", [0, -500]];
_marker setMarkerType "mil_start";
_marker setMarkerSize [0.7, 0.7];

while {true} do {
    private _fps = diag_fps;
    private _color = "ColorGREEN";

    if (_fps < 30) then {_color = "ColorYELLOW"};
    if (_fps < 20) then {_color = "ColorORANGE"};
    if (_fps < 10) then {_color = GRLIB_color_enemy_bright};

    _marker setMarkerColor _color;
    _marker setMarkerText format [
        "Server: %1 FPS, %2 local groups, %3 local units",
        round (_fps * 100) / 100,
        {local _x} count allGroups,
        {local _x} count allUnits
    ];

    sleep 15;
};
