/*
    File: fn_getNearestOpforSector.sqf
    Author: watergard
    Date: 2023-04-19
    Last Update: 2023-04-19

    Description:
        Gets the marker of the nearest sector from given position inside given radius.

    Parameter(s):
        _radius - Radius in which to look for the nearest sector    [NUMBER, defaults to 1000]
        _pos    - Position to look from for the nearest sector      [POSITION, defaults to getPos player]

    Returns:
        Marker of nearest sector [STRING]
*/

params [
    ["_radius", 1000, [0]],
    ["_pos", getPos player, [[]], [2, 3]]
];

private _opforSectors = sectors_allSectors - blufor_sectors;

private _sectors = _opforSectors select {((markerPos _x) distance2d _pos) < _radius}; 
 
if (_sectors isEqualTo []) exitWith {""}; 
 
_sectors = _sectors apply {[(markerPos _x) distance2d _pos, _x]}; 
_sectors sort true; 
 
(_sectors select 0) select 1