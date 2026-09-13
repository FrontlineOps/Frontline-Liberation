/* Diagnostic provenance only. Config inheritance is not munition calibration. */
params [["_ammo", "", [""]]];
private _cfg = configFile >> "CfgAmmo" >> _ammo;
if (!isClass _cfg) exitWith {[]};
private _rows = ["  Physical source status: UNVALIDATED. Fragmentation metadata alone does not define gas energy, an initial pressure field, chemistry or an injury law."];
{
    private _field = _x;
    private _entry = _cfg >> _field;
    if (isNumber _entry) then {
        private _ancestor = _cfg;
        private _origin = "UNRESOLVED";
        for "_depth" from 0 to 31 do {
            private _direct = configProperties [_ancestor, "true", false];
            if (_direct findIf {configName _x == _field} >= 0) exitWith {
                _origin = configName _ancestor;
            };
            _ancestor = inheritsFrom _ancestor;
            if (isNull _ancestor) exitWith {};
        };
        _rows pushBack format ["  %1=%2; defining class=%3; inherited=%4", _field, getNumber _entry, _origin, _origin != configName _cfg];
    } else {
        _rows pushBack format ["  %1 has no numeric config entry; any ACE runtime fallback is not measured source data.", _field];
    };
} forEach ["ace_frag_charge", "ace_frag_metal", "ace_frag_gurney_c"];
_rows pushBack "  ACE charge/metal inputs are grams. Gurney metadata belongs to fragmentation; it is not a validated total blast-energy conversion.";
_rows
