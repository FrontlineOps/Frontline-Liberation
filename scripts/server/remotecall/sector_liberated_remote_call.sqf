params ["_liberated_sector"];

private _combat_readiness_increase = 0;
switch (true) do {
    case (_liberated_sector in sectors_bigtown):    {_combat_readiness_increase = floor (random 10) * GRLIB_difficulty_modifier;};
    case (_liberated_sector in sectors_capture):    {_combat_readiness_increase = floor (random 6) * GRLIB_difficulty_modifier;};
    case (_liberated_sector in sectors_military):   {_combat_readiness_increase = 5 + (floor (random 11)) * GRLIB_difficulty_modifier;};
    case (_liberated_sector in sectors_factory):    {_combat_readiness_increase = 3 + (floor (random 7)) * GRLIB_difficulty_modifier;};
    case (_liberated_sector in sectors_tower):      {_combat_readiness_increase = 5 + (floor (random 3)) * GRLIB_difficulty_modifier;};
};



combat_readiness = combat_readiness + _combat_readiness_increase;
combat_readiness = 150 min combat_readiness;
stats_readiness_earned = stats_readiness_earned + _combat_readiness_increase;

[_liberated_sector, 0] remoteExecCall ["remote_call_sector"];


if(_liberated_sector in sectors_military) then {
    if( isNil "blufor_military_sectors") then {
        blufor_military_sectors = [];
    };

    blufor_military_sectors pushback _liberated_sector; publicVariable "blufor_military_sectors";
};
blufor_sectors pushback _liberated_sector;
publicVariable "blufor_sectors";
sector_to_blufor = createHashMap;
{
    sector_to_blufor set [_x, true];
} forEach blufor_sectors;
last_blufor_sector_change = CBA_missionTime;
stats_sectors_liberated = stats_sectors_liberated + 1;

reset_battlegroups_ai = true; publicVariable "reset_battlegroups_ai";

if (_liberated_sector in sectors_factory) then {
    {
        if (_liberated_sector in _x) exitWith {KP_liberation_production = KP_liberation_production - [_x];};
    } forEach KP_liberation_production;

    private _sectorFacilities = (KP_liberation_production_markers select {_liberated_sector == (_x select 0)}) select 0;
    KP_liberation_production pushBack [
        markerText _liberated_sector,
        _liberated_sector,
        1,
        [],
        _sectorFacilities select 1,
        _sectorFacilities select 2,
        _sectorFacilities select 3,
        3,
        [] call KC_DETERMINE_PRODUCTION_INTERVAL,
        0,
        0,
        0
    ];
};

[_liberated_sector] spawn F_cr_liberatedSector;

if ((random 100) <= KP_liberation_cr_wounded_chance || (count blufor_sectors) == 1) then {
    [_liberated_sector] spawn civrep_wounded_civs;
};

[] spawn check_victory_conditions;

sleep 1;

[] spawn KPLIB_fnc_doSave;
