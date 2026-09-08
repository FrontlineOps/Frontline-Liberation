KPLIB_INTEL_SERVER_COMMIT_PRISONER = {
    params [["_unit", objNull, [objNull]], ["_caller", objNull, [objNull]], ["_source", "escort", [""]]];
    if (!(call KPLIB_INTEL_SERVER_MUTATION_ALLOWED) || {!KPLIB_intelligence_enabled}) exitWith {false};
    if !([_caller, _unit, KPLIB_intelligence_delivery_distance] call KPLIB_INTEL_SERVER_ACTOR_VALID) exitWith {false};
    if (isPlayer _unit || {!(_unit isKindOf "Man")} || {vehicle _unit isNotEqualTo _unit} || {!(_unit getVariable ["KPLIB_intelligencePrisoner", false])}) exitWith {false};
    if (_unit getVariable ["KPLIB_intelligenceDelivered", false]) exitWith {true};
    private _site = [getPosATL _unit] call KPLIB_INTEL_SERVER_GET_SITE;
    if (_site isEqualTo [] || {_site isNotEqualTo ([getPosATL _caller] call KPLIB_INTEL_SERVER_GET_SITE)}) exitWith {false};
    private _sources = localNamespace getVariable "KPLIB_INTEL_SOURCES";
    private _entry = _sources getOrDefault [netId _unit, []];
    if (_entry isEqualTo [] || {(_entry # 0) isNotEqualTo _unit}) exitWith {false};
    private _detainees = localNamespace getVariable "KPLIB_INTEL_DETAINEES";
    if (count _detainees >= KPLIB_intelligence_max_detainees) exitWith {false};
    private _caseId = "";
    {
        if ((_y getOrDefault ["target", objNull]) isEqualTo _unit && {(_y get "stage") == 1} && {(_y get "status") == "ACTIVE"}) exitWith {_caseId = _x};
    } forEach (localNamespace getVariable "KPLIB_INTEL_CASES");
    private _id = call KPLIB_INTEL_SERVER_NEW_ID;
    _detainees set [_id, createHashMapFromArray [
        ["id", _id], ["unit", _unit], ["source", _entry], ["case", _caseId], ["site", _site],
        ["actor", objNull], ["endsAt", -1], ["startedAt", -1]
    ]];
    _sources deleteAt (netId _unit);
    _unit setVariable ["KPLIB_intelligenceDelivered", true, true];
    _unit setVariable ["KPLIB_intelligenceDetained", true, true];
    _unit setVariable ["KPLIB_intelligenceDetaineeId", _id, true];
    _unit setVariable ["KPLIB_intelligenceEscort", objNull, true];
    _unit setVariable ["KPLIB_surrenderEscortActive", nil, true];
    private _oldGroup = group _unit;
    private _group = createGroup [GRLIB_side_civilian, true];
    _group setVariable ["acex_headless_blacklist", true, true];
    [_unit] joinSilent _group;
    [_unit] remoteExecCall ["KPLIB_INTEL_LOCAL_DETAIN", 0];
    [{
        params ["_unit"];
        if (!isNull _unit && {_unit getVariable ["KPLIB_intelligenceDetained", false]}) then {
            [_unit] remoteExecCall ["KPLIB_INTEL_LOCAL_DETAIN", owner _unit];
        };
    }, [_unit], 1] call CBA_fnc_waitAndExecute;
    if (!isNull _oldGroup && {units _oldGroup isEqualTo []}) then {deleteGroup _oldGroup};
    if !(_unit getVariable ["KPLIB_intelligenceCaptureCounted", false]) then {
        stats_prisoners_captured = (missionNamespace getVariable ["stats_prisoners_captured", 0]) + 1;
        _unit setVariable ["KPLIB_intelligenceCaptureCounted", true];
    };
    ["INFO", 0, "Prisoner detained. Approach them and select Interrogate prisoner to obtain information."] remoteExecCall ["KPLIB_INTEL_CLIENT_NOTIFY", _caller];
    call KPLIB_INTEL_SERVER_CHANGED;
    true
};

KPLIB_INTEL_SERVER_INTERROGATION_VALID = {
    params ["_entry", "_actor"];
    private _unit = _entry get "unit";
    [_actor, _unit, KPLIB_intelligence_interaction_distance] call KPLIB_INTEL_SERVER_ACTOR_VALID
        && {vehicle _unit isEqualTo _unit}
        && {lifeState _unit != "INCAPACITATED"}
        && {!(_unit getVariable ["ACE_isUnconscious", false])}
        && {([getPosATL _unit] call KPLIB_INTEL_SERVER_GET_SITE) isEqualTo (_entry get "site")}
        && {([getPosATL _actor] call KPLIB_INTEL_SERVER_GET_SITE) isEqualTo (_entry get "site")}
};

KPLIB_INTEL_SERVER_REQUEST_ACTION = {
    params [["_unit", objNull, [objNull]], ["_action", "", [""]]];
    private _caller = call KPLIB_INTEL_SERVER_GET_CALLER;
    if (isNull _caller || {!KPLIB_intelligence_enabled}) exitWith {};
    private _owner = remoteExecutedOwner;
    [{
        params ["_caller", "_owner", "_unit", "_action"];
        if (isNull _caller || {owner _caller != _owner}) exitWith {};
        [_caller, _unit, _action] call KPLIB_INTEL_SERVER_DO_ACTION;
    }, [_caller, _owner, _unit, _action]] call CBA_fnc_execNextFrame;
};

KPLIB_INTEL_SERVER_DO_ACTION = {
    params ["_caller", "_unit", "_action"];
    if !(call KPLIB_INTEL_SERVER_MUTATION_ALLOWED) exitWith {false};
    private _detainees = localNamespace getVariable "KPLIB_INTEL_DETAINEES";
    private _entry = createHashMap;
    {if ((_y get "unit") isEqualTo _unit) exitWith {_entry = _y}} forEach _detainees;
    if (_action == "CANCEL") exitWith {
        if (count _entry > 0 && {(_entry get "actor") isEqualTo _caller}) then {
            _entry set ["actor", objNull];
            _entry set ["endsAt", -1];
            _unit setVariable ["KPLIB_intelligenceInterrogating", false, true];
        };
        true
    };
    if !([_caller, _unit, KPLIB_intelligence_interaction_distance] call KPLIB_INTEL_SERVER_ACTOR_VALID) exitWith {false};
    if (_action == "INTERROGATE") exitWith {
        if (count _entry == 0 || {!isNull (_entry get "actor")} || {!([_entry, _caller] call KPLIB_INTEL_SERVER_INTERROGATION_VALID)}) exitWith {false};
        if (values _detainees findIf {(_x get "actor") isEqualTo _caller} >= 0) exitWith {false};
        _entry set ["actor", _caller];
        _entry set ["startedAt", CBA_missionTime];
        _entry set ["endsAt", CBA_missionTime + KPLIB_intelligence_interrogation_duration];
        _unit setVariable ["KPLIB_intelligenceInterrogating", true, true];
        [_unit, KPLIB_intelligence_interrogation_duration] remoteExecCall ["KPLIB_INTEL_CLIENT_INTERROGATE", _caller];
        true
    };
    private _case = createHashMap;
    {
        if ((_y getOrDefault ["target", objNull]) isEqualTo _unit && {(_y get "status") == "ACTIVE"}) exitWith {_case = _y};
    } forEach (localNamespace getVariable "KPLIB_INTEL_CASES");
    if (count _case == 0) exitWith {false};
    if !([_caller, _unit] call KPLIB_INTEL_SERVER_SOURCE_VISIBLE) exitWith {false};
    if (_action == "HVT" && {(_case get "stage") == 1}) exitWith {
        if (isPlayer _unit || {_unit getVariable ["KPLIB_intelligencePrisoner", false]}) exitWith {false};
        if (!captive _unit && {(_case get "guards") findIf {alive _x && {!captive _x} && {!(_x getVariable ["KPLIB_intelligencePrisoner", false])} && {_x distance _unit < 100}} >= 0}) exitWith {
            [_caller, "Secure the HVT's nearby guards first."] call KPLIB_INTEL_SERVER_REJECT;
            false
        };
        private _group = createGroup [GRLIB_side_civilian, true];
        private _result = [_unit, _group] call KPLIB_SURRENDER_SERVER_CONVERT_UNIT;
        if !(_result # 0) then {deleteGroup _group};
        _result # 0
    };
    if (_action == "SABOTAGE" && {(_case get "stage") == 2}) exitWith {
        // Completion is verified against the registered objective; arbitrary props cannot grant effects.
        private _success = [_case] call KPLIB_INTEL_SERVER_COMPLETE_CASE;
        if (_success) then {
            _unit setVariable ["KPLIB_intelligenceObjective", "", true];
            _unit setDamage 1;
        };
        _success
    };
    false
};

KPLIB_INTEL_SERVER_TICK_CUSTODY = {
    if !(call KPLIB_INTEL_SERVER_MUTATION_ALLOWED) exitWith {};
    private _detainees = localNamespace getVariable "KPLIB_INTEL_DETAINEES";
    {
        private _id = _x;
        private _entry = _detainees get _id;
        private _unit = _entry get "unit";
        if (isNull _unit || {!alive _unit}) then {
            _detainees deleteAt _id;
            call KPLIB_INTEL_SERVER_CHANGED;
            continue;
        };
        if (([getPosATL _unit] call KPLIB_INTEL_SERVER_GET_SITE) isNotEqualTo (_entry get "site")) then {
            _entry set ["actor", objNull];
            _unit setVariable ["KPLIB_intelligenceInterrogating", false, true];
            _unit setVariable ["KPLIB_intelligenceDelivered", false, true];
            _unit setVariable ["KPLIB_intelligenceDetained", false, true];
            private _source = _entry get "source";
            (localNamespace getVariable "KPLIB_INTEL_SOURCES") set [netId _unit, _source];
            _detainees deleteAt _id;
            [_unit, "detention site lost"] call KPLIB_SURRENDER_SERVER_RELEASE_ESCORT;
            call KPLIB_INTEL_SERVER_CHANGED;
            continue;
        };
        private _actor = _entry get "actor";
        if (isNull _actor) then {
            if ((_entry get "endsAt") >= 0) then {
                _entry set ["endsAt", -1];
                _unit setVariable ["KPLIB_intelligenceInterrogating", false, true];
            };
            continue;
        };
        if !([_entry, _actor] call KPLIB_INTEL_SERVER_INTERROGATION_VALID) then {
            _entry set ["actor", objNull];
            _entry set ["endsAt", -1];
            _unit setVariable ["KPLIB_intelligenceInterrogating", false, true];
            continue;
        };
        if (CBA_missionTime < (_entry get "endsAt")) then {continue};
        // Consume before publishing or advancing; duplicate requests cannot reissue this source.
        _detainees deleteAt _id;
        private _source = _entry get "source";
        [_source, (_entry get "case") == ""] call KPLIB_INTEL_SERVER_REVEAL_SOURCE;
        private _case = (localNamespace getVariable "KPLIB_INTEL_CASES") getOrDefault [_entry get "case", createHashMap];
        if (count _case > 0 && {(_case get "stage") == 1} && {(_case get "target") isEqualTo _unit}) then {
            [_case, "The recovered HVT was interrogated and identified the support site."] call KPLIB_INTEL_SERVER_ADVANCE_CASE;
        };
        private _group = group _unit;
        deleteVehicle _unit;
        if (units _group isEqualTo []) then {deleteGroup _group};
        ["INFO", 0, "Interrogation complete. The source report and any follow-up mission are in Intelligence Case Files."] remoteExecCall ["KPLIB_INTEL_CLIENT_NOTIFY", _actor];
        call KPLIB_INTEL_SERVER_CHANGED;
    } forEach keys _detainees;
};
