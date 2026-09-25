/* UAV reconnaissance over unconfirmed reports: gunfire, casualties and lost contact
   with no confirmed sighting nearby. Alerted theaters are looked at first. With no
   report to check, a periodic survey flies over a contested, BLUFOR-pushed or long-
   unobserved control cell. Funded from sector aircraft stock with the faction's
   "uav" catalog (AUTO or MANUAL). */
BATTLESPACE_UAV_SURVEY_AT = 0;
BATTLESPACE_UAV_RECON_SELECT_CLASS = {
    private _opfor = (missionNamespace getVariable ["KPLIB_autoFactionCatalogs", createHashMap]) getOrDefault ["opfor", createHashMap];
    private _pool = BATTLESPACE_RESOURCE_CLASS_POOLS getOrDefault ["aircraft", []];
    private _valid = (_opfor getOrDefault ["uav", []]) select {_x in _pool};
    if (_valid isEqualTo []) then {""} else {selectRandom _valid}
};

BATTLESPACE_UAV_RECON_DECISION_TICK = {
    if !([] call BATTLESPACE_STRATEGIC_SERVER_CALL_ALLOWED) exitWith {};
    if (GRLIB_endgame != 0) exitWith {};
    if (["UAV_RECON"] call BATTLESPACE_STRATEGIC_COUNT_OPERATIONS >= (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_MAX_ACTIVE_UAV_RECON", 1])) exitWith {};
    private _class = [] call BATTLESPACE_UAV_RECON_SELECT_CLASS;
    if (_class == "") exitWith {};
    private _watched = (values BATTLESPACE_STRATEGIC_OPERATIONS select {(_x getOrDefault ["kind", ""]) == "UAV_RECON"}) apply {_x getOrDefault ["contactPosition", [0, 0, 0]]};
    private _confirmed = [[], 0, 120, false, grpNull, true, false] call BATTLESPACE_CONTACT_QUERY;
    private _best = [];
    private _bestScore = 0;
    {
        private _kind = BATTLESPACE_CONTACT_UNCONFIRMED find (_x select 6);
        if (_kind < 0) then {continue};
        private _position = _x select 0;
        if (_confirmed findIf {(_x select 0) distance2D _position <= 500} >= 0) then {continue};
        if (_watched findIf {_x distance2D _position <= 1500} >= 0) then {continue};
        private _score = 10 * ([_position] call BATTLESPACE_THEATER_LEVEL_AT) + (_x select 2) + _kind;
        if (_score > _bestScore) then {_bestScore = _score; _best = _position};
    } forEach ([[], 0, 300, false, grpNull, true, true] call BATTLESPACE_CONTACT_QUERY);
    private _survey = false;
    if (_best isEqualTo [] && {CBA_missionTime >= BATTLESPACE_UAV_SURVEY_AT}) then {
        _best = [_watched] call BATTLESPACE_CELL_SURVEY_TARGET;
        _survey = _best isNotEqualTo [];
    };
    if (_best isEqualTo []) exitWith {};
    private _target = [_best select 0, _best select 1, 0];
    private _origin = [_target, "nextUavReconAt"] call BATTLESPACE_AIR_RESPONSE_FIND_SOURCE;
    if (_origin == "") exitWith {};
    private _metadata = createHashMapFromArray [
        ["phase", "INTERCEPT"],
        ["originSector", _origin],
        ["targetSector", [sectors_allSectors, _target] call BIS_fnc_nearestPosition],
        ["contactPosition", _target],
        ["expiresAt", CBA_missionTime + (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_UAV_RECON_LIFETIME", 1200])],
        ["outcome", ""]
    ];
    private _taskForceId = [
        "UAV Recon", createHashMapFromArray [["manpower", 0], ["vehicles", [_class]], ["structures", []]],
        getMarkerPos _origin, _target, getMarkerPos _origin, _origin, "UAV_RECON", _metadata
    ] call BATTLESPACE_STRATEGIC_CREATE_FUNDED_TASK_FORCE;
    if (_taskForceId == "") exitWith {};
    if (_survey) then {BATTLESPACE_UAV_SURVEY_AT = CBA_missionTime + (missionNamespace getVariable ["BATTLESPACE_STRATEGIC_UAV_SURVEY_INTERVAL", 900])};
    private _state = BATTLESPACE_SECTOR_STATES get _origin;
    _state set ["nextUavReconAt", CBA_missionTime + ([(missionNamespace getVariable ["BATTLESPACE_STRATEGIC_UAV_RECON_COOLDOWN", 900])] call KPLIB_RADIO_SERVER_COMMAND_DELAY)];
    [] call BATTLESPACE_LOGISTICS_SAVE;
    [format ["Dispatched UAV recon %1 (%2) from %3 over %4 at %5", _taskForceId, _class, _origin, ["unconfirmed report", "survey cell"] select _survey, mapGridPosition _target]] call BATTLESPACE_STRATEGIC_LOG;
};
