if (!isServer || {isRemoteExecuted}) exitWith {};
private _weatherModes = [
    [0.25],
    [0, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.55],
    [0, 0.1, 0.15, 0.2, 0.25, 0.3, 0.325, 0.35, 0.375, 0.4, 0.425, 0.45, 0.475, 0.5, 0.525, 0.55, 0.575, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 1]
];

private _mode = GRLIB_weather_param;
private _newWeather = selectRandom (_weatherModes select (_mode - 1));
0 setOvercast _newWeather;
forceWeatherChange;

[format ["Set initial weather to: %1 - Param Value: %2 - Time: %3", _newWeather, GRLIB_weather_param, diag_tickTime], "WEATHER"] call KPLIB_fnc_log;

while {GRLIB_endgame == 0} do {
    _mode = GRLIB_weather_param;
    _newWeather = selectRandom (_weatherModes select (_mode - 1));
    (3600 * timeMultiplier) setOvercast _newWeather;
    [format ["Set next weather transition to: %1 - Time: %2", _newWeather, diag_tickTime], "WEATHER"] call KPLIB_fnc_log;
    private _next = diag_tickTime + 3000;
    waitUntil {
        sleep 5;
        GRLIB_endgame != 0 || {GRLIB_weather_param != _mode} || {diag_tickTime >= _next}
    };
};
