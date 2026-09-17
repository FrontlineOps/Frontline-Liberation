setResupplyFlags = {
    params ["_player", "_debug"];

    if (!isServer || {isNull _player} || {side group _player != GRLIB_side_friendly}) exitWith {false};

    private _isDebugOn = !isNil {_debug};
    private _currentSquad = [_player] call getResupplyGroupKey;
    if (_currentSquad isEqualTo "") exitWith {
        format ["Could not derive a network group key for %1", _player] call resupplyLog;
        false
    };

    private _currentRoles = [];
    private _legacySquadFlag = "AUTO";

    if ((localNamespace getVariable ["KPLIB_manualFactions", false])) then {
        ([_player] call KPLIB_fnc_getPlayerRole) params ["_sideKey", "_role"];
        _legacySquadFlag = "MANUAL:" + _sideKey;
        _currentRoles = [_role];
    };
    _player setVariable ["resupplySquadRoleFlags", _currentRoles, true];
    _player setVariable ["resupplySquadGroupFlag", _legacySquadFlag, true];
    _player setVariable ["resupplySquadGroupName", _currentSquad, true];
    _player setVariable ["resupplySquadGroup", group _player, true];

    private _newCompatibleCrates = [_player] call getCompatibleCratesForPlayer;
    _player setVariable ["resupplyCompatibleCrates", _newCompatibleCrates, true];

    private _currentAllocations = localNamespace getVariable _currentSquad;
    if (isNil {_currentAllocations}) then {
        _currentAllocations = createHashMapFromArray [
            ["SpecialtyResources", if ((localNamespace getVariable ["KPLIB_manualFactions", false])) then {[_legacySquadFlag] call KPLIB_fnc_resupplySpecialtyLimit} else {0}],
            ["SpecialtyLimit", [_legacySquadFlag] call KPLIB_fnc_resupplySpecialtyLimit],
            ["Crates", 0],
            ["ResetTime", -1],
            ["RecallResetTime", -1],
            ["CanReset", true],
            ["CrateObjects", []]
        ];
        localNamespace setVariable [_currentSquad, _currentAllocations];
        missionNamespace setVariable [_currentSquad, _currentAllocations, true];
        format ["Initialized automatic group %1 (%2)", groupId (group _player), _currentSquad] call resupplyLog;
    };

    if (_isDebugOn) then {
        format [
            "SetResupplyFlags(%1): group=%2 key=%3 categories=%4",
            _player,
            groupId (group _player),
            _currentSquad,
            count _newCompatibleCrates
        ] call resupplyLog;
    };

    ["resupplyFlagSets", [], _player] call CBA_fnc_targetEvent;
    true
};
