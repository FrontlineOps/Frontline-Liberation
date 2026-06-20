params [
    ["_vehicle", objNull, []]
];

private _aliveCrew = [];
waitUntil {
	sleep 5;

	_aliveCrew = [];
	{
		if ((alive _x)) then {
			_aliveCrew pushBack _x;
		};
	} forEach crew _vehicle;
	!(alive _vehicle) ||
	((count (_aliveCrew)) <= 1)
};


if ((count _aliveCrew) <= 1 && alive _vehicle) then {

	(group _vehicle) leaveVehicle _vehicle;
	{unassignVehicle _vehicle} forEach (_aliveCrew);
    (_aliveCrew) allowGetIn false;
};