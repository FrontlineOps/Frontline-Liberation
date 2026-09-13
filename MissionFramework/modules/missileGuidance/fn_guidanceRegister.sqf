/* CBA Fired/FiredMan and ProjectileCreated converge here; never a network endpoint. */
params [["_projectile", objNull, [objNull]], ["_shooter", objNull, [objNull]], ["_carrier", objNull, [objNull]], ["_weapon", "", [""]]];
if (isRemoteExecuted || {isNull _projectile}) exitWith {};
private _profile = [typeOf _projectile] call KPLIB_fnc_guidanceResolve;
if ((_profile get "family") == "COUNTERMEASURE") exitWith {
    if (_projectile getVariable ["KPLIB_guidanceCM", false]) exitWith {};
    _projectile setVariable ["KPLIB_guidanceCM", true];
    private _list = localNamespace getVariable ["KPLIB_guidanceCountermeasures", []];
    _list = _list select {!isNull (_x select 0) && {CBA_missionTime < (_x select 1)}};
    _list pushBack [_projectile, CBA_missionTime + ((_profile get "life") min 60), _profile get "lock"];
    private _limit = missionNamespace getVariable ["KPLIB_guidance_max_countermeasures", 512];
    if (count _list > _limit) then {_list deleteRange [0, count _list - _limit]};
    localNamespace setVariable ["KPLIB_guidanceCountermeasures", _list];
};
if (!local _projectile) exitWith {};
if ((_profile get "family") == "BALLISTIC") exitWith {};
if (!isNull _shooter) then {_projectile setVariable ["KPLIB_guidanceShooter", _shooter]};
if (!isNull _carrier) then {_projectile setVariable ["KPLIB_guidanceCarrier", _carrier]};
if (_weapon != "") then {_projectile setVariable ["KPLIB_guidanceWeapon", _weapon]};
if (_projectile getVariable ["KPLIB_guidanceQueued", false] || {_projectile getVariable ["KPLIB_guidanceOwner", ""] != ""}) exitWith {};
_projectile setVariable ["KPLIB_guidanceQueued", true];
// Fired callbacks and addon initialization finish before controller selection.
[{_this call KPLIB_fnc_guidanceStart}, [_projectile]] call CBA_fnc_execNextFrame;
