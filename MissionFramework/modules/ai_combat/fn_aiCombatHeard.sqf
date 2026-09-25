/* Newest gunfire any member of a group heard within the age limit:
   [estimate, heardAt, listener], or [] when none. Shared by every group-level
   response (investigation, ambushes, reconnaissance) instead of each scanning
   the perception registry itself. */
params ["_group", "_maxAge"];
private _registry = localNamespace getVariable ["KPLIB_aiCombat_registry", createHashMap];
private _newest = [];
{
    private _heard = (_registry getOrDefault [netId _x, createHashMap]) getOrDefault ["heard", []];
    if (_heard isNotEqualTo [] && {CBA_missionTime - (_heard select 1) <= _maxAge} && {_newest isEqualTo [] || {(_heard select 1) > (_newest select 1)}}) then {
        _newest = [_heard select 0, _heard select 1, _x];
    };
} forEach units _group;
_newest
