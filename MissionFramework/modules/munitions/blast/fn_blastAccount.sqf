/* Raw ACE damage accounting, per body part. Each credit is consumed once.
   MODEL consumes earlier native damage; NATIVE consumes an earlier supplement.
   Credits persist for the bounded delivery lifetime, but match native damage
   within 0.5 s of the original explosion, not the delayed delivery timestamp.
   Near-simultaneous same-ammo native events remain conservatively pooled.
   This does not identify individual real-world injury mechanisms. */
params ["_ledger", "_mode", "_ammo", "_amount", "_now", ["_eventAt", -1]];
if (_eventAt < 0) then {_eventAt = _now};
private _entries = (_ledger getOrDefault ["entries", []]) select {_now - (_x select 0) <= 10};
_ledger set ["entries", _entries];
private _remaining = +_amount;
if (_mode == "MODEL" && {_now <= (_ledger getOrDefault ["saturated", -1])}) exitWith {[[0,0,0,0,0,0], +_amount]};
private _helper = (toLower _ammo) find "ace_explosion_reflection_" == 0 || {_ammo == "vehiclehit"};
private _thermal = _ammo == "burn" || {_ammo == "burning"};
private _opposite = if (_mode == "MODEL") then {2} else {3};
{
    _x params ["", "_entryAmmo"];
    private _entryHelper = (toLower _entryAmmo) find "ace_explosion_reflection_" == 0 || {_entryAmmo == "vehiclehit"};
    private _entryThermal = _entryAmmo == "burn" || {_entryAmmo == "burning"};
    private _entryAt = _x param [4, _x select 0];
    // Native burn events lack a specific explosion identity. Preserve their
    // existing short rolling credit window independently of pressure timing.
    private _matchesTime = if (_thermal && {_entryThermal}) then {
        abs (_now - (_x select 0)) <= 2.5
    } else {
        abs (_eventAt - _entryAt) <= 0.5
    };
    if (_matchesTime && {_entryAmmo == _ammo || {_helper && {!_entryThermal}} || {_entryHelper && {!_thermal}} || {_thermal && {_entryThermal}}}) then {
        private _credit = _x select _opposite;
        for "_part" from 0 to 5 do {
            private _used = (_remaining select _part) min (_credit select _part);
            _remaining set [_part, (_remaining select _part) - _used];
            _credit set [_part, (_credit select _part) - _used];
        };
    };
} forEach _entries;
_entries = _entries select {((_x select 2) findIf {_x > 0}) >= 0 || {((_x select 3) findIf {_x > 0}) >= 0}};
if (_remaining findIf {_x > 0} >= 0) then {
    if (count _entries >= 128) then {
        _ledger set ["saturated", _now + 10];
        if (_mode == "MODEL") then {_remaining = [0,0,0,0,0,0]};
    } else {
        private _entry = [_now, _ammo, [0,0,0,0,0,0], [0,0,0,0,0,0], _eventAt];
        _entry set [if (_mode == "MODEL") then {3} else {2}, +_remaining];
        _entries pushBack _entry;
    };
};
_ledger set ["entries", _entries];
private _credited = [];
for "_part" from 0 to 5 do {_credited pushBack ((_amount select _part) - (_remaining select _part))};
[_remaining, _credited]
