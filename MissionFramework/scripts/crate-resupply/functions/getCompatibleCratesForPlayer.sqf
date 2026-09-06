getCompatibleCratesForPlayer = {
    params ["_player"];

    if (isNull _player || {isNull (group _player)}) exitWith {createHashMap};

    private _compatibleCrates = createHashMap;
    {
        private _crateName = _x;
        private _crateInfo = _y;
        private _category = _crateInfo getOrDefault ["Category", "Faction Supplies"];
        private _currentValue = _compatibleCrates getOrDefault [_category, []];

        _currentValue pushBack _crateName;
        _compatibleCrates set [_category, _currentValue];
    } forEach ResupplyCrates;

    _compatibleCrates
};
