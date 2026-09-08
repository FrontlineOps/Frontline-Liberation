/* Authoritative case records stay in localNamespace. Clients receive only current-stage summaries. */
localNamespace setVariable ["KPLIB_INTEL_CASES", createHashMap];
localNamespace setVariable ["KPLIB_INTEL_DETAINEES", createHashMap];
localNamespace setVariable ["KPLIB_INTEL_EFFECTS", createHashMap];
localNamespace setVariable ["KPLIB_INTEL_RETIRED", []];
localNamespace setVariable ["KPLIB_INTEL_NEXT_ID", 0];
localNamespace setVariable ["KPLIB_INTEL_DIRTY", false];

KPLIB_INTEL_SERVER_INTERNAL = {isServer && {!isRemoteExecuted}};
KPLIB_INTEL_SERVER_MUTATION_ALLOWED = {
    call KPLIB_INTEL_SERVER_INTERNAL && {!(missionNamespace getVariable ["BATTLESPACE_LOGISTICS_SAVING", false])}
};
KPLIB_INTEL_SERVER_CHANGED = {
    if !(call KPLIB_INTEL_SERVER_INTERNAL) exitWith {};
    localNamespace setVariable ["KPLIB_INTEL_DIRTY", true];
    KPLIB_INTEL_LAST_FINGERPRINT = "";
};

KPLIB_INTEL_SERVER_NEW_ID = {
    if !(call KPLIB_INTEL_SERVER_INTERNAL) exitWith {""};
    private _next = 1 + (localNamespace getVariable ["KPLIB_INTEL_NEXT_ID", 0]);
    localNamespace setVariable ["KPLIB_INTEL_NEXT_ID", _next];
    format ["INTEL_%1", _next]
};

KPLIB_INTEL_SERVER_GET_SITE = {
    params ["_position"];
    private _radius = KPLIB_intelligence_terminal_distance;
    private _found = [];
    {
        if (_position distance2D _x <= _radius) exitWith {_found = ["FOB", +_x]};
    } forEach (missionNamespace getVariable ["GRLIB_all_fobs", []]);
    if (_found isNotEqualTo []) exitWith {_found};
    {
        private _primary = _y getOrDefault ["primary", objNull];
        private _pos = _y getOrDefault ["markerPos", []];
        if (!isNull _primary && {alive _primary} && {count _pos >= 2} && {_position distance2D _pos <= _radius}) exitWith {
            _found = ["PB", +_pos];
        };
    } forEach (missionNamespace getVariable ["KPLIB_COPS_STATE", createHashMap]);
    _found
};

KPLIB_INTEL_SERVER_IS_NEAR_TERMINAL = {
    params ["_unit"];
    !isNull _unit && {([getPosATL _unit] call KPLIB_INTEL_SERVER_GET_SITE) isNotEqualTo []}
};

KPLIB_INTEL_SERVER_ACTOR_VALID = {
    params ["_actor", "_target", ["_distance", 4]];
    !isNull _actor && {isPlayer _actor} && {alive _actor}
        && {side group _actor == GRLIB_side_friendly}
        && {vehicle _actor isEqualTo _actor}
        && {lifeState _actor != "INCAPACITATED"}
        && {!(_actor getVariable ["ACE_isUnconscious", false])}
        && {!isNull _target} && {alive _target} && {_actor distance _target <= _distance}
};

KPLIB_INTEL_SERVER_SOURCE_VISIBLE = {
    params ["_actor", "_target"];
    private _end = if (_target isKindOf "Man") then {aimPos _target} else {(getPosASL _target) vectorAdd [0, 0, 0.15]};
    lineIntersectsSurfaces [eyePos _actor, _end, _actor, _target, true, 1, "GEOM", "NONE"] isEqualTo []
};

KPLIB_INTEL_SERVER_HAS_EFFECT = {
    params ["_sector", "_kind"];
    if (!isServer) exitWith {false};
    private _expiry = (localNamespace getVariable ["KPLIB_INTEL_EFFECTS", createHashMap]) getOrDefault [_sector + ":" + _kind, 0];
    CBA_missionTime < _expiry
};

KPLIB_INTEL_SERVER_CASE_BRIEF = {
    params ["_case"];
    private _kind = _case get "kind";
    private _sector = [_case get "sector"] call KPLIB_INTEL_SERVER_LABEL;
    private _effect = switch (_kind) do {
        case "LOGISTICS": {format ["Destroy %1%% of the remaining manpower, supplies, rockets and transport stock at %2.", round (100 * KPLIB_intelligence_stock_loss), _sector]};
        case "FIRE_SUPPORT": {format ["Interrupt new fire missions from batteries funded by %1 for %2 minutes.", _sector, round (KPLIB_intelligence_disruption_duration / 60)]};
        default {format ["Block new funded ground formations from %1 for %2 minutes. Existing enemy forces remain active.", _sector, round (KPLIB_intelligence_disruption_duration / 60)]};
    };
    private _title = ["Supply network", "Fire-control network", "Command network"] select (["LOGISTICS", "FIRE_SUPPORT", "COMMAND"] find _kind);
    private _stage = _case get "stage";
    private _instruction = switch (_stage) do {
        case 0: {"Search the defended building for dispatch documents. Expect interior guards, patrols and crewed emplacements. Use Collect intelligence on the documents; destroying them loses this lead."};
        case 1: {"Find the HVT inside the defended building and bring them back ALIVE. Clear the security detail, then use Detain HVT (also required after ACE restraint). Escort the prisoner to a FOB or patrol base and interrogate them to reveal the final target."};
        default {"Assault the defended support compound. Find the marked equipment and use Sabotage support site, or destroy it. Completing this stage applies the stated effect to the enemy sector."};
    };
    [_title, _instruction, _effect]
};

