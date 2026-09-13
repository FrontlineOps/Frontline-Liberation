/* Pure shape validation shared by server/receiver. Old endpoint-only replies
   remain accepted, but never acquire invented category labels. */
params ["_lines", ["_meta", []], ["_limit", 128]];
_limit = _limit max 128 min 4096;
if !(_lines isEqualType [] && {_meta isEqualType []}) exitWith {false};
if (count _lines > _limit || {_lines findIf {
    !(_x isEqualType []) || {count _x != 2} || {_x findIf {
        !(_x isEqualType []) || {count _x != 3} || {_x findIf {!(_x isEqualType 0) || {!finite _x} || {abs _x > 1000000}} >= 0}
    } >= 0}
} >= 0}) exitWith {false};
if (_meta isEqualTo []) exitWith {true};
if (count _meta != 3 || {!((_meta select 0) isEqualTo 1)} || {!((_meta select 1) isEqualType [])} || {!((_meta select 2) isEqualType [])}) exitWith {false};
private _tags = _meta select 1;
private _stats = _meta select 2;
if (count _tags != count _lines || {count _stats != 13}) exitWith {false};
if (_tags findIf {
    !(_x isEqualType []) || {count _x != 2} || {!((_x select 0) in ["PROJECTILE","CHILD","FRAGMENT","GEOMETRY"])}
    || {!((_x select 1) isEqualType "")} || {count (_x select 1) > 128}
} >= 0) exitWith {false};
_stats findIf {!(_x isEqualType 0) || {!finite _x} || {_x < 0} || {_x > 100000000} || {_x != floor _x}} < 0
