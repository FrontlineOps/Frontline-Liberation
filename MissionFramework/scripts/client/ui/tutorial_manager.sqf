// Interface-local field guide. Keep the intro's howtoplay handshake; field
// openings never start a cinematic camera or change the player's position.
if (!hasInterface) exitWith {};
disableSerialization;

if (isNil "howtoplay") then {howtoplay = 0;};
private _getPages = compileFinal preprocessFileLineNumbers "scripts\client\ui\tutorial_pages.sqf";

private _renderPage = {
    params ["_display", "_index"];
    if (isNull _display) exitWith {};
    private _pages = _display getVariable ["KPLIB_tutorial_pages", []];
    if (_index < 0 || {_index >= count _pages}) exitWith {};

    (_pages select _index) params ["_title", "_body"];
    (_display displayCtrl 514) ctrlSetText _title;
    private _text = _display displayCtrl 515;
    _text ctrlSetStructuredText parseText _body;
    private _position = ctrlPosition _text;
    _position set [3, ctrlTextHeight _text + 0.025 * safezoneH];
    _text ctrlSetPosition _position;
    _text ctrlCommit 0;
    (_display displayCtrl 516) ctrlSetScrollValues [0, 0];

    (_display displayCtrl 517) ctrlSetText format [localize "STR_TUTO_PAGE", _index + 1, count _pages];
    (_display displayCtrl 518) ctrlEnable (_index > 0);
    (_display displayCtrl 519) ctrlEnable (_index < count _pages - 1);
    _display setVariable ["KPLIB_tutorial_page", _index];
    uiNamespace setVariable ["KPLIB_tutorial_lastPage", _index];
};

while {true} do {
    waitUntil {uiSleep 0.3; howtoplay == 1};
    // The intro closes its menu after setting the request flag.
    waitUntil {uiSleep 0.1; !dialog || {howtoplay == 0}};
    if (howtoplay == 1) then {
        private _introCamera = missionNamespace getVariable ["cinematic_camera_started", false];
        if (createDialog "liberation_tutorial") then {
            private _display = findDisplay 5353;
            private _pages = call _getPages;
            private _list = _display displayCtrl 513;
            _display setVariable ["KPLIB_tutorial_pages", _pages];
            _display setVariable ["KPLIB_tutorial_render", _renderPage];

            {
                _list lbAdd format ["%1. %2", _forEachIndex + 1, _x select 0];
            } forEach _pages;

            [_list, "LBSelChanged", {
                params ["_control", "_index"];
                private _display = ctrlParent _control;
                [_display, _index] call (_display getVariable "KPLIB_tutorial_render");
            }] call CBA_fnc_addBISEventHandler;
            [_display displayCtrl 518, "ButtonClick", {
                private _list = (ctrlParent (_this select 0)) displayCtrl 513;
                _list lbSetCurSel ((lbCurSel _list - 1) max 0);
            }] call CBA_fnc_addBISEventHandler;
            [_display displayCtrl 519, "ButtonClick", {
                private _list = (ctrlParent (_this select 0)) displayCtrl 513;
                _list lbSetCurSel ((lbCurSel _list + 1) min (lbSize _list - 1));
            }] call CBA_fnc_addBISEventHandler;
            [_display, "Unload", {howtoplay = 0;}] call CBA_fnc_addBISEventHandler;

            // Always render on opening, including reopening the same chapter.
            private _lastPage = uiNamespace getVariable ["KPLIB_tutorial_lastPage", 0];
            _list lbSetCurSel (_lastPage min (count _pages - 1));
            ["Frontline field guide opened", "TUTORIAL"] call KPLIB_fnc_log;
            waitUntil {
                uiSleep 0.2;
                isNull _display || {howtoplay == 0} || {!alive player}
            };
            if (!isNull _display) then {_display closeDisplay 0;};
        } else {
            ["Unable to open Frontline field guide", "TUTORIAL"] call KPLIB_fnc_log;
        };

        if (_introCamera) then {cinematic_camera_started = false;};
        howtoplay = 0;
    };
};
