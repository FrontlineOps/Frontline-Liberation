private [ "_huronlocal" ];

"huronmarker" setMarkerTextLocal "Potato 01";

while { true } do {
    "huronmarker" setMarkerAlphaLocal ([0, 1] select KP_liberation_mapmarkers);
    _huronlocal = if (KP_liberation_mapmarkers) then {[] call KPLIB_fnc_potatoScan} else {objNull};
    if ( !( isNull _huronlocal) ) then {
        "huronmarker" setmarkerposlocal (getpos _huronlocal);
    } else {
        "huronmarker" setmarkerposlocal markers_reset;
    };
    sleep 4.9;
};
