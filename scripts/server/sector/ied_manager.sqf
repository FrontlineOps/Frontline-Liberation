params ["_sector", "_radius", "_number"];

if (_number <= 0) exitWith {};

if (KP_liberation_asymmetric_debug > 0) then {[format ["ied_manager.sqf for %1 spawned on: %2", markerText _sector, debug_source], "ASYMMETRIC"] remoteExecCall ["KPLIB_fnc_log", 2];};

_number = round _number;

private _activation_radius_infantry = 6.66;
private _activation_radius_vehicles = 10;

private _spread = 12;
private _infantry_trigger = 1 + (ceil (random 2));
private _ultra_strong = false;
if (random 100 < (abs KP_liberation_civ_rep)) then {
    _ultra_strong = true;
};
private _vehicle_trigger = 1;
private _ied_type = selectRandom ["IEDLandBig_F","ACE_IEDLandBig_Range", "IEDLandSmall_F", "ACE_IEDLandSmall_Range"];
private _ied_obj = objNull;
private _roadobj = [(markerPos _sector) getPos [random _radius, random 360], _radius, []] call BIS_fnc_nearestRoad;
private _goes_boom = false;
private _ied_marker = "";

if (KP_liberation_asymmetric_debug > 0) then {[format ["ied_manager.sqf -> spawning IED %1 at %2", _number, markerText _sector], "ASYMMETRIC"] remoteExecCall ["KPLIB_fnc_log", 2];};

if (_number > 0) then {
    [_sector, _radius, _number - 1] spawn ied_manager;
};

if (!(isnull _roadobj)) then {

    private _roadpos = getpos _roadobj;
    private _iedPos = _roadpos getPos [_spread, random 360];

    _iedPos set [2, 0];
    _ied_obj = createMine [_ied_type, _iedPos, [], 0];
    _ied_obj setdir (random 360);
    _ied_obj setVectorUp (surfaceNormal [_iedPos#0, _iedPos#1]);
    if (KP_liberation_asymmetric_debug > 0) then {
        (format ["IED Manager Spawn at %1 | ATL %2", getPos _ied_obj, getPosATL _ied_obj]) remoteExec ["diag_log", 2];
    };
    if (KP_liberation_asymmetric_debug > 0) then {[format ["ied_manager.sqf -> IED %1 spawned at %2", _number, markerText _sector], "ASYMMETRIC"] remoteExecCall ["KPLIB_fnc_log", 2];};

    while {_sector in active_sectors && mineActive _ied_obj && !_goes_boom} do {
        private _nearbyFriendlies = ((getPos _ied_obj) nearEntities [["Man", "Car", "Tank", "Air"], _activation_radius_vehicles]) select {
            side _x == GRLIB_side_friendly
        };
        private _nearInfantry = _nearbyFriendlies select {
            _x isKindOf "Man" && {_x distance _ied_obj <= _activation_radius_infantry}
        };
        private _peopleOnTopForSomeReason = _nearInfantry select {_x distance _ied_obj <= 1.6};
        private _nearVehicles = _nearbyFriendlies select {!(_x isKindOf "Man")};
        if (count _nearInfantry >= _infantry_trigger || count _nearVehicles >= _vehicle_trigger || count _peopleOnTopForSomeReason >= 1) then {
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
    if (KP_liberation_asymmetric_debug > 0) then {[format ["ied_manager.sqf -> _roadobj is Null for IED %1 at %2", _number, markerText _sector], "ASYMMETRIC"] remoteExecCall ["KPLIB_fnc_log", 2];};
};

if ((KP_liberation_asymmetric_debug > 0) && !(isNull _roadobj)) then {[format ["ied_manager.sqf -> exited IED %1 loop at %2", _number, markerText _sector], "ASYMMETRIC"] remoteExecCall ["KPLIB_fnc_log", 2];};

sleep 1800;

if (!(isNull _ied_obj)) then {deleteVehicle _ied_obj;};
