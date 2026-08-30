/*
    File: fn_getPlayerCount.sqf
    Author: KP Liberation Dev Team - https://github.com/KillahPotatoes
    Date: 2019-11-25
    Last Update: 2019-11-25
    License: MIT License - http://www.opensource.org/licenses/MIT

    Description:
        Returns the number of connected players.
        Set DEBUG_PLAYER_COUNT to a value other than -1 to override count for testing.

    Parameter(s):
        NONE

    Returns:
        Amount of players [NUMBER]
*/

private _playerCount = count allPlayers;
if (DEBUG_PLAYER_COUNT_OVERRIDE != -1) then {
    // Allow us to simulate different play conditions
    _playerCount = DEBUG_PLAYER_COUNT_OVERRIDE;
};

_playerCount;
