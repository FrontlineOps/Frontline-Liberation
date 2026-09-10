// Build display-only text from the current mission settings on each opening.
// Each row pairs a chapter number with its localized text's format arguments.
private _victory = localize format ["STR_PARAMS_VICTORYCONDITION_%1", KP_liberation_victoryCondition];
private _vehiclePolicy = localize (if (KP_liberation_allow_fob_vehcile_building) then {
    "STR_TUTO_VEHICLES_FOBS"
} else {
    if (KP_liberation_allow_fixedwing_at_fobs) then {"STR_TUTO_VEHICLES_PLANES"} else {"STR_TUTO_VEHICLES_BASE"}
});

private _chapters = [
    [1, [_victory]],
    [2, []],
    [3, [GRLIB_capture_size, 2 max ceil ((call KPLIB_fnc_getPlayerCount) * 0.15)]],
    [4, []],
    [5, [round (BATTLESPACE_STRATEGIC_OFFMAP_REGEN_RATIO * 100), round (BATTLESPACE_STRATEGIC_OFFMAP_REGEN_INTERVAL / 60)]],
    [6, [round ((KPLIB_radio_intercept_interval select 0) / 60), round ((KPLIB_radio_intercept_interval select 1) / 60), round (KPLIB_radio_disruption_duration / 60), KPLIB_radio_disruption_multiplier]],
    [7, []],
    [8, [KPLIB_intelligence_interaction_distance, KPLIB_intelligence_interrogation_duration, round (KPLIB_intelligence_task_chance * 100)]],
    [9, [round (KPLIB_intelligence_stock_loss * 100), round (KPLIB_intelligence_disruption_duration / 60)]],
    [10, []],
    [11, []],
    [12, [round (GRLIB_fob_range * 0.8), _vehiclePolicy]],
    [13, [KPLIB_COPS_MAX, KPLIB_COPS_MIN_FOB_DISTANCE, KPLIB_COPS_MIN_HOSTILE_SECTOR_DISTANCE, round (KPLIB_COPS_DISMANTLE_COOLDOWN / 60), KPLIB_COPS_REDEPLOY_RADIUS]],
    [14, []],
    [15, []],
    [16, []]
];

_chapters apply {
    _x params ["_number", "_arguments"];
    [
        localize format ["STR_TUTO_TITLE%1", _number],
        format ([localize format ["STR_TUTO_TEXT%1", _number]] + _arguments)
    ]
}