/* Plain text, never parseText: received diagnostic labels cannot inject UI
   markup. Controls belong to the Zeus display and disappear when it closes. */
if (!hasInterface) exitWith {};
params ["_key", "_text", "_top", "_height"];
disableSerialization;
private _display = findDisplay 312;
if (isNull _display) exitWith {};
private _control = uiNamespace getVariable [_key, controlNull];
if (isNull _control && {_text != ""}) then {
    _control = _display ctrlCreate ["KPLIB_MunitionsOverlay", -1];
    _control ctrlSetPosition [safezoneX + 0.22 * safezoneW, safezoneY + _top * safezoneH, 0.56 * safezoneW, _height * safezoneH];
    _control ctrlEnable false;
    _control ctrlCommit 0;
    uiNamespace setVariable [_key, _control];
};
if (isNull _control) exitWith {};
_control ctrlShow (_text != "");
if (ctrlText _control != _text) then {_control ctrlSetText _text};
