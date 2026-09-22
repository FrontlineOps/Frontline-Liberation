// Stay available when vanilla fog is initially enabled or toggled back on.
while {GRLIB_endgame == 0} do {
    if (!KP_liberation_fog_param) then {5 setFog [0, 0, 0]};
    sleep 30;
};
