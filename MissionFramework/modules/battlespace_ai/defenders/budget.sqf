// One allowance for paid ground combat formations, including troops in transit.
// Reassignment never debits resources or consumes a formation slot.
BATTLESPACE_GROUND_OPERATION_KINDS = ["DEFENDER", "RESERVE", "BATTLEGROUP", "DEEP RECONNAISSANCE PATROL"];

BATTLESPACE_GROUND_FORCE_COUNT = {
    private _count = 0;
    {
        private _kind = _y getOrDefault ["kind", ""];
        if (_kind in BATTLESPACE_GROUND_OPERATION_KINDS) then {
            _count = _count + 1;
        };
    } forEach BATTLESPACE_STRATEGIC_OPERATIONS;
    _count
};

BATTLESPACE_GROUND_ALLOCATION_BLOCK = {
    private _opened = missionNamespace getVariable ["BATTLESPACE_GROUND_ALLOCATION_OPENED", -1e9];
    if (CBA_missionTime - _opened >= BATTLESPACE_STRATEGIC_DEFENDER_DECISION_INTERVAL) then {
        BATTLESPACE_GROUND_ALLOCATION_OPENED = CBA_missionTime;
        BATTLESPACE_GROUND_FORMATIONS_CREATED = 0;
    };
    if ([] call BATTLESPACE_GROUND_FORCE_COUNT >= BATTLESPACE_STRATEGIC_GROUND_FORCE_CAP) exitWith {"Global ground force allowance reached"};
    if ((missionNamespace getVariable ["BATTLESPACE_GROUND_FORMATIONS_CREATED", 0]) >= BATTLESPACE_STRATEGIC_GROUND_FORMATIONS_PER_TICK) exitWith {"Formation allowance used; awaiting next evaluation"};
    ""
};
