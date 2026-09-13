/* Inserted before ACE's terminal wound handler, never a HandleDamage EH.
   Other handlers, body selections and armor processing remain in their pipeline. */
if (isRemoteExecuted) exitWith {_this};
params ["_unit", "_damages", "_kind", ["_ammo", ""]];
if (!local _unit || {localNamespace getVariable ["KPLIB_blastApplying", false]}) exitWith {_this};
private _thermal = _kind in ["burn", "burning"];
private _helper = (toLower _ammo) find "ace_explosion_reflection_" == 0 || {_ammo == "vehiclehit"};
if (!_thermal && {!_helper} && {!(([ _ammo ] call KPLIB_fnc_blastProfile) get "eligible")}) exitWith {_this};
private _parts = ["head", "body", "leftarm", "rightarm", "leftleg", "rightleg"];
private _amount = [0,0,0,0,0,0];
{
    private _index = _parts find toLower (_x select 1);
    if (_index >= 0) then {_amount set [_index, (_amount select _index) + ((_x select 0) max 0)]};
} forEach _damages;
private _ledger = _unit getVariable ["KPLIB_blastLedger", createHashMap];
private _result = [_ledger, "NATIVE", [_ammo, "burn"] select _thermal, _amount, CBA_missionTime] call KPLIB_fnc_blastAccount;
_unit setVariable ["KPLIB_blastLedger", _ledger];
private _forwarded = _result select 0;
[_unit, "NATIVE", "ACE ACCOUNTING", [_ammo, _kind, "input", _amount, "credited", _result select 1, "forwarded", _forwarded]] call KPLIB_fnc_blastTrace;
private _adjusted = [];
{
    private _row = +_x;
    private _index = _parts find toLower (_row select 1);
    if (_index >= 0 && {_amount select _index > 0}) then {
        private _scale = (_forwarded select _index) / (_amount select _index);
        _row set [0, (_row select 0) * _scale];
        if (count _row > 2) then {_row set [2, (_row select 2) * _scale]};
    };
    _adjusted pushBack _row;
} forEach _damages;
if (_forwarded isNotEqualTo _amount) then {
    [objNull, "BLAST CREDIT (late native)", getPosASL _unit, [_ammo, _amount, _forwarded], _unit] call KPLIB_fnc_munitionsEvent;
};
[_unit, _adjusted, _kind, _ammo]
