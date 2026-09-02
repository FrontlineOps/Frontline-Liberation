/*
    Description:
        Restricts vanilla communication to Side text for regular players.
        Arma keeps Global available to logged-in admins and the server host.
*/

if (!hasInterface) exitWith {false};

{
    _x enableChannel [false, false];
} forEach [0, 1, 2, 3, 4, 5, 6];

1 enableChannel [true, false];

["Chat channels configured locally: Side text enabled; vanilla VON and other configured text channels disabled", "CLIENT"] call KPLIB_fnc_log;

true
