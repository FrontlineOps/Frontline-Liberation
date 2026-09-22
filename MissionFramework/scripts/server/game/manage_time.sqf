if (!isServer || {isRemoteExecuted}) exitWith {};
// Settings edits apply immediately in settingsApply. This single worker handles
// crossing 20:00/04:00 and keeps the engine on the active CBA configuration.
while {true} do {
    private _desiredMultiplier = GRLIB_time_factor * ([1, 4] select (GRLIB_shorter_nights && {daytime >= 20 || {daytime < 4}}));
    if (timeMultiplier != _desiredMultiplier) then {
        setTimeMultiplier _desiredMultiplier;
    };
    sleep 10;
};
