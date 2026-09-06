while {true} do {
    private _desiredMultiplier = [
        GRLIB_time_factor,
        GRLIB_time_factor * 4
    ] select (GRLIB_shorter_nights && {daytime > 20 || daytime < 4});

    if (timeMultiplier != _desiredMultiplier) then {
        setTimeMultiplier _desiredMultiplier;
    };
    sleep 10;
};
