/*
    Description:
        Disables configured vanilla text and voice channels for regular players.
        Keeps Side map markers and drawing enabled (Arma 3 2.22+).
        Arma keeps Global available to logged-in admins and the server host.
*/

if (!hasInterface) exitWith {false};

{
    _x enableChannel [false, false];
} forEach [0, 1, 2, 3, 4, 5, 6];

// Side: text chat, voice chat, map markers, map drawing.
1 enableChannel [false, false, true, true];

["Chat channels configured locally: Side markers/drawing enabled; Side text, vanilla VON and other configured text channels disabled", "CLIENT"] call KPLIB_fnc_log;

true
