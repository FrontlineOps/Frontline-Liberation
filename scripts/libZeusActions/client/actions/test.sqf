KC_DEBUG_TEST = false;
KC_DEBUG_POS = [];
KC_DEBUG_NEXT_TICK = 0;
KC_DEBUG_TEST_PFH = { 
 
    if(KC_DEBUG_TEST == true) then { 
        private _houses = (getPos player) nearObjects ["Building", 50];

        {
            private _bPos = getPos _x vectorAdd [0,0,1];
            drawIcon3D ["\a3\ui_f\data\IGUI\Cfg\Cursors\selectover_ca.paa", [1,1,0,1], _bPos, 0.75, 0.75, 0, typeOf _x, 1, 0.035, "TahomaB"];
            for "_i" from 0 to 50 do
            {
                private _exit = _x buildingExit _i;

                if(_exit isEqualTo [0,0,0]) then { continue };

                private _offseted = _exit vectorAdd [0,0,1];

                drawIcon3D ["\a3\ui_f\data\IGUI\Cfg\Cursors\selectover_ca.paa", [1,0,0,1], _offseted, 0.55, 0.55, 0, format ["E %1", _i], 1, 0.0275, "TahomaB"];
                drawLine3D [_bPos, _offseted, [1,0,0,1]];
            };

            private _positions = _x buildingPos -1;

            {
                

                private _offseted = _x;

                drawIcon3D ["\a3\ui_f\data\IGUI\Cfg\Cursors\selectover_ca.paa", [0,1,0,1], _offseted, 0.55, 0.55, 0, format ["P %1", _forEachIndex], 1, 0.0275, "TahomaB"];
                drawLine3D [_bPos, _offseted, [0,1,0,1]];
            } forEach _positions;
        } forEach _houses;

        private _nearRoads = ((getPos player) nearRoads 10);

        {
            private _nearRoad = _x;
            if(!isNil { _nearRoad }) then {

                private _connectedRoads = roadsConnectedTo [_nearRoad, true];

                {
                    private _pos = getPos _x;
                    drawIcon3D ["\a3\ui_f\data\IGUI\Cfg\Cursors\selectover_ca.paa", [0,1,0,1], _pos, 0.55, 0.55, 0, format ["C %1", _forEachIndex], 1, 0.0275, "TahomaB"];
                } forEach _connectedRoads;

                drawIcon3D ["\a3\ui_f\data\IGUI\Cfg\Cursors\selectover_ca.paa", [1,0,0,1], getPos _nearRoad, 0.55, 0.55, 0, "R", 1, 0.0275, "TahomaB"];
            };
        } forEach _nearRoads;
        if (CBA_missionTime > KC_DEBUG_NEXT_TICK) then {
            KC_DEBUG_POS = [getPosATL player, 125, 50, -10] call BIS_fnc_findOverwatch;
            //KC_DEBUG_POS = getPos player;
            KC_DEBUG_NEXT_TICK = CBA_missionTime + 5;
            KC_BEST_PLACES = selectBestPlaces [KC_DEBUG_POS, 50, "10 * forest + 5 * trees + 5 * houses - 10 * sea - 30 * meadow - 30 * windy", 5, 40];

            

            KC_OVERLOOKPLACES = selectBestPlaces [getPos player, 1000, "2 * hills + 3 * meadow - 5 * houses + 1 * forest - 50 * sea", 50, 40];
        };
        drawIcon3D ["\a3\ui_f\data\IGUI\Cfg\Cursors\selectover_ca.paa", [1,0,0,1], KC_DEBUG_POS, 0.55, 0.55, 0, "OW", 1, 0.0275, "TahomaB"];
        drawLine3D [getPos player, KC_DEBUG_POS, [0,1,0,1]];


        {
            _x params ["_pos", "_expr"];
            drawIcon3D ["\a3\ui_f\data\IGUI\Cfg\Cursors\selectover_ca.paa", [1,0,1,1], _pos, 0.55, 0.55, 0, str _expr, 1, 0.0275, "TahomaB"];
            drawLine3D [_pos, KC_DEBUG_POS, [0,1,0,1]];
        } forEach KC_BEST_PLACES;

        {
            drawIcon3D ["\a3\ui_f\data\IGUI\Cfg\Cursors\selectover_ca.paa", [1,0,0,1], _x, 0.55, 0.55, 0, "P", 1, 0.0275, "TahomaB"];
        } forEach KC_PATH;

        {
            _x params ["_pos", "_expr"];
            drawIcon3D ["\a3\ui_f\data\IGUI\Cfg\Cursors\selectover_ca.paa", [1,1,1,1], _pos, 0.55, 0.55, 0, str _expr, 1, 0.0275, "TahomaB"];
            drawLine3D [_pos, getPos player, [0,1,0,1]];
        } forEach KC_OVERLOOKPLACES
    } else { 
 
        [_this select 1] call CBA_fnc_removePerFrameHandler; 
    }; 
}; 



private _statement = {
    params ["_position", "_objects", "_groups", "_waypoints", "_markers", "_hoveredEntity", "_args"];
    KC_DEBUG_TEST = !KC_DEBUG_TEST;

    if(KC_DEBUG_TEST == true) then {

        [
            {  _this call KC_DEBUG_TEST_PFH },
            0,
            []
        ] call CBA_fnc_addPerFrameHandler;
    };
};


private _action = ["testrender", "Toggle Test", ["", [1,1,1,1]], _statement, { true }] call zen_context_menu_fnc_createAction;
[_action, [], 0] call zen_context_menu_fnc_addAction;