params [["_building", objNull, [objNull]]];
if (isNull _building) exitWith {};

dorepackage = 0;
if !(createDialog "liberation_repackage_fob") exitWith {};
waitUntil {sleep 0.1; !dialog || {!alive player} || {dorepackage != 0}};

if (alive player && {dorepackage in [1, 2]}) then {
    private _selection = dorepackage;
    closeDialog 0;
    [_building, player, _selection] remoteExec ["KPLIB_fnc_repackageFob", 2];
};
