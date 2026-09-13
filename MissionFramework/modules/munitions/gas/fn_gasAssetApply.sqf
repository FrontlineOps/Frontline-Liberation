/* Absolute GAME floors, never another additive explosion. Owner-local writes
   preserve higher native damage and do not resurrect, repair or replay a hit. */
if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {"Rejected sender"};
if (!isRemoteExecuted && {!isServer}) exitWith {"Server issue required"};
params [["_object",objNull,[objNull]],["_id","",[""]],["_at",-1,[0]],["_position",[],[[]]],["_floors",[],[[]]],["_source",objNull,[objNull]]];
if (!(missionNamespace getVariable ["KPLIB_munitions_blast_enabled",true])
    || {!(missionNamespace getVariable ["KPLIB_munitions_gas_assets",true])}) exitWith {"Disabled"};
if (!local _object || {!([_object] call KPLIB_fnc_gasAssetEligible)}) exitWith {"Not local / protected / ineligible"};
if (_id == "" || {count _id > 128} || {!finite _at} || {CBA_missionTime - _at > 9} || {_at > CBA_missionTime + 0.5}) exitWith {"Stale / invalid identity"};
if (count _position != 3 || {_position findIf {!(_x isEqualType 0) || {!finite _x} || {abs _x > 1000000}} >= 0}) exitWith {"Invalid position"};
if (getPosASL _object distance _position > 1) exitWith {"Object moved"};
if (_floors isEqualTo [] || {count _floors > 16} || {_floors findIf {
    !(_x isEqualType [] && {count _x == 4} && {(_x select 0) isEqualType 0} && {finite (_x select 0)}
        && {_x select 0 == floor (_x select 0)} && {_x select 0 >= -1} && {_x select 0 < 128}
        && {(_x select 1) isEqualType ""} && {count (_x select 1) <= 128}
        && {(_x select 2) isEqualType 0} && {finite (_x select 2)} && {_x select 2 >= 0} && {_x select 2 <= 1}
        && {(_x select 3) isEqualType 0} && {finite (_x select 3)} && {_x select 3 >= 0} && {_x select 3 <= 1})
} >= 0}) exitWith {"Invalid component floors"};
private _indices = _floors apply {_x select 0};
if (count (_indices arrayIntersect _indices) != count _indices) exitWith {"Duplicate components"};
private _hp = getAllHitPointsDamage _object;
private _names = _hp param [0,[]];
if (_floors findIf {
    private _index = _x select 0;
    if (_index == -1) then {_names isNotEqualTo []} else {_index >= count _names || {(_names select _index) != (_x select 1)}}
} >= 0) exitWith {"Component layout changed"};
private _seen = (_object getVariable ["KPLIB_gasAssetApplied",[]]) select {CBA_missionTime - (_x select 1) < 10};
if (count _seen >= 128 || {_seen findIf {_x select 0 == _id} >= 0}) exitWith {"Duplicate / rate cap"};
_seen pushBack [_id,CBA_missionTime];
_object setVariable ["KPLIB_gasAssetApplied",_seen];
private _result = [];
{
    _x params ["_index","_name","_floor","_baseline"];
    if (!alive _object) exitWith {};
    private _before = if (_index < 0) then {damage _object} else {_object getHitIndex _index};
    if (_before + 0.001 < _baseline) then {
        _result pushBack [_name,_floor,_before,"Skipped: repaired since observation"];
        continue;
    };
    if (_floor > _before + 0.0001) then {
        if (_index < 0) then {
            // Only objects without component data use global damage.
            _object setDamage [_floor,true,_source,_source];
        } else {
            _object setHitIndex [_index,_floor,true,_source,_source];
        };
    };
    private _after = if (_index < 0) then {damage _object} else {_object getHitIndex _index};
    _result pushBack [_name,_floor,_before,_after];
} forEach _floors;
_object setVariable ["KPLIB_gasAssetLast",[_id,CBA_missionTime,_result]];
[objNull,"PRESSURE ASSET APPLY",getPosASL _object,[_id,typeOf _object,_result],_object] call KPLIB_fnc_munitionsEvent;
format ["Applied on owner %1: %2",clientOwner,_result]
