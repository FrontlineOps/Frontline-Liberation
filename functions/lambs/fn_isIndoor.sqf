/*
 * Adapted from LAMBS Danger.fsm by nkenny.
 * Source: addons/main/functions/fnc_isIndoor.sqf
 * Upstream commit: 63122df5d9403a52f10bf50198ac75a49f0a3d6b
 * Adapted 2026-08-27 for the KPLIB namespace.
 * License: see NOTICE.md and LICENSE.LAMBS in this directory.
 */
params ["_unit"];

private _trace = lineIntersectsSurfaces [
    eyePos _unit,
    eyePos _unit vectorAdd [0, 0, 10],
    _unit,
    objNull,
    true,
    -1,
    "GEOM",
    "NONE",
    true
];

if (_trace isEqualTo []) exitWith {false};

_trace findIf {_x select 3 isKindOf "Building"} != -1
