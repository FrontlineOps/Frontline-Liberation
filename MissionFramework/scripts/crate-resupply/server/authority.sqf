// Snapshot configuration once; client public variables are never policy inputs.
{
    localNamespace setVariable ["KPLIB_" + _x, missionNamespace getVariable _x];
} forEach [
    "ResupplyCrateSourceClasses", "ResupplyDefaultRecallCooldown", "ResupplyDefaultSpecialtyCooldown",
    "ResupplyPlayersPerCrate", "ResupplyMinimumGroupCrates", "ResupplyMaximumGroupCrates",
    "ResupplyRoleDescriptionsToRoleFlags", "ResupplyRoleDescriptionToSquadFlags"
];
localNamespace setVariable ["KPLIB_resupplyAllocations", ResupplyCrateAllocations];
localNamespace setVariable ["KPLIB_resupplyDefinitions", ResupplyCrates];
/* Private identity and allocation state; public variables are presentation only. */
localNamespace setVariable ["KPLIB_resupplyRegistry", createHashMap];

KPLIB_fnc_validateResupplyRequest = {
    params ["_unit", "_operation", ["_crate", objNull], ["_crateName", ""]];
    if (!isServer || {canSuspend} || {!isRemoteExecuted}) exitWith {false};
    private _caller = call KPLIB_fnc_permissionCaller;
    if (isNull _caller || {side group _caller != GRLIB_side_friendly} || {_caller != _unit} || {!alive _caller} || {!isNull objectParent _caller}) exitWith {false};
    private _sources = nearestObjects [_caller, localNamespace getVariable "KPLIB_ResupplyCrateSourceClasses", 10];
    if ((_sources findIf {alive _x && {owner _x in [0, 2]}}) == -1) exitWith {false};

    private _groupKey = [_caller] call getResupplyGroupKey;
    if (_groupKey == "") exitWith {false};
    if (_operation == "recall") exitWith {true};
    private _registry = localNamespace getVariable "KPLIB_resupplyRegistry";
    private _valid = true;
    if (_operation != "spawn") then {
        private _record = _registry getOrDefault [netId _crate, []];
        if (isNull _crate || {_crate distance _caller > 10} || {count _record != 3}) exitWith {_valid = false};
        _record params ["_name", "_ownerKey", "_model"];
        _crateName = _name;
        _valid = typeOf _crate == _model
            && {_crate getVariable ["resupplyCrateName", ""] == _name}
            && {_crate getVariable ["resupplySquadOwner", ""] == _ownerKey};
        // Manual mode has no legacy cross-group resupplier bypass.
        if ((localNamespace getVariable ["KPLIB_manualFactions", false]) && {_ownerKey != _groupKey}) then {_valid = false};
    };
    if (!_valid || {!(_crateName in (localNamespace getVariable "KPLIB_resupplyDefinitions"))}) exitWith {false};
    if !(_operation in ["spawn", "refill"]) exitWith {true};

    private _definition = (localNamespace getVariable "KPLIB_resupplyDefinitions") get _crateName;
    private _compatible = [_caller] call getCompatibleCratesForPlayer;
    if !(_crateName in (_compatible getOrDefault [_definition getOrDefault ["Category", "Faction Supplies"], []])) exitWith {false};
    private _allocation = localNamespace getVariable [_groupKey, createHashMap];
    private _cooldowns = _allocation getOrDefault ["CrateCooldowns", createHashMap];
    if (CBA_missionTime < (_cooldowns getOrDefault [_crateName, 0])) exitWith {
        [_caller, "This crate is still on cooldown."] call KPLIB_fnc_permissionRejected;
        false
    };
    private _limit = _definition getOrDefault ["Limit", 0];
    if (_operation == "spawn" && {_limit > 0}) then {
        private _count = 0;
        {if ((_y select 0) == _crateName && {(_y select 1) == _groupKey}) then {_count = _count + 1}} forEach _registry;
        if (_count >= _limit) then {_valid = false};
    };
    _valid
};

localNamespace setVariable ["KPLIB_startCrateCooldown", {
    params ["_groupKey", "_crateName"];
    private _allocation = localNamespace getVariable _groupKey;
    private _cooldowns = _allocation getOrDefault ["CrateCooldowns", createHashMap];
    _cooldowns set [_crateName, CBA_missionTime + (((localNamespace getVariable "KPLIB_resupplyDefinitions") get _crateName) getOrDefault ["CustomCooldown", 0])];
    _allocation set ["CrateCooldowns", _cooldowns];
}];

KPLIB_fnc_resupplySpecialtyLimit = {
    params ["_flag"];
    ((localNamespace getVariable "KPLIB_resupplyAllocations") getOrDefault [_flag, createHashMap]) getOrDefault ["SpecialtyAllocations", 0]
};
