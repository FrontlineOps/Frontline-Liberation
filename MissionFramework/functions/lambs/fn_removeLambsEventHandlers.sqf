/*
 * Adapted from LAMBS Danger.fsm by nkenny.
 * Source: addons/main/functions/fnc_removeEventhandlers.sqf
 * Upstream commit: 63122df5d9403a52f10bf50198ac75a49f0a3d6b
 * Adapted 2026-08-27 for the KPLIB namespace.
 * License: see NOTICE.md and LICENSE.LAMBS in this directory.
 */
params ["_unit", "_eventHandlers"];

{
    _unit removeEventHandler _x;
} forEach _eventHandlers;
