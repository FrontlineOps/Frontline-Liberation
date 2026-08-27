getResupplyGroupKey = {
    params ["_player"];

    if (isNull _player) exitWith {""};

    private _group = group _player;
    if (isNull _group) exitWith {""};

    private _networkId = _group call BIS_fnc_netId;
    if (_networkId isEqualTo "") exitWith {""};

    private _sideKey = switch (side _group) do {
        case west: {"WEST"};
        case east: {"EAST"};
        case independent: {"GUER"};
        case civilian: {"CIV"};
        default {"UNKNOWN"};
    };
    private _safeNetworkId = (_networkId splitString ":") joinString "_";

    format ["KPLIB_resupplyGroup_%1_%2", _sideKey, _safeNetworkId]
};