KPLIB_INTEL_SERVER_BUILD_PAYLOAD = {
    private _reports = [];
    {_reports pushBack (_y get "report")} forEach KPLIB_INTEL_LEADS;
    private _cases = [];
    {
        private _case = _y;
        ([_case] call KPLIB_INTEL_SERVER_CASE_BRIEF) params ["_title", "_brief", "_effect"];
        _cases pushBack [_x, _title, _case get "stage", _case get "status", +(_case get "position"), _brief, _effect, +(_case get "history"), _case get "deadline"];
    } forEach (localNamespace getVariable ["KPLIB_INTEL_CASES", createHashMap]);
    _cases sort true;
    [KPLIB_INTEL_REVISION, _reports, _cases, count (localNamespace getVariable ["KPLIB_INTEL_DETAINEES", createHashMap]), 3]
};

KPLIB_INTEL_SERVER_SEND_PAYLOAD = {
    params [["_targets", [], [[], objNull]]];
    if !(call KPLIB_INTEL_SERVER_INTERNAL) exitWith {};
    if (_targets isEqualType [] && {_targets isEqualTo []}) exitWith {};
    [call KPLIB_INTEL_SERVER_BUILD_PAYLOAD] remoteExecCall ["KPLIB_INTEL_CLIENT_RECEIVE_SNAPSHOT", _targets];
};

KPLIB_INTEL_SERVER_RECONCILE = {
    params [["_force", false, [false]]];
    if (!(call KPLIB_INTEL_SERVER_MUTATION_ALLOWED) || {!KPLIB_intelligence_enabled}) exitWith {};
    call KPLIB_INTEL_SERVER_UPDATE_INFORMANT;
    call KPLIB_INTEL_SERVER_TICK_CUSTODY;
    call KPLIB_INTEL_SERVER_TICK_CASES;
    private _cases = localNamespace getVariable "KPLIB_INTEL_CASES";
    private _archived = keys _cases select {!(((_cases get _x) get "status") in ["ACTIVE", "QUEUED"])};
    _archived = [_archived, [], {(_cases get _x) get "deadline"}, "ASCEND"] call BIS_fnc_sortBy;
    while {count _archived > 24} do {_cases deleteAt (_archived deleteAt 0)};
    {
        if (((KPLIB_INTEL_LEADS get _x) get "expiresAt") <= CBA_missionTime) then {KPLIB_INTEL_LEADS deleteAt _x};
    } forEach keys KPLIB_INTEL_LEADS;
    private _oldest = [keys KPLIB_INTEL_LEADS, [], {((KPLIB_INTEL_LEADS get _x) get "report") # 6}, "ASCEND"] call BIS_fnc_sortBy;
    while {count _oldest > KPLIB_intelligence_max_archived_reports} do {KPLIB_INTEL_LEADS deleteAt (_oldest deleteAt 0)};
    private _sources = localNamespace getVariable "KPLIB_INTEL_SOURCES";
    {if (isNull ((_sources get _x) # 0)) then {_sources deleteAt _x}} forEach keys _sources;
    private _effects = localNamespace getVariable "KPLIB_INTEL_EFFECTS";
    {if ((_effects get _x) <= CBA_missionTime) then {_effects deleteAt _x}} forEach keys _effects;
    private _fingerprint = str ((call KPLIB_INTEL_SERVER_BUILD_PAYLOAD) select [1]);
    if (_force || {_fingerprint != KPLIB_INTEL_LAST_FINGERPRINT}) then {
        KPLIB_INTEL_LAST_FINGERPRINT = _fingerprint;
        KPLIB_INTEL_REVISION = KPLIB_INTEL_REVISION + 1;
        [allPlayers select {isPlayer _x && {side group _x == GRLIB_side_friendly}}] call KPLIB_INTEL_SERVER_SEND_PAYLOAD;
    };
    if (localNamespace getVariable ["KPLIB_INTEL_DIRTY", false] && {missionNamespace getVariable ["KPLIB_init", false]} && {!(missionNamespace getVariable ["kp_liberation_saving", false])}) then {
        localNamespace setVariable ["KPLIB_INTEL_DIRTY", false];
        [] spawn {
            if !(call KPLIB_fnc_doSave) then {localNamespace setVariable ["KPLIB_INTEL_DIRTY", true]};
        };
    };
};
