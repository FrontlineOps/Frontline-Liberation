params [["_missile", objNull, [objNull]], ["_target", objNull, [objNull]], ["_display", false, [true]]];
if (_display) exitWith {
    if (!hasInterface || {isRemoteExecuted && {remoteExecutedOwner != 2}}
        || {isNull _target} || {vehicle player != _target}) exitWith {};
    if !(missionNamespace getVariable ["KPLIB_guidance_warnings", true]) exitWith {};
    private _next = localNamespace getVariable ["KPLIB_guidanceWarningAt", -1];
    if (CBA_missionTime < _next) exitWith {};
    localNamespace setVariable ["KPLIB_guidanceWarningAt", CBA_missionTime + 2];
    private _sound = getArray (configOf _target >> "soundLocked");
    if (count _sound >= 3 && {(_sound select 0) isEqualType ""} && {_sound select 0 != ""}) then {
        playSoundUI [_sound select 0, _sound select 1, _sound select 2];
    };
};
if (!isServer || {isNull _missile} || {isNull _target} || {!alive _missile} || {!alive _target}
    || {!(_target isKindOf "Air")}) exitWith {};
if (isRemoteExecuted && {remoteExecutedOwner != owner _missile}) exitWith {};
if (CBA_missionTime < (_target getVariable ["KPLIB_guidanceWarningAt", -1])) exitWith {};
private _profile = [typeOf _missile] call KPLIB_fnc_guidanceResolve;
if (!((_profile get "family") in ["ARH", "SARH", "RADIO"])) exitWith {};
private _mask = getNumber (configOf _target >> "lockDetectionSystem");
if (isText (configOf _target >> "lockDetectionSystem")) then {
    _mask = 0;
    {_mask = _mask + parseNumber _x} forEach ((getText (configOf _target >> "lockDetectionSystem")) splitString "+ ");
};
if (floor (_mask / 8) mod 2 != 1) exitWith {};
if (_missile distance _target > (_profile get "range")) exitWith {};
if ((vectorDir _missile) vectorDotProduct ((getPosASL _missile) vectorFromTo (aimPos _target)) < cos (_profile get "gimbal")) exitWith {};
if (!([getPosASL _missile, aimPos _target, _missile, _target] call KPLIB_fnc_guidanceVisible)) exitWith {};
_target setVariable ["KPLIB_guidanceWarningAt", CBA_missionTime + 2];
private _owners = [];
{if (isPlayer _x) then {_owners pushBackUnique owner _x}} forEach crew _target;
{[_missile, _target, true] remoteExecCall ["KPLIB_fnc_guidanceReceive", _x]} forEach _owners;
