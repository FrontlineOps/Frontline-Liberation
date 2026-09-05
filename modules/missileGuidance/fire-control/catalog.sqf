/*
    Faction generation runs before missile-guidance initialization. Register
    installed selected-faction capabilities, not legacy vehicle class names.
    Native SAMs keep native fire control. Custom control requires a calibrated
    ground-SAM ammunition profile; guidance coefficients stay in missiles/.
*/
IADS_SearchRadarClasses = [];
IADS_LaunchVehicleClasses = [];
IADS_VLS = [];
IADS_IGNORE_TURN = [];
IADS_POINT_DEFENSE = [];
IADS_CRAM = [];

{
    private _catalog = _y;
    {
        private _class = _x;
        private _capability = [_class] call KPLIB_fnc_getVehicleAirDefense;
        if (_capability get "radar") then {IADS_SearchRadarClasses pushBackUnique _class};
        private _ammos = _capability get "missileAmmo";
        private _profiles = _ammos apply {IADS_AmmoToMissile getOrDefault [_x, ""]};
        if (_profiles isEqualTo [] || {(_profiles findIf {!(_x in ["SA-6", "SA-15", "SA-20", "Tamir"])}) >= 0}) then {continue};
        IADS_LaunchVehicleClasses pushBackUnique _class;
        if ((_profiles findIf {(IADS_Missiles get _x) param [5, false]}) >= 0) then {IADS_VLS pushBackUnique _class};
        if ("SA-20" in _profiles) then {IADS_IGNORE_TURN pushBackUnique _class};
        if ((_profiles arrayIntersect ["SA-15", "SA-20", "Tamir"]) isNotEqualTo []) then {IADS_POINT_DEFENSE pushBackUnique _class};
        if ("Tamir" in _profiles) then {IADS_CRAM pushBackUnique _class};
    } forEach (_catalog getOrDefault ["aa", []]);
} forEach (missionNamespace getVariable ["KPLIB_autoFactionCatalogs", createHashMap]);
