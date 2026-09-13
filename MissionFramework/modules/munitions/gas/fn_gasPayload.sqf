/* Bounded replay-only schema. No received field can alter simulation state. */
params ["_fields"];
if !(_fields isEqualType [] && {count _fields <= 1}) exitWith {false};
private _bad = _fields findIf {
    call {
        private _f = _x;
        if !(_f isEqualType [] && {count _f in [12,13]}) exitWith {true};
        if !((_f select 0) isEqualType "" && {count (_f select 0) <= 128}
            && {(_f select 1) isEqualType ""} && {count (_f select 1) <= 256}
            && {(_f select 2) isEqualType true} && {(_f select 7) isEqualType true}
            && {(_f select 8) in ["GAS","LEGACY"]}
            && {(_f select 10) isEqualType ""} && {count (_f select 10) <= 2048}
            && {(_f select 11) isEqualType ""} && {count (_f select 11) <= 2048}) exitWith {true};
        if ([3,4,5] findIf {!((_f select _x) isEqualType 0) || {!finite (_f select _x)} || {_f select _x <= 0} || {_f select _x > 10000}} >= 0) exitWith {true};
        private _nodes = _f select 6;
        if !(_nodes isEqualType [] && {count _nodes <= 128}) exitWith {true};
        if (_nodes findIf {
            !(_x isEqualType [] && {count _x == 3} && {(_x select 0) isEqualType []} && {count (_x select 0) == 3}
                && {(_x select 0) findIf {!(_x isEqualType 0) || {!finite _x} || {abs _x > 1000000}} < 0}
                && {(_x select 1) isEqualType 0} && {finite (_x select 1)}
                && {(_x select 2) isEqualType 0} && {finite (_x select 2)})
        } >= 0) exitWith {true};
        private _frames = _f select 9;
        if !(_frames isEqualType [] && {count _frames <= 12}) exitWith {true};
        if (_f select 8 == "LEGACY") exitWith {_frames isNotEqualTo []};
        if (count _nodes != 64) exitWith {true};
        private _previous = -1;
        if (_frames findIf {
            call {
                if !(_x isEqualType [] && {count _x == 2} && {(_x select 0) isEqualType 0}
                    && {finite (_x select 0)} && {_x select 0 >= 0} && {_x select 0 >= _previous}
                    && {_x select 0 <= (_f select 4) + 0.01}
                    && {(_x select 1) isEqualType []} && {count (_x select 1) == 64}) exitWith {true};
                _previous = _x select 0;
                (_x select 1) findIf {!(_x isEqualType [] && {count _x == 4} && {_x findIf {!(_x isEqualType 0) || {!finite _x}} < 0})} >= 0
            }
        } >= 0) exitWith {true};
        if (count _f == 12) exitWith {false};
        private _info = _f select 12;
        if !(_info isEqualType [] && {count _info == 3}) exitWith {true};
        _info params ["_n", "_requested", "_indices"];
        if !(_n isEqualType 0 && {_n in [7,9,11,13,15]} && {_requested isEqualType 0} && {finite _requested} && {_requested >= 0.5} && {_requested <= 12}
            && {_indices isEqualType []} && {count _indices == 64}) exitWith {true};
        _indices findIf {!(_x isEqualType 0) || {!finite _x} || {_x != floor _x} || {_x < 0} || {_x >= _n^3}} >= 0
    }
};
_bad < 0
