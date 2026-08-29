params ["_fobContainer"];

if (count GRLIB_all_fobs >= GRLIB_maximum_fobs) exitWith {
    hint format [localize "STR_HINT_FOBS_EXCEEDED", GRLIB_maximum_fobs];
};

private _minimumFobDistance = 1000;
private _minimumSectorDistance = 300;

FOB_build_in_progress = true;
publicVariable "FOB_build_in_progress";

private _nearFobIndex = GRLIB_all_fobs findIf {
    player distance _x < _minimumFobDistance
};
if (_nearFobIndex != -1) exitWith {
    hint format [
        localize "STR_FOB_BUILDING_IMPOSSIBLE",
        floor _minimumFobDistance,
        floor (player distance (GRLIB_all_fobs select _nearFobIndex))
    ];
    FOB_build_in_progress = false;
    publicVariable "FOB_build_in_progress";
};

private _nearSectorIndex = sectors_allSectors findIf {
    player distance (markerPos _x) < _minimumSectorDistance
};
if (_nearSectorIndex != -1) exitWith {
    hint format [
        localize "STR_FOB_BUILDING_IMPOSSIBLE_SECTOR",
        floor _minimumSectorDistance,
        floor (player distance (markerPos (sectors_allSectors select _nearSectorIndex)))
    ];
    FOB_build_in_progress = false;
    publicVariable "FOB_build_in_progress";
};

buildtype = 99;
dobuild = 1;
deleteVehicle _fobContainer;
