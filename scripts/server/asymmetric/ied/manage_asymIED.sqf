params ["_sector", "_count"];

if (_count <= 0) exitWith {};

if (KP_liberation_asymmetric_debug > 0) then {[format ["manage_asymIED.sqf for %1 spawned on: %2", markerText _sector, debug_source], "ASYMMETRIC"] remoteExecCall ["KPLIB_fnc_log", 2];};

waitUntil {sleep 1; _sector in KP_liberation_asymmetric_sectors};

if (KP_liberation_asymmetric_debug > 0) then {[format ["manage_asymIED.sqf -> spawning IED %1 at %2", _count, markerText _sector], "ASYMMETRIC"] remoteExecCall ["KPLIB_fnc_log", 2];};

private _activation_radius_infantry = 6.66;
private _activation_radius_vehicles = 10;
private _spread = 7;
private _infantry_trigger = 1 + (ceil (random 2));
private _vehicle_trigger = 1;
private _ied_type = selectRandom ["IEDLandBig_F","ACE_IEDLandBig_Range", "IEDLandSmall_F", "ACE_IEDLandSmall_Range"];
private _ied_obj = objNull;
private _roadobj = [(markerPos (_sector) getPos [random (400), random (360)]), 200, []] call BIS_fnc_nearestRoad;
private _goes_boom = false;
private _ied_marker = "";
private _ultra_strong = false;
if (random 100 < (abs KP_liberation_civ_rep)) then {
    _ultra_strong = true;
};

if (_count > 0) then {
    [_sector, _count - 1] spawn manage_asymIED;
};

if (!(isnull _roadobj)) then {
    private _roadpos = getpos _roadobj; 

    private _iedPos = _roadpos getPos [_spread, random 360];

    _iedPos set [2, 0];
    _ied_obj = createMine [_ied_type, _iedPos, [], 0];
    _ied_obj setdir (random 360);
    _ied_obj setVectorUp (surfaceNormal [_iedPos#0, _iedPos#1]);

    (format ["Asym IED Spawn at %1 | ATL %2", getPos _ied_obj, getPosATL _ied_obj]) remoteExec ["diag_log", 2];
    diag_log format ["Oselot - IEDS SPAWN: pos %1; atl %2", getpos _ied_obj, getposatl _ied_obj];

    if (KP_liberation_asymmetric_debug > 0) then {[format ["manage_asymIED.sqf -> IED %1 spawned at %2", _count, markerText _sector], "ASYMMETRIC"] remoteExecCall ["KPLIB_fnc_log", 2];};

    while {(_sector in KP_liberation_asymmetric_sectors) && (mineActive _ied_obj) && !_goes_boom} do {
        _nearinfantry = ((getpos _ied_obj) nearEntities ["Man", _activation_radius_infantry]) select {side _x == GRLIB_side_friendly};

        private _peopleOnTopForSomeReason = ((getpos _ied_obj) nearEntities ["Man", 1.6]) select {side _x == GRLIB_side_friendly};
        _nearvehicles = ((getpos _ied_obj) nearEntities [["Car", "Tank", "Air"], _activation_radius_vehicles]) select {side _x == GRLIB_side_friendly};
        if (count _nearinfantry >= _infantry_trigger || count _nearvehicles >= _vehicle_trigger || count _peopleOnTopForSomeReason >= 1) then {
            if (_ultra_strong) then {
                "ammo_Missile_Cruise_01" createVehicle (getpos _ied_obj);
                deleteVehicle _ied_obj;
            } else {
                _ied_obj setDamage 1;
            };
            stats_ieds_detonated = stats_ieds_detonated + 1; publicVariable "stats_ieds_detonated";
            _goes_boom = true;

            {

                private _shouldExplodeRandomly = (floor random 100) <= 2;
                if ((_x getvariable ["ace_iseod", false]) != true || (stance _x) != "PRONE" || _shouldExplodeRandomly) then {
                    _x setDamage 1;
                    _ied_obj setDamage 1;
                }
            } forEach _peopleOnTopForSomeReason;
        };
        sleep 1;
    };
} else {
    if (KP_liberation_asymmetric_debug > 0) then {[format ["manage_asymIED.sqf -> _roadobj is Null for IED %1 at %2", _count, markerText _sector], "ASYMMETRIC"] remoteExecCall ["KPLIB_fnc_log", 2];};
};

if ((KP_liberation_asymmetric_debug > 0) && !(isNull _roadobj)) then {[format ["manage_asymIED.sqf -> exit IED %1 loop at %2", _count, markerText _sector], "ASYMMETRIC"] remoteExecCall ["KPLIB_fnc_log", 2];};

sleep 60;

if (!(isNull _ied_obj)) then {deleteVehicle _ied_obj;};
