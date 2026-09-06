/*
 * Author: jokoho482
 * Adapted from LAMBS Danger.fsm.
 * Source: addons/main/functions/fnc_isAlive.sqf
 * Upstream commit: 63122df5d9403a52f10bf50198ac75a49f0a3d6b
 * Adapted 2026-08-27 for the KPLIB namespace.
 * License: see NOTICE.md and LICENSE.LAMBS in this directory.
 */

alive _this && {(lifeState _this) isNotEqualTo "INCAPACITATED"}
