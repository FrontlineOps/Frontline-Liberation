if (!isServer) exitWith {};
// Settings apply clock edits immediately; this existing loop handles the
// day/night boundary and remains the authoritative clock owner.
while {true} do {
    private _desiredMultiplier = GRLIB_time_factor * ([1, 4] select (GRLIB_shorter_nights && {daytime >= 20 || daytime < 4}));

    if (timeMultiplier != _desiredMultiplier) then {
        setTimeMultiplier _desiredMultiplier;
    };
    sleep 10;
};
