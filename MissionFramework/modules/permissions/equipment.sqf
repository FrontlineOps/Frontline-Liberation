/* A shared filter serves immediate owner-local checks and a bounded server reconciliation. */
KPLIB_fnc_roleDefinition = {
    params ["_unit"];
    if (!(localNamespace getVariable ["KPLIB_manualFactions", false]) || {side group _unit != GRLIB_side_friendly}) exitWith {createHashMap};
    ([_unit] call KPLIB_fnc_getPlayerRole) params ["_sideKey", "_role"];
    (((localNamespace getVariable "KPLIB_factionProfiles") get _sideKey) get "roles") getOrDefault [_role, createHashMapFromArray [["allowed", []], ["starter", [[], [], [], [], [], [], "", "", [], ["", "", "", "", "", ""]]]]]
};

KPLIB_fnc_enforceRoleEquipment = {
    params [["_unit", player, [objNull]]];
    if (!(localNamespace getVariable ["KPLIB_manualFactions", false])) exitWith {};
    if (isNull _unit || {!local _unit} || {!alive _unit} || {side group _unit != GRLIB_side_friendly}) exitWith {};
    if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {};
    if (_unit isEqualTo player && {!(localNamespace getVariable ["KPLIB_permissionsReady", false])}) exitWith {};
    private _role = [_unit] call KPLIB_fnc_roleDefinition;
    private _loadout = getUnitLoadout _unit;
    private _identity = [_unit] call KPLIB_fnc_getPlayerRole;
    private _previous = _unit getVariable ["KPLIB_lastCheckedLoadout", []];
    if (_previous isEqualTo [_identity, _loadout]) exitWith {};
    ([_loadout, _role get "allowed", _role get "starter"] call KPLIB_fnc_filterRoleLoadout) params ["_clean", "_removed"];
    _unit setVariable ["KPLIB_lastCheckedLoadout", [_identity, _clean]];
    if (_removed isNotEqualTo []) then {
        _unit setUnitLoadout [_clean, false];
        if (_unit isEqualTo player) then {systemChat format ["Removed equipment outside your role: %1", _removed joinString ", "]};
        [format ["Role equipment correction: %1 prohibited classes", count _removed], "PERMISSIONS"] call KPLIB_fnc_log;
    };
};

KPLIB_fnc_receiveRoleCorrection = {
    if (!hasInterface || {side group player != GRLIB_side_friendly} || {!isRemoteExecuted} || {remoteExecutedOwner != 2}) exitWith {};
    params ["_observed", "_clean"];
    if (getUnitLoadout player isEqualTo _observed) then {
        player setUnitLoadout [_clean, false];
        player setVariable ["KPLIB_lastCheckedLoadout", []];
        systemChat "Equipment outside your assigned role was removed.";
    };
};

KPLIB_fnc_checkPlayerEquipment = {
    params ["_unit"];
    if (!(localNamespace getVariable ["KPLIB_manualFactions", false])) exitWith {};
    if (!isServer || {!isPlayer _unit} || {!alive _unit} || {side group _unit != GRLIB_side_friendly}) exitWith {};
    private _loadout = getUnitLoadout _unit;
    private _identity = [_unit] call KPLIB_fnc_getPlayerRole;
    private _cache = localNamespace getVariable ["KPLIB_equipmentAudit", createHashMap];
    private _checked = _cache getOrDefault [netId _unit, []];
    if (_checked isEqualTo [_identity, _loadout]) exitWith {};
    private _role = [_unit] call KPLIB_fnc_roleDefinition;
    ([_loadout, _role get "allowed", _role get "starter"] call KPLIB_fnc_filterRoleLoadout) params ["_clean", "_removed"];
    _cache set [netId _unit, [_identity, _clean]];
    localNamespace setVariable ["KPLIB_equipmentAudit", _cache];
    if (_removed isNotEqualTo []) then {
        [_loadout, _clean] remoteExecCall ["KPLIB_fnc_receiveRoleCorrection", owner _unit];
        [_unit, "Equipment does not match the assigned role."] call KPLIB_fnc_permissionRejected;
    };
};

