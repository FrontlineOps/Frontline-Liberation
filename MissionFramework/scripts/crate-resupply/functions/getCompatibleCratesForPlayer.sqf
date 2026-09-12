getCompatibleCratesForPlayer = {
    params ["_player"];

    if (isNull _player || {side group _player != GRLIB_side_friendly} || {isNull (group _player)}) exitWith {createHashMap};

    private _compatibleCrates = createHashMap;
    {
        private _crateName = _x;
        private _crateInfo = _y;
        if ((localNamespace getVariable ["KPLIB_manualFactions", false])) then {
            ([_player] call KPLIB_fnc_getPlayerRole) params ["_sideKey", "_role"];
            if ((_crateInfo get "faction") != _sideKey || {!(_role in (_crateInfo getOrDefault ["roles", []]))}) then {continue};
        };
        private _category = _crateInfo getOrDefault ["Category", "Faction Supplies"];
        private _currentValue = _compatibleCrates getOrDefault [_category, []];

        _currentValue pushBack _crateName;
        _compatibleCrates set [_category, _currentValue];
    } forEach (if (isServer) then {localNamespace getVariable ["KPLIB_resupplyDefinitions", ResupplyCrates]} else {ResupplyCrates});

    _compatibleCrates
};
