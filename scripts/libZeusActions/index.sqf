
[] call compileFinal preprocessFile "scripts\libZeusActions\shared\index.sqf";
if (isServer) then {
	[] call compileFinal preprocessFile "scripts\libZeusActions\server\index.sqf";
};

if (hasInterface) then {
	[] call compileFinal preprocessFile "scripts\libZeusActions\client\index.sqf";
};