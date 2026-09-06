setResupplyFlags = {
    params ["_player", "_debug"];

    if (!isServer || {isNull _player}) exitWith {false};

    private _isDebugOn = !isNil {_debug};
    private _currentRoleDescription = roleDescription _player;
    private _currentSquad = [_player] call getResupplyGroupKey;
    if (_currentSquad isEqualTo "") exitWith {
        format ["Could not derive a network group key for %1", _player] call resupplyLog;
        false
    };

    /* Legacy role metadata is retained only for unrelated mission permissions. */
    private _currentRoles = [];
    {
        if (_currentRoleDescription find _y != -1) then {
            _currentRoles pushBack _x;
        };
    } forEach ResupplyRoleDescriptionsToRoleFlags;

    private _legacySquadFlag = "AUTO";
    {
        private _flagInfo = _x;
        private _squadNames = _flagInfo get "SquadNames";
        {
            if (_currentRoleDescription find _x != -1) exitWith {
                _legacySquadFlag = _flagInfo get "FlagName";
            };
        } forEach _squadNames;
        if (_legacySquadFlag != "AUTO") exitWith {};
    } forEach ResupplyRoleDescriptionToSquadFlags;

    _player setVariable ["resupplySquadRoleFlags", _currentRoles, true];
    _player setVariable ["resupplySquadGroupFlag", _legacySquadFlag, true];
    _player setVariable ["resupplySquadGroupName", _currentSquad, true];
    _player setVariable ["resupplySquadGroup", group _player, true];

    private _newCompatibleCrates = [_player] call getCompatibleCratesForPlayer;
    _player setVariable ["resupplyCompatibleCrates", _newCompatibleCrates, true];
    _player setVariable ["resupplyLastDescription", _currentRoleDescription];

    private _currentAllocations = missionNamespace getVariable _currentSquad;
    if (isNil {_currentAllocations}) then {
        _currentAllocations = createHashMapFromArray [
            ["SpecialtyResources", 0],
            ["Crates", 0],
            ["ResetTime", -1],
            ["RecallResetTime", -1],
            ["CanReset", true],
            ["CrateObjects", []]
        ];
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
