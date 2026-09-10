/* Internal server-only issuance, also called by the legacy activation hook.
   Duplicate calls, recapture and restart cannot roll another reward. */
if (!isServer || {isRemoteExecuted} || {!(localNamespace getVariable ["KPLIB_factoryReady", false])}) exitWith {false};
params [["_sector", "", [""]]];
if !(_sector in sectors_factory) exitWith {false};
private _registry = localNamespace getVariable "KPLIB_factoryRegistry";
if (_sector in _registry) exitWith {true};
if (_sector in blufor_sectors) exitWith {
    _registry set [_sector, [[], [], []]];
    true
};
if (localNamespace getVariable ["KPLIB_factoryPlanning", false]) exitWith {false};
if (_sector in (localNamespace getVariable ["KPLIB_factoryFailed", []])) exitWith {false};
if (!canSuspend) exitWith {[_sector] spawn KPLIB_fnc_factoryEnsure; false};
if (allPlayers findIf {alive _x && {_x distance2D markerPos _sector < 350}} >= 0) exitWith {false};
localNamespace setVariable ["KPLIB_factoryPlanning", true];
private _layout = [_sector] call KPLIB_fnc_factoryPlan;
if (allPlayers findIf {alive _x && {_x distance2D markerPos _sector < 350}} >= 0) exitWith {
    localNamespace setVariable ["KPLIB_factoryPlanning", false];
    false
};
if (_layout isEqualTo []) exitWith {
    (localNamespace getVariable "KPLIB_factoryFailed") pushBackUnique _sector;
    localNamespace setVariable ["KPLIB_factoryPlanning", false];
    [format ["%1: no clear authored depot footprint inside the objective; placement skipped. Check the factory site configuration.", _sector], "FACTORY"] call KPLIB_fnc_log;
    false
};
private _classes = [KP_liberation_supply_crate, KP_liberation_ammo_crate, KP_liberation_fuel_crate];
private _baseValue = missionNamespace getVariable ["KPLIB_factory_crate_value", 100];
if (!(_baseValue isEqualType 0) || {!finite _baseValue} || {_baseValue <= 0}) then {
    ["Invalid factory crate value; using 100 per pallet.", "FACTORY"] call KPLIB_fnc_log;
    _baseValue = 100;
};
private _amount = round (_baseValue * GRLIB_resources_multiplier);
_amount = (_amount max 1) min 10000;
// Commit the consumed ledger and physical identities without a scheduled
// save interleaving between object creation and registration.
isNil {
    private _crates = [];
    _registry set [_sector, [_layout, _crates, []]];
    {
        _x params ["_position", "_resource", ["_direction", _layout select 1], ["_up", surfaceNormal (_x select 0)]];
        private _crate = [_classes select _resource, _amount, _position] call KPLIB_fnc_createCrate;
        if (isNull _crate) then {continue};
        _crate setDir _direction;
        _crate setVectorUp _up;
        _crate setPosATL _position;
        _crates pushBack _crate;
    } forEach (_layout call KPLIB_fnc_factoryLayout);
    [format ["%1: depot at %2 with %3 recoverable pallets (%4 each).", _sector, _layout select 0, count _crates, _amount], "FACTORY"] call KPLIB_fnc_log;
};
localNamespace setVariable ["KPLIB_factoryPlanning", false];
true