KPLIB_fnc_refreshRoleEquipment = {
    if (!hasInterface || {side group player != GRLIB_side_friendly} || {!alive player} || {!(localNamespace getVariable ["KPLIB_permissionsReady", false])}) exitWith {};
    [] remoteExecCall ["KPLIB_fnc_requestVehicleAccess", 2];
    if (!(localNamespace getVariable ["KPLIB_manualFactions", false])) exitWith {};
    private _role = [player] call KPLIB_fnc_roleDefinition;
    if (localNamespace getVariable ["KPLIB_pendingRoleStarter", false]) then {
        player setUnitLoadout [_role get "starter", false];
        localNamespace setVariable ["KPLIB_pendingRoleStarter", false];
    };
    localNamespace setVariable ["KPLIB_clientRole", [player] call KPLIB_fnc_getPlayerRole];
    player setUnitTrait ["Medic", (_role getOrDefault ["medic", 0]) > 0];
    player setUnitTrait ["Engineer", (_role getOrDefault ["engineer", 0]) > 0];
    player setVariable ["ace_medical_medicClass", _role getOrDefault ["medic", 0], true];
    player setVariable ["ACE_isEngineer", _role getOrDefault ["engineer", 0], true];
    player setVariable ["KPLIB_lastCheckedLoadout", []];
    if (!isNil "KPLIB_fnc_initPlayerArsenal") then {
        {if (!isNull _x) then {[_x, player] call KPLIB_fnc_initPlayerArsenal}} forEach KARMA_ARSENAL_CRATES;
    };
    if (!isNil "KPLIB_fnc_refreshVirtualArsenal") then {[] call KPLIB_fnc_refreshVirtualArsenal};
    [player] call KPLIB_fnc_enforceRoleEquipment;
};

if (isServer) then {
    [{
        private _players = allPlayers select {isPlayer _x};
        private _cache = localNamespace getVariable ["KPLIB_equipmentAudit", createHashMap];
        private _connected = _players apply {netId _x};
        {if !(_x in _connected) then {_cache deleteAt _x}} forEach keys _cache;
        if (_players isEqualTo []) exitWith {};
        private _cursor = localNamespace getVariable ["KPLIB_roleAuditCursor", 0];
        for "_i" from 1 to (KPLIB_roleAuditBatchSize min count _players) do {
            private _unit = _players select (_cursor mod count _players);
            [_unit] call KPLIB_fnc_checkPlayerEquipment;
            [_unit] call KPLIB_fnc_validatePlayerVehicle;
            _cursor = _cursor + 1;
        };
        localNamespace setVariable ["KPLIB_roleAuditCursor", _cursor];
    }, KPLIB_roleAuditInterval] call CBA_fnc_addPerFrameHandler;
    ["Role equipment and vehicle reconciliation initialized", "PERMISSIONS"] call KPLIB_fnc_log;
};

KPLIB_fnc_refreshVirtualArsenal = {
    if (!hasInterface || {side group player != GRLIB_side_friendly} || {!(localNamespace getVariable ["KPLIB_manualFactions", false])}) exitWith {};
    private _allowed = [player] call KPLIB_fnc_getRoleGear;
    ( [player] call KPLIB_fnc_getPlayerRole ) params ["_sideKey"];
    private _data = ((localNamespace getVariable "KPLIB_factionProfiles") get _sideKey) get "arsenal";
    {
        _x params ["_bucket", "_remove", "_add"];
        [missionNamespace, true, false] call _remove;
        [missionNamespace, (_data get _bucket) arrayIntersect _allowed, false] call _add;
    } forEach [
        ["weapons", BIS_fnc_removeVirtualWeaponCargo, BIS_fnc_addVirtualWeaponCargo],
        ["magazines", BIS_fnc_removeVirtualMagazineCargo, BIS_fnc_addVirtualMagazineCargo],
        ["items", BIS_fnc_removeVirtualItemCargo, BIS_fnc_addVirtualItemCargo],
        ["backpacks", BIS_fnc_removeVirtualBackpackCargo, BIS_fnc_addVirtualBackpackCargo]
    ];
    if (KP_liberation_ace) then {
        [player, true, false] call ace_arsenal_fnc_removeVirtualItems;
        [player, _allowed, false] call ace_arsenal_fnc_addVirtualItems;
    };
    KP_liberation_allowed_items = _allowed apply {toLower _x};
};
