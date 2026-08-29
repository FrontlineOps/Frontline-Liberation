GRLIB_conflicting_objects = [];
GRLIB_buildoverlay_icon = "\A3\ui_f\data\map\markers\handdrawn\objective_CA.paa";
GRLIB_buildoverlay_color = [ 1, 0, 0, 1 ];
GRLIB_buildoverlay_cfg = configFile >> "cfgVehicles";
KPLIB_buildOverlayActive = false;

KPLIB_fnc_startBuildOverlay = {
    if (missionNamespace getVariable ["KPLIB_buildOverlayActive", false]) exitWith {};

    KPLIB_buildOverlayActive = true;
    ["KPLIB_buildOverlay", "onEachFrame", {
        if (build_confirmed isEqualTo 1) then {
            {
                if (alive _x) then {
                    private _position = getPos _x;
                    drawIcon3D [
                        GRLIB_buildoverlay_icon,
                        GRLIB_buildoverlay_color,
                        [_position select 0, _position select 1, 1.5],
                        1,
                        1,
                        0,
                        getText (GRLIB_buildoverlay_cfg >> typeOf _x >> "displayName"),
                        2,
                        0.04,
                        "puristaMedium"
                    ];
                };
            } forEach GRLIB_conflicting_objects;
        };
    }] call BIS_fnc_addStackedEventHandler;
};

KPLIB_fnc_stopBuildOverlay = {
    if (missionNamespace getVariable ["KPLIB_buildOverlayActive", false]) then {
        ["KPLIB_buildOverlay", "onEachFrame"] call BIS_fnc_removeStackedEventHandler;
        KPLIB_buildOverlayActive = false;
    };

    GRLIB_conflicting_objects = [];
};
