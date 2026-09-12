getResupplyGroupCrateLimit = {
    params ["_group"];

    if (isNull _group) exitWith {0};

    private _setting = {
        params ["_name"];
        if (isServer) then {localNamespace getVariable ("KPLIB_" + _name)} else {missionNamespace getVariable _name}
    };
    private _playerCount = {isPlayer _x} count units _group;
    private _playersPerCrate = (["ResupplyPlayersPerCrate"] call _setting) max 1;
    private _limit = ceil ((_playerCount max 1) / _playersPerCrate);
    _limit = _limit max (["ResupplyMinimumGroupCrates"] call _setting);
    _limit min (["ResupplyMaximumGroupCrates"] call _setting)
};
