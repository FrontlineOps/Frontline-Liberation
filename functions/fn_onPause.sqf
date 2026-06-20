/*---------------------------------------*\
 | Copyright © 2022 watergard.           |
 | All Rights Reserved.                  |
 | Usage: [] call KPLIB_fnc_setupVehicle |
\*---------------------------------------*/

private _ctrlAbort = findDisplay 49 displayCtrl 104;

_ctrlAbort ctrlremovealleventhandlers "buttonclick";
_ctrlAbort ctrladdeventhandler [ "buttonclick", "endmission 'endmission'; true" ];