/* Bounded recovery/ownership maintenance. Medical physiology remains ACM/ACE. */
if (isRemoteExecuted || {isNil "_KPLIB_blastTraumaServerContext"}) exitWith {};
private _now = CBA_missionTime;
private _enabled = missionNamespace getVariable ["KPLIB_munitions_trauma_enabled", true];
if (isServer) then {
    private _states = localNamespace getVariable "KPLIB_blastTraumaStates";
    private _keys = keys _states;
    private _cursor = localNamespace getVariable ["KPLIB_blastTraumaCursor", 0];
    for "_i" from 1 to (32 min count _keys) do {
        private _key = _keys select (_cursor mod count _keys);
        _cursor = _cursor + 1;
        private _state = _states get _key;
        private _unit = _state get "unit";
        if (isNull _unit || {!alive _unit}) then {
            _states deleteAt _key;
        } else {
            private _scores = [_state get "scores", _now - (_state get "at")] call KPLIB_fnc_blastTraumaDecay;
            if (!_enabled || {selectMax _scores < 0.005}) then {
                if (selectMax (_state get "scores") > 0) then {
                    _state set ["scores", [0, 0]];
                    _state set ["at", _now];
                    [_state] call KPLIB_fnc_blastTraumaSend;
                };
                if (_now - (_state get "last") > 600) then {_states deleteAt _key};
            };
            if (owner _unit != (_state get "owner")) then {[_state] call KPLIB_fnc_blastTraumaSend};
        };
    };
    localNamespace setVariable ["KPLIB_blastTraumaCursor", _cursor];
};
private _units = localNamespace getVariable "KPLIB_blastTraumaLocalUnits";
private _cursor = localNamespace getVariable ["KPLIB_blastTraumaLocalCursor", 0];
for "_i" from 1 to (32 min count _units) do {
    _cursor = _cursor mod count _units;
    private _unit = _units select _cursor;
    private _snapshot = _unit getVariable ["KPLIB_blastTraumaLocal", []];
    if (isNull _unit || {!local _unit} || {!alive _unit} || {_snapshot isEqualTo []}) then {
        if (!isNull _unit && {local _unit}) then {
            [_unit, "forceWalk", "frontline_blast", false] call ace_common_fnc_statusEffect_set;
        };
        _units deleteAt _cursor;
    } else {
        private _scores = [_snapshot select 3, _now - (_snapshot select 2)] call KPLIB_fnc_blastTraumaDecay;
        private _valid = _enabled && {isDamageAllowed _unit} && {_unit getVariable ["ace_medical_allowDamage", true]};
        private _walk = _valid && {(_scores select 1) >= 0.65};
        [_unit, "forceWalk", "frontline_blast", _walk] call ace_common_fnc_statusEffect_set;
        if (!_enabled || {selectMax _scores < 0.005}) then {
            // Keep the revision on the object to reject replayed snapshots,
            // but stop visiting recovered survivors every maintenance tick.
            _units deleteAt _cursor;
        } else {
            _cursor = _cursor + 1;
        };
    };
};
localNamespace setVariable ["KPLIB_blastTraumaLocalCursor", _cursor];
if (!hasInterface) exitWith {};
private _unit = missionNamespace getVariable ["ACE_player", player];
private _scores = [0, 0];
private _snapshot = _unit getVariable ["KPLIB_blastTraumaLocal", []];
if (_enabled && {alive _unit} && {local _unit} && {isNull curatorCamera}
    && {isDamageAllowed _unit} && {_unit getVariable ["ace_medical_allowDamage", true]}
    && {!(_unit getVariable ["ACE_isUnconscious", false])} && {_snapshot isNotEqualTo []}) then {
    _scores = [_snapshot select 3, _now - (_snapshot select 2)] call KPLIB_fnc_blastTraumaDecay;
};
localNamespace setVariable ["KPLIB_blastTraumaSway", 1 + 0.75 * ((_scores select 0) min 1) + 0.5 * ((_scores select 1) min 1)];
private _protection = (missionNamespace getVariable ["ace_hearing_earProtection", 0]) max 0 min 1;
private _muffle = ((_scores select 0) min 1) * (1 - _protection);
// ACE combines hearing sources using the lowest volume, not stacked multipliers.
private _oldMuffle = localNamespace getVariable ["KPLIB_blastTraumaMuffle", 0];
if (!isNil "ace_common_fnc_setHearingCapability" && {
    abs (_muffle - _oldMuffle) > 0.005 || {(_muffle > 0.005) != (_oldMuffle > 0.005)}
}) then {
    ["frontline_blast", 1 - 0.55 * _muffle, _muffle > 0.005, 0.25] call ace_common_fnc_setHearingCapability;
    localNamespace setVariable ["KPLIB_blastTraumaMuffle", _muffle];
};
private _blur = localNamespace getVariable ["KPLIB_blastTraumaBlur", -1];
private _oldBlur = localNamespace getVariable ["KPLIB_blastTraumaBlurAmount", 0];
if (_blur >= 0 && {
    abs ((_scores select 0) - _oldBlur) > 0.005 || {((_scores select 0) > 0.005) != (_oldBlur > 0.005)}
}) then {
    _blur ppEffectEnable ((_scores select 0) > 0.005);
    _blur ppEffectAdjust [0.35 * ((_scores select 0) min 1)];
    _blur ppEffectCommit 0.25;
    localNamespace setVariable ["KPLIB_blastTraumaBlurAmount", _scores select 0];
};

