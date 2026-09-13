if (isRemoteExecuted || {localNamespace getVariable ["KPLIB_blastTraumaReady", false]}) exitWith {};
localNamespace setVariable ["KPLIB_blastTraumaReady", true];
localNamespace setVariable ["KPLIB_blastTraumaStates", createHashMap];
localNamespace setVariable ["KPLIB_blastTraumaLocalUnits", []];
localNamespace setVariable ["KPLIB_blastTraumaSway", 1];
// ACM uses this same ACE healing event and additive sway interface in 1.4.8.
// Never write its knockout, oxygen, airway or evacuation variables.
["ace_medical_treatment_fullHealLocalMod", {
    params ["_unit"];
    if (local _unit) then {
        private _KPLIB_blastTraumaHealContext = true;
        [_unit] call KPLIB_fnc_blastTraumaReset;
    };
}] call CBA_fnc_addEventHandler;
["CAManBase", "Respawn", {
    params ["_unit"];
    _unit setVariable ["KPLIB_blastTraumaLocal", []];
    _unit setVariable ["KPLIB_blastTraumaHealed", CBA_missionTime];
}] call CBA_fnc_addClassEventHandler;
if (hasInterface && {!isNil "ace_common_fnc_addSwayFactor"}) then {
    ["multiplier", {localNamespace getVariable ["KPLIB_blastTraumaSway", 1]}, "frontline_blast"] call ace_common_fnc_addSwayFactor;
    localNamespace setVariable ["KPLIB_blastTraumaBlur", ppEffectCreate ["DynamicBlur", 1785]];
};
localNamespace setVariable ["KPLIB_blastTraumaPFH", [{
    private _KPLIB_blastTraumaServerContext = true;
    [] call KPLIB_fnc_blastTraumaTick;
}, 0.25] call CBA_fnc_addPerFrameHandler];
addMissionEventHandler [["Ended", "MPEnded"] select isMultiplayer, {
    [localNamespace getVariable ["KPLIB_blastTraumaPFH", -1]] call CBA_fnc_removePerFrameHandler;
    localNamespace setVariable ["KPLIB_blastTraumaSway", 1];
    if (hasInterface && {!isNil "ace_common_fnc_setHearingCapability"}) then {
        ["frontline_blast", 1, false, 0] call ace_common_fnc_setHearingCapability;
    };
    private _blur = localNamespace getVariable ["KPLIB_blastTraumaBlur", -1];
    if (_blur >= 0) then {ppEffectDestroy _blur};
    {deleteVehicle _x} forEach (localNamespace getVariable ["KPLIB_gasDustEmitters", []]);
}];

