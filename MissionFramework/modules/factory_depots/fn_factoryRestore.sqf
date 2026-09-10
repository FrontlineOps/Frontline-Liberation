/* Internal one-time load. Missing extension is an old save: friendly factories
   are already claimed. Empty/depleted rows never receive replacement pallets.
   Unrestorable cargo remains serialized for a later restart instead of being
   silently discarded or replaced with another cache. */
if (!isServer || {isRemoteExecuted}) exitWith {};
params ["_saved", "_loadedObjects"];
private _registry = localNamespace getVariable "KPLIB_factoryRegistry";
if !(count _registry == 0) exitWith {};
if (_saved isEqualTo []) exitWith {
    {_registry set [_x, [[], [], []]]} forEach (sectors_factory arrayIntersect blufor_sectors);
};
private _validVector = {
    params ["_value"];
    _value isEqualType [] && {count _value == 3} && {_value findIf {!(_x isEqualType 0) || {!finite _x}} < 0}
};
private _valid = _saved isEqualType [] && {count _saved == 2} && {(_saved select 0) isEqualTo 1} && {(_saved select 1) isEqualType []};
if (_valid) then {
    {
        if (!(_x isEqualType []) || {count _x != 3}) exitWith {_valid = false};
        _x params ["_sector", "_layout", "_cargo"];
        if (!(_sector isEqualType "") || {!(_layout isEqualType [])} || {!(_cargo isEqualType [])} || {count _cargo > 24}) exitWith {_valid = false};
        if (!(_layout isEqualTo []) && {!(count _layout in [2, 3, 4]) || {!([_layout select 0] call _validVector)} || {!((_layout select 1) isEqualType 0)}}) exitWith {_valid = false};
        if (count _layout == 4) then {
            private _bays = _layout select 3;
            if (!(_bays isEqualType []) || {count _bays != 6}) then {
                _valid = false;
            } else {
                {
                    if (!(_x isEqualType []) || {!(count _x in [4, 5])}
                        || {!([_x select 0] call _validVector)}
                        || {!((_x select 1) isEqualType 0)} || {!finite (_x select 1)}
                        || {!((_x select 2) in [0, 1, 2])}
                        || {!((_x select 3) isEqualType 0)} || {!finite (_x select 3)}
                        || {(_x select 3) < 0} || {(_x select 3) > 100}
                        || {!((_x param [4, false]) isEqualType false)}) exitWith {_valid = false};
                } forEach _bays;
            };
        };
        if (!_valid) exitWith {};
        {
            if (!(_x isEqualType []) || {count _x != 8}) exitWith {_valid = false};
            _x params ["_class", "_amount", "_position", "_direction", "_up", "_damage", "_carrier", "_transit"];
            if (!(_class isEqualType "") || {!(_amount isEqualType 0)} || {!finite _amount} || {_amount <= 0}
                || {!([_position] call _validVector)} || {!(_direction isEqualType 0)} || {!finite _direction}
                || {!([_up] call _validVector)} || {!(_damage isEqualType 0)} || {!finite _damage}
                || {!(_carrier isEqualType [])} || {!(_transit isEqualType false)}) exitWith {_valid = false};
            if (!(_carrier isEqualTo []) && {count _carrier != 3 || {!((_carrier select 0) isEqualType "")} || {!([_carrier select 1] call _validVector)} || {!([_carrier select 2] call _validVector)}}) exitWith {_valid = false};
        } forEach _cargo;
        if (!_valid) exitWith {};
    } forEach (_saved select 1);
};
if (!_valid) exitWith {
    localNamespace setVariable ["KPLIB_factoryOpaqueSave", _saved];
    {_registry set [_x, [[], [], []]]} forEach sectors_factory;
    ["Unrecognized factory save extension retained unchanged; cache issuance disabled to prevent duplication.", "FACTORY"] call KPLIB_fnc_log;
};
private _legacySites = call compileFinal preprocessFileLineNumbers "modules\factory_depots\legacy-sites.sqf";
private _classes = [KP_liberation_supply_crate, KP_liberation_ammo_crate, KP_liberation_fuel_crate] apply {toLower _x};
{
    _x params ["_sector", "_layout", "_cargo"];
    if (_sector in _registry) then {continue};
    // Upgrade only a recognized original layout, before restoring objects.
    // Surviving loose cargo still at its original slot moves to the matching
    // interior slot. Hauls, attachments, damage, amounts and empty slots persist.
    private _legacy = _legacySites findIf {
        (_x select 0) == toLower worldName && {(_x select 1) == _sector} && {(_x select [2]) isEqualTo _layout}
    };
    if (_legacy >= 0 && {canSuspend} && {!(_cargo isEqualTo [])}
        && {allPlayers findIf {alive _x && {_x distance2D markerPos _sector < 350}} < 0}) then {
        private _replacement = [_sector] call KPLIB_fnc_factoryPlan;
        if (!(_replacement isEqualTo []) && {!(_replacement isEqualTo _layout)}
            && {allPlayers findIf {alive _x && {_x distance2D markerPos _sector < 350}} < 0}) then {
            private _oldSlots = _layout call KPLIB_fnc_factoryLayout;
            private _newSlots = _replacement call KPLIB_fnc_factoryLayout;
            private _used = [];
            _cargo = _cargo apply {
                private _row = +_x;
                if ((_row select 6) isEqualTo [] && {!(_row select 7)} && {(_row select 5) < 1}) then {
                    private _position = _row select 2;
                    private _kind = _classes find toLower (_row select 0);
                    private _slot = _oldSlots findIf {
                        (_x select 1) == _kind && {_position distance2D (_x select 0) < 0.75}
                        && {abs ((_position select 2) - ((_x select 0) select 2)) < 1}
                    };
                    if (_slot >= 0 && {!(_slot in _used)}) then {
                        private _new = _newSlots select _slot;
                        _row set [2, +(_new select 0)];
                        _row set [3, _new param [2, _replacement select 1]];
                        _row set [4, _new param [3, surfaceNormal (_new select 0)]];
                        _used pushBack _slot;
                    };
                };
                _row
            };
            _layout = _replacement;
            [format ["%1: moved %2 surviving depot pallets into the objective during load.", _sector, count _used], "FACTORY"] call KPLIB_fnc_log;
        };
    };
    private _crates = [];
    private _pending = [];
    _registry set [_sector, [_layout, _crates, _pending]];
    {
        _x params ["_class", "_amount", "_position", "_direction", "_up", "_damage", "_carrier", "_transit"];
        if (_damage >= 1) then {continue};
        if (!(toLower _class in KPLIB_crates) || {!isClass (configFile >> "CfgVehicles" >> _class)}) then {
            _pending pushBack _x;
            continue;
        };
        private _parent = objNull;
        if !(_carrier isEqualTo []) then {
            private _index = _loadedObjects findIf {typeOf _x == (_carrier select 0) && {getPosWorld _x vectorDistance (_carrier select 1) < 0.5}};
            if (_index >= 0) then {_parent = _loadedObjects select _index};
        };
        private _place = +_position;
        if (_transit && {isNull _parent}) then {
            // Vehicles away from FOBs are not saved by Liberation. Recover
            // their cargo on clear ground nearby, never in mid-air/on a roof.
            _place set [2, 0];
            _place = _place findEmptyPosition [6, 40, _class];
        };
        if (_place isEqualTo [] || {surfaceIsWater _place}) then {
            _pending pushBack _x;
            continue;
        };
        private _crate = [_class, _amount, _place] call KPLIB_fnc_createCrate;
        if (isNull _crate) then {
            _pending pushBack _x;
            continue;
        };
        _crate setDir _direction;
        _crate setVectorUp _up;
        _crate setPosATL _place;
        if (!isNull _parent) then {
            _crate attachTo [_parent, _carrier select 2];
            _crate setDir (_direction - getDir _parent);
            _parent setVariable ["GRLIB_ammo_truck_load", (_parent getVariable ["GRLIB_ammo_truck_load", 0]) + 1, true];
        } else {
            if (_transit) then {_crate setVectorUp surfaceNormal _place};
        };
        _crate setDamage (_damage max 0);
        _crates pushBack _crate;
    } forEach _cargo;
    [format ["%1: restored %2 cargo pallets; %3 retained pending valid placement/class.", _sector, count _crates, count _pending], "FACTORY"] call KPLIB_fnc_log;
} forEach (_saved select 1);
