waitUntil {!isNil "save_is_loaded" && {save_is_loaded}};

while {true} do {
    if ((count blufor_sectors) >= ((count sectors_allSectors) * 0.6)) then {
        if (combat_readiness > 0) then {
            combat_readiness = combat_readiness - round(random(2));
        };
    } else {
        if (
            (combat_readiness < ((count blufor_sectors) * 2) && combat_readiness < 35)
            || (combat_readiness < ((count blufor_sectors) * 1.25) && combat_readiness < 60)
        ) then {
            combat_readiness = combat_readiness + 0.25;
            stats_readiness_earned = stats_readiness_earned + 0.25;
        };
    };
    sleep (600 + random (600));
};
