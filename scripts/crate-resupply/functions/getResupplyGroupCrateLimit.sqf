getResupplyGroupCrateLimit = {
    params ["_group"];

    if (isNull _group) exitWith {0};

    private _playerCount = {isPlayer _x} count units _group;
    private _playersPerCrate = ResupplyPlayersPerCrate max 1;
    private _limit = ceil ((_playerCount max 1) / _playersPerCrate);
    _limit = _limit max ResupplyMinimumGroupCrates;
    _limit min ResupplyMaximumGroupCrates
};
