# Vendored LAMBS Danger.fsm code

The following mission functions contain code adapted from LAMBS Danger.fsm by Ken Rune Mikkelsen (`nkenny`):

- `fn_garrison.sqf`, from `addons/wp/functions/fnc_taskGarrison.sqf`
- `fn_taskPatrol.sqf`, from `addons/wp/functions/fnc_taskPatrol.sqf`
- `fn_taskPatrolWaypointStatement.sqf`, extracted from `addons/wp/functions/fnc_taskPatrol.sqf`
- `fn_hunt.sqf`, from `addons/wp/functions/fnc_taskHunt.sqf`
- `fn_rush.sqf`, from `addons/wp/functions/fnc_taskRush.sqf`
- `fn_taskReset.sqf`, from `addons/wp/functions/fnc_taskReset.sqf`
- `fn_findClosestTarget.sqf`, from `addons/main/functions/fnc_findClosestTarget.sqf`
- `fn_findBuildings.sqf`, from `addons/main/functions/fnc_findBuildings.sqf`
- `fn_doUgl.sqf`, from `addons/main/functions/UnitAction/fnc_doUGL.sqf`
- `fn_checkMagazineAiUsageFlags.sqf`, from `addons/main/functions/fnc_checkMagazineAiUsageFlags.sqf`
- `fn_doAnimation.sqf`, from `addons/main/functions/fnc_doAnimation.sqf`
- `fn_getLauncherUnits.sqf`, from `addons/main/functions/fnc_getLauncherUnits.sqf`
- `fn_isAlive.sqf`, from `addons/main/functions/fnc_isAlive.sqf`
- `fn_isIndoor.sqf`, from `addons/main/functions/fnc_isIndoor.sqf`
- `fn_removeLambsEventHandlers.sqf`, from `addons/main/functions/fnc_removeEventhandlers.sqf`

The sources were taken from upstream commit `63122df5d9403a52f10bf50198ac75a49f0a3d6b` and adapted on 2026-08-27. The adaptations replace addon macros and function names with mission-local `KPLIB_fnc_*` names, isolate internal state variables, replace addon-only animation events with mission remote execution, remove debug-only hooks, and make the documented random garrison exit condition the default.

Upstream project: <https://github.com/nk3nny/LambsDanger>

These adapted files remain subject to the LAMBS license in `LICENSE.LAMBS`. In addition to GPL version 2, the upstream license prohibits use or distribution on monetized servers or communities, prohibits upload of the software or derivatives to the Steam Workshop, and requires modified or derivative source to remain open source.
