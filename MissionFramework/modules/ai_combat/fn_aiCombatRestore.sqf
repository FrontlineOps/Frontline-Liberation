/* Only the authoritative server may release its AI controls on a new owner.
   This also restores AI flags after Zeus possession without ordering a player. */
params [["_unit", objNull, [objNull]], ["_flags", [], [[]]], ["_original", [], [[]]], ["_stance", "", [""]]];
if (isRemoteExecuted) then {
    if (remoteExecutedOwner != 2) exitWith {_unit = objNull};
} else {
    if (!isServer) exitWith {_unit = objNull};
};
if (isNull _unit || {!local _unit} || {!(_unit isKindOf "CAManBase")}) exitWith {};
if (count _flags != 3 || {_flags findIf {!(_x isEqualType true)} >= 0}) exitWith {};
{
    if (_flags select _forEachIndex) then {_unit enableAI _x};
} forEach ["AUTOTARGET", "FSM", "FIREWEAPON"];
if (isPlayer _unit || {!isNull remoteControlled _unit}) exitWith {};
if (_stance != "" && {toUpper _stance in ["UP", "MIDDLE", "DOWN", "AUTO"]}
    && {toUpper unitPos _unit == "MIDDLE"}) then {_unit setUnitPos _stance};
_unit doWatch objNull;
_unit doFire objNull;
_unit doTarget objNull;
if (alive _unit && {isNull objectParent _unit} && {count _original == 3}
    && {_original findIf {!(_x isEqualType "")} < 0}
    && {(_original select 0) in weapons _unit}) then {_unit selectWeapon _original};
