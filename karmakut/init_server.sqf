[] call compileFinal preProcessFileLineNumbers "karmakut\deployable_field_hospitals\server\init.sqf";
[] call compileFinal preProcessFileLineNumbers "karmakut\trash_cleanup\server\init.sqf";

// GLOBAL BYPASS VARIABLE FOR ENFORCED ARSENAL - NETWORKED
missionNamespace setVariable ["BYPASS_ENFORCED_ARSENAL", false, true];