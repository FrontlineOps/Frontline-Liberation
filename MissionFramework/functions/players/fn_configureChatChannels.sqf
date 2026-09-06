/*
    Description:
        Disables configured vanilla text and voice channels for regular players.
        Arma keeps Global available to logged-in admins and the server host.
*/

if (!hasInterface) exitWith {false};

{
    _x enableChannel [false, false];
} forEach [0, 1, 2, 3, 4, 5, 6];

["Chat channels configured locally: Side text, vanilla VON and other configured text channels disabled", "CLIENT"] call KPLIB_fnc_log;

true
