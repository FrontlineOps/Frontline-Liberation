// Generated starter data used only by AUTO respawn/enforcement paths.
RA_FullArsenal = +(missionNamespace getVariable ["KPLIB_autoFactionPlayerArsenal", []]);
RA_AllAmmoTypes = +((missionNamespace getVariable ["KPLIB_autoFactionPlayerArsenalData", createHashMap]) getOrDefault ["magazines", []]);
RA_StartingUniforms = +(missionNamespace getVariable ["KPLIB_autoFactionPlayerUniforms", []]);
RA_StartingHeadwear = +(missionNamespace getVariable ["KPLIB_autoFactionPlayerHeadgear", []]);
RA_StartingGoggles = +(missionNamespace getVariable ["KPLIB_autoFactionPlayerGoggles", []]);
RA_StartingItems = +(missionNamespace getVariable ["KPLIB_autoFactionPlayerStartingItems", []]);

if (KP_liberation_faction_source == "AUTO" && {RA_FullArsenal isEqualTo [] || {RA_StartingUniforms isEqualTo []}}) then {
    private _message = "Generated BLUFOR arsenal or starting uniforms are empty; automatic faction initialization cannot continue";
    [_message, "FACTIONS"] call KPLIB_fnc_log;
    throw _message;
};
