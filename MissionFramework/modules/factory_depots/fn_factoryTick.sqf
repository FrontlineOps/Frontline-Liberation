/* Slow pass over known depots. Global markers reconstruct for JIP without
   a custom client loop or replaying historical capture notifications. */
if (!isServer || {isRemoteExecuted} || {!(localNamespace getVariable ["KPLIB_factoryReady", false])}) exitWith {};
private _registry = localNamespace getVariable "KPLIB_factoryRegistry";
{
    private _sector = _x;
    private _marker = "KPLIB_depot_" + _sector;
    private _entry = _registry get _sector;
    private _totals = [_sector] call KPLIB_fnc_factoryStatus;
    if (!(_sector in blufor_sectors) || {(_entry select 0) isEqualTo []}) then {
        deleteMarker _marker;
        for "_bay" from 0 to 5 do {deleteMarker format ["%1_bay%2", _marker, _bay]};
        continue;
    };
    if (markerShape _marker == "") then {
        createMarker [_marker, (_entry select 0) select 0];
        _marker setMarkerType "mil_box";
        _marker setMarkerColor "ColorGUER";
        _marker setMarkerSize [0.65, 0.65];
    };
    private _text = if ((_totals select 0) > 0) then {
        format ["Factory haul: %1 pallets | %2 supply / %3 ammo / %4 fuel", _totals select 0, _totals select 1, _totals select 2, _totals select 3]
    } else {"Factory depot: cleared"};
    if (markerText _marker != _text) then {_marker setMarkerText _text};
    {
        _x params ["_position", "", "_resource"];
        private _bayMarker = format ["%1_bay%2", _marker, _forEachIndex];
        private _remaining = {alive _x && {isNull attachedTo _x} && {_x distance2D _position < 5}} count (_entry select 1);
        if (_remaining == 0) then {
            deleteMarker _bayMarker;
            continue;
        };
        if (markerShape _bayMarker == "") then {
            createMarker [_bayMarker, _position];
            _bayMarker setMarkerType "mil_dot";
            _bayMarker setMarkerSize [0.35, 0.35];
            _bayMarker setMarkerColor "ColorGUER";
        };
        private _label = format ["%1: %2 pallets", ["Supply", "Ammunition", "Fuel"] select _resource, _remaining];
        if (markerText _bayMarker != _label) then {_bayMarker setMarkerText _label};
    } forEach ((_entry select 0) param [3, []]);
} forEach keys _registry;
// Retry a player-blocked initial placement once the objective is clear.
if !(localNamespace getVariable ["KPLIB_factoryPlanning", false]) then {
    private _pending = sectors_factory select {!(_x in _registry) && {!(_x in (localNamespace getVariable "KPLIB_factoryFailed"))}};
    private _index = _pending findIf {private _position = markerPos _x; allPlayers findIf {alive _x && {_x distance2D _position < 350}} < 0};
    if (_index >= 0) then {[_pending select _index] spawn KPLIB_fnc_factoryEnsure};
};
