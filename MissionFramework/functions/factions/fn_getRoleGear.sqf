/* BLUFOR gear policy shared by virtual arsenals and manual field checks. */
params [["_unit", objNull, [objNull]]];
if (isNull _unit || {side group _unit != GRLIB_side_friendly}) exitWith {[]};
if !(localNamespace getVariable ["KPLIB_manualFactions", false]) exitWith {
    +(missionNamespace getVariable ["KPLIB_autoFactionPlayerArsenal", []])
};
([_unit] call KPLIB_fnc_getPlayerRole) params ["_sideKey", "_role"];
private _profile = (localNamespace getVariable "KPLIB_factionProfiles") get _sideKey;
+(((_profile get "roles") getOrDefault [_role, createHashMap]) getOrDefault ["allowed", []])
